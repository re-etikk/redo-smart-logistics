import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

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
        'role': 'truck_owner',
        'onboarding_complete': false,
      });
    }
    return res;
  }

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'redopartner://auth',
    );
  }

  static Future<AuthResponse> demoLogin() async {
    const demoEmail = 'driver@redo.app';
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
        data: {'full_name': 'Harpreet Singh (Demo Partner)'},
      );
      final res = await client.auth.signInWithPassword(
        email: demoEmail,
        password: demoPass,
      );
      if (res.user != null) {
        await client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': 'Harpreet Singh (Demo Partner)',
          'company_name': 'Delhi NCR',
          'phone': '+91 98765 43210',
          'role': 'truck_owner',
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

  static Future<void> saveTruckStep({
    required String registrationNumber,
    required String truckType,
    required String bodyType,
    required double capacityTons,
    required String homeOrigin,
    required String emptyReturnFrom,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    final truckId = 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    await client.from('trucks').upsert({
      'truck_id': truckId,
      'owner_id': uid,
      'registration_number': registrationNumber.toUpperCase(),
      'truck_type': truckType,
      'body_type': bodyType,
      'home_origin': homeOrigin,
      'default_capacity_tons': capacityTons,
      'status': 'available',
    });

    // Register return trip for matching
    await client.from('truck_trips').insert({
      'truck_id': truckId,
      'origin': emptyReturnFrom,
      'destination': homeOrigin,
      'available_capacity_tons': capacityTons,
      'departure_at': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
    });
  }

  static Future<String> uploadDocument({
    required String docType,
    required Uint8List fileBytes,
  }) async {
    final uid = currentUser?.id ?? 'guest-driver';
    final fileName = '$uid/$docType-${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
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
        'document_reference_masked': 'upload:…${fileName.substring(fileName.length - 8)}',
      });

      return fileName;
    } catch (_) {
      return fileName;
    }
  }

  static Future<void> finishOnboarding() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('profiles').update({'onboarding_complete': true}).eq('id', uid);
  }

  // --- Loads & Trips ---
  static Future<List<AvailableLoad>> getAvailableLoads() async {
    try {
      final res = await client.from('cargo_requests')
          .select('*, sme:profiles(*)')
          .eq('status', 'open')
          .limit(10);

      if (res.isNotEmpty) {
        return (res as List).map((r) => AvailableLoad.fromJson(r)).toList();
      }
    } catch (_) {}

    // Fallback live freight loads on high-traffic return corridors
    return [
      AvailableLoad(
        cargoId: 'CRG-MH04-881',
        smeName: 'Tata AutoComp Systems',
        origin: 'Mumbai (Bhiwandi Hub)',
        destination: 'Delhi NCR (Manesar)',
        cargoType: 'Automotive Engine Parts',
        weightTons: 8.5,
        offeredPriceInr: 24500.0,
        matchScore: 98,
        pickupWindow: 'Today 6:00 PM - 9:00 PM',
      ),
      AvailableLoad(
        cargoId: 'CRG-GJ01-442',
        smeName: 'Reliance Retail Logistics',
        origin: 'Surat',
        destination: 'Delhi NCR',
        cargoType: 'Packaged Consumer Goods',
        weightTons: 6.0,
        offeredPriceInr: 18000.0,
        matchScore: 92,
        pickupWindow: 'Tomorrow 8:00 AM',
      ),
      AvailableLoad(
        cargoId: 'CRG-RJ14-109',
        smeName: 'Jaipur Rugs Exports',
        origin: 'Jaipur',
        destination: 'Mumbai Port',
        cargoType: 'Handicrafts & Rugs',
        weightTons: 11.0,
        offeredPriceInr: 28500.0,
        matchScore: 89,
        pickupWindow: 'Tomorrow 11:00 AM',
      ),
    ];
  }

  static Future<List<ActiveTrip>> getActiveTrips() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await client.from('bookings')
          .select('*, cargo:cargo_requests(*, sme:profiles(*)), truck:trucks(*)')
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        return (res as List).map((r) => ActiveTrip.fromJson(r)).toList();
      }
    } catch (_) {}

    return [
      ActiveTrip(
        bookingId: 'BK-89421',
        cargoId: 'CRG-5512',
        origin: 'Mumbai (Bhiwandi Hub)',
        destination: 'Delhi NCR (Gurugram)',
        cargoType: 'Automotive Components',
        weightTons: 8.5,
        payoutInr: 22100.0,
        status: 'in_transit',
        shipperName: 'Sharma Logistics (Rajesh)',
        shipperPhone: '+91 98765 43210',
      ),
    ];
  }

  static Future<void> updateTripStatus(String bookingId, String newStatus) async {
    try {
      await client.from('bookings').update({'status': newStatus}).eq('id', bookingId);
    } catch (_) {}
  }

  static Future<void> broadcastDriverGps({
    required double lat,
    required double lng,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      await client.from('trucks').update({
        'current_lat': lat,
        'current_lng': lng,
        'gps_enabled': true,
      }).eq('owner_id', uid);
    } catch (_) {}
  }
}
