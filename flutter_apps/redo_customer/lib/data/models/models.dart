class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? companyName;
  final String? avatarUrl;
  final bool onboardingComplete;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.companyName,
    this.avatarUrl,
    required this.onboardingComplete,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'sme',
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

class CargoRequest {
  final String cargoId;
  final String smeId;
  final String origin;
  final String destination;
  final double distanceKm;
  final String cargoType;
  final double cargoWeightTons;
  final String? pickupDate;
  final String urgency;
  final String status;
  final String createdAt;

  CargoRequest({
    required this.cargoId,
    required this.smeId,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.cargoType,
    required this.cargoWeightTons,
    this.pickupDate,
    required this.urgency,
    required this.status,
    required this.createdAt,
  });

  factory CargoRequest.fromJson(Map<String, dynamic> json) {
    return CargoRequest(
      cargoId: json['cargo_id'] as String,
      smeId: json['sme_id'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      cargoType: json['cargo_type'] as String? ?? 'General Goods',
      cargoWeightTons: (json['cargo_weight_tons'] as num?)?.toDouble() ?? 5.0,
      pickupDate: json['pickup_date'] as String?,
      urgency: json['urgency'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class TruckMatch {
  final String truckId;
  final String ownerId;
  final String truckType;
  final String? registrationNumber;
  final String origin;
  final String destination;
  final double availableCapacityTons;
  final double matchScore;
  final double basePriceInr;
  final double backhaulDiscountPercent;
  final double finalPriceInr;
  final double driverRating;
  final double onTimeRate;
  final String departureAt;

  TruckMatch({
    required this.truckId,
    required this.ownerId,
    required this.truckType,
    this.registrationNumber,
    required this.origin,
    required this.destination,
    required this.availableCapacityTons,
    required this.matchScore,
    required this.basePriceInr,
    required this.backhaulDiscountPercent,
    required this.finalPriceInr,
    required this.driverRating,
    required this.onTimeRate,
    required this.departureAt,
  });

  factory TruckMatch.fromJson(Map<String, dynamic> json) {
    return TruckMatch(
      truckId: json['truck_id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      truckType: json['truck_type'] as String? ?? '22FT',
      registrationNumber: json['registration_number'] as String?,
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      availableCapacityTons: (json['available_capacity_tons'] as num?)?.toDouble() ?? 9.0,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 88.0,
      basePriceInr: (json['base_price_inr'] as num?)?.toDouble() ?? 25000.0,
      backhaulDiscountPercent: (json['discount_pct'] as num?)?.toDouble() ?? 28.0,
      finalPriceInr: (json['final_price_inr'] as num?)?.toDouble() ?? 18000.0,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 4.8,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.94,
      departureAt: json['departure_at'] as String? ?? 'Today 6:00 PM',
    );
  }
}

class BookingItem {
  final String id;
  final String cargoId;
  final String truckId;
  final String origin;
  final String destination;
  final String cargoType;
  final double weightTons;
  final double agreedPriceInr;
  final String status;
  final double? currentLat;
  final double? currentLng;
  final String? driverName;
  final String? driverPhone;
  final String? truckReg;
  final String createdAt;

  BookingItem({
    required this.id,
    required this.cargoId,
    required this.truckId,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.weightTons,
    required this.agreedPriceInr,
    required this.status,
    this.currentLat,
    this.currentLng,
    this.driverName,
    this.driverPhone,
    this.truckReg,
    required this.createdAt,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>?;
    final truck = json['truck'] as Map<String, dynamic>?;
    final owner = truck?['owner'] as Map<String, dynamic>?;

    return BookingItem(
      id: json['id'] as String,
      cargoId: json['cargo_id'] as String? ?? cargo?['cargo_id'] as String? ?? '',
      truckId: json['truck_id'] as String? ?? truck?['truck_id'] as String? ?? '',
      origin: cargo?['origin'] as String? ?? json['origin'] as String? ?? 'Mumbai',
      destination: cargo?['destination'] as String? ?? json['destination'] as String? ?? 'Delhi',
      cargoType: cargo?['cargo_type'] as String? ?? 'Industrial Cargo',
      weightTons: (cargo?['cargo_weight_tons'] as num?)?.toDouble() ?? (json['weight_tons'] as num?)?.toDouble() ?? 5.0,
      agreedPriceInr: (json['agreed_price_inr'] as num?)?.toDouble() ?? 18000.0,
      status: json['status'] as String? ?? 'pending',
      currentLat: (truck?['current_lat'] as num?)?.toDouble() ?? (json['current_lat'] as num?)?.toDouble(),
      currentLng: (truck?['current_lng'] as num?)?.toDouble() ?? (json['current_lng'] as num?)?.toDouble(),
      driverName: owner?['full_name'] as String? ?? 'Driver Assigned',
      driverPhone: owner?['phone'] as String? ?? '+91 98765 43210',
      truckReg: truck?['registration_number'] as String? ?? 'DL 01 AB 4321',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
