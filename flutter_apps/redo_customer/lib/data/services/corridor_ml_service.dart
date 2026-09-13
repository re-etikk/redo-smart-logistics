import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'routing_service.dart';

/// Classification of how a cargo load relates to the truck corridor.
enum EnRouteType {
  direct,          // Exactly matches origin and destination (e.g. Patna -> Delhi)
  enRouteDropoff,  // Same origin, drops off at intermediate hub (e.g. Patna -> Lucknow on Patna -> Delhi)
  enRoutePickup,   // Intermediate pickup, drops at truck's destination (e.g. Lucknow -> Delhi on Patna -> Delhi)
  enRouteSegment,  // Intermediate pickup and drop along corridor (e.g. Varanasi -> Kanpur on Patna -> Delhi)
  returnBackhaul,  // Return trip corridor in opposite direction (e.g. Delhi -> Patna)
  none,            // Out of corridor / unrelated route
}

/// Result of ML corridor evaluation for a cargo request against a route.
class CorridorMatchResult {
  final bool isMatch;
  final EnRouteType matchType;
  final int matchScore; // 0..100
  final double detourKm;
  final String badgeText;
  final String description;
  final String corridorKey;
  final List<String> reasons;
  final double estimatedExtraEarningInr;

  const CorridorMatchResult({
    required this.isMatch,
    required this.matchType,
    required this.matchScore,
    required this.detourKm,
    required this.badgeText,
    required this.description,
    required this.corridorKey,
    required this.reasons,
    this.estimatedExtraEarningInr = 0,
  });

  static const notMatched = CorridorMatchResult(
    isMatch: false,
    matchType: EnRouteType.none,
    matchScore: 0,
    detourKm: 9999,
    badgeText: '',
    description: '',
    corridorKey: '',
    reasons: [],
  );
}

/// Dynamic Machine Learning & Corridor Waypoint Interception Service
class CorridorMLService {
  static final CorridorMLService _instance = CorridorMLService._internal();
  factory CorridorMLService() => _instance;
  CorridorMLService._internal();

  final Map<String, double> _corridorAffinityWeights = {};
  double _learnedDetourToleranceKm = 35.0;
  bool _initialized = false;

  static const String _prefWeightsKey = 'redo_corridor_ml_weights_v1';
  static const String _prefToleranceKey = 'redo_corridor_detour_tolerance_v1';

