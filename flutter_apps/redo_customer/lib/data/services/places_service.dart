import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class GooglePlaceSuggestion {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  GooglePlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  String get displayName => mainText ?? description.split(',').first.trim();
}

class IndianHubLocation {
  final String name;
  final String state;
  final double lat;
  final double lng;

  const IndianHubLocation({
    required this.name,
    required this.state,
    required this.lat,
    required this.lng,
  });

  String get fullName => '$name, $state';
}

class PlacesService {
  static const List<IndianHubLocation> indianHubs = [
    IndianHubLocation(name: 'Delhi NCR', state: 'DL', lat: 28.6139, lng: 77.2090),
    IndianHubLocation(name: 'Mumbai', state: 'MH', lat: 19.0760, lng: 72.8777),
    IndianHubLocation(name: 'Bengaluru', state: 'KA', lat: 12.9716, lng: 77.5946),
    IndianHubLocation(name: 'Hyderabad', state: 'TG', lat: 17.3850, lng: 78.4867),
    IndianHubLocation(name: 'Ahmedabad', state: 'GJ', lat: 23.0225, lng: 72.5714),
    IndianHubLocation(name: 'Chennai', state: 'TN', lat: 13.0827, lng: 80.2707),
    IndianHubLocation(name: 'Kolkata', state: 'WB', lat: 22.5726, lng: 88.3639),
    IndianHubLocation(name: 'Pune', state: 'MH', lat: 18.5204, lng: 73.8567),
    IndianHubLocation(name: 'Jaipur', state: 'RJ', lat: 26.9124, lng: 75.7873),
    IndianHubLocation(name: 'Lucknow', state: 'UP', lat: 26.8467, lng: 80.9462),
    IndianHubLocation(name: 'Kanpur', state: 'UP', lat: 26.4499, lng: 80.3319),
    IndianHubLocation(name: 'Patna', state: 'BR', lat: 25.5941, lng: 85.1376),
    IndianHubLocation(name: 'Indore', state: 'MP', lat: 22.7196, lng: 75.8577),
    IndianHubLocation(name: 'Surat', state: 'GJ', lat: 21.1702, lng: 72.8311),
    IndianHubLocation(name: 'Nagpur', state: 'MH', lat: 21.1458, lng: 79.0882),
    IndianHubLocation(name: 'Vadodara', state: 'GJ', lat: 22.3072, lng: 73.1812),
    IndianHubLocation(name: 'Bhopal', state: 'MP', lat: 23.2599, lng: 77.4126),
    IndianHubLocation(name: 'Ludhiana', state: 'PB', lat: 30.9010, lng: 75.8573),
    IndianHubLocation(name: 'Agra', state: 'UP', lat: 27.1767, lng: 78.0081),
    IndianHubLocation(name: 'Nashik', state: 'MH', lat: 19.9975, lng: 73.7898),
    IndianHubLocation(name: 'Varanasi', state: 'UP', lat: 25.3176, lng: 82.9739),
    IndianHubLocation(name: 'Meerut', state: 'UP', lat: 28.9845, lng: 77.7064),
    IndianHubLocation(name: 'Rajkot', state: 'GJ', lat: 22.3039, lng: 70.8022),
    IndianHubLocation(name: 'Amritsar', state: 'PB', lat: 31.6340, lng: 74.8723),
    IndianHubLocation(name: 'Allahabad (Prayagraj)', state: 'UP', lat: 25.4358, lng: 81.8463),
    IndianHubLocation(name: 'Ranchi', state: 'JH', lat: 23.3441, lng: 85.3096),
    IndianHubLocation(name: 'Jamshedpur', state: 'JH', lat: 22.8046, lng: 86.2029),
    IndianHubLocation(name: 'Coimbatore', state: 'TN', lat: 11.0168, lng: 76.9558),
    IndianHubLocation(name: 'Visakhapatnam', state: 'AP', lat: 17.6868, lng: 83.2185),
    IndianHubLocation(name: 'Vijayawada', state: 'AP', lat: 16.5062, lng: 80.6480),
    IndianHubLocation(name: 'Chandigarh', state: 'CH', lat: 30.7333, lng: 76.7794),
    IndianHubLocation(name: 'Guwahati', state: 'AS', lat: 26.1445, lng: 91.7362),
    IndianHubLocation(name: 'Bhubaneswar', state: 'OD', lat: 20.2961, lng: 85.8245),
    IndianHubLocation(name: 'Raipur', state: 'CG', lat: 21.2514, lng: 81.6296),
    IndianHubLocation(name: 'Kochi', state: 'KL', lat: 9.9312, lng: 76.2673),
    IndianHubLocation(name: 'Kozhikode', state: 'KL', lat: 11.2588, lng: 75.7804),
    IndianHubLocation(name: 'Madurai', state: 'TN', lat: 9.9252, lng: 78.1198),
    IndianHubLocation(name: 'Jabalpur', state: 'MP', lat: 23.1815, lng: 79.9864),
    IndianHubLocation(name: 'Gwalior', state: 'MP', lat: 26.2183, lng: 78.1828),
    IndianHubLocation(name: 'Kota', state: 'RJ', lat: 25.2138, lng: 75.8648),
    IndianHubLocation(name: 'Dehradun', state: 'UK', lat: 30.3165, lng: 78.0322),
    IndianHubLocation(name: 'Jammu', state: 'JK', lat: 32.7266, lng: 74.8570),
    IndianHubLocation(name: 'Noida', state: 'UP', lat: 28.5355, lng: 77.3910),
    IndianHubLocation(name: 'Gurugram', state: 'HR', lat: 28.4595, lng: 77.0266),
    IndianHubLocation(name: 'Faridabad', state: 'HR', lat: 28.4089, lng: 77.3178),
    IndianHubLocation(name: 'Ghaziabad', state: 'UP', lat: 28.6692, lng: 77.4538),
  ];

