import 'package:dio/dio.dart';
import '../models/weather_data.dart';
import '../models/daily_forecast.dart';
import 'logger_service.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Obtener datos del clima para una ubicación específica
  Future<WeatherData?> getWeatherData(double latitude, double longitude, String locationName) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          'timezone': 'auto',
        },
      );

      if (response.statusCode == 200) {
        // Log detallado de la respuesta para debugging
        LoggerService.info('Respuesta completa de la API: ${response.data}');
        
        // Verificar estructura de la respuesta
        if (response.data == null) {
          LoggerService.error('Respuesta de la API es null');
          return null;
        }
        
        if (response.data is! Map<String, dynamic>) {
          LoggerService.error('Respuesta de la API no es un Map válido: ${response.data.runtimeType}');
          return null;
        }
        
        final data = response.data as Map<String, dynamic>;
        LoggerService.info('Estructura de datos: ${data.keys.toList()}');
        
        if (data['current'] == null) {
          LoggerService.error('Campo "current" no encontrado en la respuesta');
          LoggerService.info('Campos disponibles: ${data.keys.toList()}');
          return null;
        }
        
        LoggerService.info('Datos current: ${data['current']}');
        
        try {
          return WeatherData.fromJson(data, latitude, longitude, locationName);
        } catch (parseError) {
          LoggerService.error('Error parseando datos del clima: $parseError');
          LoggerService.info('Usando datos de clima por defecto debido a error de parsing');
          return WeatherData.defaultData(latitude, longitude, locationName);
        }
      } else {
        LoggerService.error('Error en respuesta del clima: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      String errorMessage = 'Error de conexión';
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Timeout: La conexión tardó demasiado';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Error de conexión: Verifique su conexión a internet';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Error del servidor: ${e.response?.statusCode}';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Solicitud cancelada';
          break;
        default:
          errorMessage = 'Error de red: ${e.message}';
      }
      
      LoggerService.error('Error DioException: $errorMessage - ${e.toString()}');
       
       // Retornar datos por defecto en caso de error de conexión
       LoggerService.info('Usando datos de clima por defecto debido a error de conexión');
       return WeatherData.defaultData(latitude, longitude, locationName);
     } catch (e) {
       LoggerService.error('Error inesperado obteniendo datos del clima: $e');
       
       // Retornar datos por defecto en caso de error inesperado
       LoggerService.info('Usando datos de clima por defecto debido a error inesperado');
       return WeatherData.defaultData(latitude, longitude, locationName);
     }
  }

  /// Obtener pronóstico por horas para las próximas 24 horas desde la hora actual
  Future<List<WeatherData>?> getHourlyForecast(double latitude, double longitude, String locationName) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'hourly': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
          'timezone': 'auto',
          'forecast_days': 2, // Aumentamos a 2 días para asegurar que tenemos suficientes horas
        },
      );

      if (response.statusCode == 200) {
        final hourly = response.data['hourly'];
        final List<WeatherData> forecast = [];
        
        // Obtener la hora actual del dispositivo
        final now = DateTime.now();
        final currentHour = now.hour;
        
        // Buscar el índice que corresponde a la hora actual o la siguiente
        int startIndex = 0;
        final times = hourly['time'] as List;
        
        for (int i = 0; i < times.length; i++) {
          final forecastTime = DateTime.parse(times[i]);
          // Si encontramos una hora igual o posterior a la actual, empezamos desde ahí
          if (forecastTime.hour >= currentHour && forecastTime.day == now.day) {
            startIndex = i;
            break;
          }
          // Si ya pasamos al día siguiente, empezamos desde la primera hora del día siguiente
          if (forecastTime.day > now.day) {
            startIndex = i;
            break;
          }
        }
        
        // Obtener las próximas 12 horas desde la hora actual
        final int hoursToShow = 12;
        final int maxHours = (times.length - startIndex).clamp(0, hoursToShow);
        
        for (int i = 0; i < maxHours; i++) {
          final index = startIndex + i;
          if (index >= times.length) break;
          
          final weatherData = WeatherData(
            temperature: hourly['temperature_2m'][index]?.toDouble() ?? 0.0,
            humidity: hourly['relative_humidity_2m'][index]?.toDouble() ?? 0.0,
            windSpeed: hourly['wind_speed_10m'][index]?.toDouble() ?? 0.0,
            description: WeatherData.getWeatherDescription(hourly['weather_code'][index] ?? 0),
            icon: WeatherData.getWeatherIcon(hourly['weather_code'][index] ?? 0),
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            timestamp: DateTime.parse(hourly['time'][index]),
          );
          forecast.add(weatherData);
        }
        
        LoggerService.info('Pronóstico por horas desde las ${now.hour}:00 - ${forecast.length} horas obtenidas');
        return forecast;
      } else {
        LoggerService.error('Error en respuesta del pronóstico por horas: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error obteniendo pronóstico por horas: $e');
      return null;
    }
  }

  /// Obtener pronóstico extendido (opcional para futuras mejoras)
  Future<List<DailyForecast>?> getWeatherForecast(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'temperature_2m_max,temperature_2m_min,weather_code',
          'timezone': 'auto',
          'forecast_days': 7,
        },
      );

      if (response.statusCode == 200) {
        final daily = response.data['daily'];
        final List<DailyForecast> forecast = [];
        
        for (int i = 0; i < (daily['time']?.length ?? 0); i++) {
          // Crear datos simplificados para el pronóstico
          final weatherData = DailyForecast(
            date: DateTime.parse(daily['time'][i]),
            maxTemperature: daily['temperature_2m_max'][i]?.toDouble() ?? 0.0,
            minTemperature: daily['temperature_2m_min'][i]?.toDouble() ?? 0.0,
            description: WeatherData.getWeatherDescription(daily['weather_code'][i] ?? 0),
            icon: WeatherData.getWeatherIcon(daily['weather_code'][i] ?? 0),
            weatherCode: daily['weather_code'][i] ?? 0,
          );
          forecast.add(weatherData);
        }
        
        return forecast;
      } else {
        LoggerService.error('Error en respuesta del pronóstico: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error obteniendo pronóstico del clima: $e');
      return null;
    }
  }
}
