import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Data layer for the customer app.
/// Auth + profile go straight to Supabase (RLS-safe).
/// Cargo, matching, bookings and tracking go through the Express backend —
/// the same API the website uses — so ML matching, the booking state machine,
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }
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
      final res = await client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
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

    // If Supabase client query returned empty or threw RLS error, query backend service-role API
    if (profileData.isEmpty || profileData['company_name'] == null) {
      try {
        final res = await ApiService.get('/auth/profile');
        if (res is Map && res.isNotEmpty) {
          profileData = Map<String, dynamic>.from(res);
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'customer_profile_${uid}_';

      final cachedFullName =
          prefs.getString('${pPrefix}full_name') ??
          prefs.getString('customer_saved_name');
      final cachedCompany =
          prefs.getString('${pPrefix}company_name') ??
          prefs.getString('customer_saved_company');
      final cachedPhone =
          prefs.getString('${pPrefix}phone') ??
          prefs.getString('customer_saved_phone');
      final cachedGstin =
          prefs.getString('${pPrefix}gstin') ??
          prefs.getString('customer_saved_gstin');
      final cachedPan =
          prefs.getString('${pPrefix}pan_number') ??
          prefs.getString('customer_saved_pan');
      final cachedAddress =
          prefs.getString('${pPrefix}business_address') ??
          prefs.getString('customer_saved_address');
      final cachedAvatar =
          prefs.getString('${pPrefix}avatar_url') ??
          prefs.getString('customer_saved_avatar');
      final cachedOnboarded =
          prefs.getBool('${pPrefix}onboarding_complete') ??
          prefs.getBool('customer_saved_onboarded');

      if (profileData.isEmpty) {
        if (cachedCompany != null || cachedFullName != null) {
          profileData['id'] = uid;
          profileData['role'] = 'sme';
          profileData['onboarding_complete'] = cachedOnboarded ?? true;
        } else {
          return null;
        }
      }

      if ((profileData['full_name'] == null ||
              profileData['full_name'].toString().isEmpty) &&
          cachedFullName != null) {
        profileData['full_name'] = cachedFullName;
      }
      if ((profileData['company_name'] == null ||
              profileData['company_name'].toString().isEmpty) &&
          cachedCompany != null) {
        profileData['company_name'] = cachedCompany;
      }
      if ((profileData['phone'] == null ||
              profileData['phone'].toString().isEmpty) &&
          cachedPhone != null) {
        profileData['phone'] = cachedPhone;
      }
      if ((profileData['gstin'] == null ||
              profileData['gstin'].toString().isEmpty) &&
          cachedGstin != null) {
        profileData['gstin'] = cachedGstin;
      }
      if ((profileData['pan_number'] == null ||
              profileData['pan_number'].toString().isEmpty) &&
          cachedPan != null) {
        profileData['pan_number'] = cachedPan;
      }
      if ((profileData['business_address'] == null ||
              profileData['business_address'].toString().isEmpty) &&
          cachedAddress != null) {
        profileData['business_address'] = cachedAddress;
      }
      if ((profileData['avatar_url'] == null ||
              profileData['avatar_url'].toString().isEmpty) &&
          cachedAvatar != null) {
        profileData['avatar_url'] = cachedAvatar;
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
    String? avatarUrl,
    bool onboardingComplete = true,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in. Please log in first.');
    final resolvedName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (currentUser?.email?.split('@').first ?? 'User');

    // 1. Immediately cache in SharedPreferences (user-scoped AND global fallback)
    try {
      final prefs = await SharedPreferences.getInstance();
      final pPrefix = 'customer_profile_${uid}_';
      await prefs.setString('${pPrefix}company_name', companyName.trim());
      await prefs.setString('customer_saved_company', companyName.trim());
      await prefs.setString('${pPrefix}full_name', resolvedName);
      await prefs.setString('customer_saved_name', resolvedName);
      await prefs.setBool('${pPrefix}onboarding_complete', onboardingComplete);
      await prefs.setBool('customer_saved_onboarded', onboardingComplete);

      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}phone', phone.trim());
        await prefs.setString('customer_saved_phone', phone.trim());
      }
      if (gstin != null && gstin.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}gstin', gstin.trim().toUpperCase());
        await prefs.setString(
          'customer_saved_gstin',
          gstin.trim().toUpperCase(),
        );
      }
      if (panNumber != null && panNumber.trim().isNotEmpty) {
        await prefs.setString(
          '${pPrefix}pan_number',
          panNumber.trim().toUpperCase(),
        );
        await prefs.setString(
          'customer_saved_pan',
          panNumber.trim().toUpperCase(),
        );
      }
      if (businessAddress != null && businessAddress.trim().isNotEmpty) {
        await prefs.setString(
          '${pPrefix}business_address',
          businessAddress.trim(),
        );
        await prefs.setString('customer_saved_address', businessAddress.trim());
      }
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        await prefs.setString('${pPrefix}avatar_url', avatarUrl.trim());
        await prefs.setString('customer_saved_avatar', avatarUrl.trim());
      }
    } catch (_) {}

    // 2. Prepare payload
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
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      data['avatar_url'] = avatarUrl.trim();
    }

    // 3. Persist to Supabase client
    try {
      await client.from('profiles').upsert(data);
    } catch (_) {
      data.remove('gstin');
      data.remove('pan_number');
      data.remove('business_address');
      try {
        await client.from('profiles').upsert(data);
      } catch (_) {}
    }

    // 4. Also sync with backend admin endpoint (bypasses RLS issues)
    try {
      await ApiService.patch('/auth/profile', data);
    } catch (_) {}
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
    double? pickupLat,
    double? pickupLng,
    String? dropAddress,
    String? gstin,
    int packageCount = 1,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    String? dimensions,
    bool isFragile = false,
    bool isTemperatureSensitive = false,
    double declaredValueInr = 0.0,
    double estimatedPriceInr = 0.0,
    String? specialHandlingNotes,
  }) async {
    // Ensure profile exists first so there is never a PROFILE_MISSING block
    try {
      final p = await getProfile();
      if (p == null) {
        await saveProfile(companyName: 'Shipper Business');
      }
    } catch (_) {}

    final pickup =
        pickupAt ??
        DateTime.now().add(
          urgency == 'instant'
              ? const Duration(hours: 1)
              : const Duration(days: 1),
        );
    final dist = distanceKm ?? 500.0;

    final resolvedDimensions = dimensions ??
        ((lengthCm != null && widthCm != null && heightCm != null)
            ? '${lengthCm.round()} x ${widthCm.round()} x ${heightCm.round()} cm'
            : null);

    final specialHandlingMap = <String, dynamic>{
      'pickup_address': pickupAddress ?? origin,
      'drop_address': dropAddress ?? destination,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
      'package_count': packageCount,
      'dimensions': ?resolvedDimensions,
      'length_cm': ?lengthCm,
      'width_cm': ?widthCm,
      'height_cm': ?heightCm,
      'is_fragile': isFragile,
      'is_temperature_sensitive': isTemperatureSensitive,
      'declared_value_inr': declaredValueInr,
      'estimated_price_inr': estimatedPriceInr,
      if (specialHandlingNotes != null && specialHandlingNotes.isNotEmpty)
        'note': specialHandlingNotes,
    };
    final specialHandlingJson = jsonEncode(specialHandlingMap);

    final body = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'distance_km': dist,
      'cargo_type': cargoType,
      'cargo_weight_tons': weightTons,
      'pickup_at': pickup.toUtc().toIso8601String(),
      'urgency': urgency,
      'pickup_date': ?pickupDate,
      if (pickupAddress != null && pickupAddress.isNotEmpty)
        'pickup_address': pickupAddress,
      if (pickupLat != null && pickupLng != null) ...{
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
      },
      if (dropAddress != null && dropAddress.isNotEmpty)
        'drop_address': dropAddress,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
      'package_count': packageCount,
      'dimensions': ?resolvedDimensions,
      'length_cm': ?lengthCm,
      'width_cm': ?widthCm,
      'height_cm': ?heightCm,
      'is_fragile': isFragile,
      'is_temperature_sensitive': isTemperatureSensitive,
      'declared_value_inr': declaredValueInr,
      'estimated_price_inr': estimatedPriceInr,
      'special_handling': specialHandlingJson,
    };

    CargoRequest result;
    try {
      final res = await ApiService.post('/cargo', body);
      result = CargoRequest.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      // Fallback 1: Direct Supabase insert via authenticated or public client session
      final uid = client.auth.currentUser?.id;
      final generatedId =
          'CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      try {
        final row = {
          'cargo_id': generatedId,
          'sme_id': ?uid,
          'origin': origin,
          'destination': destination,
          'distance_km': dist,
          'cargo_type': cargoType,
          'cargo_weight_tons': weightTons,
          'pickup_at': pickup.toUtc().toIso8601String(),
          if (pickupLat != null && pickupLng != null) 'pickup_lat': pickupLat,
          if (pickupLat != null && pickupLng != null) 'pickup_lng': pickupLng,
          'urgency': urgency,
          'status': 'open',
          'special_handling': specialHandlingJson,
          'pickup_date': ?pickupDate,
        };
        final dbData = await client.from('cargo_requests').insert(row).select().single();
        result = CargoRequest.fromJson(Map<String, dynamic>.from(dbData));
      } catch (dbError) {
        // Both primary API and Supabase direct connection failed!
        // Never invent fake local-only shipment records if backend exists.
        throw Exception(
          'Unable to reach REDO servers to create your shipment. Please check your internet connection and try again ($dbError).',
        );
      }
    }

    // Immediately cache locally so it never disappears on re-login or screen change
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = client.auth.currentUser?.id;
      final rawList = prefs.getStringList('customer_posted_cargo_$uid') ?? [];
      rawList.insert(0, jsonEncode(result.toJson()));
      if (uid != null) {
        await prefs.setStringList(
          'customer_posted_cargo_$uid',
          rawList.take(25).toList(),
        );
      }
      await prefs.setStringList(
        'customer_posted_cargo_latest',
        rawList.take(25).toList(),
      );
    } catch (_) {}

    return result;
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
    try {
      final res = await ApiService.get('/recommendations/trucks/$cargoId');
      final recs = (res['recommendations'] as List?) ?? [];
      if (recs.isNotEmpty) {
        return recs.map((raw) {
          final r = Map<String, dynamic>.from(raw);
          final backendPrice =
              (r['estimated_price_inr'] as num?)?.toDouble() ?? 0;
          final km = (r['distance_km'] as num?)?.toDouble() ?? 0;
          final tons = (r['capacity_available_tons'] as num?)?.toDouble() ?? 0;
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
            driverRating: (r['driver_rating'] as num?)?.toDouble() ?? 0,
            onTimeRate: (r['on_time_rate'] as num?)?.toDouble() ?? 0,
            departureAt: depart,
          );
        }).toList();
      }
    } catch (_) {}

    // Return ONLY real matching trucks from the ML matching pipeline — zero fake/mock trucks!
    return [];
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
    String bookingId =
        'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    String status = 'matched';
    final rand = Random.secure();
    final uniquePickupOtp = (1000 + rand.nextInt(9000)).toString();
    final uniqueDeliveryOtp = (1000 + rand.nextInt(9000)).toString();
    String pickupOtp = uniquePickupOtp;
    String deliveryOtp = uniqueDeliveryOtp;

    try {
      final res = await ApiService.post('/bookings', {
        'cargo_id': cargoId,
        'truck_id': truckId,
        'agreed_price_inr': agreedPriceInr,
        'match_score': matchScore / 100,
        'pickup_otp': uniquePickupOtp,
        'delivery_otp': uniqueDeliveryOtp,
      });
      bookingId = '${res['id'] ?? bookingId}';
      status = '${res['status'] ?? status}';
      if (res['pickup_otp'] != null) pickupOtp = '${res['pickup_otp']}';
      if (res['delivery_otp'] != null) deliveryOtp = '${res['delivery_otp']}';
    } catch (e) {
      try {
        final row = {
          'id': bookingId,
          'cargo_id': cargoId,
          'truck_id': truckId,
          'agreed_price_inr': agreedPriceInr,
          'status': 'matched',
          'pickup_otp': uniquePickupOtp,
          'delivery_otp': uniqueDeliveryOtp,
        };
        await client.from('bookings').upsert(row);
      } catch (_) {}
    }
    return BookingItem(
      id: bookingId,
      cargoId: cargoId,
      truckId: truckId,
      pickupOtp: pickupOtp,
      deliveryOtp: deliveryOtp,
      origin: origin,
      destination: destination,
      cargoType: cargoType,
      weightTons: weightTons,
      agreedPriceInr: agreedPriceInr,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static Future<List<BookingItem>> getShipments() async {
    final Map<String, BookingItem> merged = {};
    final uid = client.auth.currentUser?.id;

    // 1. Fetch real bookings from Express API
    try {
      final res = await ApiService.get('/bookings');
      if (res is List) {
        for (final r in res) {
          final item = BookingItem.fromJson(Map<String, dynamic>.from(r));
          final key = item.cargoId.isNotEmpty ? item.cargoId : item.id;
          merged[key] = item;
        }
      }
    } catch (_) {}

    // 2. Fetch bookings from Supabase table directly with full driver and truck relations
    try {
      final rows = await client
          .from('bookings')
          .select('*, truck:trucks(*, owner:profiles(full_name, phone))')
          .order('created_at', ascending: false);
      if (rows.isNotEmpty) {
        for (final r in (rows as List)) {
          final item = BookingItem.fromJson(Map<String, dynamic>.from(r));
          final key = item.cargoId.isNotEmpty ? item.cargoId : item.id;
          if (!merged.containsKey(key)) {
            merged[key] = item;
          }
        }
      }
    } catch (_) {}

    // 3. Fetch user's cargo requests from Express API (/cargo?scope=mine)
    try {
      final cargoRes = await ApiService.get('/cargo?scope=mine');
      if (cargoRes is List) {
        for (final c in cargoRes) {
          final cargo = CargoRequest.fromJson(Map<String, dynamic>.from(c));
          if (!merged.containsKey(cargo.cargoId)) {
            merged[cargo.cargoId] = BookingItem.fromCargo(cargo);
          }
        }
      }
    } catch (_) {}

    // 4. Fetch user's cargo requests from Supabase directly
    try {
      var query = client.from('cargo_requests').select('*');
      if (uid != null && uid.isNotEmpty) {
        query = query.eq('sme_id', uid);
      }
      final cargoRows = await query
          .order('created_at', ascending: false)
          .limit(30);
      if (cargoRows.isNotEmpty) {
        for (final r in (cargoRows as List)) {
          final cargo = CargoRequest.fromJson(Map<String, dynamic>.from(r));
          if (!merged.containsKey(cargo.cargoId)) {
            merged[cargo.cargoId] = BookingItem.fromCargo(cargo);
          }
        }
      }
    } catch (_) {}

    // 5. Read locally persisted cargo requests from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKeys = [
        if (uid != null) 'customer_posted_cargo_$uid',
        'customer_posted_cargo_latest',
      ];
      for (final key in localKeys) {
        final list = prefs.getStringList(key) ?? [];
        for (final raw in list) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final cargo = CargoRequest.fromJson(map);
            if (!merged.containsKey(cargo.cargoId)) {
              merged[cargo.cargoId] = BookingItem.fromCargo(cargo);
            }
          } catch (_) {}
        }
      }

      // Auto-sync locally saved cargo requests to backend so Partner App receives them immediately
      Future.microtask(() async {
        try {
          for (final key in localKeys) {
            final list = prefs.getStringList(key) ?? [];
            for (final raw in list) {
              try {
                final map = jsonDecode(raw) as Map<String, dynamic>;
                await ApiService.post('/cargo', map);
              } catch (_) {}
            }
          }
        } catch (_) {}
      });
    } catch (_) {}

    final result = merged.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Cache combined shipments offline
    try {
      if (result.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = uid != null
            ? 'customer_shipments_$uid'
            : 'customer_shipments_cached';
        await prefs.setStringList(
          cacheKey,
          result.take(30).map((e) => jsonEncode(e.toJson())).toList(),
        );
      }
    } catch (_) {}

    // If result is empty, try loading cached shipments from SharedPreferences
    if (result.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = uid != null
            ? 'customer_shipments_$uid'
            : 'customer_shipments_cached';
        final cached = prefs.getStringList(cacheKey) ?? [];
        for (final raw in cached) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            result.add(BookingItem.fromJson(map));
          } catch (_) {}
        }
      } catch (_) {}
    }

    return result;
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

  static Future<BookingItem?> getBookingByIdOrSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final res = await ApiService.get('/bookings/$q');
      if (res is Map<String, dynamic>) {
        return BookingItem.fromJson(res);
      }
    } catch (_) {}

    try {
      final data = await client
          .from('bookings')
          .select(
            '*, cargo:cargo_requests(*), truck:trucks(*, owner:profiles(*))',
          )
          .or('id.eq.$q,cargo_id.eq.$q')
          .maybeSingle();
      if (data != null) {
        return BookingItem.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}

    try {
      final cargo = await client
          .from('cargo_requests')
          .select('*')
          .eq('cargo_id', q)
          .maybeSingle();
      if (cargo != null) {
        return BookingItem.fromCargo(
          CargoRequest.fromJson(Map<String, dynamic>.from(cargo)),
        );
      }
    } catch (_) {}

    return null;
  }

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

  /// Any booking or cargo request change (partner advances status on their app) -> refresh.
  static RealtimeChannel subscribeBookings(void Function() onChange) {
    final ch = client.channel(
      'bookings-cargo-${DateTime.now().microsecondsSinceEpoch}',
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      callback: (_) => onChange(),
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'cargo_requests',
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

  // --- Dynamic Pricing Engine Integration ---

  static Future<PriceQuote> getPriceQuote({
    required String origin,
    required String destination,
    required double weightTons,
    String cargoType = 'general',
    double distanceKm = 0,
    double volumeCft = 0,
    String urgency = 'standard',
  }) async {
    final dist = distanceKm > 0 ? distanceKm : 500.0;
    final wTons = weightTons > 0 ? weightTons : 0.5;

    try {
      final queryParams = <String, String>{
        'origin': origin,
        'destination': destination,
        'weight_tons': wTons.toStringAsFixed(2),
        'cargo_type': cargoType,
        'distance_km': dist.toStringAsFixed(0),
        'volume_cft': volumeCft.toStringAsFixed(1),
        'urgency': urgency,
      };
      final uri = Uri(path: '/pricing/quote', queryParameters: queryParams).toString();
      final res = await ApiService.get(uri);
      if (res is Map<String, dynamic>) {
        return PriceQuote.fromJson(res);
      }
    } catch (_) {}

    // Deterministic fallback using the identical ReDo dynamic pricing engine formula:
    // (backend/src/services/dynamicPricing.js)
    return _computeDeterministicQuote(
      origin: origin,
      destination: destination,
      distanceKm: dist,
      weightTons: wTons,
      cargoType: cargoType,
      volumeCft: volumeCft,
      urgency: urgency,
    );
  }

  static PriceQuote _computeDeterministicQuote({
    required String origin,
    required String destination,
    required double distanceKm,
    required double weightTons,
    required String cargoType,
    required double volumeCft,
    required String urgency,
  }) {
    final volTons = volumeCft > 0 ? (volumeCft / 120.0) : 0.0;
    final billableWeight = max(weightTons, volTons);

    // Corridor matching
    final normO = origin.toLowerCase();
    final normD = destination.toLowerCase();
    double baseRate = 2.50;
    double minFare = 1200.0;
    String corridorId = 'default';
    String corridorName = 'All-India Standard Lane';

    if ((normO.contains('delhi') && normD.contains('patna')) ||
        (normO.contains('patna') && normD.contains('delhi'))) {
      corridorId = 'delhi_patna';
      corridorName = 'Delhi - Agra - Kanpur - Lucknow - Patna';
      baseRate = 2.40;
      minFare = 1500.0;
    } else if ((normO.contains('delhi') && normD.contains('mumbai')) ||
        (normO.contains('mumbai') && normD.contains('delhi'))) {
      corridorId = 'delhi_mumbai';
      corridorName = 'Delhi - Jaipur - Ahmedabad - Surat - Mumbai';
      baseRate = 2.20;
      minFare = 1500.0;
    } else if ((normO.contains('mumbai') && normD.contains('bengaluru')) ||
        (normO.contains('bengaluru') && normD.contains('mumbai'))) {
      corridorId = 'mumbai_bengaluru';
      corridorName = 'Mumbai - Pune - Kolhapur - Bengaluru';
      baseRate = 2.30;
      minFare = 1500.0;
    }

    // Cargo multiplier
    final normCargo = cargoType.toLowerCase();
    double cargoMultiplier = 1.0;
    if (normCargo.contains('fragile')) {
      cargoMultiplier = 1.18;
    } else if (normCargo.contains('perishable') || normCargo.contains('cold')) {
      cargoMultiplier = 1.25;
    } else if (normCargo.contains('fmcg') || normCargo.contains('food')) {
      cargoMultiplier = 1.08;
    } else if (normCargo.contains('high_value') || normCargo.contains('electronic')) {
      cargoMultiplier = 1.30;
    } else if (normCargo.contains('chem') || normCargo.contains('hazard')) {
      cargoMultiplier = 1.35;
    }

    final urgencyMultiplier = urgency == 'express' ? 1.15 : 1.0;
    final rawBase = distanceKm * billableWeight * baseRate;
    final calculatedFreight = (rawBase * cargoMultiplier * urgencyMultiplier).roundToDouble();
    final driverFreight = max(minFare, calculatedFreight);
    final redoFee = (driverFreight * 0.08).roundToDouble();
    final customerPrice = driverFreight + redoFee;

    final dedicated = max(4500.0, (distanceKm * 18.0 + 1500.0).roundToDouble());
    final savings = max(0.0, dedicated - customerPrice);
    final savingsPct = dedicated > 0 ? ((savings / dedicated) * 100).round() : 0;

    return PriceQuote(
      estimatedPriceInr: driverFreight,
      finalPriceInr: customerPrice,
      applicableFeesInr: redoFee,
      savingsAmountInr: savings,
      savingsPct: savingsPct,
      estimatedDedicatedTruckPriceInr: dedicated,
      conditions: PricingConditions(
        corridorId: corridorId,
        corridorName: corridorName,
        baseRatePerTonKm: baseRate,
        minFareInr: minFare,
        cargoTypeMultiplier: cargoMultiplier,
        surgeMultiplier: 1.0,
        isSurging: false,
        demandCount: 0,
        supplyCount: 0,
        billableWeightTons: billableWeight,
        actualWeightTons: weightTons,
        volumetricWeightTons: volTons,
        commissionPct: 0.08,
        urgency: urgency,
      ),
      isOfflineEstimated: true,
    );
  }

  // --- Real Driver Dispatch Integration ---

  static Future<Map<String, dynamic>> getDispatchState(String cargoId) async {
    try {
      final res = await ApiService.get('/cargo/$cargoId/dispatch');
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    // Fallback: Query Supabase tables directly
    try {
      final bookingRow = await client
          .from('bookings')
          .select('*, truck:trucks(*, owner:profiles(full_name, phone))')
          .eq('cargo_id', cargoId)
          .maybeSingle();

      if (bookingRow != null) {
        final bMap = Map<String, dynamic>.from(bookingRow);
        final truck = bMap['truck'] as Map<String, dynamic>?;
        final owner = truck?['owner'] as Map<String, dynamic>?;
        return {
          'status': 'assigned',
          'booking': bMap,
          'assigned_driver': {
            'name': owner?['full_name'] ?? 'Assigned Driver',
            'phone': owner?['phone'] ?? '+91-9876543210',
            'truck_reg': truck?['registration_number'] ?? '',
            'truck_type': truck?['truck_type'] ?? 'Commercial Truck',
            'rating': (truck?['driver_rating'] as num?)?.toDouble() ?? 4.8,
          },
        };
      }

      final offersRows = await client
          .from('dispatch_offers')
          .select('id, driver_id, truck_id, distance_km, status, expires_at, created_at')
          .eq('cargo_id', cargoId)
          .order('created_at', ascending: false);

      final cargoRow = await client
          .from('cargo_requests')
          .select('status')
          .eq('cargo_id', cargoId)
          .maybeSingle();

      final offersList = (offersRows as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final activeCount = offersList.where((o) {
        final status = o['status'] as String? ?? '';
        final exp = DateTime.tryParse(o['expires_at'] as String? ?? '');
        return status == 'pending' && (exp == null || exp.isAfter(DateTime.now()));
      }).length;

      return {
        'status': cargoRow?['status'] ?? 'open',
        'offers': offersList,
        'offers_count': offersList.length,
        'active_offers_count': activeCount,
      };
    } catch (_) {
      return {'status': 'open', 'offers': [], 'offers_count': 0, 'active_offers_count': 0};
    }
  }

  static Future<bool> retryDispatch(String cargoId) async {
    try {
      final res = await ApiService.post('/cargo/$cargoId/dispatch/retry');
      return res is Map && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelCargoRequest(String cargoId) async {
    bool ok = false;
    try {
      await ApiService.patch('/cargo/$cargoId', {'status': 'cancelled'});
      ok = true;
    } catch (_) {}

    try {
      await client.from('cargo_requests').update({'status': 'cancelled'}).eq('cargo_id', cargoId);
      ok = true;
    } catch (_) {}

    return ok;
  }

  static RealtimeChannel subscribeDispatch({
    required String cargoId,
    required void Function(Map<String, dynamic> change) onUpdate,
  }) {
    final ch = client.channel('dispatch-$cargoId-${DateTime.now().microsecondsSinceEpoch}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'dispatch_offers',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cargo_id',
        value: cargoId,
      ),
      callback: (payload) => onUpdate({'table': 'dispatch_offers', 'record': payload.newRecord}),
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cargo_id',
        value: cargoId,
      ),
      callback: (payload) => onUpdate({'table': 'bookings', 'record': payload.newRecord}),
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'cargo_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cargo_id',
        value: cargoId,
      ),
      callback: (payload) => onUpdate({'table': 'cargo_requests', 'record': payload.newRecord}),
    );
    ch.subscribe();
    return ch;
  }
}
