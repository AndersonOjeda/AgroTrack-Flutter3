import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../services/logger_service.dart';
import '../services/weather_state_provider.dart';

class SimpleWeatherWidget extends StatefulWidget {
  const SimpleWeatherWidget({super.key});

  @override
  State<SimpleWeatherWidget> createState() => _SimpleWeatherWidgetState();
}

class _SimpleWeatherWidgetState extends State<SimpleWeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _locationController = TextEditingController();
  Timer? _prefsTimer;
  int _lastUpdateTimestamp = 0;

  @override
  void initState() {
    super.initState();
    // Solo cargar clima actual si no hay datos previos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherProvider = Provider.of<WeatherStateProvider>(
        context,
        listen: false,
      );
      if (!weatherProvider.hasWeatherData) {
        _getCurrentLocationWeather();
      }
      _startPreferencesListener();
    });
  }

  void _startPreferencesListener() {
    // Verificar cambios en SharedPreferences cada segundo
    _prefsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkForLocationUpdates();
    });
  }

  Future<void> _checkForLocationUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('location_update_timestamp') ?? 0;

      if (timestamp > _lastUpdateTimestamp) {
        _lastUpdateTimestamp = timestamp;

        final lat = prefs.getDouble('selected_latitude');
        final lng = prefs.getDouble('selected_longitude');
        final locationName = prefs.getString('selected_location');

        if (lat != null && lng != null && locationName != null) {
          LoggerService.info(
            'Detectado cambio de ubicación desde SharedPreferences: $locationName',
          );
          await _updateWeatherFromPreferences(lat, lng, locationName);
        }
      }
    } catch (e) {
      LoggerService.error('Error verificando actualizaciones de ubicación: $e');
    }
  }

  Future<void> _updateWeatherFromPreferences(
    double lat,
    double lng,
    String locationName,
  ) async {
    final weatherProvider = Provider.of<WeatherStateProvider>(
      context,
      listen: false,
    );

    try {
      weatherProvider.setLoading(true);

      final weatherData = await _weatherService.getWeatherData(
        lat,
        lng,
        locationName,
      );

      if (weatherData != null) {
        weatherProvider.updateSelectedWeather(weatherData);
        LoggerService.info(
          'Widget de clima actualizado desde SharedPreferences: $locationName',
        );
      } else {
        weatherProvider.setError('No se pudieron obtener los datos del clima');
      }
    } catch (e) {
      LoggerService.error(
        'Error actualizando clima desde SharedPreferences: $e',
      );
      weatherProvider.setError('Error al obtener el clima: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _prefsTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocationWeather() async {
    final weatherProvider = Provider.of<WeatherStateProvider>(
      context,
      listen: false,
    );
    weatherProvider.setLoading(true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        weatherProvider.setError('Servicios de ubicación deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          weatherProvider.setError('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        weatherProvider.setError(
          'Permisos de ubicación denegados permanentemente',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      // Obtener nombre de la ubicación
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Mi ubicación';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
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
      }

      final weatherData = await _weatherService.getWeatherData(
        position.latitude,
        position.longitude,
        locationName,
      );

      if (weatherData != null) {
        weatherProvider.updateWeather(weatherData, locationName);
      } else {
        weatherProvider.setError('No se pudieron obtener los datos del clima');
      }
    } catch (e) {
      LoggerService.error('Error obteniendo clima actual: $e');
      weatherProvider.setError('Error al obtener el clima: ${e.toString()}');
    }
  }

  Future<void> _searchLocationWeather() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) return;

    final weatherProvider = Provider.of<WeatherStateProvider>(
      context,
      listen: false,
    );
    weatherProvider.setLoading(true);

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final weatherData = await _weatherService.getWeatherData(
          location.latitude,
          location.longitude,
          query,
        );

        if (weatherData != null) {
          weatherProvider.updateWeather(weatherData, query);
        } else {
          weatherProvider.setError(
            'No se pudieron obtener los datos del clima para esta ubicación',
          );
        }
      } else {
        weatherProvider.setError('No se encontró la ubicación especificada');
      }
    } catch (e) {
      LoggerService.error('Error buscando ubicación: $e');
      weatherProvider.setError('Error al buscar la ubicación: ${e.toString()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar la ubicación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar ubicación'),
        content: TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'Ej: Bogotá, Colombia',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            Navigator.of(context).pop();
            _searchLocationWeather();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchLocationWeather();
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherStateProvider>(
      builder: (context, weatherProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: weatherProvider.isLoading
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando clima...'),
                  ],
                )
              : weatherProvider.hasWeatherData
              ? Row(
                  children: [
                    // Icono del clima
                    Text(
                      weatherProvider.weatherIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),

                    // Información del clima
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherProvider.weatherSummary,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            weatherProvider.currentLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'Datos del mapa sincronizados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botones de acción
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, size: 20),
                          onPressed: _showLocationSearch,
                          tooltip: 'Buscar ubicación',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          onPressed: _getCurrentLocationWeather,
                          tooltip: 'Mi ubicación',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : weatherProvider.errorMessage != null
              ? Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error al cargar clima',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            weatherProvider.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _getCurrentLocationWeather,
                      tooltip: 'Reintentar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Widget del clima',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Toca en el mapa o busca una ubicación',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, size: 20),
                          onPressed: _showLocationSearch,
                          tooltip: 'Buscar ubicación',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          onPressed: _getCurrentLocationWeather,
                          tooltip: 'Mi ubicación',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
