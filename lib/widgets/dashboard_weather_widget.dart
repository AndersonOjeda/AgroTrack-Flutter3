import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../services/weather_state_provider.dart';
import '../models/weather_data.dart';
import '../services/logger_service.dart';

class DashboardWeatherWidget extends StatefulWidget {
  const DashboardWeatherWidget({super.key});

  @override
  State<DashboardWeatherWidget> createState() => _DashboardWeatherWidgetState();
}

class _DashboardWeatherWidgetState extends State<DashboardWeatherWidget> {
  final WeatherService _weatherService = WeatherService();

  bool _isLoadingWeather = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _listenForHeaderLocationUpdates();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('selected_latitude');
      final savedLng = prefs.getDouble('selected_longitude');
      final savedLocation = prefs.getString('selected_location');

      LoggerService.info(
        'Datos guardados - Lat: $savedLat, Lng: $savedLng, Location: $savedLocation',
      );

      if (savedLat != null && savedLng != null && savedLocation != null) {
        LoggerService.info('Usando ubicación guardada: $savedLocation');
        await _getWeatherForLocation(savedLat, savedLng, savedLocation);
        await _getHourlyForecast(savedLat, savedLng, savedLocation);
      } else {
        LoggerService.info(
          'No hay ubicación guardada, obteniendo ubicación actual',
        );
        await _getCurrentLocationWeather();
      }
    } catch (e) {
      LoggerService.error('Error cargando ubicación guardada: $e');
      await _getCurrentLocationWeather();
    }
  }

  void _listenForHeaderLocationUpdates() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final lastUpdate = prefs.getInt('location_update_timestamp') ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        if (currentTime - lastUpdate < 5000 && lastUpdate > 0) {
          final lat = prefs.getDouble('selected_latitude');
          final lng = prefs.getDouble('selected_longitude');
          final location = prefs.getString('selected_location');

          if (lat != null && lng != null && location != null) {
            await _getWeatherForLocation(lat, lng, location);
            await _getHourlyForecast(lat, lng, location);
            await prefs.remove('location_update_timestamp');
          }
        }
      } catch (e) {
        LoggerService.error('Error en listener de ubicación: $e');
      }
    });
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String locationName = 'Mi ubicación';
      try {
        LoggerService.info(
          'Iniciando geocodificación inversa para: ${position.latitude}, ${position.longitude}',
        );
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        LoggerService.info('Placemarks obtenidos: ${placemarks.length}');

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          LoggerService.info(
            'Placemark: locality=${placemark.locality}, subLocality=${placemark.subLocality}, subAdministrativeArea=${placemark.subAdministrativeArea}, administrativeArea=${placemark.administrativeArea}, country=${placemark.country}',
          );

          // Construir el nombre en formato ciudad, departamento
          String city = '';
          String department = '';

          // Obtener ciudad (locality, subLocality, o subAdministrativeArea)
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            city = placemark.locality!;
          } else if (placemark.subLocality != null &&
              placemark.subLocality!.isNotEmpty) {
            city = placemark.subLocality!;
          } else if (placemark.subAdministrativeArea != null &&
              placemark.subAdministrativeArea!.isNotEmpty) {
            city = placemark.subAdministrativeArea!;
          }

          // Obtener departamento (administrativeArea)
          if (placemark.administrativeArea != null &&
              placemark.administrativeArea!.isNotEmpty) {
            department = placemark.administrativeArea!;
          }

          LoggerService.info(
            'Ciudad extraída: $city, Departamento extraído: $department',
          );

          // Construir el nombre final
          if (city.isNotEmpty && department.isNotEmpty) {
            locationName = '$city, $department';
          } else if (city.isNotEmpty) {
            locationName = city;
          } else if (department.isNotEmpty) {
            locationName = department;
          } else {
            locationName = 'Mi ubicación';
          }

          LoggerService.info('Nombre de ubicación final: $locationName');
        } else {
          LoggerService.warning(
            'No se encontraron placemarks para las coordenadas',
          );
        }
      } catch (e) {
        LoggerService.error('Error obteniendo nombre de ubicación: $e');
        locationName = 'Mi ubicación';
      }

      await _getWeatherForLocation(
        position.latitude,
        position.longitude,
        locationName,
      );
      await _getHourlyForecast(
        position.latitude,
        position.longitude,
        locationName,
      );
    } catch (e) {
      LoggerService.error('Error obteniendo ubicación actual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getWeatherForLocation(
    double lat,
    double lng,
    String locationName,
  ) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final weatherData = await _weatherService.getWeatherData(
        lat,
        lng,
        locationName,
      );

      if (mounted) {
        final weatherProvider = Provider.of<WeatherStateProvider>(
          context,
          listen: false,
        );
        weatherProvider.updateWeather(weatherData, locationName);
      }
    } catch (e) {
      LoggerService.error('Error obteniendo clima: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error obteniendo clima: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _getHourlyForecast(
    double lat,
    double lng,
    String locationName,
  ) async {
    try {
      final weatherProvider = Provider.of<WeatherStateProvider>(
        context,
        listen: false,
      );
      weatherProvider.setLoadingHourly(true);

      final hourlyData = await _weatherService.getHourlyForecast(
        lat,
        lng,
        locationName,
      );

      if (mounted) {
        weatherProvider.updateHourlyForecast(hourlyData);
      }
    } catch (e) {
      LoggerService.error('Error obteniendo pronóstico por horas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherStateProvider>(
      builder: (context, weatherProvider, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildMainWeatherCard(weatherProvider),
                const SizedBox(height: 16),
                _buildHourlyForecast(weatherProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainWeatherCard(WeatherStateProvider weatherProvider) {
    if (_isLoadingWeather || _isLoadingLocation || weatherProvider.isLoading) {
      return _buildLoadingCard();
    }

    if (weatherProvider.errorMessage != null) {
      return _buildErrorCard(weatherProvider.errorMessage!);
    }

    if (!weatherProvider.hasWeatherData) {
      return _buildNoDataCard();
    }

    final weather = weatherProvider.selectedWeatherData!;
    final location = weatherProvider.currentLocation;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: _getWeatherGradient(weather.description),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildBackgroundElements(weather),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header con ubicación
                Flexible(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),

                // Sección central con temperatura e icono
                Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icono del clima
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _getWeatherIcon(weather.description),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Temperatura
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${weather.temperature.round()}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            Text(
                              '${(weather.temperature * 9 / 5 + 32).round()} F',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer con día
                Flexible(
                  child: Text(
                    _formatDay(DateTime.now()),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElements(WeatherData weather) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            _getBackgroundIcon(weather.description),
            style: const TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(WeatherStateProvider weatherProvider) {
    if (weatherProvider.isLoadingHourly) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!weatherProvider.hasHourlyForecast) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Pronóstico por horas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: weatherProvider.hourlyForecast!.length.clamp(0, 12),
              itemBuilder: (context, index) {
                final hourData = weatherProvider.hourlyForecast![index];
                return _buildHourlyItem(hourData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyItem(WeatherData hourData) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Text(
              _formatHour(hourData.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Flexible(
            flex: 2,
            child: Text(
              _getWeatherIcon(hourData.description),
              style: const TextStyle(fontSize: 24),
            ),
          ),

          Flexible(
            child: Text(
              '${hourData.temperature.round()}°',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el clima',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF90A4AE), Color(0xFF607D8B)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌤️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No hay datos del clima',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getWeatherGradient(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('rain') ||
        desc.contains('lluvia') ||
        desc.contains('drizzle')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4FC3F7), Color(0xFF1976D2)],
      );
    } else if (desc.contains('cloud') ||
        desc.contains('nublado') ||
        desc.contains('overcast')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF78909C), Color(0xFF455A64)],
      );
    } else if (desc.contains('sun') ||
        desc.contains('despejado') ||
        desc.contains('clear')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB74D), Color(0xFFFF8F00)],
      );
    } else if (desc.contains('partly') || desc.contains('parcialmente')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF81C784), Color(0xFFFFB74D)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF81C784), Color(0xFF388E3C)],
      );
    }
  }

  String _getWeatherDescription(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('rain') ||
        desc.contains('lluvia') ||
        desc.contains('drizzle')) {
      return 'Rainy';
    } else if (desc.contains('cloud') ||
        desc.contains('nublado') ||
        desc.contains('overcast')) {
      return 'Cloudy';
    } else if (desc.contains('sun') ||
        desc.contains('despejado') ||
        desc.contains('clear')) {
      return 'Sunny';
    } else if (desc.contains('partly') || desc.contains('parcialmente')) {
      return 'Partly Cloudy';
    } else {
      return 'Pleasant';
    }
  }

  String _getWeatherIcon(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('rain') ||
        desc.contains('lluvia') ||
        desc.contains('drizzle')) {
      return '🌧️';
    } else if (desc.contains('cloud') ||
        desc.contains('nublado') ||
        desc.contains('overcast')) {
      return '☁️';
    } else if (desc.contains('sun') ||
        desc.contains('despejado') ||
        desc.contains('clear')) {
      return '☀️';
    } else if (desc.contains('partly') || desc.contains('parcialmente')) {
      return '⛅';
    } else {
      return '🌤️';
    }
  }

  String _getBackgroundIcon(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('rain') ||
        desc.contains('lluvia') ||
        desc.contains('drizzle')) {
      return '💧';
    } else if (desc.contains('cloud') ||
        desc.contains('nublado') ||
        desc.contains('overcast')) {
      return '☁️';
    } else if (desc.contains('sun') ||
        desc.contains('despejado') ||
        desc.contains('clear')) {
      return '☀️';
    } else if (desc.contains('partly') || desc.contains('parcialmente')) {
      return '⛅';
    } else {
      return '🌤️';
    }
  }

  String _formatDay(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[date.weekday % 7];
  }

  String _formatHour(DateTime date) {
    final hour = date.hour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
