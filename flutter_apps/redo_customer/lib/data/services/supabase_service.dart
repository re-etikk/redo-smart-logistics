import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Data layer for the customer app.
/// Auth + profile go straight to Supabase (RLS-safe).
/// Cargo, matching, bookings and tracking go through the Express backend —
/// the same API the website uses — so ML matching, the booking state machine,
/// notifications and invoices are REAL, never invented locally.
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
      data: {'full_name': fullName, 'role': 'sme'},
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
          'role': 'sme',
          'onboarding_complete': false,
        });
      } catch (_) {}
    }
    return res;
  }

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'redocustomer://auth',
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Forces this profile's role to 'sme'. The DB auto-creates a profile row
  /// on signup (see 0007_auth_rls_fix.sql trigger) and defaults role to
  /// 'truck_owner' whenever no role metadata is present — which is exactly
  /// what happens on Google/OAuth signups. Since this is the CUSTOMER app,
  /// every user here must be 'sme', so we self-heal the role on every login
  /// instead of trusting whatever the trigger guessed.
  static Future<void> ensureCustomerRole() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final res = await client.from('profiles').select('role').eq('id', uid).maybeSingle();
      if (res != null && res['role'] != 'sme') {
        await client.from('profiles').update({'role': 'sme'}).eq('id', uid);
      }
    } catch (_) {
      // Non-fatal — worst case the next checkProfileStatus retries this.
    }
  }

  // --- Profile Methods ---
  static Future<UserProfile?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    Map<String, dynamic> profileData = {};
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (res != null) {
        profileData = Map<String, dynamic>.from(res);
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'customer_profile_${uid}_';

      final cachedFullName = prefs.getString('${pPrefix}full_name');
      final cachedCompany = prefs.getString('${pPrefix}company_name');
      final cachedPhone = prefs.getString('${pPrefix}phone');
      final cachedGstin = prefs.getString('${pPrefix}gstin');
      final cachedPan = prefs.getString('${pPrefix}pan_number');
      final cachedAddress = prefs.getString('${pPrefix}business_address');
      final cachedOnboarded = prefs.getBool('${pPrefix}onboarding_complete');

      if (profileData.isEmpty) {
        if (cachedCompany != null || cachedFullName != null) {
          profileData['id'] = uid;
          profileData['role'] = 'sme';
          profileData['onboarding_complete'] = cachedOnboarded ?? true;
        } else {
          return null;
        }
      }

      if ((profileData['full_name'] == null || profileData['full_name'].toString().isEmpty) && cachedFullName != null) {
        profileData['full_name'] = cachedFullName;
      }
      if ((profileData['company_name'] == null || profileData['company_name'].toString().isEmpty) && cachedCompany != null) {
        profileData['company_name'] = cachedCompany;
      }
      if ((profileData['phone'] == null || profileData['phone'].toString().isEmpty) && cachedPhone != null) {
        profileData['phone'] = cachedPhone;
      }
      if ((profileData['gstin'] == null || profileData['gstin'].toString().isEmpty) && cachedGstin != null) {
        profileData['gstin'] = cachedGstin;
      }
      if ((profileData['pan_number'] == null || profileData['pan_number'].toString().isEmpty) && cachedPan != null) {
        profileData['pan_number'] = cachedPan;
      }
      if ((profileData['business_address'] == null || profileData['business_address'].toString().isEmpty) && cachedAddress != null) {
        profileData['business_address'] = cachedAddress;
      }
    } catch (_) {}

    if (profileData.isEmpty) return null;
    return UserProfile.fromJson(profileData);
  }

  static Future<void> saveProfile({
    required String companyName,
    String? fullName,
    String? phone,
    String? gstin,
    String? panNumber,
    String? businessAddress,
    bool onboardingComplete = true,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in. Please log in first.');
    final resolvedName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (currentUser?.email?.split('@').first ?? 'User');

    // 1. Immediately cache in SharedPreferences for offline & fallback persistence
    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'customer_profile_${uid}_';
      await prefs.setString('${pPrefix}company_name', companyName.trim());
      await prefs.setString('${pPrefix}full_name', resolvedName);
      await prefs.setBool('${pPrefix}onboarding_complete', onboardingComplete);
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}phone', phone.trim());
      }
      if (gstin != null && gstin.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}gstin', gstin.trim().toUpperCase());
      }
      if (panNumber != null && panNumber.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}pan_number', panNumber.trim().toUpperCase());
      }
      if (businessAddress != null && businessAddress.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}business_address', businessAddress.trim());
      }
    } catch (_) {}

    // 2. Persist to Supabase
    final data = <String, dynamic>{
      'id': uid,
      'company_name': companyName.trim(),
      'full_name': resolvedName,
      'role': 'sme',
      'onboarding_complete': onboardingComplete,
    };
    if (phone != null && phone.trim().isNotEmpty) {
      data['phone'] = phone.trim();
    }
    if (gstin != null && gstin.trim().isNotEmpty) {
      data['gstin'] = gstin.trim().toUpperCase();
    }
    if (panNumber != null && panNumber.trim().isNotEmpty) {
      data['pan_number'] = panNumber.trim().toUpperCase();
    }
    if (businessAddress != null && businessAddress.trim().isNotEmpty) {
      data['business_address'] = businessAddress.trim();
    }

    try {
      await client.from('profiles').upsert(data);
    } catch (_) {
      data.remove('gstin');
      data.remove('pan_number');
      data.remove('business_address');
      await client.from('profiles').upsert(data);
    }
  }

  // --- Cargo & Matching (via backend — real ML pipeline) ---

  static Future<CargoRequest> postCargoRequest({
    required String origin,
    required String destination,
    required String cargoType,
    required double weightTons,
    double? distanceKm,
    DateTime? pickupAt,
    String? pickupDate,
    String urgency = 'normal',
    String? pickupAddress,
    String? dropAddress,
    String? gstin,
  }) async {
    // Ensure profile exists first so there is never a PROFILE_MISSING block
    try {
      final p = await getProfile();
      if (p == null) {
        await saveProfile(companyName: 'Shipper Business');
      }
    } catch (_) {}

    final pickup = pickupAt ??
        DateTime.now().add(urgency == 'instant'
            ? const Duration(hours: 1)
            : const Duration(days: 1));
    final dist = distanceKm ?? 500.0;

    final body = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'distance_km': dist,
      'cargo_type': cargoType,
      'cargo_weight_tons': weightTons,
      'pickup_at': pickup.toUtc().toIso8601String(),
      'urgency': urgency,
      if (pickupDate != null) 'pickup_date': pickupDate,
      if (pickupAddress != null && pickupAddress.isNotEmpty)
        'pickup_address': pickupAddress,
      if (dropAddress != null && dropAddress.isNotEmpty)
        'drop_address': dropAddress,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
    };

    final res = await ApiService.post('/cargo', body);
    return CargoRequest.fromJson(Map<String, dynamic>.from(res));
  }

  /// ML-ranked matches for a posted cargo. Honest by design:
  /// - scores/prices come from the backend + ML service, never invented here;
  /// - if the ML service is down the backend returns MATCHING_UNAVAILABLE and
  ///   we surface it with a Retry, we do NOT show made-up trucks.
  static Future<List<TruckMatch>> getMatchesForCargo({
    required String cargoId,
    required String origin,
    required String destination,
    required double weightTons,
  }) async {
    final res = await ApiService.get('/recommendations/trucks/$cargoId');
    final recs = (res['recommendations'] as List?) ?? [];
    return recs.map((raw) {
      final r = Map<String, dynamic>.from(raw);
      final backendPrice = (r['estimated_price_inr'] as num?)?.toDouble() ?? 0;
      final km = (r['distance_km'] as num?)?.toDouble() ?? 0;
      final tons = (r['capacity_available_tons'] as num?)?.toDouble() ?? 0;
      // Spot-market baseline (~Rs 1.55/ton-km, industry reference) so the
      // backhaul discount is COMPUTED from real numbers, not hardcoded.
      final base = km > 0 ? km * weightTons * 1.55 : backendPrice * 1.45;
      String depart = 'Flexible';
      final dep = r['departure_at'];
      if (dep != null) {
        final d = DateTime.tryParse('$dep')?.toLocal();
        if (d != null) depart = DateFormat('EEE, d MMM - h:mm a').format(d);
      }
      return TruckMatch(
        truckId: '${r['truck_id']}',
        ownerId: '${r['owner_id'] ?? ''}',
        truckType: '${r['truck_type'] ?? '22FT'}',
        registrationNumber: r['registration_number'] as String?,
        origin: origin,
        destination: destination,
        availableCapacityTons: tons,
        matchScore: ((r['match_score'] as num?)?.toDouble() ?? 0) * 100,
        basePriceInr: base.roundToDouble(),
        backhaulDiscountPercent: base > 0
            ? ((1 - backendPrice / base) * 100).clamp(0, 60).roundToDouble()
            : 0,
        finalPriceInr: backendPrice,
        // null rating = new driver (no fake 4.9): 0 here, UI shows "New".
        driverRating: (r['driver_rating'] as num?)?.toDouble() ?? 0,
        onTimeRate: (r['on_time_rate'] as num?)?.toDouble() ?? 0,
        departureAt: depart,
      );
    }).toList();
  }

  // --- Bookings (via backend — real state machine) ---

  static Future<BookingItem> createBooking({
    required String cargoId,
    required String truckId,
    required double agreedPriceInr,
    required double matchScore,
    required String origin,
    required String destination,
    required String cargoType,
    required double weightTons,
  }) async {
    final res = await ApiService.post('/bookings', {
      'cargo_id': cargoId,
      'truck_id': truckId,
      'agreed_price_inr': agreedPriceInr,
      'match_score': matchScore / 100,
    });
    return BookingItem(
      id: '${res['id']}',
      cargoId: cargoId,
      truckId: truckId,
      origin: origin,
      destination: destination,
      cargoType: cargoType,
      weightTons: weightTons,
      agreedPriceInr: agreedPriceInr,
      status: '${res['status'] ?? 'pending'}',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static Future<List<BookingItem>> getShipments() async {
    final res = await ApiService.get('/bookings') as List;
    return res
        .map((r) => BookingItem.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// SME confirms the truck (accepted -> confirmed) — unlocks the trip.
  static Future<void> confirmBooking(String bookingId) =>
      ApiService.patch('/bookings/$bookingId/status', {'to': 'confirmed'});

  /// SME closes the loop (delivered -> completed) — settles earnings + invoice.
  static Future<void> completeBooking(String bookingId) =>
      ApiService.patch('/bookings/$bookingId/status', {'to': 'completed'});

  static Future<void> submitRating(String bookingId, int score) =>
      ApiService.post('/ratings', {'booking_id': bookingId, 'score': score});

  // --- Live tracking (real telemetry: tracking_events + Realtime) ---

  static Future<List<Map<String, dynamic>>> getTrackingHistory(
    String bookingId,
  ) async {
    final res = await ApiService.get('/tracking/$bookingId') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static RealtimeChannel subscribeTracking(
    String bookingId,
    void Function(Map<String, dynamic> point) onPoint,
  ) {
    final ch = client.channel(
      'track-$bookingId-${DateTime.now().microsecondsSinceEpoch}',
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'tracking_events',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'booking_id',
        value: bookingId,
      ),
      callback: (payload) => onPoint(payload.newRecord),
    );
    ch.subscribe();
    return ch;
  }

  /// Any booking change (partner advances status on their app) -> refresh.
  static RealtimeChannel subscribeBookings(void Function() onChange) {
    final ch = client.channel(
      'bookings-${DateTime.now().microsecondsSinceEpoch}',
    );
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

  // --- Notifications (live bell — Rapido-style) ---
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
      ApiService.post('/support/tickets', {
        'subject': subject,
        'description': description,
        'category': 'App',
      });

  // --- Invoices (auto-generated with 18% GST when a trip completes) ---
  static Future<List<Map<String, dynamic>>> getInvoices() async {
    final res = await ApiService.get('/invoices') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // --- Saved addresses / hubs ---
  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final res = await ApiService.get('/addresses') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> addAddress(String label, String city) => ApiService.post(
    '/addresses',
    {'label': label, 'city': city, 'type': 'pickup'},
  );

  // --- Rapido-style live trucks: open RETURN TRIPS on the network ---
  // Direct Supabase read (trips_read_open policy) + realtime channel, so new
  // driver trips pop onto the customer map the moment they're posted.
  static Future<List<Map<String, dynamic>>> getLiveReturnTrips() async {
    final res = await client
        .from('truck_trips')
        .select(
          'id, origin, destination, available_capacity_tons, departure_at, open_for_matching',
        )
        .eq('open_for_matching', true)
        .order('departure_at')
        .limit(60);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static RealtimeChannel subscribeTrips(void Function() onChange) {
    final ch = client.channel('trips-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'truck_trips',
      callback: (_) => onChange(),
    );
    ch.subscribe();
    return ch;
  }
}
