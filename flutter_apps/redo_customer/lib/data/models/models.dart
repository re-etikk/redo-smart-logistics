import 'dart:convert';

class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? companyName;
  final String? avatarUrl;
  final bool onboardingComplete;
  final String? gstin;
  final String? panNumber;
  final String? businessAddress;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.companyName,
    this.avatarUrl,
    required this.onboardingComplete,
    this.gstin,
    this.panNumber,
    this.businessAddress,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'sme',
      companyName: json['company_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      gstin: json['gstin'] as String?,
      panNumber: json['pan_number'] as String?,
      businessAddress: json['business_address'] as String?,
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
    if (gstin != null) 'gstin': gstin,
    if (panNumber != null) 'pan_number': panNumber,
    if (businessAddress != null) 'business_address': businessAddress,
  };

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? role,
    String? companyName,
    String? avatarUrl,
    bool? onboardingComplete,
    String? gstin,
    String? panNumber,
    String? businessAddress,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      businessAddress: businessAddress ?? this.businessAddress,
    );
  }
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
  final String? pickupAt;
  final String urgency;
  final String status;
  final String createdAt;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropAddress;
  final String? gstin;
  final int packageCount;
  final String? dimensions;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final bool isFragile;
  final bool isTemperatureSensitive;
  final double declaredValueInr;
  final double estimatedPriceInr;

  CargoRequest({
    required this.cargoId,
    required this.smeId,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.cargoType,
    required this.cargoWeightTons,
    this.pickupDate,
    this.pickupAt,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropAddress,
    this.gstin,
    this.packageCount = 1,
    this.dimensions,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isFragile = false,
    this.isTemperatureSensitive = false,
    this.declaredValueInr = 0.0,
    this.estimatedPriceInr = 0.0,
  });

  factory CargoRequest.fromJson(Map<String, dynamic> json) {
    String? pAddr;
    String? dAddr;
    String? gNum;
    int pkgCount = (json['package_count'] as num?)?.toInt() ?? 1;
    String? dims = json['dimensions'] as String?;
    double? l = (json['length_cm'] as num?)?.toDouble();
    double? w = (json['width_cm'] as num?)?.toDouble();
    double? h = (json['height_cm'] as num?)?.toDouble();
    bool fragile = json['is_fragile'] as bool? ?? false;
    bool tempSens = json['is_temperature_sensitive'] as bool? ?? false;
    double decVal = (json['declared_value_inr'] as num?)?.toDouble() ?? 0.0;
    double estPrice = (json['estimated_price_inr'] as num?)?.toDouble() ??
        (json['offered_price_inr'] as num?)?.toDouble() ??
        0.0;

    final sh = json['special_handling'] as String?;
    if (sh != null && sh.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(sh) as Map<String, dynamic>;
        pAddr = decoded['pickup_address'] as String?;
        dAddr = decoded['drop_address'] as String?;
        gNum = decoded['gstin'] as String?;
        if (decoded['package_count'] != null) {
          pkgCount = (decoded['package_count'] as num).toInt();
        }
        if (decoded['dimensions'] != null) {
          dims = decoded['dimensions'] as String;
        }
        if (decoded['length_cm'] != null) {
          l = (decoded['length_cm'] as num).toDouble();
        }
        if (decoded['width_cm'] != null) {
          w = (decoded['width_cm'] as num).toDouble();
        }
        if (decoded['height_cm'] != null) {
          h = (decoded['height_cm'] as num).toDouble();
        }
        if (decoded['is_fragile'] != null) {
          fragile = decoded['is_fragile'] as bool;
        }
        if (decoded['is_temperature_sensitive'] != null) {
          tempSens = decoded['is_temperature_sensitive'] as bool;
        }
        if (decoded['declared_value_inr'] != null) {
          decVal = (decoded['declared_value_inr'] as num).toDouble();
        }
        if (decoded['estimated_price_inr'] != null) {
          estPrice = (decoded['estimated_price_inr'] as num).toDouble();
        }
      } catch (_) {}
    }

    return CargoRequest(
      cargoId: json['cargo_id'] as String,
      smeId: json['sme_id'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      cargoType: json['cargo_type'] as String? ?? '',
      cargoWeightTons: (json['cargo_weight_tons'] as num?)?.toDouble() ?? 0,
      pickupDate: json['pickup_date'] as String?,
      pickupAt: json['pickup_at'] as String?,
      urgency: json['urgency'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'open',
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      pickupAddress: pAddr ?? json['pickup_address'] as String?,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      dropAddress: dAddr ?? json['drop_address'] as String?,
      gstin: gNum ?? json['gstin'] as String?,
      packageCount: pkgCount,
      dimensions: dims,
      lengthCm: l,
      widthCm: w,
      heightCm: h,
      isFragile: fragile,
      isTemperatureSensitive: tempSens,
      declaredValueInr: decVal,
      estimatedPriceInr: estPrice,
    );
  }

  Map<String, dynamic> toJson() => {
    'cargo_id': cargoId,
    'sme_id': smeId,
    'origin': origin,
    'destination': destination,
    'distance_km': distanceKm,
    'cargo_type': cargoType,
    'cargo_weight_tons': cargoWeightTons,
    if (pickupDate != null) 'pickup_date': pickupDate,
    if (pickupAt != null) 'pickup_at': pickupAt,
    'urgency': urgency,
    'status': status,
    'created_at': createdAt,
    if (pickupAddress != null) 'pickup_address': pickupAddress,
    if (pickupLat != null) 'pickup_lat': pickupLat,
    if (pickupLng != null) 'pickup_lng': pickupLng,
    if (dropAddress != null) 'drop_address': dropAddress,
    if (gstin != null) 'gstin': gstin,
    'package_count': packageCount,
    if (dimensions != null) 'dimensions': dimensions,
    if (lengthCm != null) 'length_cm': lengthCm,
    if (widthCm != null) 'width_cm': widthCm,
    if (heightCm != null) 'height_cm': heightCm,
    'is_fragile': isFragile,
    'is_temperature_sensitive': isTemperatureSensitive,
    'declared_value_inr': declaredValueInr,
    'estimated_price_inr': estimatedPriceInr,
  };
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
      truckType: json['truck_type'] as String? ?? '',
      registrationNumber: json['registration_number'] as String?,
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      availableCapacityTons:
          (json['available_capacity_tons'] as num?)?.toDouble() ?? 0,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      basePriceInr: (json['base_price_inr'] as num?)?.toDouble() ?? 0,
      backhaulDiscountPercent: (json['discount_pct'] as num?)?.toDouble() ?? 0,
      finalPriceInr: (json['final_price_inr'] as num?)?.toDouble() ?? 0,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0,
      departureAt: json['departure_at'] as String? ?? 'Not provided',
    );
  }
}

