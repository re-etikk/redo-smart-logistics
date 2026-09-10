import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? json['description'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
      fullText: json['description'] as String? ?? '',
    );
  }
}

class PlaceLatLng {
  final double lat;
  final double lng;
  final String address;
  const PlaceLatLng({required this.lat, required this.lng, required this.address});
}

class PlacesService {
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Fetch autocomplete suggestions for Indian locations
  static Future<List<PlacePrediction>> getAutocompleteSuggestions(String input) async {
    if (input.trim().length < 2) return [];
    try {
      final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
        'input': input,
        'key': AppConfig.googleMapsKey,
        'components': 'country:in',
        'types': '(cities)',
        'language': 'en',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions
          .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get lat/lng for a place from placeId
  static Future<PlaceLatLng?> getPlaceDetails(String placeId) async {
    try {
      final uri = Uri.parse(_placeDetailsUrl).replace(queryParameters: {
        'place_id': placeId,
        'key': AppConfig.googleMapsKey,
        'fields': 'geometry,formatted_address',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final geo = result?['geometry'] as Map<String, dynamic>?;
      final loc = geo?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      return PlaceLatLng(
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
        address: result?['formatted_address'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode a lat/lng to a city name
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(_geocodeUrl).replace(queryParameters: {
        'latlng': '$lat,$lng',
        'key': AppConfig.googleMapsKey,
        'result_type': 'locality|administrative_area_level_2',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      return first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }
}
