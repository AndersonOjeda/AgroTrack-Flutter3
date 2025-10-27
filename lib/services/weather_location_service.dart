import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../models/weather_location.dart';
import '../models/weather_data.dart';
import '../models/farm_location_model.dart';
import 'weather_service.dart';
import 'logger_service.dart';
import 'database_service.dart';

class WeatherLocationService {
  static const String _tableName = 'farm_locations';
  static const String _currentLocationKey = 'current_weather_location_id';
  
  static final WeatherLocationService _instance = WeatherLocationService._internal();
  factory WeatherLocationService() => _instance;
  WeatherLocationService._internal();

  final Uuid _uuid = const Uuid();
  static final SupabaseClient _client = Supabase.instance.client;
  
  List<WeatherLocation> _savedLocations = [];
  WeatherLocation? _currentLocation;
  
  // Getters
  List<WeatherLocation> get savedLocations => List.unmodifiable(_savedLocations);
  WeatherLocation? get currentLocation => _currentLocation;
  int get currentLocationIndex => _savedLocations.indexOf(_currentLocation ?? _savedLocations.first);

  /// Inicializa el servicio cargando ubicaciones guardadas
  Future<void> initialize() async {
    try {
      await _loadSavedLocations();
      
      // No agregar ubicación por defecto automáticamente
      // El usuario debe agregar ubicaciones manualmente
      
      LoggerService.info('WeatherLocationService inicializado con ${_savedLocations.length} ubicaciones');
    } catch (e) {
      LoggerService.error('Error inicializando WeatherLocationService: $e');
    }
  }

  /// Carga ubicaciones guardadas desde SharedPreferences
  Future<void> _loadSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getString(_locationsKey);
      final currentIndex = prefs.getInt(_currentLocationKey) ?? 0;
      
