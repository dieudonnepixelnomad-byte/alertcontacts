import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/places_autocomplete.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static const String _apiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue: '',
  );

  /// Recherche d'autocomplétion de lieux
  static Future<PlaceAutoCompleteResponse> getAutocomplete(String input) async {
    developer.log('ApiKey: $_apiKey', name: 'PlaceService');
    try {
      final String url =
          '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&language=fr'; // Limité au Cameroun
      developer.log('Request URL: $url', name: 'PlaceService');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        developer.log('Response JSON: $json', name: 'PlaceService');
        return PlaceAutoCompleteResponse.fromJson(json);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les détails d'un lieu par son place_id
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final String url =
          '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&fields=geometry,formatted_address,name';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['result'] != null) {
          return PlaceDetails.fromJson(json['result']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }
}

/// Modèle pour les détails d'un lieu
class PlaceDetails {
  final PlaceGeometry? geometry;
  final String? formattedAddress;
  final String? name;

  PlaceDetails({this.geometry, this.formattedAddress, this.name});

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      geometry: json['geometry'] != null
          ? PlaceGeometry.fromJson(json['geometry'])
          : null,
      formattedAddress: json['formatted_address'],
      name: json['name'],
    );
  }
}

class PlaceGeometry {
  final PlaceLocation? location;

  PlaceGeometry({this.location});

  factory PlaceGeometry.fromJson(Map<String, dynamic> json) {
    return PlaceGeometry(
      location: json['location'] != null
          ? PlaceLocation.fromJson(json['location'])
          : null,
    );
  }
}

class PlaceLocation {
  final double lat;
  final double lng;

  PlaceLocation({required this.lat, required this.lng});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