  static final List<List<String>> _knownCorridors = [
    ['kolkata', 'durgapur', 'asansol', 'dhanbad', 'ranchi', 'patna', 'gaya', 'muzaffarpur', 'varanasi', 'prayagraj', 'lucknow', 'kanpur', 'agra', 'mathura', 'aligarh', 'delhi'],
    ['patna', 'buxar', 'varanasi', 'ayodhya', 'gorakhpur', 'lucknow', 'kanpur', 'etawah', 'agra', 'noida', 'delhi'],
    ['delhi', 'gurugram', 'neemrana', 'jaipur', 'ajmer', 'bhilwara', 'udaipur', 'ahmedabad', 'vadodara', 'bharuch', 'surat', 'vapi', 'bhiwandi', 'mumbai', 'pune', 'satara', 'kolhapur', 'belagavi', 'hubli', 'davangere', 'tumakuru', 'bengaluru'],
    ['srinagar', 'jammu', 'amritsar', 'jalandhar', 'ludhiana', 'ambala', 'panipat', 'delhi', 'faridabad', 'agra', 'gwalior', 'jhansi', 'sagar', 'nagpur', 'hyderabad', 'kurnool', 'anantapur', 'bengaluru', 'salem', 'madurai', 'kanyakumari'],
    ['kolkata', 'kharagpur', 'balasore', 'cuttack', 'bhubaneswar', 'berhampur', 'visakhapatnam', 'rajahmundry', 'vijayawada', 'guntur', 'ongole', 'nellore', 'chennai'],
    ['indore', 'dewas', 'ujjain', 'bhopal', 'hoshangabad', 'nagpur'],
    ['mumbai', 'nashik', 'dhule', 'indore', 'gwalior', 'agra', 'delhi'],
    ['chennai', 'vellore', 'krishnagiri', 'bengaluru', 'mysuru', 'coimbatore', 'kochi'],
    ['hyderabad', 'solapur', 'pune', 'mumbai'],
    ['ahmedabad', 'rajkot', 'jamnagar', 'porbandar'],
  ];

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefWeightsKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((k, v) {
          if (v is num) _corridorAffinityWeights[k] = v.toDouble();
        });
      }
      _learnedDetourToleranceKm = prefs.getDouble(_prefToleranceKey) ?? 35.0;
    } catch (e) {
      debugPrint('CorridorMLService init error: $e');
    }
    _initialized = true;
  }

  static String normCity(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\b(hub|junction|station|terminal|city|ncr|depot|wharf|port|area|district|nagar)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.contains('delhi') || s.contains('new delhi') || s.contains('gurugram') || s.contains('noida')) return 'delhi';
    if (s.contains('mumbai') || s.contains('bombay') || s.contains('navi mumbai') || s.contains('thane')) return 'mumbai';
    if (s.contains('bengaluru') || s.contains('bangalore')) return 'bengaluru';
    if (s.contains('hyderabad') || s.contains('secunderabad')) return 'hyderabad';
    if (s.contains('kolkata') || s.contains('calcutta')) return 'kolkata';
    if (s.contains('chennai') || s.contains('madras')) return 'chennai';
    if (s.contains('patna')) return 'patna';
    if (s.contains('lucknow')) return 'lucknow';
    if (s.contains('kanpur')) return 'kanpur';
    if (s.contains('varanasi') || s.contains('banaras') || s.contains('kashi')) return 'varanasi';
    if (s.contains('pune')) return 'pune';
    if (s.contains('jaipur')) return 'jaipur';
    if (s.contains('ahmedabad')) return 'ahmedabad';
    if (s.contains('surat')) return 'surat';
    if (s.contains('nagpur')) return 'nagpur';
    if (s.contains('indore')) return 'indore';
    if (s.contains('bhopal')) return 'bhopal';
    if (s.contains('agra')) return 'agra';
    return s;
  }

  CorridorMatchResult evaluateCargoMatch({
    required String driverFrom,
    required String driverTo,
    required CargoRequest cargo,
    double truckCapacityTons = 16.0,
  }) {
    final dFrom = normCity(driverFrom);
    final dTo = normCity(driverTo);
    final lFrom = normCity(cargo.origin);
    final lTo = normCity(cargo.destination);

    if (dFrom.isEmpty || dTo.isEmpty || lFrom.isEmpty || lTo.isEmpty) {
      return CorridorMatchResult.notMatched;
    }

    final corridorKey = '$dFrom\_$dTo';
    final loadCorridorKey = '$lFrom\_$lTo';
    final priceEst = (cargo.distanceKm * cargo.cargoWeightTons * 1.05).roundToDouble();

    if (_isCityMatch(dFrom, lFrom) && _isCityMatch(dTo, lTo)) {
      final affinity = _getCorridorAffinity(corridorKey);
      final score = _calculateScore(
        baseScore: 98,
        detourKm: 0,
        loadWeight: cargo.cargoWeightTons,
        truckCapacity: truckCapacityTons,
        affinityBonus: affinity,
      );
      return CorridorMatchResult(
        isMatch: true,
        matchType: EnRouteType.direct,
        matchScore: score,
        detourKm: 0,
        badgeText: '★ $score% Direct Route Match',
        description: 'Direct match for your corridor (${cargo.origin} → ${cargo.destination})',
        corridorKey: corridorKey,
        reasons: ['Direct corridor alignment', 'Zero detour (+0 km)', 'Immediate pickup match'],
        estimatedExtraEarningInr: priceEst,
      );
    }

    if (_isCityMatch(dFrom, lTo) && _isCityMatch(dTo, lFrom)) {
      final affinity = _getCorridorAffinity('$dTo\_$dFrom');
      final score = _calculateScore(
        baseScore: 94,
        detourKm: 0,
        loadWeight: cargo.cargoWeightTons,
        truckCapacity: truckCapacityTons,
        affinityBonus: affinity,
      );
      return CorridorMatchResult(
        isMatch: true,
        matchType: EnRouteType.returnBackhaul,
        matchScore: score,
        detourKm: 0,
        badgeText: '🔄 $score% Return Backhaul Match',
        description: 'Eliminate empty return trip with this backhaul load',
        corridorKey: '$dTo\_$dFrom',
        reasons: ['Zero deadhead miles', 'Guaranteed return freight', '+0 km detour'],
        estimatedExtraEarningInr: priceEst,
      );
    }

    final topoMatch = _checkTopologySequence(
      driverOrigin: dFrom,
      driverDest: dTo,
      loadOrigin: lFrom,
      loadDest: lTo,
    );

    if (topoMatch != null) {
      final detour = topoMatch.detourKm;
      final affinity = _getCorridorAffinity(loadCorridorKey);

      int baseScore = 90;
      String badge = '';
      String desc = '';
      List<String> reasons = [];

      switch (topoMatch.type) {
        case EnRouteType.enRouteDropoff:
          baseScore = 96;
          badge = 'En-Route Dropoff (${cargo.destination})';
          desc = 'Pickup at origin (${cargo.origin}) and drop off en-route to $driverTo';
          reasons = [
            'Pick up at start point',
            'Deliver en-route without leaving highway (+${detour.round()} km detour)',
            'Free capacity for remaining corridor to $driverTo',
          ];
          break;
        case EnRouteType.enRoutePickup:
          baseScore = 93;
          badge = 'En-Route Pickup (${cargo.origin})';
          desc = 'Pickup at intermediate hub (${cargo.origin}) and deliver to $driverTo';
          reasons = [
            'Pickup on highway route',
            'Full direct delivery at destination ($driverTo)',
            '+${detour.round()} km detour',
          ];
          break;
        case EnRouteType.enRouteSegment:
          baseScore = 89;
          badge = 'En-Route Highway Segment';
          desc = 'Carry cargo between ${cargo.origin} and ${cargo.destination} along your route';
          reasons = [
            'Intermediate highway segment',
            'In-transit freight revenue',
            '+${detour.round()} km detour',
          ];
          break;
        default:
          break;
      }

      final score = _calculateScore(
        baseScore: baseScore,
        detourKm: detour,
        loadWeight: cargo.cargoWeightTons,
        truckCapacity: truckCapacityTons,
        affinityBonus: affinity,
      );

      return CorridorMatchResult(
        isMatch: true,
        matchType: topoMatch.type,
        matchScore: score,
        detourKm: detour,
        badgeText: '★ $score% $badge',
        description: desc,
        corridorKey: '$dFrom\_$lFrom\_$lTo\_$dTo',
        reasons: reasons,
        estimatedExtraEarningInr: priceEst,
      );
    }

    final pDriverOrigin = RoutingService.getCoordinatesForCity(driverFrom);
    final pDriverDest = RoutingService.getCoordinatesForCity(driverTo);
    final pLoadOrigin = RoutingService.getCoordinatesForCity(cargo.origin);
    final pLoadDest = RoutingService.getCoordinatesForCity(cargo.destination);

    if (pDriverOrigin != null && pDriverDest != null && pLoadOrigin != null && pLoadDest != null) {
      final geoResult = _evaluateGeometricDetour(
        driverOrigin: pDriverOrigin,
        driverDest: pDriverDest,
        loadOrigin: pLoadOrigin,
        loadDest: pLoadDest,
        driverFromName: driverFrom,
        driverToName: driverTo,
        cargo: cargo,
        truckCapacityTons: truckCapacityTons,
      );
      if (geoResult.isMatch) return geoResult;
    }

    return CorridorMatchResult.notMatched;
  }

  static bool _isCityMatch(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    return false;
  }

  _TopologyMatch? _checkTopologySequence({
    required String driverOrigin,
    required String driverDest,
    required String loadOrigin,
    required String loadDest,
  }) {
    for (final corridor in _knownCorridors) {
      final idxDOrig = _findCityIndex(corridor, driverOrigin);
      final idxDDest = _findCityIndex(corridor, driverDest);

      if (idxDOrig != -1 && idxDDest != -1 && idxDOrig < idxDDest) {
        final idxLOrig = _findCityIndex(corridor, loadOrigin);
        final idxLDest = _findCityIndex(corridor, loadDest);

        if (idxLOrig != -1 && idxLDest != -1 && idxLOrig < idxLDest) {
          final isSameOrig = (idxLOrig == idxDOrig);
          final isSameDest = (idxLDest == idxDDest);
          final isEnRoute = (idxLOrig >= idxDOrig && idxLDest <= idxDDest);

          if (isSameOrig && idxLDest < idxDDest) {
            return const _TopologyMatch(type: EnRouteType.enRouteDropoff, detourKm: 0.0);
          } else if (idxLOrig > idxDOrig && isSameDest) {
            return const _TopologyMatch(type: EnRouteType.enRoutePickup, detourKm: 0.0);
          } else if (isEnRoute) {
            return const _TopologyMatch(type: EnRouteType.enRouteSegment, detourKm: 0.0);
          }
        }
      }
    }
    return null;
  }

  static int _findCityIndex(List<String> corridor, String city) {
    final n = normCity(city);
    for (int i = 0; i < corridor.length; i++) {
      final c = corridor[i];
      if (c == n || c.contains(n) || n.contains(c)) return i;
    }
    return -1;
  }

  CorridorMatchResult _evaluateGeometricDetour({
    required LatLng driverOrigin,
    required LatLng driverDest,
    required LatLng loadOrigin,
    required LatLng loadDest,
    required String driverFromName,
    required String driverToName,
    required CargoRequest cargo,
    required double truckCapacityTons,
  }) {
    final directDistanceKm = _haversineKm(driverOrigin, driverDest);
    if (directDistanceKm < 20) return CorridorMatchResult.notMatched;

    final dOrigToLoadOrig = _haversineKm(driverOrigin, loadOrigin);
    final dLoadOrigToLoadDest = _haversineKm(loadOrigin, loadDest);
    final dLoadDestToDriverDest = _haversineKm(loadDest, driverDest);

    final detourDistanceKm = (dOrigToLoadOrig + dLoadOrigToLoadDest + dLoadDestToDriverDest) - directDistanceKm;

    final dotOrigin = _dotProduct(driverOrigin, driverDest, loadOrigin);
    final dotDest = _dotProduct(driverOrigin, driverDest, loadDest);
    final forwardDirection = (dotOrigin <= dotDest + 0.05);
    final maxAllowedDetour = math.max(_learnedDetourToleranceKm, directDistanceKm * 0.15);

    if (forwardDirection && detourDistanceKm <= maxAllowedDetour) {
      EnRouteType mType = EnRouteType.enRouteSegment;
      String badge = 'En-Route Match';
      String desc = 'Carries along your corridor with +${detourDistanceKm.round()} km detour';

      if (dOrigToLoadOrig <= 25) {
        mType = EnRouteType.enRouteDropoff;
        badge = 'En-Route Dropoff (${cargo.destination})';
        desc = 'Pickup at your origin and drop en-route (+${detourDistanceKm.round()} km detour)';
      } else if (dLoadDestToDriverDest <= 25) {
        mType = EnRouteType.enRoutePickup;
        badge = 'En-Route Pickup (${cargo.origin})';
        desc = 'Pickup along route and drop at your final destination';
      }

      final score = _calculateScore(
        baseScore: 90,
        detourKm: detourDistanceKm,
        loadWeight: cargo.cargoWeightTons,
        truckCapacity: truckCapacityTons,
        affinityBonus: 0,
      );

      final priceEst = (cargo.distanceKm * cargo.cargoWeightTons * 1.05).roundToDouble();

      return CorridorMatchResult(
        isMatch: true,
        matchType: mType,
        matchScore: score,
        detourKm: detourDistanceKm,
        badgeText: '★ $score% $badge',
        description: desc,
        corridorKey: '${normCity(driverFromName)}_${normCity(cargo.origin)}_${normCity(cargo.destination)}',
        reasons: [
          'Direct road path alignment',
          '+${detourDistanceKm.round()} km extra detour',
          'Compatible truck payload',
        ],
        estimatedExtraEarningInr: priceEst,
      );
    }

    return CorridorMatchResult.notMatched;
  }

  int _calculateScore({
    required int baseScore,
    required double detourKm,
    required double loadWeight,
    required double truckCapacity,
    required double affinityBonus,
  }) {
    final detourPenalty = (detourKm / 5.0).clamp(0.0, 20.0);
    double capBonus = 0;
    if (truckCapacity > 0) {
      final ratio = loadWeight / truckCapacity;
      if (ratio >= 0.4 && ratio <= 0.95) {
        capBonus = 4.0;
      } else if (ratio > 1.0) {
        capBonus = -10.0;
      }
    }

    final raw = baseScore - detourPenalty + capBonus + (affinityBonus * 5.0);
    return raw.round().clamp(40, 99);
  }

  Future<void> recordInteraction(String corridorKey, String action, {double? detourKm}) async {
    if (corridorKey.isEmpty) return;
    await init();

    double delta = 0;
    if (action == 'accept_load') {
      delta = 1.0;
      if (detourKm != null && detourKm > _learnedDetourToleranceKm) {
        _learnedDetourToleranceKm = math.min(100.0, _learnedDetourToleranceKm + (detourKm - _learnedDetourToleranceKm) * 0.2);
      }
    } else if (action == 'view_route') {
      delta = 0.2;
    } else if (action == 'decline_load') {
      delta = -0.5;
    }

    final current = _corridorAffinityWeights[corridorKey] ?? 0.0;
    _corridorAffinityWeights[corridorKey] = (current + delta).clamp(-5.0, 10.0);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefWeightsKey, jsonEncode(_corridorAffinityWeights));
      await prefs.setDouble(_prefToleranceKey, _learnedDetourToleranceKm);
    } catch (e) {
      debugPrint('Error saving ML weights: $e');
    }
  }

  double _getCorridorAffinity(String corridorKey) {
    return _corridorAffinityWeights[corridorKey] ?? 0.0;
  }

  static double _haversineKm(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = _rad(p2.latitude - p1.latitude);
    final dLng = _rad(p2.longitude - p1.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(p1.latitude)) * math.cos(_rad(p2.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * (math.pi / 180.0);

  static double _dotProduct(LatLng a, LatLng b, LatLng c) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final magSq = dx * dx + dy * dy;
    if (magSq == 0) return 0.0;
    return ((c.longitude - a.longitude) * dx + (c.latitude - a.latitude) * dy) / magSq;
  }
}

class _TopologyMatch {
  final EnRouteType type;
  final double detourKm;
  const _TopologyMatch({required this.type, required this.detourKm});
}
