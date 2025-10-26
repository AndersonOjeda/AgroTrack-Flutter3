import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

class WeatherService {
  // API key de OpenWeatherMap - Reemplazar con tu API key real
  // Puedes obtener una gratis en: https://openweathermap.org/api
  static const String _apiKey = '0bf757c4eab4ff05ccfc5d23f0a745eb';
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
        LoggerService.error('Error en API del clima: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error al obtener datos del clima', error: e);
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
        LoggerService.error('Error en API del pronóstico: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error al obtener pronóstico', error: e);
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
        LoggerService.error('Error en API Open-Meteo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error al obtener datos del clima (Open-Meteo)', error: e);
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

  /// Obtiene alertas meteorológicas para una ubicación
  static Future<List<Map<String, dynamic>>> getWeatherAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = '$_baseUrl/onecall?'
          'lat=$latitude&lon=$longitude'
          '&appid=$_apiKey&units=metric&lang=es'
          '&exclude=minutely';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = data['alerts'] as List<dynamic>? ?? [];
        
        return alerts.map((alert) => {
          'event': alert['event'] ?? 'Alerta meteorológica',
          'description': alert['description'] ?? 'Sin descripción',
          'start': alert['start'] ?? 0,
          'end': alert['end'] ?? 0,
          'sender_name': alert['sender_name'] ?? 'Servicio meteorológico',
        }).toList();
      } else {
        LoggerService.error('Error en API de alertas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error al obtener alertas meteorológicas', error: e);
      return [];
    }
  }

  /// Obtiene pronóstico extendido usando endpoint gratuito
  static Future<Map<String, dynamic>?> getExtendedForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Usar el endpoint gratuito de forecast en lugar de onecall
      final url = '$_baseUrl/forecast?'
          'lat=$latitude&lon=$longitude'
          '&appid=$_apiKey&units=metric&lang=es';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Transformar los datos para que sean compatibles con el formato esperado
        return {
          'current': {
            'temp': data['list'][0]['main']['temp'],
            'humidity': data['list'][0]['main']['humidity'],
            'wind_speed': data['list'][0]['wind']['speed'],
            'weather': data['list'][0]['weather'],
          },
          'daily': data['list'].take(5).map((item) => {
            'dt': item['dt'],
            'temp': {
              'day': item['main']['temp'],
              'min': item['main']['temp_min'],
              'max': item['main']['temp_max'],
            },
            'weather': item['weather'],
            'pop': item['pop'] ?? 0.0, // Probabilidad de precipitación
          }).toList(),
          'hourly': data['list'].take(24).toList(),
        };
      } else {
        LoggerService.error('Error en API del pronóstico extendido: ${response.statusCode}');
        // Fallback a datos básicos del clima actual
        return await getCurrentWeather(latitude: latitude, longitude: longitude);
      }
    } catch (e) {
      LoggerService.error('Error al obtener pronóstico extendido', error: e);
      // Fallback a datos básicos del clima actual
      return await getCurrentWeather(latitude: latitude, longitude: longitude);
    }
  }

  /// Genera recomendaciones agrícolas basadas en el clima
  static List<String> getAgriculturalRecommendations(Map<String, dynamic> weatherData) {
    final recommendations = <String>[];
    
    if (weatherData['current'] != null) {
      final current = weatherData['current'];
      final temp = current['temp']?.toDouble() ?? 0.0;
      final humidity = current['humidity']?.toInt() ?? 0;
      final windSpeed = current['wind_speed']?.toDouble() ?? 0.0;
      
      // Verificar pronóstico de lluvia en las próximas 24 horas
      bool rainExpected = false;
      if (weatherData['hourly'] != null) {
        final hourly = weatherData['hourly'] as List;
        for (int i = 0; i < 24 && i < hourly.length; i++) {
          final hour = hourly[i];
          if (hour['weather'] != null && hour['weather'].isNotEmpty) {
            final weatherCode = hour['weather'][0]['id'];
            if (weatherCode >= 200 && weatherCode < 700) { // Códigos de lluvia/tormenta
              rainExpected = true;
              break;
            }
          }
        }
      }
      
      // Recomendaciones basadas en lluvia
      if (rainExpected) {
        recommendations.add("🌧️ Lluvia esperada en las próximas 24 horas");
        recommendations.add("💧 Hoy no riegues, se esperan lluvias");
        recommendations.add("🚫 Evita aplicar fertilizantes por lluvia esperada");
        recommendations.add("🏠 Protege cultivos sensibles si es necesario");
      }
      
      // Recomendaciones basadas en humedad
      if (humidity > 80) {
        recommendations.add("💨 Alta humedad ($humidity%) - Evita aplicar fertilizantes");
        recommendations.add("🍄 Riesgo de hongos - Monitorea tus cultivos");
        recommendations.add("🌬️ Asegura buena ventilación en invernaderos");
      } else if (humidity < 30) {
        recommendations.add("🏜️ Baja humedad ($humidity%) - Aumenta el riego");
        recommendations.add("💦 Considera riego por aspersión para aumentar humedad");
      }
      
      // Recomendaciones basadas en temperatura
      if (temp > 35) {
        recommendations.add("🔥 Temperatura muy alta (${temp.round()}°C) - Riega temprano");
        recommendations.add("☂️ Proporciona sombra a cultivos sensibles");
        recommendations.add("⏰ Evita trabajar en campo durante horas pico");
      } else if (temp < 5) {
        recommendations.add("❄️ Temperatura baja (${temp.round()}°C) - Protege cultivos del frío");
        recommendations.add("🔥 Considera calefacción en invernaderos");
        recommendations.add("🌱 Retrasa siembras de cultivos sensibles al frío");
      } else if (temp >= 15 && temp <= 25) {
        recommendations.add("🌡️ Temperatura ideal (${temp.round()}°C) para la mayoría de cultivos");
        recommendations.add("🌱 Buen momento para siembras y trasplantes");
      }
      
      // Recomendaciones basadas en viento
      if (windSpeed > 10) {
        recommendations.add("💨 Viento fuerte (${windSpeed.toStringAsFixed(1)} m/s) - Protege plantas altas");
        recommendations.add("🚫 Evita aplicar pesticidas por viento fuerte");
        recommendations.add("🏗️ Refuerza estructuras de soporte");
      }
      
      // Recomendaciones generales si no hay condiciones especiales
      if (recommendations.isEmpty) {
        recommendations.add("☀️ Condiciones normales - Mantén rutina de cuidados");
        recommendations.add("📊 Monitorea regularmente tus cultivos");
        recommendations.add("💧 Riega según necesidades específicas de cada planta");
      }
    }
    
    return recommendations;
  }

  /// Detecta alertas automáticas basadas en condiciones meteorológicas
  static List<Map<String, dynamic>> generateAutomaticAlerts(Map<String, dynamic> weatherData) {
    final alerts = <Map<String, dynamic>>[];
    
    if (weatherData['current'] != null) {
      final current = weatherData['current'];
      final temp = current['temp']?.toDouble() ?? 0.0;
      final humidity = current['humidity']?.toInt() ?? 0;
      final windSpeed = current['wind_speed']?.toDouble() ?? 0.0;
      
      // Alerta por temperatura extrema
      if (temp > 40) {
        alerts.add({
          'type': 'warning',
          'title': 'Temperatura Extrema',
          'message': 'Temperatura muy alta (${temp.round()}°C). Protege tus cultivos.',
          'icon': '🔥',
          'priority': 'high'
        });
      } else if (temp < 0) {
        alerts.add({
          'type': 'warning',
          'title': 'Riesgo de Helada',
          'message': 'Temperatura bajo cero (${temp.round()}°C). Riesgo de helada.',
          'icon': '❄️',
          'priority': 'high'
        });
      }
      
      // Alerta por humedad extrema
      if (humidity > 90) {
        alerts.add({
          'type': 'info',
          'title': 'Humedad Muy Alta',
          'message': 'Humedad del $humidity%. Alto riesgo de enfermedades fúngicas.',
          'icon': '💨',
          'priority': 'medium'
        });
      }
      
      // Alerta por viento fuerte
      if (windSpeed > 15) {
        alerts.add({
          'type': 'warning',
          'title': 'Viento Fuerte',
          'message': 'Vientos de ${windSpeed.toStringAsFixed(1)} m/s. Protege estructuras.',
          'icon': '💨',
          'priority': 'medium'
        });
      }
      
      // Verificar pronóstico de lluvia intensa
      if (weatherData['hourly'] != null) {
        final hourly = weatherData['hourly'] as List;
        bool heavyRainExpected = false;
        
        for (int i = 0; i < 24 && i < hourly.length; i++) {
          final hour = hourly[i];
          if (hour['weather'] != null && hour['weather'].isNotEmpty) {
            final weatherCode = hour['weather'][0]['id'];
            if (weatherCode >= 500 && weatherCode < 600) { // Códigos de lluvia intensa
              heavyRainExpected = true;
              break;
            }
          }
        }
        
        if (heavyRainExpected) {
          alerts.add({
            'type': 'info',
            'title': 'Lluvia Intensa Esperada',
            'message': 'Se esperan lluvias intensas en las próximas 24 horas.',
            'icon': '🌧️',
            'priority': 'medium'
          });
        }
      }
    }
    
    return alerts;
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