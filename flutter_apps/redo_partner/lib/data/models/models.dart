import 'dart:convert';
import 'package:intl/intl.dart';

class DriverProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? companyName;
  final String? avatarUrl;
  final bool onboardingComplete;
  // Dedicated flag for THIS app (driver + truck KYC setup) — separate from
  // `onboardingComplete`, which the customer app uses for its own business
  // profile setup on the same shared `profiles` row. See migration 0008.
  final bool partnerOnboardingComplete;
  final String? dlNumber;
  final bool dlVerified;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final bool faceBiometricVerified;

  DriverProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.companyName,
    this.avatarUrl,
    required this.onboardingComplete,
    this.partnerOnboardingComplete = false,
    this.dlNumber,
    this.dlVerified = false,
    this.panNumber,
    this.aadhaarNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.faceBiometricVerified = false,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Driver',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'truck_owner',
      companyName: json['company_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      partnerOnboardingComplete: (json['partner_onboarding_complete'] as bool?) ?? (json['onboarding_complete'] as bool? ?? false),
      dlNumber: json['dl_number'] as String?,
      dlVerified: json['dl_verified'] as bool? ?? false,
      panNumber: json['pan_number'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      faceBiometricVerified: json['face_biometric_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'role': role,
    'company_name': companyName,
    'avatar_url': avatarUrl,
    'onboarding_complete': onboardingComplete,
    'partner_onboarding_complete': partnerOnboardingComplete,
    if (dlNumber != null) 'dl_number': dlNumber,
    'dl_verified': dlVerified,
    if (panNumber != null) 'pan_number': panNumber,
    if (aadhaarNumber != null) 'aadhaar_number': aadhaarNumber,
    if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
    if (bankIfsc != null) 'bank_ifsc': bankIfsc,
    'face_biometric_verified': faceBiometricVerified,
  };
}

class TruckModel {
  final String truckId;
  final String ownerId;
  final String truckType;
  final String registrationNumber;
  final String bodyType;
  final String homeOrigin;
  final double defaultCapacityTons;
  final String status;
  final bool rcVerified;
  final String? insurancePolicy;
  final String? insuranceExpiry;
  final String? fitnessValidUntil;
  final String? nationalPermit;
  final String? pucValidUntil;
  final bool verifiedBadge;

  TruckModel({
    required this.truckId,
    required this.ownerId,
    required this.truckType,
    required this.registrationNumber,
    required this.bodyType,
    required this.homeOrigin,
    required this.defaultCapacityTons,
    required this.status,
    this.rcVerified = true,
    this.insurancePolicy,
    this.insuranceExpiry,
    this.fitnessValidUntil,
    this.nationalPermit,
    this.pucValidUntil,
    this.verifiedBadge = true,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    return TruckModel(
      truckId: json['truck_id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      truckType: json['truck_type'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? '',
      bodyType: json['body_type'] as String? ?? '',
      homeOrigin: json['home_origin'] as String? ?? '',
      defaultCapacityTons: (json['default_capacity_tons'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'available',
      rcVerified: json['rc_verified'] as bool? ?? true,
      insurancePolicy: json['insurance_policy'] as String?,
      insuranceExpiry: json['insurance_expiry'] as String?,
      fitnessValidUntil: json['fitness_valid_until'] as String?,
      nationalPermit: json['national_permit'] as String?,
      pucValidUntil: json['puc_valid_until'] as String?,
      verifiedBadge: json['verified_badge'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'truck_id': truckId,
    'owner_id': ownerId,
    'truck_type': truckType,
    'registration_number': registrationNumber,
    'body_type': bodyType,
    'home_origin': homeOrigin,
    'default_capacity_tons': defaultCapacityTons,
    'status': status,
    'rc_verified': rcVerified,
    if (insurancePolicy != null) 'insurance_policy': insurancePolicy,
    if (insuranceExpiry != null) 'insurance_expiry': insuranceExpiry,
    if (fitnessValidUntil != null) 'fitness_valid_until': fitnessValidUntil,
    if (nationalPermit != null) 'national_permit': nationalPermit,
    if (pucValidUntil != null) 'puc_valid_until': pucValidUntil,
    'verified_badge': verifiedBadge,
  };
}

class AvailableLoad {
  final String cargoId;
  final String smeName;
  final String origin;
  final String destination;
  final String cargoType;
  final double weightTons;
  final double offeredPriceInr;
  final double distanceKm;
  final String pickupWindow;
  final DateTime? pickupAt;
  final String urgency;
  final bool isInstant;
  final String? pickupAddress;
  final String? dropAddress;
  final String? gstin;
  final int matchScore;
  // True only when matchScore came from the real backend ML pipeline
  // (/recommendations/cargo/:truck_id), scored against one of this driver's
  // actual open trips. False for the flat/unfiltered fallback listing — the
  // UI should hide the score badge rather than show a fabricated number.
  final bool hasRealMatchScore;
  final List<String> matchReasons;

  AvailableLoad({
    required this.cargoId,
    required this.smeName,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.weightTons,
    required this.offeredPriceInr,
    required this.distanceKm,
    required this.pickupWindow,
    this.pickupAt,
    this.urgency = 'normal',
    this.isInstant = false,
    this.pickupAddress,
    this.dropAddress,
    this.gstin,
    this.matchScore = 0,
    this.hasRealMatchScore = false,
    this.matchReasons = const [],
  });

  factory AvailableLoad.fromJson(Map<String, dynamic> json) {
    final sme = json['sme'] as Map<String, dynamic>?;
    final urg = (json['urgency'] as String? ?? 'normal').toLowerCase();
    final isInst = urg == 'instant';

    // Parse pickup_at if present
    DateTime? parsedPickup;
    if (json['pickup_at'] != null) {
      parsedPickup = DateTime.tryParse(json['pickup_at'].toString())?.toLocal();
    }

    // Parse special handling metadata safely
    String? pAddr = json['pickup_address'] as String?;
    String? dAddr = json['drop_address'] as String?;
    String? gst = json['gstin'] as String?;

    final specialHandling = json['special_handling'];
    if (specialHandling is String && specialHandling.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> meta = jsonDecode(specialHandling);
        pAddr ??= meta['pickup_address'] as String?;
        dAddr ??= meta['drop_address'] as String?;
        gst ??= meta['gstin'] as String?;
      } catch (_) {}
    }

    final tons = (json['cargo_weight_tons'] as num?)?.toDouble() ?? 0;
    final km = (json['distance_km'] as num?)?.toDouble() ?? 0;

    return AvailableLoad(
      cargoId: json['cargo_id'] as String,
      smeName: sme?['company_name'] ?? sme?['full_name'] ?? 'Verified Shipper',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      cargoType: json['cargo_type'] as String? ?? 'General Freight',
      weightTons: tons,
      // No confirmed price until a truck is matched/booked — show an
      // honest estimate using the same ₹/km/ton rate the backend uses,
      // rather than a random/undefined number.
      offeredPriceInr: (km * tons * 1.05).roundToDouble(),
      distanceKm: km,
      pickupWindow: json['pickup_window'] as String? ?? 'Flexible pickup',
      pickupAt: parsedPickup,
      urgency: urg,
      isInstant: isInst,
      pickupAddress: pAddr,
      dropAddress: dAddr,
      gstin: gst,
      // No ML match score in this flat/unfiltered listing (it isn't scored
      // against any specific truck/trip) — hasRealMatchScore stays false so
      // the UI doesn't show a fabricated percentage.
      matchScore: 0,
      hasRealMatchScore: false,
    );
  }

  /// Built from a REAL ranked result: backend GET
  /// /recommendations/cargo/:truck_id — Stage-1 hard filters (route,
  /// capacity, timing, cargo type) + Stage-2 ML ranking, scored specifically
  /// against one of the driver's own open trips. This is the actual
  /// "Mumbai→Delhi truck sees Mumbai→Delhi loads" matching the driver asked
  /// for — not a flat list of every open load in the country.
  factory AvailableLoad.fromMatchJson(Map<String, dynamic> json) {
    final urg = (json['urgency'] as String? ?? 'normal').toLowerCase();
    DateTime? parsedPickup;
    if (json['pickup_at'] != null) {
      parsedPickup = DateTime.tryParse(json['pickup_at'].toString())?.toLocal();
    }
    String window = 'Flexible pickup';
    if (parsedPickup != null) window = DateFormat('EEE, d MMM - h:mm a').format(parsedPickup);

    return AvailableLoad(
      cargoId: json['cargo_id'] as String,
      smeName: 'Verified Shipper',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      cargoType: json['cargo_type'] as String? ?? 'General Freight',
      weightTons: (json['cargo_weight_tons'] as num?)?.toDouble() ?? 0,
      offeredPriceInr: (json['estimated_price_inr'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      pickupWindow: window,
      pickupAt: parsedPickup,
      urgency: urg,
      isInstant: urg == 'instant',
      // match_score from the backend is 0..1 (ML probability) — show as a
      // whole-number percentage.
      matchScore: (((json['match_score'] as num?) ?? 0) * 100).round(),
      hasRealMatchScore: true,
      matchReasons: (json['reasons'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }
}

class ActiveTrip {
  final String bookingId;
  final String cargoId;
  final String origin;
  final String destination;
  final String cargoType;
  final double weightTons;
  final double payoutInr;
  String status; // accepted, confirmed, pickup_ready, in_transit, delivered
  final String shipperName;
  final String? shipperPhone;
  final String? podUrl;
  final DateTime? pickupAt;
  final String? pickupAddress;
  final String? dropAddress;
  final bool isInstant;

  ActiveTrip({
    required this.bookingId,
    required this.cargoId,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.weightTons,
    required this.payoutInr,
    required this.status,
    required this.shipperName,
    this.shipperPhone,
    this.podUrl,
    this.pickupAt,
    this.pickupAddress,
    this.dropAddress,
    this.isInstant = false,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>?;
    final sme = cargo?['sme'] as Map<String, dynamic>?;

    DateTime? pDate;
    if (cargo?['pickup_at'] != null) {
      pDate = DateTime.tryParse(cargo!['pickup_at'].toString())?.toLocal();
    }

    String? pAddr = cargo?['pickup_address'] as String?;
    String? dAddr = cargo?['drop_address'] as String?;
    final specialHandling = cargo?['special_handling'];
    if (specialHandling is String && specialHandling.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> meta = jsonDecode(specialHandling);
        pAddr ??= meta['pickup_address'] as String?;
        dAddr ??= meta['drop_address'] as String?;
      } catch (_) {}
    }

    final isInst = (cargo?['urgency'] as String? ?? '').toLowerCase() == 'instant';

    return ActiveTrip(
      bookingId: json['id'] as String,
      cargoId: json['cargo_id'] as String? ?? cargo?['cargo_id'] as String? ?? '',
      origin: cargo?['origin'] as String? ?? '',
      destination: cargo?['destination'] as String? ?? '',
      cargoType: cargo?['cargo_type'] as String? ?? '',
      weightTons: (cargo?['cargo_weight_tons'] as num?)?.toDouble() ?? 0,
      payoutInr: (json['agreed_price_inr'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      shipperName: sme?['company_name'] ?? sme?['full_name'] ?? 'Verified Shipper',
      shipperPhone: sme?['phone'] as String?,
      podUrl: json['pod_url'] as String?,
      pickupAt: pDate,
      pickupAddress: pAddr,
      dropAddress: dAddr,
      isInstant: isInst,
    );
  }
}
