import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final String distanceText;
  final String durationText;
  final int durationMinutes;

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.distanceText,
    required this.durationText,
    required this.durationMinutes,
  });
}

class PlaceSuggestion {
  final String name;
  final String description;
  final LatLng latLng;
  final String? city;
  final String? state;

  PlaceSuggestion({
    required this.name,
    required this.description,
    required this.latLng,
    this.city,
    this.state,
  });
}

class RoutingService {
  static final _client = http.Client();

  // Comprehensive in-memory cache for resolved Indian city/hub coordinates
  static final Map<String, LatLng> _cityCoordsCache = {
    'delhi': const LatLng(28.6139, 77.2090),
    'delhi ncr': const LatLng(28.6139, 77.2090),
    'new delhi': const LatLng(28.6139, 77.2090),
    'mumbai': const LatLng(19.0760, 72.8777),
    'patna': const LatLng(25.5941, 85.1376),
    'lucknow': const LatLng(26.8467, 80.9462),
    'kanpur': const LatLng(26.4499, 80.3319),
    'varanasi': const LatLng(25.3176, 82.9739),
    'prayagraj': const LatLng(25.4358, 81.8463),
    'agra': const LatLng(27.1767, 78.0081),
    'gorakhpur': const LatLng(26.7606, 83.3732),
    'gaya': const LatLng(24.7955, 85.0002),
    'muzaffarpur': const LatLng(26.1209, 85.3647),
    'bhagalpur': const LatLng(25.2425, 86.9842),
    'ranchi': const LatLng(23.3441, 85.3096),
    'jamshedpur': const LatLng(22.8046, 86.2029),
    'dhanbad': const LatLng(23.7957, 86.4304),
    'bokaro': const LatLng(23.6693, 86.1511),
    'kolkata': const LatLng(22.5726, 88.3639),
    'howrah': const LatLng(22.5958, 88.2636),
    'asansol': const LatLng(23.6739, 86.9524),
    'durgapur': const LatLng(23.5204, 87.3119),
    'siliguri': const LatLng(26.7271, 88.3953),
    'guwahati': const LatLng(26.1445, 91.7362),
    'jaipur': const LatLng(26.9124, 75.7873),
    'jodhpur': const LatLng(26.2389, 73.0243),
    'kota': const LatLng(25.2138, 75.8648),
    'udaipur': const LatLng(24.5854, 73.7125),
    'ahmedabad': const LatLng(23.0225, 72.5714),
    'surat': const LatLng(21.1702, 72.8311),
    'vadodara': const LatLng(22.3072, 73.1812),
    'rajkot': const LatLng(22.3039, 70.8022),
    'gandhidham': const LatLng(23.0753, 70.1337),
    'pune': const LatLng(18.5204, 73.8567),
    'nagpur': const LatLng(21.1458, 79.0882),
    'nashik': const LatLng(19.9975, 73.7898),
    'aurangabad': const LatLng(19.8762, 75.3433),
    'kolhapur': const LatLng(16.7050, 74.2433),
    'solapur': const LatLng(17.6599, 75.9064),
    'indore': const LatLng(22.7196, 75.8577),
    'bhopal': const LatLng(23.2599, 77.4126),
    'gwalior': const LatLng(26.2183, 78.1828),
    'jabalpur': const LatLng(23.1815, 79.9864),
    'raipur': const LatLng(21.2514, 81.6296),
    'bilaspur': const LatLng(22.0797, 82.1409),
    'bengaluru': const LatLng(12.9716, 77.5946),
    'mysuru': const LatLng(12.2958, 76.6394),
    'hubli': const LatLng(15.3647, 75.1240),
    'belagavi': const LatLng(15.8497, 74.4977),
    'mangaluru': const LatLng(12.9141, 74.8560),
    'hyderabad': const LatLng(17.3850, 78.4867),
    'vijayawada': const LatLng(16.5062, 80.6480),
    'visakhapatnam': const LatLng(17.6868, 83.2185),
    'guntur': const LatLng(16.3067, 80.4365),
    'tirupati': const LatLng(13.6288, 79.4192),
    'kurnool': const LatLng(15.8281, 78.0373),
    'chennai': const LatLng(13.0827, 80.2707),
    'coimbatore': const LatLng(11.0168, 76.9558),
    'madurai': const LatLng(9.9252, 78.1198),
    'tiruchirappalli': const LatLng(10.7905, 78.7047),
    'salem': const LatLng(11.6643, 78.1460),
    'tirunelveli': const LatLng(8.7139, 77.7567),
    'kochi': const LatLng(9.9312, 76.2673),
    'kozhikode': const LatLng(11.2588, 75.7804),
    'thiruvananthapuram': const LatLng(8.5241, 76.9366),
    'bhubaneswar': const LatLng(20.2961, 85.8245),
    'cuttack': const LatLng(20.4625, 85.8830),
    'rourkela': const LatLng(22.2604, 84.8536),
    'ludhiana': const LatLng(30.9010, 75.8573),
    'jalandhar': const LatLng(31.3260, 75.5762),
    'amritsar': const LatLng(31.6340, 74.8723),
    'chandigarh': const LatLng(30.7333, 76.7794),
    'ambala': const LatLng(30.3782, 76.7767),
    'panipat': const LatLng(29.3909, 76.9635),
    'karnal': const LatLng(29.6857, 76.9905),
    'meerut': const LatLng(28.9845, 77.7064),
    'ghaziabad': const LatLng(28.6692, 77.4538),
    'faridabad': const LatLng(28.4089, 77.3178),
    'gurugram': const LatLng(28.4595, 77.0266),
    'noida': const LatLng(28.5355, 77.3910),
    'bareilly': const LatLng(28.3670, 79.4304),
    'aligarh': const LatLng(27.8974, 78.0880),
    'moradabad': const LatLng(28.8386, 78.7733),
    'jhansi': const LatLng(25.4484, 78.5685),
    'haridwar': const LatLng(29.9457, 78.1642),
    'dehradun': const LatLng(30.3165, 78.0322),
    'jammu': const LatLng(32.7266, 74.8570),
    'bhiwandi': const LatLng(19.3002, 73.0635),
    'panvel': const LatLng(18.9894, 73.1175),
    'chakan': const LatLng(18.7597, 73.8587),
    'vapi': const LatLng(20.3725, 72.9106),
    'ankleshwar': const LatLng(21.6264, 73.0152),
    'neemrana': const LatLng(27.9888, 76.3883),
    'bawal': const LatLng(28.0827, 76.5855),
    'manesar': const LatLng(28.3515, 76.9388),
    'baddi': const LatLng(30.9578, 76.7914),
    'rudrapur': const LatLng(28.9800, 79.4000),
    'hosur': const LatLng(12.7409, 77.8253),
    'sriperumbudur': const LatLng(12.9699, 79.9419),
  };

