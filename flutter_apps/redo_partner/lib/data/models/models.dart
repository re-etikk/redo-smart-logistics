class DriverProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? companyName;
  final String? avatarUrl;
  final bool onboardingComplete;

  DriverProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.companyName,
    this.avatarUrl,
    required this.onboardingComplete,
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

  TruckModel({
    required this.truckId,
    required this.ownerId,
    required this.truckType,
    required this.registrationNumber,
    required this.bodyType,
    required this.homeOrigin,
    required this.defaultCapacityTons,
    required this.status,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    return TruckModel(
      truckId: json['truck_id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      truckType: json['truck_type'] as String? ?? '22FT',
      registrationNumber: json['registration_number'] as String? ?? 'MH 04 AB 1234',
      bodyType: json['body_type'] as String? ?? 'Closed container',
      homeOrigin: json['home_origin'] as String? ?? 'Mumbai',
      defaultCapacityTons: (json['default_capacity_tons'] as num?)?.toDouble() ?? 9.0,
      status: json['status'] as String? ?? 'available',
    );
  }
}

class AvailableLoad {
  final String cargoId;
  final String smeName;
  final String origin;
  final String destination;
  final String cargoType;
  final double weightTons;
  final double offeredPriceInr;
  final int matchScore;
  final String pickupWindow;

  AvailableLoad({
    required this.cargoId,
    required this.smeName,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.weightTons,
    required this.offeredPriceInr,
    required this.matchScore,
    required this.pickupWindow,
  });

  factory AvailableLoad.fromJson(Map<String, dynamic> json) {
    final sme = json['sme'] as Map<String, dynamic>?;
    return AvailableLoad(
      cargoId: json['cargo_id'] as String,
      smeName: sme?['company_name'] ?? sme?['full_name'] ?? 'Verified Shipper',
      origin: json['origin'] as String? ?? 'Mumbai',
      destination: json['destination'] as String? ?? 'Delhi',
      cargoType: json['cargo_type'] as String? ?? 'General Freight',
      weightTons: (json['cargo_weight_tons'] as num?)?.toDouble() ?? 7.5,
      offeredPriceInr: (json['offered_price_inr'] as num?)?.toDouble() ?? 24000.0,
      matchScore: (json['match_score'] as num?)?.toInt() ?? 95,
      pickupWindow: json['pickup_window'] as String? ?? 'Today 6 PM - 9 PM',
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
  final String shipperPhone;
  final String? podUrl;

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
    required this.shipperPhone,
    this.podUrl,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>?;
    final sme = cargo?['sme'] as Map<String, dynamic>?;

    return ActiveTrip(
      bookingId: json['id'] as String,
      cargoId: json['cargo_id'] as String? ?? cargo?['cargo_id'] as String? ?? '',
      origin: cargo?['origin'] as String? ?? 'Mumbai Hub',
      destination: cargo?['destination'] as String? ?? 'Delhi NCR Hub',
      cargoType: cargo?['cargo_type'] as String? ?? 'Industrial Cargo',
      weightTons: (cargo?['cargo_weight_tons'] as num?)?.toDouble() ?? 8.5,
      payoutInr: (json['agreed_price_inr'] as num?)?.toDouble() ?? 22100.0,
      status: json['status'] as String? ?? 'in_transit',
      shipperName: sme?['company_name'] ?? 'Apex Logistics',
      shipperPhone: sme?['phone'] ?? '+91 98765 11223',
      podUrl: json['pod_url'] as String?,
    );
  }
}
