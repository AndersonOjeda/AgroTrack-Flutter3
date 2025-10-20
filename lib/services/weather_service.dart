import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Para usar OpenWeatherMap necesitas registrarte en https://openweathermap.org/api
  // y obtener una API key gratuita. Por ahora usamos una demo.
  static const String _apiKey = 'demo_key'; // Reemplazar con tu API key real
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Obtiene datos del clima actual basado en coordenadas
  static Future<Map<String, dynamic>?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$_baseUrl/weather?'
          'lat=$latitude&lon=$longitude'
          '&appid=$_apiKey&units=metric&lang=es';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error en API del clima: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener datos del clima: $e');
      return null;
    }
  }

  /// Obtiene pronóstico de 5 días basado en coordenadas
  static Future<Map<String, dynamic>?> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$_baseUrl/forecast?'
          'lat=$latitude&lon=$longitude'
          '&appid=$_apiKey&units=metric&lang=es';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error en API del pronóstico: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener pronóstico: $e');
      return null;
    }
  }

  /// Convierte código de icono de OpenWeatherMap a emoji
  static String getWeatherEmoji(String? iconCode) {
    switch (iconCode) {
      case '01d': // clear sky day
        return '☀️';
      case '01n': // clear sky night
        return '🌙';
      case '02d': // few clouds day
        return '🌤️';
      case '02n': // few clouds night
        return '🌙';
      case '03d':
      case '03n': // scattered clouds
        return '⛅';
      case '04d':
      case '04n': // broken clouds
        return '☁️';
      case '09d':
      case '09n': // shower rain
        return '🌧️';
      case '10d': // rain day
        return '🌦️';
      case '10n': // rain night
        return '🌧️';
      case '11d':
      case '11n': // thunderstorm
        return '⛈️';
      case '13d':
      case '13n': // snow
        return '❄️';
      case '50d':
      case '50n': // mist
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Obtiene descripción del clima en español
  static String getWeatherDescription(String? description) {
    if (description == null) return 'Desconocido';
    
    // Capitalizar primera letra
    return description.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Convierte velocidad del viento de m/s a km/h
  static double windSpeedToKmh(double windSpeedMs) {
    return windSpeedMs * 3.6;
  }

  /// Obtiene dirección del viento basada en grados
  static String getWindDirection(int? degrees) {
    if (degrees == null) return 'N/A';
    
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Formatea la presión atmosférica
  static String formatPressure(int? pressure) {
    if (pressure == null) return 'N/A';
    return '$pressure hPa';
  }

  /// Formatea la humedad
  static String formatHumidity(int? humidity) {
    if (humidity == null) return 'N/A';
    return '$humidity%';
  }

  /// Formatea la precipitación
  static String formatPrecipitation(double? precipitation) {
    if (precipitation == null || precipitation == 0) return '0 mm';
    return '${precipitation.toStringAsFixed(1)} mm';
  }

  /// Formatea la temperatura
  static String formatTemperature(double? temp) {
    if (temp == null) return 'N/A';
    final tempInt = temp.round();
    return tempInt > 0 ? '+$tempInt°' : '$tempInt°';
  }

  /// Obtiene datos del clima usando una API alternativa gratuita (sin API key)
  /// Usa Open-Meteo como alternativa a OpenWeatherMap
  static Future<Map<String, dynamic>?> getCurrentWeatherFree({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?'
          'latitude=$latitude&longitude=$longitude'
          '&current=temperature_2m,relative_humidity_2m,precipitation,'
          'weather_code,wind_speed_10m,wind_direction_10m'
          '&timezone=auto';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Convertir formato de Open-Meteo a formato similar a OpenWeatherMap
        final current = data['current'];
        final weatherCode = current['weather_code'];
        
        return {
          'main': {
            'temp': current['temperature_2m'],
            'feels_like': current['temperature_2m'], // Open-Meteo no tiene feels_like
            'humidity': current['relative_humidity_2m'],
            'pressure': 1013, // Valor por defecto
          },
          'weather': [{
            'description': _getWeatherDescriptionFromCode(weatherCode),
            'icon': _getIconFromWeatherCode(weatherCode),
          }],
          'wind': {
            'speed': current['wind_speed_10m'] / 3.6, // Convertir km/h a m/s
            'deg': current['wind_direction_10m'],
          },
          'rain': {
            '1h': current['precipitation'] ?? 0,
          },
        };
      } else {
        print('Error en API Open-Meteo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener datos del clima (Open-Meteo): $e');
      return null;
    }
  }

  /// Convierte código de clima de Open-Meteo a descripción
  static String _getWeatherDescriptionFromCode(int code) {
    switch (code) {
      case 0: return 'Cielo despejado';
      case 1: return 'Principalmente despejado';
      case 2: return 'Parcialmente nublado';
      case 3: return 'Nublado';
      case 45: case 48: return 'Niebla';
      case 51: case 53: case 55: return 'Llovizna';
      case 61: case 63: case 65: return 'Lluvia';
      case 71: case 73: case 75: return 'Nieve';
      case 95: return 'Tormenta';
      case 96: case 99: return 'Tormenta con granizo';
      default: return 'Desconocido';
    }
  }

  /// Convierte código de clima de Open-Meteo a icono
  static String _getIconFromWeatherCode(int code) {
    switch (code) {
      case 0: return '01d';
      case 1: return '02d';
      case 2: return '03d';
      case 3: return '04d';
      case 45: case 48: return '50d';
      case 51: case 53: case 55: return '09d';
      case 61: case 63: case 65: return '10d';
      case 71: case 73: case 75: return '13d';
      case 95: case 96: case 99: return '11d';
      default: return '01d';
    }
  }
}