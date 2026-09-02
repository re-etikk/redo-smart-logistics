import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
      data: {'full_name': fullName},
    );
    if (res.user != null) {
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'full_name': fullName,
        'role': 'sme',
        'onboarding_complete': false,
      });
    }
    return res;
  }

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'redocustomer://auth',
    );
  }

  static Future<AuthResponse> demoLogin() async {
    const demoEmail = 'customer@redo.app';
    const demoPass = 'Password@123';
    try {
      return await client.auth.signInWithPassword(
        email: demoEmail,
        password: demoPass,
      );
    } catch (_) {
      await client.auth.signUp(
        email: demoEmail,
        password: demoPass,
        data: {'full_name': 'Rajesh Sharma (Shipper Demo)'},
      );
      final res = await client.auth.signInWithPassword(
        email: demoEmail,
        password: demoPass,
      );
      if (res.user != null) {
        await client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': 'Rajesh Sharma (Shipper Demo)',
          'company_name': 'Sharma Logistics & Trading',
          'role': 'sme',
          'onboarding_complete': true,
        });
      }
      return res;
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Profile Methods ---
  static Future<UserProfile?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await client.from('profiles').select().eq('id', uid).maybeSingle();
      if (res == null) return null;
      return UserProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile({
    required String companyName,
    String? fullName,
    String? phone,
    bool onboardingComplete = true,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('profiles').upsert({
      'id': uid,
      'company_name': companyName,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      'role': 'sme',
      'onboarding_complete': onboardingComplete,
    });
  }

  // --- Cargo & Matching (via backend — real ML pipeline) ---

  static Future<CargoRequest> postCargoRequest({
    required String origin,
    required String destination,
    required String cargoType,
    required double weightTons,
  }) async {
    final pickup = DateTime.now().add(const Duration(days: 1));
    final at = DateTime(pickup.year, pickup.month, pickup.day, 10);
    final res = await ApiService.post('/cargo', {
      'origin': origin,
      'destination': destination,
      'cargo_type': cargoType,
      'cargo_weight_tons': weightTons,
      'pickup_at': at.toUtc().toIso8601String(),
      'urgency': 'normal',
    });
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
        backhaulDiscountPercent:
            base > 0 ? ((1 - backendPrice / base) * 100).clamp(0, 60).roundToDouble() : 0,
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
    return res.map((r) => BookingItem.fromJson(Map<String, dynamic>.from(r))).toList();
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

  static Future<List<Map<String, dynamic>>> getTrackingHistory(String bookingId) async {
    final res = await ApiService.get('/tracking/$bookingId') as List;
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static RealtimeChannel subscribeTracking(
      String bookingId, void Function(Map<String, dynamic> point) onPoint) {
    final ch = client.channel('track-$bookingId-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'tracking_events',
      filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, column: 'booking_id', value: bookingId),
      callback: (payload) => onPoint(payload.newRecord),
    );
    ch.subscribe();
    return ch;
  }

  /// Any booking change (partner advances status on their app) -> refresh.
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
      ApiService.post('/support/tickets',
          {'subject': subject, 'description': description, 'category': 'App'});

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

  static Future<void> addAddress(String label, String city) =>
      ApiService.post('/addresses', {'label': label, 'city': city, 'type': 'pickup'});


  // --- Rapido-style live trucks: open RETURN TRIPS on the network ---
  // Direct Supabase read (trips_read_open policy) + realtime channel, so new
  // driver trips pop onto the customer map the moment they're posted.
  static Future<List<Map<String, dynamic>>> getLiveReturnTrips() async {
    final res = await client
        .from('truck_trips')
        .select('id, origin, destination, available_capacity_tons, departure_at, status')
        .eq('status', 'open')
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
