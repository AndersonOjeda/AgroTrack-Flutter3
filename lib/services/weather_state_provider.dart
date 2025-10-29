import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';

/// Provider para gestionar el estado global del clima
/// Permite compartir datos del clima entre diferentes pantallas
class WeatherStateProvider extends ChangeNotifier {
  WeatherData? _selectedWeatherData;
  String? _locationName;
  List<WeatherData>? _hourlyForecast;
  bool _isLoading = false;
  bool _isLoadingHourly = false;
  String? _errorMessage;

  // Getters
  WeatherData? get selectedWeatherData => _selectedWeatherData;
  WeatherData? get weatherData => _selectedWeatherData;
  String? get locationName => _locationName;
  List<WeatherData>? get hourlyForecast => _hourlyForecast;
  bool get isLoading => _isLoading;
  bool get isLoadingHourly => _isLoadingHourly;
  String? get errorMessage => _errorMessage;
  bool get hasWeatherData => _selectedWeatherData != null;
  bool get hasHourlyForecast => _hourlyForecast != null && _hourlyForecast!.isNotEmpty;

  /// Actualizar los datos del clima seleccionado
  void updateSelectedWeather(WeatherData? weatherData) {
    _selectedWeatherData = weatherData;
    _errorMessage = null;
    notifyListeners();
  }

  /// Actualizar los datos del clima con ubicación
  void updateWeather(WeatherData? weatherData, String? locationName) {
    _selectedWeatherData = weatherData;
    _locationName = locationName;
    _errorMessage = null;
    notifyListeners();
  }

  /// Actualizar pronóstico por horas
  void updateHourlyForecast(List<WeatherData>? forecast) {
    _hourlyForecast = forecast;
    _isLoadingHourly = false;
    notifyListeners();
  }

  /// Establecer estado de carga
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establecer estado de carga para pronóstico por horas
  void setLoadingHourly(bool loading) {
    _isLoadingHourly = loading;
    notifyListeners();
  }

  /// Establecer mensaje de error
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Limpiar todos los datos
  void clearWeatherData() {
    _selectedWeatherData = null;
    _locationName = null;
    _hourlyForecast = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingHourly = false;
    notifyListeners();
  }

  /// Obtener información resumida del clima actual
  String get weatherSummary {
    if (_selectedWeatherData == null) return 'Sin datos del clima';
    
    final weather = _selectedWeatherData!;
    return '${weather.temperature.round()}°C - ${weather.description}';
  }

  /// Obtener el icono del clima actual
  String get weatherIcon {
    if (_selectedWeatherData == null) return '🌤️';
    return _selectedWeatherData!.icon;
  }

  /// Obtener la ubicación actual
  String get currentLocation {
    if (_locationName != null) return _locationName!;
    if (_selectedWeatherData == null) return 'Ubicación no seleccionada';
    return _selectedWeatherData!.locationName;
  }

  /// Verificar si los datos del clima son recientes (menos de 30 minutos)
  bool get isDataFresh {
    if (_selectedWeatherData == null) return false;
    
    // Como WeatherData no tiene timestamp, consideramos que siempre son frescos
    // En una implementación real, podrías agregar un campo timestamp a WeatherData
    return true;
  }

  /// Obtener color representativo basado en la temperatura
  String get temperatureColor {
    if (_selectedWeatherData == null) return '#2196F3'; // Azul por defecto
    
    final temp = _selectedWeatherData!.temperature;
    if (temp < 0) return '#1565C0'; // Azul oscuro
    if (temp < 10) return '#2196F3'; // Azul
    if (temp < 20) return '#4CAF50'; // Verde
    if (temp < 30) return '#FF9800'; // Naranja
    return '#F44336'; // Rojo
  }

  /// Debug: Imprimir información del estado actual
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
      print('=====================================');
    }
  }
}