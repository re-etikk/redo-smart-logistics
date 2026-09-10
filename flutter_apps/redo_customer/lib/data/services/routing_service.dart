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

  PlaceSuggestion({
    required this.name,
    required this.description,
    required this.latLng,
  });
}

class RoutingService {
  static final _client = http.Client();

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
  /// Tries Google Directions API first; if billing is inactive, seamlessly
  /// uses OSRM (100% free, real Indian highway road network).
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

  /// Searches places across India by keyword (e.g. "Bhiwandi", "Okhla Phase 3", "Transport Nagar")
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];

    // 1. Google Places Autocomplete + Details — most reliable & best Indian
    // address/landmark coverage, uses the same key as the map/routing calls.
    try {
      final googleResults = await _searchGooglePlaces(query);
      if (googleResults.isNotEmpty) return googleResults;
    } catch (e) {
      debugPrint('Google Places search error: $e');
    }

    // 2. Photon / OpenStreetMap search (free fallback if Google Places
    // billing/quota isn't enabled on the key)
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}'
        '&limit=8&lat=22.9734&lon=78.6569&location_bias_scale=0.9', // bias toward India
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
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
          if (props['street'] != null) parts.add('${props['street']}');
          if (props['locality'] != null) parts.add('${props['locality']}');
          if (props['city'] != null) parts.add('${props['city']}');
          if (props['state'] != null) parts.add('${props['state']}');
          if (props['country'] != null) parts.add('${props['country']}');

          results.add(PlaceSuggestion(
            name: '$name',
            description: parts.isNotEmpty ? parts.join(', ') : '$name, India',
            latLng: LatLng(lat, lng),
          ));
        }

        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    // 3. Hardcoded fallback list matching common freight hubs
    final staticHubs = [
      PlaceSuggestion(name: 'Mumbai Hub', description: 'Bhiwandi / Kalamboli Freight Hub, MH', latLng: const LatLng(19.0760, 72.8777)),
      PlaceSuggestion(name: 'Delhi NCR Hub', description: 'Sanjay Gandhi Transport Nagar / Okhla, DL', latLng: const LatLng(28.6139, 77.2090)),
      PlaceSuggestion(name: 'Pune Hub', description: 'Chakan Industrial Logistics Corridor, MH', latLng: const LatLng(18.5204, 73.8567)),
      PlaceSuggestion(name: 'Jaipur Hub', description: 'VKI Area Transport Nagar, RJ', latLng: const LatLng(26.9124, 75.7873)),
      PlaceSuggestion(name: 'Surat Hub', description: 'Sachin GIDC Textile Hub, GJ', latLng: const LatLng(21.1702, 72.8311)),
      PlaceSuggestion(name: 'Ahmedabad Hub', description: 'Narol Aslali Transport Complex, GJ', latLng: const LatLng(23.0225, 72.5714)),
      PlaceSuggestion(name: 'Bengaluru Hub', description: 'Peenya Industrial Logistics Complex, KA', latLng: const LatLng(12.9716, 77.5946)),
      PlaceSuggestion(name: 'Hyderabad Hub', description: 'Autonagar Logistics Park, TS', latLng: const LatLng(17.3850, 78.4867)),
      PlaceSuggestion(name: 'Kolkata Hub', description: 'Dankuni Freight Terminal, WB', latLng: const LatLng(22.5726, 88.3639)),
      PlaceSuggestion(name: 'Chennai Hub', description: 'Madhavaram Truck Terminal, TN', latLng: const LatLng(13.0827, 80.2707)),
    ];

    final q = query.toLowerCase();
    return staticHubs.where((h) =>
      h.name.toLowerCase().contains(q) || h.description.toLowerCase().contains(q)
    ).toList();
  }

  /// Google Places Autocomplete + Details — resolves predictions to lat/lng.
  static Future<List<PlaceSuggestion>> _searchGooglePlaces(String query) async {
    final autoUri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&components=country:in'
      '&key=${AppConfig.googleMapsKey}',
    );
    final autoRes = await _client.get(autoUri).timeout(const Duration(seconds: 6));
    if (autoRes.statusCode != 200) return [];
    final autoData = jsonDecode(autoRes.body);
    if (autoData['status'] != 'OK') {
      debugPrint('Places Autocomplete status: ${autoData['status']} ${autoData['error_message'] ?? ''}');
      return [];
    }
    final predictions = (autoData['predictions'] as List?) ?? [];
    if (predictions.isEmpty) return [];

    final top = predictions.take(8).toList();
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
        final detailRes = await _client.get(detailUri).timeout(const Duration(seconds: 6));
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

  /// Auto-detects device GPS location and returns formatted address + LatLng
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

      // Reverse geocode via Nominatim
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}',
        );
        final res = await _client.get(uri, headers: {'User-Agent': 'REDO-Logistics-App'}).timeout(const Duration(seconds: 4));
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