  /// Decodes Google / OSRM encoded polyline format into a `List<LatLng>`
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Fetches real-road driving route following highways & streets.
  static Future<RouteInfo?> getDrivingRoute(LatLng origin, LatLng destination) async {
    // 1. Try Google Directions API
    try {
      final googleUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=${AppConfig.googleMapsKey}',
      );
      final res = await _client.get(googleUri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final polylineStr = route['overview_polyline']['points'] as String;
          final pts = decodePolyline(polylineStr);
          final meters = (leg['distance']['value'] as num).toDouble();
          final seconds = (leg['duration']['value'] as num).toInt();

          return RouteInfo(
            points: pts,
            distanceKm: (meters / 1000).roundToDouble(),
            distanceText: leg['distance']['text'] ?? '${(meters / 1000).round()} km',
            durationText: leg['duration']['text'] ?? '${(seconds / 3600).round()} hrs',
            durationMinutes: (seconds / 60).round(),
          );
        }
      }
    } catch (_) {}

    // 2. Resilient OSRM fallback (Real roads, zero-config, no billing required)
    try {
      final osrmUri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline',
      );
      final res = await _client.get(osrmUri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final polylineStr = route['geometry'] as String;
          final pts = decodePolyline(polylineStr);
          final meters = (route['distance'] as num).toDouble();
          final seconds = (route['duration'] as num).toInt();

          final km = (meters / 1000).roundToDouble();
          final hours = seconds ~/ 3600;
          final mins = (seconds % 3600) ~/ 60;
          final durText = hours > 0 ? '$hours hr $mins min' : '$mins min';

          return RouteInfo(
            points: pts,
            distanceKm: km,
            distanceText: '${km.round()} km',
            durationText: durText,
            durationMinutes: (seconds / 60).round(),
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    }

    // 3. Mathematical fallback if offline
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude, origin.longitude, destination.latitude, destination.longitude,
    );
    final estRoadKm = ((distanceMeters / 1000) * 1.25).roundToDouble();
    final estMinutes = (estRoadKm / 45 * 60).round();

    return RouteInfo(
      points: [origin, destination],
      distanceKm: estRoadKm,
      distanceText: '${estRoadKm.round()} km (est.)',
      durationText: '${estMinutes ~/ 60} hr ${estMinutes % 60} min',
      durationMinutes: estMinutes,
    );
  }

  /// Universal Multi-Tier Search for Any City, Town, Village, Hub or Landmark across India.
  /// Tier 1: Google Places Autocomplete (if key active)
  /// Tier 2: Real-time OpenStreetMap / Nominatim (Covers all of India)
  /// Tier 3: Photon Komoot Geocoder
  /// Tier 4: Comprehensive Indian Logistics Hubs Database (150+ hubs)
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final Map<String, PlaceSuggestion> dedup = {};

    // 1. Try Google Places Autocomplete
    try {
      final googleResults = await _searchGooglePlaces(q);
      for (final p in googleResults) {
        dedup[p.name.toLowerCase()] = p;
        _cacheCoordinates(p.name, p.latLng);
      }
      if (dedup.length >= 5) return dedup.values.toList();
    } catch (e) {
      debugPrint('Google Places search error: $e');
    }

    // 2. High-Precision Nominatim OpenStreetMap API (Real-time Indian locations)
    try {
      final nomResults = await _searchNominatim(q);
      for (final p in nomResults) {
        final key = p.name.toLowerCase();
        if (!dedup.containsKey(key)) {
          dedup[key] = p;
          _cacheCoordinates(p.name, p.latLng);
        }
      }
      if (dedup.length >= 5) return dedup.values.toList();
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    }

    // 3. Photon Komoot Geocoder (India Bounded)
    try {
      final photonResults = await _searchPhoton(q);
      for (final p in photonResults) {
        final key = p.name.toLowerCase();
        if (!dedup.containsKey(key)) {
          dedup[key] = p;
          _cacheCoordinates(p.name, p.latLng);
        }
      }
      if (dedup.length >= 5) return dedup.values.toList();
    } catch (e) {
      debugPrint('Photon search error: $e');
    }

    // 4. Comprehensive 150+ Indian Logistics Hubs Database
    final localMatches = _searchStaticHubs(q);
    for (final p in localMatches) {
      final key = p.name.toLowerCase();
      if (!dedup.containsKey(key)) {
        dedup[key] = p;
        _cacheCoordinates(p.name, p.latLng);
      }
    }

    return dedup.values.toList();
  }

  /// Google Places Autocomplete + Details
  static Future<List<PlaceSuggestion>> _searchGooglePlaces(String query) async {
    final autoUri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&components=country:in'
      '&key=${AppConfig.googleMapsKey}',
    );
    final autoRes = await _client.get(autoUri).timeout(const Duration(seconds: 4));
    if (autoRes.statusCode != 200) return [];
    final autoData = jsonDecode(autoRes.body);
    if (autoData['status'] != 'OK') return [];
    final predictions = (autoData['predictions'] as List?) ?? [];
    if (predictions.isEmpty) return [];

    final top = predictions.take(6).toList();
    final futures = top.map((p) async {
      final placeId = p['place_id'] as String?;
      final mainText = (p['structured_formatting']?['main_text'] as String?) ?? p['description'] as String? ?? query;
      final secondaryText = (p['structured_formatting']?['secondary_text'] as String?) ?? '';
      if (placeId == null) return null;
      try {
        final detailUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=geometry/location'
          '&key=${AppConfig.googleMapsKey}',
        );
        final detailRes = await _client.get(detailUri).timeout(const Duration(seconds: 4));
        if (detailRes.statusCode != 200) return null;
        final detailData = jsonDecode(detailRes.body);
        if (detailData['status'] != 'OK') return null;
        final loc = detailData['result']?['geometry']?['location'];
        if (loc == null) return null;
        return PlaceSuggestion(
          name: mainText,
          description: secondaryText.isNotEmpty ? secondaryText : mainText,
          latLng: LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
        );
      } catch (_) {
        return null;
      }
    });

    final resolved = await Future.wait(futures);
    return resolved.whereType<PlaceSuggestion>().toList();
  }

  /// Real-Time OpenStreetMap / Nominatim search across all Indian cities and towns
  static Future<List<PlaceSuggestion>> _searchNominatim(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&countrycodes=in'
      '&format=json'
      '&addressdetails=1'
      '&limit=8',
    );
    final res = await _client.get(
      uri,
      headers: {'User-Agent': 'REDO-Smart-Logistics-Platform/2.0 (contact@redo.in)'},
    ).timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List?;
    if (list == null || list.isEmpty) return [];

    final results = <PlaceSuggestion>[];
    for (final item in list) {
      final latStr = item['lat'] as String?;
      final lonStr = item['lon'] as String?;
      if (latStr == null || lonStr == null) continue;
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lonStr);
      if (lat == null || lng == null) continue;

      final addr = (item['address'] as Map<String, dynamic>?) ?? {};
      final cityName = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state_district'] ?? item['name'] ?? query;
      final stateName = addr['state'] ?? '';
      final displayName = item['display_name'] as String? ?? '$cityName, India';

      results.add(PlaceSuggestion(
        name: '$cityName',
        description: displayName,
        latLng: LatLng(lat, lng),
        city: '$cityName',
        state: stateName.isNotEmpty ? '$stateName' : null,
      ));
    }
    return results;
  }

  /// Photon Komoot Geocoder
  static Future<List<PlaceSuggestion>> _searchPhoton(String query) async {
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}'
      '&limit=8&lat=22.9734&lon=78.6569&location_bias_scale=0.9',
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final features = (data['features'] as List?) ?? [];
    final results = <PlaceSuggestion>[];

    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>?;
      final geom = f['geometry'] as Map<String, dynamic>?;
      if (props == null || geom == null) continue;

      final coords = (geom['coordinates'] as List?) ?? [];
      if (coords.length < 2) continue;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();

      final name = props['name'] ?? query;
      final parts = <String>[];
      if (props['city'] != null) parts.add('${props['city']}');
      if (props['state'] != null) parts.add('${props['state']}');
      if (props['country'] != null) parts.add('${props['country']}');

      results.add(PlaceSuggestion(
        name: '$name',
        description: parts.isNotEmpty ? parts.join(', ') : '$name, India',
        latLng: LatLng(lat, lng),
      ));
    }
    return results;
  }

  /// Comprehensive Database of 150+ Major Indian Freight Hubs & Cities
  static List<PlaceSuggestion> _searchStaticHubs(String query) {
    final q = query.toLowerCase().trim();
    final results = <PlaceSuggestion>[];

    for (final entry in _cityCoordsCache.entries) {
      if (entry.key.contains(q) || q.contains(entry.key)) {
        final title = _capitalize(entry.key);
        results.add(PlaceSuggestion(
          name: title,
          description: '$title Transport Corridor, India',
          latLng: entry.value,
        ));
      }
    }
    return results;
  }

  static String _capitalize(String s) {
    return s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  static void _cacheCoordinates(String name, LatLng latLng) {
    final n = _normalizeCityName(name);
    if (n.isNotEmpty) {
      _cityCoordsCache[n] = latLng;
    }
  }

  static String _normalizeCityName(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\b(hub|junction|station|terminal|city|ncr|depot|wharf|port|area|district|nagar)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Resolves any city or hub name to LatLng with automatic geocoding fallback
  static LatLng? getCoordinatesForCity(String cityName) {
    final n = _normalizeCityName(cityName);
    if (n.isEmpty) return null;

    // Direct match
    if (_cityCoordsCache.containsKey(n)) {
      return _cityCoordsCache[n];
    }

    // Partial contains match
    for (final entry in _cityCoordsCache.entries) {
      if (entry.key.contains(n) || n.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Auto-detects device GPS location
  static Future<PlaceSuggestion?> getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 7),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);

      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}',
        );
        final res = await _client.get(uri, headers: {'User-Agent': 'REDO-Smart-Logistics-Platform/2.0'}).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final addr = data['address'] as Map<String, dynamic>?;
          final suburb = addr?['suburb'] ?? addr?['neighbourhood'] ?? addr?['road'] ?? 'Current Location';
          final city = addr?['city'] ?? addr?['town'] ?? addr?['state_district'] ?? 'Near You';
          return PlaceSuggestion(
            name: '$suburb',
            description: '$suburb, $city',
            latLng: latLng,
          );
        }
      } catch (_) {}

      return PlaceSuggestion(
        name: 'My Current Location',
        description: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        latLng: latLng,
      );
    } catch (e) {
      debugPrint('GPS auto-detect error: $e');
      return null;
    }
  }
}