class BookingItem {
  final String id;
  final String cargoId;
  final String truckId;
  final String? pickupOtp; // shipper shares on arrival
  final String? deliveryOtp; // shipper shares on delivery
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
  final String? pickupAddress;
  final String? dropAddress;
  final int packageCount;
  final String? dimensions;
  final bool isFragile;
  final bool isTemperatureSensitive;
  final double declaredValueInr;
  final double estimatedPriceInr;

  BookingItem({
    required this.id,
    required this.cargoId,
    required this.truckId,
    this.pickupOtp,
    this.deliveryOtp,
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
    this.pickupAddress,
    this.dropAddress,
    this.packageCount = 1,
    this.dimensions,
    this.isFragile = false,
    this.isTemperatureSensitive = false,
    this.declaredValueInr = 0.0,
    this.estimatedPriceInr = 0.0,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>?;
    final truck = json['truck'] as Map<String, dynamic>?;
    final owner = truck?['owner'] as Map<String, dynamic>?;

    String? pAddr = cargo?['pickup_address'] as String? ?? json['pickup_address'] as String?;
    String? dAddr = cargo?['drop_address'] as String? ?? json['drop_address'] as String?;
    int pkgCount = (cargo?['package_count'] as num?)?.toInt() ??
        (json['package_count'] as num?)?.toInt() ??
        1;
    String? dims = cargo?['dimensions'] as String? ?? json['dimensions'] as String?;
    bool fragile = cargo?['is_fragile'] as bool? ?? json['is_fragile'] as bool? ?? false;
    bool tempSens = cargo?['is_temperature_sensitive'] as bool? ?? json['is_temperature_sensitive'] as bool? ?? false;
    double decVal = (cargo?['declared_value_inr'] as num?)?.toDouble() ??
        (json['declared_value_inr'] as num?)?.toDouble() ??
        0.0;
    double estPrice = (cargo?['estimated_price_inr'] as num?)?.toDouble() ??
        (json['estimated_price_inr'] as num?)?.toDouble() ??
        (json['agreed_price_inr'] as num?)?.toDouble() ??
        0.0;

    final sh = (cargo?['special_handling'] ?? json['special_handling']) as String?;
    if (sh != null && sh.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(sh) as Map<String, dynamic>;
        pAddr = decoded['pickup_address'] as String? ?? pAddr;
        dAddr = decoded['drop_address'] as String? ?? dAddr;
        if (decoded['package_count'] != null) {
          pkgCount = (decoded['package_count'] as num).toInt();
        }
        if (decoded['dimensions'] != null) {
          dims = decoded['dimensions'] as String;
        }
        if (decoded['is_fragile'] != null) {
          fragile = decoded['is_fragile'] as bool;
        }
        if (decoded['is_temperature_sensitive'] != null) {
          tempSens = decoded['is_temperature_sensitive'] as bool;
        }
        if (decoded['declared_value_inr'] != null) {
          decVal = (decoded['declared_value_inr'] as num).toDouble();
        }
        if (decoded['estimated_price_inr'] != null) {
          estPrice = (decoded['estimated_price_inr'] as num).toDouble();
        }
      } catch (_) {}
    }

    final rawDeliveryOtp = json['delivery_otp'] as String?;
    final rawPickupOtp = json['pickup_otp'] as String?;
    final bookingIdStr = (json['id'] ?? '').toString();
    final fallbackDelivery = bookingIdStr.isNotEmpty
        ? ((bookingIdStr.hashCode.abs() % 9000) + 1000).toString()
        : '8492';
    final fallbackPickup = bookingIdStr.isNotEmpty
        ? ((('${bookingIdStr}_pickup').hashCode.abs() % 9000) + 1000).toString()
        : '3174';

    return BookingItem(
      id: json['id'] as String,
      pickupOtp: (rawPickupOtp != null && rawPickupOtp.isNotEmpty) ? rawPickupOtp : fallbackPickup,
      deliveryOtp: (rawDeliveryOtp != null && rawDeliveryOtp.isNotEmpty) ? rawDeliveryOtp : fallbackDelivery,
      cargoId:
          json['cargo_id'] as String? ?? cargo?['cargo_id'] as String? ?? '',
      truckId:
          json['truck_id'] as String? ?? truck?['truck_id'] as String? ?? '',
      origin: cargo?['origin'] as String? ?? json['origin'] as String? ?? '',
      destination:
          cargo?['destination'] as String? ??
          json['destination'] as String? ??
          '',
      cargoType:
          cargo?['cargo_type'] as String? ??
          json['cargo_type'] as String? ??
          '',
      weightTons:
          (cargo?['cargo_weight_tons'] as num?)?.toDouble() ??
          (json['weight_tons'] as num?)?.toDouble() ??
          0,
      agreedPriceInr: (json['agreed_price_inr'] as num?)?.toDouble() ?? estPrice,
      status: json['status'] as String? ?? 'pending',
      currentLat:
          (truck?['current_lat'] as num?)?.toDouble() ??
          (json['current_lat'] as num?)?.toDouble(),
      currentLng:
          (truck?['current_lng'] as num?)?.toDouble() ??
          (json['current_lng'] as num?)?.toDouble(),
      driverName:
          owner?['full_name'] as String? ?? json['driver_name'] as String?,
      driverPhone:
          owner?['phone'] as String? ?? json['driver_phone'] as String?,
      truckReg:
          truck?['registration_number'] as String? ??
          json['truck_reg'] as String?,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      pickupAddress: pAddr,
      dropAddress: dAddr,
      packageCount: pkgCount,
      dimensions: dims,
      isFragile: fragile,
      isTemperatureSensitive: tempSens,
      declaredValueInr: decVal,
      estimatedPriceInr: estPrice,
    );
  }

