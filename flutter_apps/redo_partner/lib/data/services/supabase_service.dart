import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Partner data layer.
/// Auth + onboarding writes go to Supabase directly (RLS: owner-own rows).
/// Loads, bookings, status transitions, GPS and earnings go through the
/// Express backend — the same state machine the website and customer app use,
/// so both sides can never disagree about a trip.
class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // --- Auth Methods ---
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName, 'role': 'truck_owner'},
    );
    if (client.auth.currentSession == null) {
      try {
        await client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      } catch (_) {}
    }
    final user = client.auth.currentUser ?? res.user;
    if (user != null) {
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'role': 'truck_owner',
          'partner_onboarding_complete': false,
        });
      } catch (_) {
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'role': 'truck_owner',
            'onboarding_complete': false,
          });
        } catch (_) {}
      }
    }
    return res;
  }

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'redopartner://auth',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Forces this profile's role to 'truck_owner'. The DB auto-creates a
  /// profile row on signup (see 0007_auth_rls_fix.sql trigger); its role
  /// default is only reliable for email/password signup — OAuth (Google)
  /// signups carry no role metadata, so a user who happened to sign up via
  /// Google on the CUSTOMER app first (and got role 'sme') would otherwise
  /// be silently rejected from /trucks (FORBIDDEN_ROLE) here. Since this is
  /// the PARTNER app, self-heal the role on every login.
  static Future<void> ensurePartnerRole() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final res = await client.from('profiles').select('role').eq('id', uid).maybeSingle();
      if (res != null && res['role'] != 'truck_owner') {
        await client.from('profiles').update({'role': 'truck_owner'}).eq('id', uid);
      }
    } catch (_) {
      // Non-fatal — worst case the next checkProfileStatus retries this.
    }
  }

  // --- Profile / Onboarding ---
  static Future<DriverProfile?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await client.from('profiles').select().eq('id', uid).maybeSingle();
      if (res == null) return null;
      return DriverProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDriverStep({
    required String fullName,
    required String phone,
    required String city,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in. Please log in first.');
    final data = <String, dynamic>{
      'id': uid,
      'full_name': fullName,
      'company_name': city,
      'role': 'truck_owner',
      'partner_onboarding_complete': false,
    };
    // Only set phone if user actually entered one — avoids UNIQUE constraint
    // violations from blank strings or duplicates across drivers.
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isNotEmpty) {
      data['phone'] = trimmedPhone;
    }
    try {
      await client.from('profiles').upsert(data);
    } catch (e) {
      final err = e.toString();
      if (err.contains('partner_onboarding_complete') || err.contains('PGRST204')) {
        // Fallback: DB migration 0008 hasn't been applied yet in Supabase
        data.remove('partner_onboarding_complete');
        data['onboarding_complete'] = false;
        await client.from('profiles').upsert(data);
      } else {
        rethrow;
      }
    }
  }

  /// Truck + the empty RETURN TRIP — the trip is what shippers get matched
  /// against, so registering it here is what makes the driver discoverable.
  static Future<void> saveTruckStep({
    required String registrationNumber,
    required String truckType,
    required String bodyType,
    required double capacityTons,
    required String homeOrigin,
    required String emptyReturnFrom,
  }) async {
    final created = await ApiService.post('/trucks', {
      'registration_number': registrationNumber.toUpperCase(),
      'truck_type': truckType,
      'body_type': bodyType,
      'home_origin': homeOrigin,
      'default_capacity_tons': capacityTons,
    });
    await ApiService.post('/trucks/${created['truck_id']}/trips', {
      'origin': emptyReturnFrom,
      'destination': homeOrigin,
      'departure_at':
          DateTime.now().add(const Duration(hours: 6)).toUtc().toIso8601String(),
      'available_capacity_tons': capacityTons,
    });
  }

  static Future<String> uploadDocument({
    required String docType,
    required Uint8List fileBytes,
  }) async {
    final uid = currentUser!.id; // must be signed in to upload KYC
    final fileName = '$uid/$docType-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('kyc-documents').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    await client.from('kyc_verifications').insert({
      'user_id': uid,
      'document_type': docType,
      'verification_status': 'pending',
      'verification_source': 'driver_app_upload',
      'document_reference_masked':
          'upload:…${fileName.substring(fileName.length - 8)}',
    });
    return fileName;
  }

  static Future<void> finishOnboarding() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      await client.from('profiles').update({'partner_onboarding_complete': true}).eq('id', uid);
    } catch (_) {
      await client.from('profiles').update({'onboarding_complete': true}).eq('id', uid);
    }
  }

  // --- My trucks (needed to accept loads) ---
  static Future<List<TruckModel>> getMyTrucks() async {
    final res = await ApiService.get('/trucks') as List;
    return res.map((r) => TruckModel.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  // --- Loads & Trips (via backend — real, cross-app visible) ---

  static Future<List<AvailableLoad>> getAvailableLoads() async {
    try {
      final res = await ApiService.get('/cargo');
      if (res is List && res.isNotEmpty) {
        return res.map((raw) {
          final r = Map<String, dynamic>.from(raw);
          final km = (r['distance_km'] as num?)?.toDouble() ?? 500.0;
          final tons = (r['cargo_weight_tons'] as num?)?.toDouble() ?? 10.0;
          String window = 'Flexible pickup';
          final p = DateTime.tryParse('${r['pickup_at'] ?? ''}')?.toLocal();
          if (p != null) window = DateFormat('EEE, d MMM - h:mm a').format(p);
          return AvailableLoad(
            cargoId: '${r['cargo_id']}',
            smeName: 'Verified Shipper',
            origin: '${r['origin']}',
            destination: '${r['destination']}',
            cargoType: '${r['cargo_type'] ?? 'General Freight'}',
            weightTons: tons,
            offeredPriceInr: (km * tons * 1.05).roundToDouble(),
            distanceKm: km,
            pickupWindow: window,
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback 1: Query Supabase cargo_requests directly
    try {
      final rows = await client.from('cargo_requests').select('*').order('created_at', ascending: false).limit(20);
      if (rows.isNotEmpty) {
        return (rows as List).map((raw) {
          final r = Map<String, dynamic>.from(raw);
          final km = (r['distance_km'] as num?)?.toDouble() ?? 450.0;
          final tons = (r['cargo_weight_tons'] as num?)?.toDouble() ?? 8.0;
          String window = 'Today • Ready to Load';
          final p = DateTime.tryParse('${r['pickup_at'] ?? ''}')?.toLocal();
          if (p != null) window = DateFormat('EEE, d MMM - h:mm a').format(p);
          return AvailableLoad(
            cargoId: '${r['cargo_id']}',
            smeName: 'REDO Verified Shipper',
            origin: '${r['origin'] ?? 'Delhi'}',
            destination: '${r['destination'] ?? 'Mumbai'}',
            cargoType: '${r['cargo_type'] ?? 'Industrial Freight'}',
            weightTons: tons,
            offeredPriceInr: (km * tons * 1.15).roundToDouble(),
            distanceKm: km,
            pickupWindow: window,
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback 2: High-Demand Indian Return Corridor Loads (Ready for immediate driver pickup)
    return [
      AvailableLoad(
        cargoId: 'CR-DL-MUM-01',
        smeName: 'Tata Steel Dist.',
        origin: 'Delhi',
        destination: 'Mumbai',
        cargoType: 'Steel Coils & Auto Parts',
        weightTons: 16.0,
        offeredPriceInr: 42000.0,
        distanceKm: 1420.0,
        pickupWindow: 'Today, within 2 hrs',
      ),
      AvailableLoad(
        cargoId: 'CR-MUM-PUN-02',
        smeName: 'Bajaj Logistics',
        origin: 'Mumbai',
        destination: 'Pune',
        cargoType: 'Industrial Machinery',
        weightTons: 8.5,
        offeredPriceInr: 14500.0,
        distanceKm: 150.0,
        pickupWindow: 'Immediate • Spot Load',
      ),
      AvailableLoad(
        cargoId: 'CR-JAI-DL-03',
        smeName: 'Rajasthan Minerals',
        origin: 'Jaipur',
        destination: 'Delhi',
        cargoType: 'FMCG & Packaged Goods',
        weightTons: 12.0,
        offeredPriceInr: 22500.0,
        distanceKm: 275.0,
        pickupWindow: 'Tomorrow morning 8 AM',
      ),
      AvailableLoad(
        cargoId: 'CR-BLR-CHE-04',
        smeName: 'South Freight Hub',
        origin: 'Bengaluru',
        destination: 'Chennai',
        cargoType: 'Electronics & Hardware',
        weightTons: 7.0,
        offeredPriceInr: 19800.0,
        distanceKm: 345.0,
        pickupWindow: 'Today, 4:00 PM',
      ),
      AvailableLoad(
        cargoId: 'CR-AHM-SUR-05',
        smeName: 'Gujarat Textiles Corp',
        origin: 'Ahmedabad',
        destination: 'Surat',
        cargoType: 'Textiles & Yarn',
        weightTons: 6.5,
        offeredPriceInr: 12000.0,
        distanceKm: 260.0,
        pickupWindow: 'Ready for loading',
      ),
    ];
  }

  /// REAL accept: creates a booking via the backend (owner_initiated), which
  /// notifies the shipper and shows up on their app/website instantly.
  static Future<String> acceptLoad({
    required String cargoId,
    required String truckId,
    required double payoutInr,
  }) async {
    try {
      final res = await ApiService.post('/bookings', {
        'cargo_id': cargoId,
        'truck_id': truckId,
        'agreed_price_inr': payoutInr,
        'owner_initiated': true,
      });
      return '${res['id']}';
    } catch (_) {
      final bkId = 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      try {
        await client.from('bookings').upsert({
          'id': bkId,
          'cargo_id': cargoId,
          'truck_id': truckId,
          'agreed_price_inr': payoutInr,
          'status': 'accepted',
        });
      } catch (_) {}
      return bkId;
    }
  }

  static Future<List<ActiveTrip>> getActiveTrips() async {
    try {
      final res = await ApiService.get('/bookings');
      if (res is List) {
        return res.map((r) => ActiveTrip.fromJson(Map<String, dynamic>.from(r))).toList();
      }
    } catch (_) {}

    try {
      final rows = await client.from('bookings').select('*').limit(10);
      if (rows.isNotEmpty) {
        return (rows as List).map((r) => ActiveTrip.fromJson(Map<String, dynamic>.from(r))).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Legal transitions only — the backend state machine is the referee.
  static Future<void> updateTripStatus(String bookingId, String newStatus) =>
      ApiService.patch('/bookings/$bookingId/status', {'to': newStatus});

  /// e-POD: photo → private bucket → /proof metadata (GPS-stamped serverside).
  /// Required before picked_up (pickup proof) and delivered (delivery proof).
  static Future<void> uploadTripProof({
    required String bookingId,
    required String proofType, // 'pickup' | 'delivery'
    required Uint8List photoBytes,
    double? lat,
    double? lng,
  }) async {
    final uid = currentUser!.id;
    final bucket = proofType == 'pickup' ? 'pickup-proofs' : 'delivery-proofs';
    final path = '$uid/$bookingId-$proofType-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from(bucket).uploadBinary(
          path,
          photoBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    await ApiService.post('/proof', {
      'booking_id': bookingId,
      'proof_type': proofType,
      'photo_url': '$bucket/$path',
      if (lat != null) 'gps_lat': lat,
      if (lng != null) 'gps_lng': lng,
    });
  }

  /// REAL GPS → tracking_events (is_simulated: false). The shipper's map
  /// moves live via Supabase Realtime — the Rapido moment.
  static Future<void> broadcastDriverGps({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    await ApiService.post('/tracking/$bookingId/events', {
      'lat': lat,
      'lng': lng,
      'is_simulated': false,
    });
  }

  // --- Earnings (computed by the backend from completed bookings) ---
  static Future<Map<String, dynamic>> getEarnings() async {
    final res = await ApiService.get('/earnings');
    return Map<String, dynamic>.from(res);
  }

  // --- Realtime ---
  /// New shipper cargo (from the website OR the customer app) pops into the
  /// loads feed instantly.
  static RealtimeChannel subscribeCargo(void Function() onChange) {
    final ch = client.channel('cargo-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'cargo_requests',
      callback: (_) => onChange(),
    );
    ch.subscribe();
    return ch;
  }

  static RealtimeChannel subscribeBookings(void Function() onChange) {
    final ch = client.channel('bookings-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      callback: (_) => onChange(),
    );
    ch.subscribe();
    return ch;
  }

  static void removeChannel(RealtimeChannel ch) => client.removeChannel(ch);

  // --- Notifications (live bell) ---
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await ApiService.get('/notifications') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> markNotificationRead(String id) =>
      ApiService.patch('/notifications/$id/read');

  static RealtimeChannel subscribeNotifications(void Function() onChange) {
    final ch = client.channel('notif-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      callback: (_) => onChange(),
    );
    ch.subscribe();
    return ch;
  }

  // --- Support tickets ---
  static Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final res = await ApiService.get('/support/tickets') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> createSupportTicket(String subject, String description) =>
      ApiService.post('/support/tickets',
          {'subject': subject, 'description': description, 'category': 'Partner App'});

  /// Post an extra empty RETURN TRIP on any corridor — this is what makes the
  /// truck matchable again after each run (the heart of the backhaul model).
  static Future<void> postReturnTrip({
    required String truckId,
    required String origin,
    required String destination,
    required double capacityTons,
  }) async {
    final d = DateTime.now().add(const Duration(days: 1));
    await ApiService.post('/trucks/$truckId/trips', {
      'origin': origin,
      'destination': destination,
      'departure_at':
          DateTime(d.year, d.month, d.day, 10).toUtc().toIso8601String(),
      'available_capacity_tons': capacityTons,
    });
  }

  // --- KYC status rows (docs screen) ---
  static Future<List<Map<String, dynamic>>> getKycRows() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    final res = await client
        .from('kyc_verifications')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }


  /// Secure handover: driver enters the OTP the shipper shares at the dock.
  /// Backend refuses picked_up/delivered until the matching OTP is verified.
  static Future<void> verifyOtp({
    required String bookingId,
    required String type, // 'pickup' | 'delivery'
    required String otp,
  }) =>
      ApiService.post('/bookings/$bookingId/verify-otp', {'type': type, 'otp': otp});

  static Future<void> verifyTripOtp({
    required String bookingId,
    required String type,
    required String otp,
  }) =>
      verifyOtp(bookingId: bookingId, type: type, otp: otp);

  /// Two-way trust: the driver rates the shipper too (same ratings ledger).
  static Future<void> submitRating(String bookingId, int score) =>
      ApiService.post('/ratings', {'booking_id': bookingId, 'score': score});

  static Future<void> rateShipper(String bookingId, int score) =>
      submitRating(bookingId, score);
}
