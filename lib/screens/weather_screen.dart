import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/weather_location_service.dart';
import '../models/weather_location.dart';
import 'weather_locations_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _weatherData;
  double? _currentLat;
  double? _currentLng;
  final WeatherLocationService _locationService = WeatherLocationService();
  WeatherLocation? _currentLocation;
  List<WeatherLocation> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _initializeWeather();
  }

  Future<void> _initializeWeather() async {
    await _locationService.initialize();
    _savedLocations = _locationService.savedLocations;
    final savedLocation = _locationService.currentLocation;
    
    if (savedLocation != null) {
      _loadWeatherFromLocation(savedLocation);
    } else {
      _loadCurrentLocationWeather();
    }
  }

  Future<void> _loadWeatherFromLocation(WeatherLocation location) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentLocation = location;
    });

    try {
      final weatherResponse = await WeatherService.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      setState(() {
        _weatherData = weatherResponse;
        _currentLat = location.latitude;
        _currentLng = location.longitude;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando datos del clima: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener ubicación actual
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Los servicios de ubicación están deshabilitados';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Permisos de ubicación denegados';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permisos de ubicación denegados permanentemente';
          _isLoading = false;
        });
        return;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // Obtener datos del clima
      final weatherResponse = await WeatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _weatherData = weatherResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando datos del clima: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWeather() async {
    if (_currentLat != null && _currentLng != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final weatherResponse = await WeatherService.getCurrentWeather(
          latitude: _currentLat!,
          longitude: _currentLng!,
        );

        setState(() {
          _weatherData = weatherResponse;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Error actualizando datos del clima: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onLocationChanged(WeatherLocation? newLocation) async {
    if (newLocation != null && newLocation != _currentLocation) {
      await _locationService.setCurrentLocation(newLocation.id);
      _loadWeatherFromLocation(newLocation);
    }
  }

  Future<void> _openLocationManager() async {
    final selectedLocation = await Navigator.of(context).push<WeatherLocation>(
      MaterialPageRoute(
        builder: (context) => const WeatherLocationsScreen(),
      ),
    );

    if (selectedLocation != null) {
      _loadWeatherFromLocation(selectedLocation);
    } else {
      // Recargar la ubicación actual en caso de cambios
      await _locationService.initialize();
      setState(() {
        _savedLocations = _locationService.savedLocations;
      });
      final currentLocation = _locationService.currentLocation;
      if (currentLocation != null && currentLocation != _currentLocation) {
        _loadWeatherFromLocation(currentLocation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _openLocationManager,
            tooltip: 'Gestionar ubicaciones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshWeather,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos del clima...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentLocationWeather,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_weatherData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No hay datos del clima disponibles'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _buildWeatherCard(),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final main = _weatherData?['main'];
    final weather = _weatherData?['weather'];
    final wind = _weatherData?['wind'];
    
    if (main == null || weather == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Datos del clima no disponibles'),
        ),
      );
    }

    final temperature = main['temp']?.round().toString() ?? '--';
    final condition = weather.isNotEmpty ? weather[0]['description'] ?? 'Desconocido' : 'Desconocido';
    final humidity = main['humidity']?.toString() ?? '--';
    final windSpeed = wind?['speed']?.toDouble() ?? 0.0;
    final windKph = (windSpeed * 3.6).round().toString(); // Convertir m/s a km/h
    final feelsLike = main['feels_like']?.round().toString() ?? '--';
    final locationName = _currentLocation?.name ?? _weatherData?['name'] ?? 'Ubicación actual';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ubicación con dropdown
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: _savedLocations.isNotEmpty
                      ? DropdownButtonHideUnderline(
                          child: DropdownButton<WeatherLocation>(
                            value: _currentLocation,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            items: _savedLocations.map((WeatherLocation location) {
                              return DropdownMenuItem<WeatherLocation>(
                                value: location,
                                child: Text(
                                  location.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _onLocationChanged,
                          ),
                        )
                      : Text(
                          locationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Temperatura principal
            Center(
              child: Column(
                children: [
                  Text(
                    '$temperature°C',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    condition,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Detalles del clima
            _buildWeatherDetail('Sensación térmica', '$feelsLike°C', Icons.thermostat),
            const SizedBox(height: 12),
            _buildWeatherDetail('Humedad', '$humidity%', Icons.water_drop),
            const SizedBox(height: 12),
            _buildWeatherDetail('Viento', '$windKph km/h', Icons.air),
            
            const SizedBox(height: 20),
            
            // Coordenadas
            if (_currentLat != null && _currentLng != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Lat: ${_currentLat!.toStringAsFixed(4)}, Lng: ${_currentLng!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}