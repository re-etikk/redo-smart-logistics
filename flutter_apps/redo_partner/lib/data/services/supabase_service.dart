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
          'onboarding_complete': false,
        });
      } catch (_) {}
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
    if (uid == null) return;
    await client.from('profiles').upsert({
      'id': uid,
      'full_name': fullName,
      'phone': phone,
      'company_name': city,
      'role': 'truck_owner',
      'onboarding_complete': false,
    });
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
    await client.from('profiles').update({'onboarding_complete': true}).eq('id', uid);
  }

  // --- My trucks (needed to accept loads) ---
  static Future<List<TruckModel>> getMyTrucks() async {
    final res = await ApiService.get('/trucks') as List;
    return res.map((r) => TruckModel.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  // --- Loads & Trips (via backend — real, cross-app visible) ---

  static Future<List<AvailableLoad>> getAvailableLoads() async {
    final res = await ApiService.get('/cargo') as List;
    return res.map((raw) {
      final r = Map<String, dynamic>.from(raw);
      final km = (r['distance_km'] as num?)?.toDouble() ?? 0;
      final tons = (r['cargo_weight_tons'] as num?)?.toDouble() ?? 0;
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
        // Payout from the SAME corridor formula the backend prices with
        // (km × tons × ₹1.05) — computed, not invented.
        offeredPriceInr: (km * tons * 1.05).roundToDouble(),
        distanceKm: km,
        pickupWindow: window,
      );
    }).toList();
  }

  /// REAL accept: creates a booking via the backend (owner_initiated), which
  /// notifies the shipper and shows up on their app/website instantly.
  static Future<String> acceptLoad({
    required String cargoId,
    required String truckId,
    required double payoutInr,
  }) async {
    final res = await ApiService.post('/bookings', {
      'cargo_id': cargoId,
      'truck_id': truckId,
      'agreed_price_inr': payoutInr,
      'owner_initiated': true,
    });
    return '${res['id']}';
  }

  static Future<List<ActiveTrip>> getActiveTrips() async {
    final res = await ApiService.get('/bookings') as List;
    return res.map((r) => ActiveTrip.fromJson(Map<String, dynamic>.from(r))).toList();
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
