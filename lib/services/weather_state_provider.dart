import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import '../models/daily_forecast.dart';

/// Provider para gestionar el estado global del clima
/// Incluye datos actuales, pronóstico horario y diario con soporte de cache.
class WeatherStateProvider extends ChangeNotifier {
  WeatherData? _selectedWeatherData;
  String? _locationName;
  List<WeatherData>? _hourlyForecast;
  List<DailyForecast>? _dailyForecast;
  bool _isLoading = false;
  bool _isLoadingHourly = false;
  bool _isLoadingDaily = false;
  String? _errorMessage;
  DateTime? _lastUpdate;

  static const _cacheWeatherKey = 'cached_weather_data';
  static const _cacheForecastKey = 'cached_daily_forecast';

  WeatherData? get selectedWeatherData => _selectedWeatherData;
  WeatherData? get weatherData => _selectedWeatherData;
  String? get locationName => _locationName;
  List<WeatherData>? get hourlyForecast => _hourlyForecast;
  List<DailyForecast>? get dailyForecast => _dailyForecast;
  bool get isLoading => _isLoading;
  bool get isLoadingHourly => _isLoadingHourly;
  bool get isLoadingDaily => _isLoadingDaily;
  String? get errorMessage => _errorMessage;
  bool get hasWeatherData => _selectedWeatherData != null;
  bool get hasHourlyForecast =>
      _hourlyForecast != null && _hourlyForecast!.isNotEmpty;
  bool get hasDailyForecast =>
      _dailyForecast != null && _dailyForecast!.isNotEmpty;
  DateTime? get lastUpdate => _lastUpdate;

  /// Actualiza la información actual del clima.
  void updateSelectedWeather(WeatherData? weatherData) {
    _selectedWeatherData = weatherData;
    _errorMessage = null;
    if (weatherData != null) {
      _locationName = weatherData.locationName;
      _lastUpdate = DateTime.now();
      _cacheWeatherData(weatherData);
    }
    notifyListeners();
  }

  /// Establece datos manualmente indicando la ubicación.
  void updateWeather(WeatherData? weatherData, String? locationName) {
    _selectedWeatherData = weatherData;
    _locationName = locationName;
    _errorMessage = null;
    if (weatherData != null) {
      _lastUpdate = DateTime.now();
      _cacheWeatherData(weatherData);
    }
    notifyListeners();
  }

  /// Actualiza el pronóstico por horas.
  void updateHourlyForecast(List<WeatherData>? forecast) {
    _hourlyForecast = forecast;
    _isLoadingHourly = false;
    notifyListeners();
  }

  /// Actualiza el pronóstico diario extendido.
  void updateDailyForecast(List<DailyForecast>? forecast) {
    _dailyForecast = forecast;
    _isLoadingDaily = false;
    if (forecast != null) {
      _cacheDailyForecast(forecast);
    }
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLoadingHourly(bool loading) {
    _isLoadingHourly = loading;
    notifyListeners();
  }

  void setLoadingDaily(bool loading) {
    _isLoadingDaily = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearWeatherData() {
    _selectedWeatherData = null;
    _locationName = null;
    _hourlyForecast = null;
    _dailyForecast = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingHourly = false;
    _isLoadingDaily = false;
    _lastUpdate = null;
    notifyListeners();
  }

  /// Carga los datos almacenados en cache para funcionamiento offline.
  Future<void> loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWeather = prefs.getString(_cacheWeatherKey);
      final cachedForecast = prefs.getString(_cacheForecastKey);

      if (cachedWeather != null && _selectedWeatherData == null) {
        final data = jsonDecode(cachedWeather) as Map<String, dynamic>;
        _selectedWeatherData = WeatherData.fromCache(data);
        _locationName = _selectedWeatherData!.locationName;
      }

      if (cachedForecast != null && (_dailyForecast == null || _dailyForecast!.isEmpty)) {
        final decoded = jsonDecode(cachedForecast) as List<dynamic>;
        _dailyForecast =
            decoded.map((e) => DailyForecast.fromJson(e as Map<String, dynamic>)).toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error cargando cache de clima: $e');
      }
    }
  }

  String get weatherSummary {
    if (_selectedWeatherData == null) return 'Sin datos del clima';
    final weather = _selectedWeatherData!;
    return '${weather.temperature.round()}°C - ${weather.description}';
  }

  String get weatherIcon {
    if (_selectedWeatherData == null) return '☁️';
    return _selectedWeatherData!.icon;
  }

  String get currentLocation {
    if (_locationName != null) return _locationName!;
    if (_selectedWeatherData == null) return 'Ubicación no seleccionada';
    return _selectedWeatherData!.locationName;
  }

  bool get isDataFresh {
    if (_selectedWeatherData == null) return false;
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 30);
  }

  String get temperatureColor {
    if (_selectedWeatherData == null) return '#2196F3';
    final temp = _selectedWeatherData!.temperature;
    if (temp < 0) return '#1565C0';
    if (temp < 10) return '#2196F3';
    if (temp < 20) return '#4CAF50';
    if (temp < 30) return '#FF9800';
    return '#F44336';
  }

  void debugPrintState() {
    if (kDebugMode) {
      print('=== Weather State Provider Debug ===');
      print('Has Weather Data: $hasWeatherData');
      print('Is Loading: $isLoading');
      print('Error Message: $_errorMessage');
      print('Location Name: $_locationName');
      if (_selectedWeatherData != null) {
        print('Weather Location: ${_selectedWeatherData!.locationName}');
        print('Temperature: ${_selectedWeatherData!.temperature}°C');
        print('Description: ${_selectedWeatherData!.description}');
      }
      print('Daily Forecast count: ${_dailyForecast?.length ?? 0}');
      print('=====================================');
    }
  }

  Future<void> _cacheWeatherData(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheWeatherKey, jsonEncode(data.toCacheJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando cache de clima: $e');
      }
    }
  }

  Future<void> _cacheDailyForecast(List<DailyForecast> forecast) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheForecastKey,
        jsonEncode(forecast.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando cache de pronóstico: $e');
      }
    }
  }
}