  factory BookingItem.fromCargo(CargoRequest c) {
    return BookingItem(
      id: c.cargoId,
      cargoId: c.cargoId,
      truckId: '',
      origin: c.origin,
      destination: c.destination,
      cargoType: c.cargoType,
      weightTons: c.cargoWeightTons,
      agreedPriceInr: c.estimatedPriceInr > 0
          ? c.estimatedPriceInr
          : (c.distanceKm * c.cargoWeightTons * 1.05).roundToDouble(),
      status: c.status,
      createdAt: c.createdAt,
      pickupAddress: c.pickupAddress,
      dropAddress: c.dropAddress,
      packageCount: c.packageCount,
      dimensions: c.dimensions,
      isFragile: c.isFragile,
      isTemperatureSensitive: c.isTemperatureSensitive,
      declaredValueInr: c.declaredValueInr,
      estimatedPriceInr: c.estimatedPriceInr,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cargo_id': cargoId,
    'truck_id': truckId,
    if (pickupOtp != null) 'pickup_otp': pickupOtp,
    if (deliveryOtp != null) 'delivery_otp': deliveryOtp,
    'origin': origin,
    'destination': destination,
    'cargo_type': cargoType,
    'weight_tons': weightTons,
    'agreed_price_inr': agreedPriceInr,
    'status': status,
    if (currentLat != null) 'current_lat': currentLat,
    if (currentLng != null) 'current_lng': currentLng,
    if (driverName != null) 'driver_name': driverName,
    if (driverPhone != null) 'driver_phone': driverPhone,
    if (truckReg != null) 'truck_reg': truckReg,
    'created_at': createdAt,
    if (pickupAddress != null) 'pickup_address': pickupAddress,
    if (dropAddress != null) 'drop_address': dropAddress,
    'package_count': packageCount,
    if (dimensions != null) 'dimensions': dimensions,
    'is_fragile': isFragile,
    'is_temperature_sensitive': isTemperatureSensitive,
    'declared_value_inr': declaredValueInr,
    'estimated_price_inr': estimatedPriceInr,
  };
}

class PricingConditions {
  final String corridorId;
  final String corridorName;
  final double baseRatePerTonKm;
  final double minFareInr;
  final double cargoTypeMultiplier;
  final double surgeMultiplier;
  final bool isSurging;
  final int demandCount;
  final int supplyCount;
  final double billableWeightTons;
  final double actualWeightTons;
  final double volumetricWeightTons;
  final double commissionPct;
  final String urgency;