      if (locationsJson != null) {
        final locationsList = json.decode(locationsJson) as List<dynamic>;
        _savedLocations = locationsList
            .map((item) => WeatherLocation.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Validar índice actual
        if (currentIndex >= 0 && currentIndex < _savedLocations.length) {
          _currentLocationIndex = currentIndex;
        } else {
          _currentLocationIndex = 0;
        }
      }
    } catch (e) {
      LoggerService.error('Error cargando ubicaciones: $e');
      _savedLocations = [];
      _currentLocationIndex = 0;
    }
  }

  /// Guarda ubicaciones en SharedPreferences
  Future<void> _saveLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = json.encode(
        _savedLocations.map((location) => location.toJson()).toList()
      );
      
      await prefs.setString(_locationsKey, locationsJson);
      await prefs.setInt(_currentLocationKey, _currentLocationIndex);
      
      LoggerService.info('Ubicaciones guardadas: ${_savedLocations.length}');
    } catch (e) {
      LoggerService.error('Error guardando ubicaciones: $e');
    }
  }



  /// Obtiene todas las ubicaciones guardadas
  Future<List<WeatherLocation>> getAllLocations() async {
    await _loadSavedLocations();
    return List.unmodifiable(_savedLocations);
  }

  /// Agrega una nueva ubicación con parámetros individuales
  Future<WeatherLocation?> addLocation({
    required String name,
    required String country,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      // Verificar si la ubicación ya existe
      final exists = _savedLocations.any((loc) => 
        (loc.latitude - latitude).abs() < 0.001 && 
        (loc.longitude - longitude).abs() < 0.001
      );
      
      if (exists) {
        LoggerService.info('La ubicación ya existe en coordenadas similares');
        return null;
      }
      
      final newLocation = WeatherLocation(
        id: '${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        country: country,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );
      
      // Si es la primera ubicación o se marca como predeterminada, establecerla como actual
      if (_savedLocations.isEmpty || isDefault) {
        // Marcar todas las demás como no predeterminadas
        _savedLocations = _savedLocations.map((loc) => 
          WeatherLocation(
            id: loc.id,
            name: loc.name,
            country: loc.country,
            latitude: loc.latitude,
            longitude: loc.longitude,
            isDefault: false,
            createdAt: loc.createdAt,
          )
        ).toList();
        
        _savedLocations.add(newLocation);
        _currentLocationIndex = _savedLocations.length - 1;
      } else {
        _savedLocations.add(newLocation);
      }
      
      await _saveLocations();
      
      LoggerService.info('Nueva ubicación agregada: ${newLocation.name}');
      return newLocation;
    } catch (e) {
      LoggerService.error('Error agregando ubicación: $e');
      return null;
    }
  }

  /// Actualiza una ubicación existente
  Future<bool> updateLocation(WeatherLocation updatedLocation) async {
    try {
      final index = _savedLocations.indexWhere((loc) => loc.id == updatedLocation.id);
      
      if (index == -1) {
        LoggerService.error('Ubicación no encontrada para actualizar: ${updatedLocation.id}');
        return false;
      }
      
      // Si se marca como predeterminada, desmarcar las demás
      if (updatedLocation.isDefault) {
        _savedLocations = _savedLocations.map((loc) => 
          WeatherLocation(
            id: loc.id,
            name: loc.name,
            country: loc.country,
            latitude: loc.latitude,
            longitude: loc.longitude,
            isDefault: loc.id == updatedLocation.id,
            createdAt: loc.createdAt,
          )
        ).toList();
        _currentLocationIndex = index;
      } else {
        _savedLocations[index] = updatedLocation;
      }
      
      await _saveLocations();
      
      LoggerService.info('Ubicación actualizada: ${updatedLocation.name}');
      return true;
    } catch (e) {
      LoggerService.error('Error actualizando ubicación: $e');
      return false;
    }
  }

  /// Elimina una ubicación por ID
  Future<bool> deleteLocation(String locationId) async {
    try {
      final index = _savedLocations.indexWhere((loc) => loc.id == locationId);
      
      if (index == -1) {
        LoggerService.info('Ubicación no encontrada para eliminar: $locationId');
        return false;
      }
      
      final removedLocation = _savedLocations.removeAt(index);
      
      // Ajustar índice actual si es necesario
      if (_savedLocations.isEmpty) {
        _currentLocationIndex = 0;
      } else if (_currentLocationIndex >= _savedLocations.length) {
        _currentLocationIndex = _savedLocations.length - 1;
      } else if (_currentLocationIndex > index) {
        _currentLocationIndex--;
      }
      
      await _saveLocations();
      
      LoggerService.info('Ubicación eliminada: ${removedLocation.name}');
      return true;
    } catch (e) {
      LoggerService.error('Error eliminando ubicación: $e');
      return false;
    }
  }

  /// Establece una ubicación como actual por ID
  Future<bool> setCurrentLocation(String locationId) async {
    try {
      final index = _savedLocations.indexWhere((loc) => loc.id == locationId);
      
      if (index == -1) {
        LoggerService.error('Ubicación no encontrada: $locationId');
        return false;
      }
      
      // Actualizar todas las ubicaciones para marcar solo esta como predeterminada
      _savedLocations = _savedLocations.map((loc) => 
        WeatherLocation(
          id: loc.id,
          name: loc.name,
          country: loc.country,
          latitude: loc.latitude,
          longitude: loc.longitude,
          isDefault: loc.id == locationId,
          createdAt: loc.createdAt,
        )
      ).toList();
      
      _currentLocationIndex = index;
      await _saveLocations();
      
      LoggerService.info('Ubicación actual cambiada a: ${_savedLocations[index].name}');
      return true;
    } catch (e) {
      LoggerService.error('Error cambiando ubicación actual: $e');
      return false;
    }
  }

  /// Agrega una nueva ubicación (método legacy)
  Future<bool> addLocationLegacy(WeatherLocation location) async {
    try {
      // Verificar si la ubicación ya existe
      final exists = _savedLocations.any((loc) => 
        loc.latitude == location.latitude && loc.longitude == location.longitude
      );
      
      if (exists) {
        LoggerService.info('La ubicación ya existe: ${location.name}');
        return false;
      }
      
      // Generar ID único si no tiene
      final newLocation = location.id.isEmpty 
          ? location.copyWith(
              id: '${location.latitude}_${location.longitude}_${DateTime.now().millisecondsSinceEpoch}',
              createdAt: DateTime.now(),
            )
          : location;
      
      _savedLocations.add(newLocation);
      await _saveLocations();
      
      LoggerService.info('Nueva ubicación agregada: ${newLocation.name}');
      return true;
    } catch (e) {
      LoggerService.error('Error agregando ubicación: $e');
      return false;
    }
  }

  /// Elimina una ubicación
  Future<bool> removeLocation(String locationId) async {
    try {
      final index = _savedLocations.indexWhere((loc) => loc.id == locationId);
      
      if (index == -1) {
        LoggerService.info('Ubicación no encontrada para eliminar: $locationId');
        return false;
      }
      
      // No permitir eliminar si es la única ubicación
      if (_savedLocations.length <= 1) {
        LoggerService.info('No se puede eliminar la única ubicación');
        return false;
      }
      
      final removedLocation = _savedLocations.removeAt(index);
      
      // Ajustar índice actual si es necesario
      if (_currentLocationIndex >= _savedLocations.length) {
        _currentLocationIndex = _savedLocations.length - 1;
      } else if (_currentLocationIndex > index) {
        _currentLocationIndex--;
      }
      
      await _saveLocations();
      
      LoggerService.info('Ubicación eliminada: ${removedLocation.name}');
      return true;
    } catch (e) {
      LoggerService.error('Error eliminando ubicación: $e');
      return false;
    }
  }

  /// Cambia la ubicación actual por índice
  Future<bool> setCurrentLocationByIndex(int index) async {
    try {
      if (index >= 0 && index < _savedLocations.length) {
        _currentLocationIndex = index;
        await _saveLocations();
        
        LoggerService.info('Ubicación actual cambiada a: ${_savedLocations[index].name}');
        return true;
      }
      
      LoggerService.error('Índice de ubicación inválido: $index');
      return false;
    } catch (e) {
      LoggerService.error('Error cambiando ubicación actual: $e');
      return false;
    }
  }

  /// Cambia la ubicación actual por ID
  Future<bool> setCurrentLocationById(String locationId) async {
    try {
      final index = _savedLocations.indexWhere((loc) => loc.id == locationId);
      
      if (index != -1) {
        return await setCurrentLocationByIndex(index);
      }
      
      LoggerService.error('Ubicación no encontrada: $locationId');
      return false;
    } catch (e) {
      LoggerService.error('Error cambiando ubicación por ID: $e');
      return false;
    }
  }

  /// Busca ubicaciones usando datos predefinidos
  Future<List<WeatherLocation>> searchLocations(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      LoggerService.info('Buscando ubicaciones: $query');
      
      final results = _getMockSearchResults(query);
      
      LoggerService.info('Encontradas ${results.length} ubicaciones para: $query');
      return results;
    } catch (e) {
      LoggerService.error('Error buscando ubicaciones: $e');
      return [];
    }
  }

  /// Obtiene datos del clima para la ubicación actual
  Future<WeatherData?> getCurrentWeatherData() async {
    try {
      final location = currentLocation;
      if (location == null) {
        LoggerService.error('No hay ubicación actual seleccionada');
        return null;
      }
      
      // Obtener datos del clima usando el servicio existente
      final weatherResponse = await WeatherService.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      
      if (weatherResponse != null) {
        return _parseWeatherResponse(weatherResponse, location);
      }
      
      return null;
    } catch (e) {
      LoggerService.error('Error obteniendo datos del clima: $e');
      return null;
    }
  }

  /// Obtiene datos del clima para todas las ubicaciones guardadas
  Future<List<WeatherData>> getAllWeatherData() async {
    try {
      final weatherDataList = <WeatherData>[];
      
      for (final location in _savedLocations) {
        final weatherResponse = await WeatherService.getCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        
        if (weatherResponse != null) {
          final weatherData = _parseWeatherResponse(weatherResponse, location);
          weatherDataList.add(weatherData);
        }
      }
      
      LoggerService.info('Datos del clima obtenidos para ${weatherDataList.length} ubicaciones');
      return weatherDataList;
    } catch (e) {
      LoggerService.error('Error obteniendo datos del clima para todas las ubicaciones: $e');
      return [];
    }
  }

  // Métodos privados

  WeatherData _parseWeatherResponse(Map<String, dynamic> response, WeatherLocation location) {
    final main = response['main'] as Map<String, dynamic>;
    final weather = (response['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final wind = response['wind'] as Map<String, dynamic>? ?? {};
    
    return WeatherData(
      locationId: location.id,
      locationName: location.name,
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: main['humidity'] as int,
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      pressure: main['pressure'] as int,
      timestamp: DateTime.now(),
    );
  }

  List<WeatherLocation> _getMockSearchResults(String query) {
    final mockLocations = [
      // Ciudades principales
      WeatherLocation(
        id: 'bogota_co',
        name: 'Bogotá',
        country: 'Colombia',
        latitude: 4.7110,
        longitude: -74.0721,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'medellin_co',
        name: 'Medellín',
        country: 'Colombia',
        latitude: 6.2442,
        longitude: -75.5812,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'cali_co',
        name: 'Cali',
        country: 'Colombia',
        latitude: 3.4516,
        longitude: -76.5320,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'barranquilla_co',
        name: 'Barranquilla',
        country: 'Colombia',
        latitude: 10.9639,
        longitude: -74.7964,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'cartagena_co',
        name: 'Cartagena',
        country: 'Colombia',
        latitude: 10.3910,
        longitude: -75.4794,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'bucaramanga_co',
        name: 'Bucaramanga',
        country: 'Colombia',
        latitude: 7.1193,
        longitude: -73.1227,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'pereira_co',
        name: 'Pereira',
        country: 'Colombia',
        latitude: 4.8133,
        longitude: -75.6961,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'manizales_co',
        name: 'Manizales',
        country: 'Colombia',
        latitude: 5.0703,
        longitude: -75.5138,
        createdAt: DateTime.now(),
      ),
      
      // Departamento de Nariño
      WeatherLocation(
        id: 'pasto_co',
        name: 'Pasto',
        country: 'Colombia',
        latitude: 1.2136,
        longitude: -77.2811,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'chachagui_co',
        name: 'Chachagüí',
        country: 'Colombia',
        latitude: 1.1833,
        longitude: -77.2833,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'yacuanquer_co',
        name: 'Yacuanquer',
        country: 'Colombia',
        latitude: 1.1333,
        longitude: -77.4167,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'ipiales_co',
        name: 'Ipiales',
        country: 'Colombia',
        latitude: 0.8317,
        longitude: -77.6419,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'tumaco_co',
        name: 'Tumaco',
        country: 'Colombia',
        latitude: 1.8014,
        longitude: -78.7658,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'sandona_co',
        name: 'Sandoná',
        country: 'Colombia',
        latitude: 1.2833,
        longitude: -77.4667,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'la_union_co',
        name: 'La Unión',
        country: 'Colombia',
        latitude: 1.6000,
        longitude: -77.1333,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'consaca_co',
        name: 'Consacá',
        country: 'Colombia',
        latitude: 1.2167,
        longitude: -77.5167,
        createdAt: DateTime.now(),
      ),
      
      // Otras ciudades importantes
      WeatherLocation(
        id: 'cucuta_co',
        name: 'Cúcuta',
        country: 'Colombia',
        latitude: 7.8939,
        longitude: -72.5078,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'ibague_co',
        name: 'Ibagué',
        country: 'Colombia',
        latitude: 4.4389,
        longitude: -75.2322,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'santa_marta_co',
        name: 'Santa Marta',
        country: 'Colombia',
        latitude: 11.2408,
        longitude: -74.1990,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'villavicencio_co',
        name: 'Villavicencio',
        country: 'Colombia',
        latitude: 4.1420,
        longitude: -73.6266,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'neiva_co',
        name: 'Neiva',
        country: 'Colombia',
        latitude: 2.9273,
        longitude: -75.2819,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'popayan_co',
        name: 'Popayán',
        country: 'Colombia',
        latitude: 2.4448,
        longitude: -76.6147,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'armenia_co',
        name: 'Armenia',
        country: 'Colombia',
        latitude: 4.5339,
        longitude: -75.6811,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'monteria_co',
        name: 'Montería',
        country: 'Colombia',
        latitude: 8.7479,
        longitude: -75.8814,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'valledupar_co',
        name: 'Valledupar',
        country: 'Colombia',
        latitude: 10.4631,
        longitude: -73.2532,
        createdAt: DateTime.now(),
      ),
      WeatherLocation(
        id: 'sincelejo_co',
        name: 'Sincelejo',
        country: 'Colombia',
        latitude: 9.3047,
        longitude: -75.3978,
        createdAt: DateTime.now(),
      ),
    ];
    
    return mockLocations.where((location) =>
      location.name.toLowerCase().contains(query.toLowerCase()) ||
      location.country.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}