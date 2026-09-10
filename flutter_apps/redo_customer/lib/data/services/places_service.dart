import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class GooglePlaceSuggestion {
  final String placeId;
  final String description;

  GooglePlaceSuggestion({required this.placeId, required this.description});
}

class PlacesService {
  static Future<List<GooglePlaceSuggestion>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&components=country:in'
      '&key=${AppConfig.googleMapsKey}'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => GooglePlaceSuggestion(
            placeId: p['place_id'],
            description: p['description'],
          )).toList();
        }
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<Map<String, double>?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry'
      '&key=${AppConfig.googleMapsKey}'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return {
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