  const PricingConditions({
    this.corridorId = 'default',
    this.corridorName = 'All-India Standard Lane',
    this.baseRatePerTonKm = 2.5,
    this.minFareInr = 1200,
    this.cargoTypeMultiplier = 1.0,
    this.surgeMultiplier = 1.0,
    this.isSurging = false,
    this.demandCount = 0,
    this.supplyCount = 0,
    this.billableWeightTons = 0.5,
    this.actualWeightTons = 0.5,
    this.volumetricWeightTons = 0.0,
    this.commissionPct = 0.08,
    this.urgency = 'standard',
  });

  factory PricingConditions.fromJson(Map<String, dynamic> json) {
    return PricingConditions(
      corridorId: json['corridor_id'] as String? ?? 'default',
      corridorName: json['corridor_name'] as String? ?? 'All-India Standard Lane',
      baseRatePerTonKm: (json['base_rate_per_ton_km'] as num?)?.toDouble() ?? 2.5,
      minFareInr: (json['min_fare_inr'] as num?)?.toDouble() ?? 1200,
      cargoTypeMultiplier: (json['cargo_type_multiplier'] as num?)?.toDouble() ?? 1.0,
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble() ?? 1.0,
      isSurging: json['is_surging'] as bool? ?? false,
      demandCount: (json['demand_count'] as num?)?.toInt() ?? 0,
      supplyCount: (json['supply_count'] as num?)?.toInt() ?? 0,
      billableWeightTons: (json['billable_weight_tons'] as num?)?.toDouble() ?? 0.5,
      actualWeightTons: (json['actual_weight_tons'] as num?)?.toDouble() ?? 0.5,
      volumetricWeightTons: (json['volumetric_weight_tons'] as num?)?.toDouble() ?? 0.0,
      commissionPct: (json['commission_pct'] as num?)?.toDouble() ?? 0.08,
      urgency: json['urgency'] as String? ?? 'standard',
    );
  }

  Map<String, dynamic> toJson() => {
    'corridor_id': corridorId,
    'corridor_name': corridorName,
    'base_rate_per_ton_km': baseRatePerTonKm,
    'min_fare_inr': minFareInr,
    'cargo_type_multiplier': cargoTypeMultiplier,
    'surge_multiplier': surgeMultiplier,
    'is_surging': isSurging,
    'demand_count': demandCount,
    'supply_count': supplyCount,
    'billable_weight_tons': billableWeightTons,
    'actual_weight_tons': actualWeightTons,
    'volumetric_weight_tons': volumetricWeightTons,
    'commission_pct': commissionPct,
    'urgency': urgency,
  };
}

class PriceQuote {
  final double estimatedPriceInr; // Base freight for the trip
  final double finalPriceInr;     // Total customer price (driver freight + redo fee)
  final double applicableFeesInr; // ReDo platform commission fee
  final double savingsAmountInr;  // Savings compared to dedicated full-truck benchmark
  final int savingsPct;           // Savings percentage
  final double estimatedDedicatedTruckPriceInr;
  final PricingConditions conditions;
  final bool isOfflineEstimated;

