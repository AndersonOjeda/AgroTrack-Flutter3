class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, double lat, double lng, String location) {
    try {
      // Validar que json no sea null
      if (json.isEmpty) {
        throw Exception('Respuesta JSON vacía');
      }
      
      // Validar que existe el campo 'current'
      final current = json['current'];
      if (current == null) {
        throw Exception('Campo "current" no encontrado en la respuesta de la API. Campos disponibles: ${json.keys.toList()}');
      }
      
      // Validar que 'current' sea un Map
      if (current is! Map<String, dynamic>) {
        throw Exception('Campo "current" no es un objeto válido: ${current.runtimeType}');
      }
      
      // Extraer valores con validaciones adicionales
      final temperature = _extractNumericValue(current, 'temperature_2m', 'temperatura');
      final humidity = _extractNumericValue(current, 'relative_humidity_2m', 'humedad');
      final windSpeed = _extractNumericValue(current, 'wind_speed_10m', 'velocidad del viento');
      final weatherCode = _extractNumericValue(current, 'weather_code', 'código del clima').toInt();
      
      return WeatherData(
        temperature: temperature,
        humidity: humidity,
        windSpeed: windSpeed,
        description: WeatherData.getWeatherDescription(weatherCode),
        icon: WeatherData.getWeatherIcon(weatherCode),
        latitude: lat,
        longitude: lng,
        locationName: location.isNotEmpty ? location : 'Ubicación desconocida',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error procesando datos del clima: $e');
    }
  }
  
  /// Método auxiliar para extraer valores numéricos de forma segura
  static double _extractNumericValue(Map<String, dynamic> data, String key, String fieldName) {
    final value = data[key];
    
    if (value == null) {
      print('Advertencia: Campo "$key" ($fieldName) no encontrado, usando valor por defecto 0.0');
      return 0.0;
    }
    
    if (value is num) {
      return value.toDouble();
    }
    
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    
    print('Advertencia: Campo "$key" ($fieldName) tiene un valor inválido: $value (${value.runtimeType}), usando valor por defecto 0.0');
     return 0.0;
   }
   
   /// Factory para crear datos de clima por defecto cuando la API falle
   factory WeatherData.defaultData(double lat, double lng, String location) {
     return WeatherData(
       temperature: 20.0, // Temperatura promedio
       humidity: 50.0, // Humedad promedio
       windSpeed: 5.0, // Velocidad de viento promedio
       description: 'Datos no disponibles',
       icon: '🌤️', // Icono neutral
       latitude: lat,
       longitude: lng,
       locationName: location.isNotEmpty ? location : 'Ubicación desconocida',
       timestamp: DateTime.now(),
     );
   }

  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Despejado';
      case 1:
      case 2:
      case 3:
        return 'Parcialmente nublado';
      case 45:
      case 48:
        return 'Niebla';
      case 51:
      case 53:
      case 55:
        return 'Llovizna';
      case 61:
      case 63:
      case 65:
        return 'Lluvia';
      case 71:
      case 73:
      case 75:
        return 'Nieve';
      case 80:
      case 81:
      case 82:
        return 'Chubascos';
      case 95:
        return 'Tormenta';
      default:
        return 'Desconocido';
    }
  }

  static String getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return '\u2600\ufe0f';
      case 1:
      case 2:
      case 3:
        return '\u26c5';
      case 45:
      case 48:
        return '\U0001F32B\ufe0f';
      case 51:
      case 53:
      case 55:
        return '\U0001F326\ufe0f';
      case 61:
      case 63:
      case 65:
        return '\U0001F327\ufe0f';
      case 71:
      case 73:
      case 75:
        return '\U0001F328\ufe0f';
      case 80:
      case 81:
      case 82:
        return '\U0001F327\ufe0f';
      case 95:
        return '\u26c8\ufe0f';
      default:
        return '\u2601\ufe0f';
    }
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WeatherData.fromCache(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
