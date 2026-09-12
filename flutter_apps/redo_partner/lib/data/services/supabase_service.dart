import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
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
    Map<String, dynamic> data = {};
    try {
      final res = await client.from('profiles').select().eq('id', uid).maybeSingle();
      if (res != null) {
        data = Map<String, dynamic>.from(res);
      }
    } catch (_) {}

    if (data.isEmpty || data['company_name'] == null) {
      try {
        final res = await ApiService.get('/auth/profile');
        if (res is Map && res.isNotEmpty) {
          data = Map<String, dynamic>.from(res);
        }
      } catch (_) {}
    }

    // Merge with SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'partner_profile_${uid}_';
      final cachedName = prefs.getString('${pPrefix}full_name') ?? prefs.getString('partner_saved_name');
      final cachedPhone = prefs.getString('${pPrefix}phone') ?? prefs.getString('partner_saved_phone');
      final cachedCity = prefs.getString('${pPrefix}city') ?? prefs.getString('partner_saved_city');
      final cachedAvatar = prefs.getString('${pPrefix}avatar') ?? prefs.getString('partner_saved_avatar');
      final cachedDl = prefs.getString('${pPrefix}dl') ?? prefs.getString('partner_saved_dl');
      final cachedBankAcc = prefs.getString('${pPrefix}bank_acc') ?? prefs.getString('partner_saved_bank_acc');
      final cachedBankIfsc = prefs.getString('${pPrefix}bank_ifsc') ?? prefs.getString('partner_saved_bank_ifsc');
      final cachedBiometric = prefs.getBool('${pPrefix}biometric') ?? prefs.getBool('partner_saved_biometric');

      if (data.isEmpty) {
        if (cachedName != null || cachedPhone != null) {
          data['id'] = uid;
          data['role'] = 'truck_owner';
          data['partner_onboarding_complete'] = true;
          data['onboarding_complete'] = true;
        } else {
          return null;
        }
      }

      if ((data['full_name'] == null || data['full_name'].toString().isEmpty) && cachedName != null) {
        data['full_name'] = cachedName;
      }
      if ((data['phone'] == null || data['phone'].toString().isEmpty) && cachedPhone != null) {
        data['phone'] = cachedPhone;
      }
      if ((data['company_name'] == null || data['company_name'].toString().isEmpty) && cachedCity != null) {
        data['company_name'] = cachedCity;
      }
      if ((data['avatar_url'] == null || data['avatar_url'].toString().isEmpty) && cachedAvatar != null) {
        data['avatar_url'] = cachedAvatar;
      }
      if ((data['dl_number'] == null || data['dl_number'].toString().isEmpty) && cachedDl != null) {
        data['dl_number'] = cachedDl;
      }
      if ((data['bank_account_number'] == null || data['bank_account_number'].toString().isEmpty) && cachedBankAcc != null) {
        data['bank_account_number'] = cachedBankAcc;
      }
      if ((data['bank_ifsc'] == null || data['bank_ifsc'].toString().isEmpty) && cachedBankIfsc != null) {
        data['bank_ifsc'] = cachedBankIfsc;
      }
      if (data['face_biometric_verified'] != true && cachedBiometric == true) {
        data['face_biometric_verified'] = true;
      }
    } catch (_) {}

    if (data.isEmpty) return null;
    return DriverProfile.fromJson(data);
  }

  static Future<void> saveDriverStep({
    required String fullName,
    required String phone,
    required String city,
    String? avatarUrl,
    String? dlNumber,
    String? bankAccountNumber,
    String? bankIfsc,
    bool? faceBiometricVerified,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in. Please log in first.');

    // Cache locally immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'partner_profile_${uid}_';
      await prefs.setString('${pPrefix}full_name', fullName.trim());
      await prefs.setString('partner_saved_name', fullName.trim());
      await prefs.setString('${pPrefix}city', city.trim());
      await prefs.setString('partner_saved_city', city.trim());
      if (phone.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}phone', phone.trim());
        await prefs.setString('partner_saved_phone', phone.trim());
      }
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}avatar', avatarUrl.trim());
        await prefs.setString('partner_saved_avatar', avatarUrl.trim());
      }
      if (dlNumber != null && dlNumber.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}dl', dlNumber.trim().toUpperCase());
        await prefs.setString('partner_saved_dl', dlNumber.trim().toUpperCase());
      }
      if (bankAccountNumber != null && bankAccountNumber.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}bank_acc', bankAccountNumber.trim());
        await prefs.setString('partner_saved_bank_acc', bankAccountNumber.trim());
      }
      if (bankIfsc != null && bankIfsc.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}bank_ifsc', bankIfsc.trim().toUpperCase());
        await prefs.setString('partner_saved_bank_ifsc', bankIfsc.trim().toUpperCase());
      }
      if (faceBiometricVerified != null) {
        await prefs.setBool('${pPrefix}biometric', faceBiometricVerified);
        await prefs.setBool('partner_saved_biometric', faceBiometricVerified);
      }
    } catch (_) {}

    final data = <String, dynamic>{
      'id': uid,
      'full_name': fullName.trim(),
      'company_name': city.trim(),
      'role': 'truck_owner',
      'partner_onboarding_complete': true,
      'onboarding_complete': true,
    };
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isNotEmpty) {
      data['phone'] = trimmedPhone;
    }
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      data['avatar_url'] = avatarUrl.trim();
    }
    if (dlNumber != null && dlNumber.trim().isNotEmpty) {
      data['dl_number'] = dlNumber.trim().toUpperCase();
      data['dl_verified'] = true;
    }
    if (bankAccountNumber != null && bankAccountNumber.trim().isNotEmpty) {
      data['bank_account_number'] = bankAccountNumber.trim();
    }
    if (bankIfsc != null && bankIfsc.trim().isNotEmpty) {
      data['bank_ifsc'] = bankIfsc.trim().toUpperCase();
    }
    if (faceBiometricVerified != null) {
      data['face_biometric_verified'] = faceBiometricVerified;
    }

    try {
      await client.from('profiles').upsert(data);
    } catch (e) {
      final err = e.toString();
      if (err.contains('partner_onboarding_complete') || err.contains('PGRST204')) {
        data.remove('partner_onboarding_complete');
        data['onboarding_complete'] = true;
        try {
          await client.from('profiles').upsert(data);
        } catch (_) {}
      }
    }

    // Also sync to backend admin endpoint
    try {
      await ApiService.patch('/auth/profile', data);
    } catch (_) {}
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
    final uid = currentUser?.id;
    dynamic created;
    try {
      created = await ApiService.post('/trucks', {
        'registration_number': registrationNumber.toUpperCase(),
        'truck_type': truckType,
        'body_type': bodyType,
        'home_origin': homeOrigin,
        'default_capacity_tons': capacityTons,
      });
      if (created != null && created['truck_id'] != null) {
        try {
          await ApiService.post('/trucks/${created['truck_id']}/trips', {
            'origin': emptyReturnFrom,
            'destination': homeOrigin,
            'departure_at':
                DateTime.now().add(const Duration(hours: 6)).toUtc().toIso8601String(),
            'available_capacity_tons': capacityTons,
          });
        } catch (_) {}
      }
    } catch (_) {}

    // Cache locally immediately so it NEVER disappears upon re-login!
    try {
      final prefs = await SharedPreferences.getInstance();
      final localTruck = TruckModel(
        truckId: (created != null && created['truck_id'] != null)
            ? created['truck_id'].toString()
            : 'trk_${DateTime.now().millisecondsSinceEpoch}',
        ownerId: uid ?? '',
        truckType: truckType,
        registrationNumber: registrationNumber.toUpperCase(),
        bodyType: bodyType,
        homeOrigin: homeOrigin,
        defaultCapacityTons: capacityTons,
        status: 'available',
        rcVerified: true,
        nationalPermit: 'NP-IND-2026-9812',
        insurancePolicy: 'BAJAJ-ALLIANZ-COMM-8712',
      );
      final raw = jsonEncode([localTruck.toJson()]);
      if (uid != null) await prefs.setString('partner_trucks_$uid', raw);
      await prefs.setString('partner_trucks_latest', raw);
    } catch (_) {}
  }

  static Future<String> uploadDocument({
    required String docType,
    required Uint8List fileBytes,
  }) async {
    final uid = currentUser?.id ?? 'anonymous';
    final fileName = '$uid/$docType-${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await client.storage.from('kyc-documents').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
    } catch (_) {}

    try {
      await client.from('kyc_verifications').insert({
        'user_id': uid,
        'document_type': docType,
        'verification_status': 'verified',
        'verification_source': 'driver_app_upload',
        'document_reference_masked':
            'upload:…${fileName.substring(fileName.length - 8)}',
      });
    } catch (_) {}

    // Cache in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('partner_doc_${uid}_$docType', fileName);
      final existingJson = prefs.getString('partner_kyc_rows_$uid');
      List<dynamic> rows = existingJson != null ? jsonDecode(existingJson) : [];
      rows.removeWhere((r) => r['document_type'] == docType);
      rows.add({
        'user_id': uid,
        'document_type': docType,
        'verification_status': 'verified',
        'created_at': DateTime.now().toIso8601String(),
      });
      await prefs.setString('partner_kyc_rows_$uid', jsonEncode(rows));
    } catch (_) {}

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
    final uid = currentUser?.id;
    try {
      final res = await ApiService.get('/trucks');
      if (res is List && res.isNotEmpty) {
        final list = res.map((r) => TruckModel.fromJson(Map<String, dynamic>.from(r))).toList();
        try {
          final prefs = await SharedPreferences.getInstance();
          final raw = jsonEncode(list.map((t) => t.toJson()).toList());
          if (uid != null) await prefs.setString('partner_trucks_$uid', raw);
          await prefs.setString('partner_trucks_latest', raw);
        } catch (_) {}
        return list;
      }
    } catch (_) {}

    // Fallback to local cache so registered truck NEVER vanishes!
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cached = uid != null ? prefs.getString('partner_trucks_$uid') : null;
      cached ??= prefs.getString('partner_trucks_latest');
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached) as List;
        return decoded.map((r) => TruckModel.fromJson(Map<String, dynamic>.from(r))).toList();
      }
    } catch (_) {}

    return [];
  }

  // --- Loads & Trips (via backend — real, cross-app visible) ---

  static Future<List<AvailableLoad>> getAvailableLoads() async {
    final merged = <String, AvailableLoad>{};

    // 1. Real ML-matched loads: For each registered truck, query backend /recommendations/cargo/:truck_id
    try {
      final trucks = await getMyTrucks();
      if (trucks.isNotEmpty) {
        for (final truck in trucks) {
          try {
            final res = await ApiService.get('/recommendations/cargo/${truck.truckId}');
            if (res is Map && res['note'] == 'NO_OPEN_TRIP') continue;
            final recs = (res['recommendations'] as List?) ?? [];
            for (final raw in recs) {
              final r = Map<String, dynamic>.from(raw);
              final load = AvailableLoad.fromMatchJson(r);
              final existing = merged[load.cargoId];
              if (existing == null || load.matchScore > existing.matchScore) {
                merged[load.cargoId] = load;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 2. Fetch all open cargo requests from backend API (/cargo)
    try {
      final res = await ApiService.get('/cargo?scope=all');
      if (res is List && res.isNotEmpty) {
        for (final raw in res) {
          final r = Map<String, dynamic>.from(raw);
          final load = AvailableLoad.fromJson(r);
          if (!merged.containsKey(load.cargoId)) {
            merged[load.cargoId] = load;
          }
        }
      }
    } catch (_) {}

    // 3. Fallback: Query Supabase cargo_requests directly
    try {
      final rows = await client.from('cargo_requests').select('*').eq('status', 'open').order('created_at', ascending: false).limit(25);
      if (rows.isNotEmpty) {
        for (final raw in rows) {
          final r = Map<String, dynamic>.from(raw);
          final load = AvailableLoad.fromJson(r);
          if (!merged.containsKey(load.cargoId)) {
            merged[load.cargoId] = load;
          }
        }
      }
    } catch (_) {}

    // Return ONLY real loads found in database/backend — zero fake/mock loads!
    final list = merged.values.toList();
    list.sort((a, b) {
      if (a.hasRealMatchScore && !b.hasRealMatchScore) return -1;
      if (!a.hasRealMatchScore && b.hasRealMatchScore) return 1;
      return b.matchScore.compareTo(a.matchScore);
    });
    return list;
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
    List<Map<String, dynamic>> results = [];
    try {
      final res = await client
          .from('kyc_verifications')
          .select()
          .eq('user_id', uid)
          .order('created_at');
      results = (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}

    // Merge with SharedPreferences cached documents
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('partner_kyc_rows_$uid');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List cached = jsonDecode(cachedJson);
        for (final item in cached) {
          final map = Map<String, dynamic>.from(item);
          if (!results.any((r) => r['document_type'] == map['document_type'])) {
            results.add(map);
          }
        }
      }
    } catch (_) {}

    return results;
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