  const PriceQuote({
    required this.estimatedPriceInr,
    required this.finalPriceInr,
    required this.applicableFeesInr,
    required this.savingsAmountInr,
    required this.savingsPct,
    required this.estimatedDedicatedTruckPriceInr,
    required this.conditions,
    this.isOfflineEstimated = false,
  });

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    final driverFreight = (json['driver_freight_inr'] as num?)?.toDouble() ??
        (json['estimated_price_inr'] as num?)?.toDouble() ??
        (json['price_inr'] as num?)?.toDouble() ??
        0.0;
    final redoFee = (json['applicable_fees_inr'] as num?)?.toDouble() ??
        (json['redo_fee_inr'] as num?)?.toDouble() ??
        (driverFreight * 0.08).roundToDouble();
    final customerPrice = (json['final_price_inr'] as num?)?.toDouble() ??
        (json['customer_price_inr'] as num?)?.toDouble() ??
        (json['price_inr'] as num?)?.toDouble() ??
        (driverFreight + redoFee);
    final dedicated = (json['estimated_dedicated_truck_price'] as num?)?.toDouble() ??
        (json['estimated_dedicated_truck_price_inr'] as num?)?.toDouble() ??
        (customerPrice * 1.6);
    final savings = (json['savings_amount'] as num?)?.toDouble() ??
        (json['savings_amount_inr'] as num?)?.toDouble() ??
        (dedicated > customerPrice ? dedicated - customerPrice : 0.0);
    final pct = (json['savings_pct'] as num?)?.toInt() ??
        (dedicated > 0 ? ((savings / dedicated) * 100).round() : 0);

    final conditionsMap = json['pricing_conditions'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['pricing_conditions'] as Map)
        : json;

    return PriceQuote(
      estimatedPriceInr: driverFreight,
      finalPriceInr: customerPrice,
      applicableFeesInr: redoFee,
      savingsAmountInr: savings,
      savingsPct: pct,
      estimatedDedicatedTruckPriceInr: dedicated,
      conditions: PricingConditions.fromJson(conditionsMap),
      isOfflineEstimated: json['is_offline_estimated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'estimated_price_inr': estimatedPriceInr,
    'final_price_inr': finalPriceInr,
    'applicable_fees_inr': applicableFeesInr,
    'savings_amount_inr': savingsAmountInr,
    'savings_pct': savingsPct,
    'estimated_dedicated_truck_price_inr': estimatedDedicatedTruckPriceInr,
    'pricing_conditions': conditions.toJson(),
    'is_offline_estimated': isOfflineEstimated,
  };
}

class DispatchOfferItem {
  final String id;
  final String cargoId;
  final String driverId;
  final String truckId;
  final double distanceKm;
  final String status; // 'pending', 'accepted', 'skipped', 'expired', 'lost'
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? driverName;
  final String? driverPhone;
  final String? truckReg;
  final String? truckType;
  final double driverRating;

  const DispatchOfferItem({
    required this.id,
    required this.cargoId,
    required this.driverId,
    required this.truckId,
    required this.distanceKm,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.driverName,
    this.driverPhone,
    this.truckReg,
    this.truckType,
    this.driverRating = 4.8,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get secondsRemaining {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  factory DispatchOfferItem.fromJson(Map<String, dynamic> json) {
    final truck = json['truck'] as Map<String, dynamic>?;
    final owner = truck?['owner'] as Map<String, dynamic>?;
    final expStr = json['expires_at'] as String?;
    final crStr = json['created_at'] as String?;

    return DispatchOfferItem(
      id: json['id']?.toString() ?? '',
      cargoId: json['cargo_id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      truckId: json['truck_id'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      expiresAt: expStr != null ? DateTime.parse(expStr) : DateTime.now().add(const Duration(seconds: 45)),
      createdAt: crStr != null ? DateTime.parse(crStr) : DateTime.now(),
      driverName: owner?['full_name'] as String? ?? json['driver_name'] as String?,
      driverPhone: owner?['phone'] as String? ?? json['driver_phone'] as String?,
      truckReg: truck?['registration_number'] as String? ?? json['truck_reg'] as String?,
      truckType: truck?['truck_type'] as String? ?? json['truck_type'] as String?,
      driverRating: (truck?['driver_rating'] as num?)?.toDouble() ?? 4.8,
    );
  }
}