  static Future<List<GooglePlaceSuggestion>> getAutocompleteSuggestions(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final List<GooglePlaceSuggestion> results = [];
    final seen = <String>{};

    // 1. First, search Google Places API
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&components=country:in'
        '&language=en'
        '&key=${AppConfig.googleMapsKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          for (final p in predictions) {
            final desc = p['description'] as String? ?? '';
            final placeId = p['place_id'] as String? ?? '';
            final structured = p['structured_formatting'] as Map<String, dynamic>?;
            final main = structured?['main_text'] as String?;
            final sec = structured?['secondary_text'] as String?;

            if (desc.isNotEmpty && !seen.contains(desc.toLowerCase())) {
              seen.add(desc.toLowerCase());
              results.add(GooglePlaceSuggestion(
                placeId: placeId,
                description: desc,
                mainText: main,
                secondaryText: sec,
              ));
            }
          }
        }
      }
    } catch (_) {
      // Fallback seamlessly to local hub database
    }

    // 2. Also check local Indian hubs database for immediate matches
    for (final hub in indianHubs) {
      final hubNameLower = hub.name.toLowerCase();
      final hubStateLower = hub.state.toLowerCase();
      if (hubNameLower.contains(cleanQuery) || hubStateLower == cleanQuery) {
        final desc = '${hub.name}, ${hub.state}, India';
        if (!seen.contains(desc.toLowerCase())) {
          seen.add(desc.toLowerCase());
          results.add(GooglePlaceSuggestion(
            placeId: 'hub_${hub.name.replaceAll(' ', '_')}',
            description: desc,
            mainText: hub.name,
            secondaryText: '${hub.state}, India (Logistics Hub)',
          ));
        }
      }
    }

    return results;
  }

  static Future<Map<String, double>?> getPlaceDetails(String placeId) async {
    // 1. Check if it's a known hub
    if (placeId.startsWith('hub_')) {
      final hubName = placeId.substring(4).replaceAll('_', ' ').toLowerCase();
      for (final hub in indianHubs) {
        if (hub.name.toLowerCase() == hubName) {
          return {'lat': hub.lat, 'lng': hub.lng};
        }
      }
    }

    // 2. Query Google Place Details API
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=${AppConfig.googleMapsKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result']?['geometry']?['location'] != null) {
          final location = data['result']['geometry']['location'];
          return {
            'lat': (location['lat'] as num).toDouble(),
            'lng': (location['lng'] as num).toDouble(),
          };
        }
      }
    } catch (_) {}

    return null;
  }

  /// Reverse geocode LatLng to city/hub name
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&result_type=locality|administrative_area_level_2'
        '&key=${AppConfig.googleMapsKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          final addr = first['formatted_address'] as String?;
          if (addr != null && addr.isNotEmpty) {
            return addr;
          }
        }
      }
    } catch (_) {}

    // Fallback: Find closest Indian hub
    return findClosestHub(lat, lng).fullName;
  }

  static IndianHubLocation findClosestHub(double lat, double lng) {
    IndianHubLocation closest = indianHubs.first;
    double minDistance = double.infinity;

    for (final hub in indianHubs) {
      final dist = sqrt(pow(lat - hub.lat, 2) + pow(lng - hub.lng, 2));
      if (dist < minDistance) {
        minDistance = dist;
        closest = hub;
      }
    }
    return closest;
  }
}
