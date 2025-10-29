import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GlobalLocationData {
  final String displayName;
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? state;
  final String? city;
  final String type;

  GlobalLocationData({
    required this.displayName,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.state,
    this.city,
    required this.type,
  });

  factory GlobalLocationData.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    
    return GlobalLocationData(
      displayName: json['display_name'] ?? '',
      name: json['name'] ?? json['display_name'] ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      country: address['country'],
      state: address['state'] ?? address['province'] ?? address['region'],
      city: address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'],
      type: json['type'] ?? 'unknown',
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() => displayName;
}

class GlobalLocationService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const int _defaultLimit = 10;
  
  // Cache para evitar llamadas repetidas
  static final Map<String, List<GlobalLocationData>> _cache = {};
  
  /// Busca ubicaciones globalmente usando la API de Nominatim
  static Future<List<GlobalLocationData>> searchLocations(
    String query, {
    int limit = _defaultLimit,
    String? countryCode,
    bool includeAddressDetails = true,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final cacheKey = '${query.toLowerCase()}_${countryCode ?? 'all'}_$limit';
    
    // Verificar cache primero
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': includeAddressDetails ? '1' : '0',
        'accept-language': 'es,en',
        'namedetails': '1',
        if (countryCode != null) 'countrycodes': countryCode,
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AgroTrack/1.0.0 (Flutter App)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final locations = data
            .map((item) => GlobalLocationData.fromJson(item))
            .where((location) => 
                location.latitude != 0.0 && 
                location.longitude != 0.0 &&
                location.displayName.isNotEmpty)
            .toList();

        // Guardar en cache
        _cache[cacheKey] = locations;
        
        // Limpiar cache si se vuelve muy grande
        if (_cache.length > 100) {
          _cache.clear();
        }

        return locations;
      } else {
        print('Error en la búsqueda de ubicaciones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error al buscar ubicaciones: $e');
      return [];
    }
  }

  /// Busca ubicaciones específicamente en un país
  static Future<List<GlobalLocationData>> searchInCountry(
    String query,
    String countryCode, {
    int limit = _defaultLimit,
  }) async {
    return searchLocations(
      query,
      limit: limit,
      countryCode: countryCode,
    );
  }

  /// Busca ciudades específicamente
  static Future<List<GlobalLocationData>> searchCities(
    String query, {
    int limit = _defaultLimit,
    String? countryCode,
  }) async {
    final allResults = await searchLocations(
      query,
      limit: limit * 2, // Buscar más para filtrar
      countryCode: countryCode,
    );

    // Filtrar solo ciudades, pueblos y lugares habitados
    return allResults.where((location) {
      final type = location.type.toLowerCase();
      return type.contains('city') ||
             type.contains('town') ||
             type.contains('village') ||
             type.contains('municipality') ||
             type.contains('administrative');
    }).take(limit).toList();
  }

  /// Obtiene detalles de una ubicación por coordenadas (geocodificación inversa)
  static Future<GlobalLocationData?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'es,en',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AgroTrack/1.0.0 (Flutter App)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GlobalLocationData.fromJson(data);
      }
    } catch (e) {
      print('Error en geocodificación inversa: $e');
    }
    return null;
  }

  /// Limpia el cache de búsquedas
  static void clearCache() {
    _cache.clear();
  }

  /// Obtiene sugerencias de países para autocompletado
  static Future<List<String>> getCountrySuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await searchLocations(
      query,
      limit: 5,
    );

    final countries = results
        .where((location) => location.country != null)
        .map((location) => location.country!)
        .toSet()
        .toList();

    return countries;
  }
}