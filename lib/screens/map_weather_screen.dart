import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
import '../services/logger_service.dart';
import '../services/weather_state_provider.dart';

class MapWeatherScreen extends StatefulWidget {
  const MapWeatherScreen({super.key});

  @override
  State<MapWeatherScreen> createState() => _MapWeatherScreenState();
}

class _MapWeatherScreenState extends State<MapWeatherScreen> {
  final MapController _mapController = MapController();
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  
  // Estado del mapa y ubicación
  LatLng _currentPosition = const LatLng(4.7110, -74.0721); // Bogotá por defecto
  List<Marker> _markers = [];
  WeatherData? _currentWeatherData;
  bool _isLoadingWeather = false;
  bool _isLoadingLocation = true;
  bool _showSearchBar = false;
  bool _showMyLocationMarker = false;
  double _currentZoom = 12.0;
  String _mapType = 'standard';
  String? _errorMessage;
  
  // Variables para persistencia
  LatLng? _selectedPosition;
  String? _selectedLocationName;
  bool _hasSelectedLocation = false;

  // Tipos de mapa disponibles
  final Map<String, String> _mapTypes = {
    'standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    'terrain': 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Inicializar el mapa con ubicación actual y clima
  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    if (mounted) {
      // Cargar clima para la ubicación inicial (punto fijo)
      await _getWeatherForLocation(_currentPosition);
    }
  }

  /// Obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _errorMessage = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Los servicios de ubicación están deshabilitados';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permisos de ubicación denegados';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados permanentemente';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _showMyLocationMarker = true;
      });

      // Mover el mapa a la ubicación actual
      _mapController.move(_currentPosition, _currentZoom);
    } catch (e) {
      LoggerService.error('Error obteniendo ubicación: $e');
      setState(() {
        _errorMessage = 'Error obteniendo ubicación: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  /// Obtener datos del clima para una ubicación específica
  Future<void> _getWeatherForLocation(LatLng position) async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = null;
    });

    try {
      // Obtener nombre de la ubicación
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      String locationName = 'Ubicación desconocida';
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Construir el nombre en formato ciudad, departamento
        String city = '';
        String department = '';
        
        // Obtener ciudad (locality, subLocality, o subAdministrativeArea)
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          city = placemark.locality!;
        } else if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          city = placemark.subLocality!;
        } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
          city = placemark.subAdministrativeArea!;
        }
        
        // Obtener departamento (administrativeArea)
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
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
          locationName = 'Ubicación desconocida';
        }
      }

      // Obtener datos del clima
      final weatherData = await _weatherService.getWeatherData(
        position.latitude,
        position.longitude,
        locationName,
      );

      if (weatherData != null) {
        // Guardar datos en el estado global
        final weatherProvider = Provider.of<WeatherStateProvider>(context, listen: false);
        weatherProvider.updateSelectedWeather(weatherData);
        
        setState(() {
          _currentWeatherData = weatherData;
          _markers = [
            Marker(
              point: position,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showWeatherDetails(weatherData),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getWeatherColor(weatherData.temperature),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weatherData.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      Text(
                        '${weatherData.temperature.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron obtener datos del clima';
        });
      }
    } catch (e) {
      LoggerService.error('Error obteniendo datos del clima: $e');
      setState(() {
        _errorMessage = 'Error obteniendo datos del clima: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  /// Obtener color del marcador basado en la temperatura
  Color _getWeatherColor(double temperature) {
    if (temperature < 0) return Colors.blue.shade700;
    if (temperature < 10) return Colors.blue.shade500;
    if (temperature < 20) return Colors.green.shade500;
    if (temperature < 30) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  /// Buscar ubicación por nombre
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa una ubicación para buscar';
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _errorMessage = null;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = LatLng(location.latitude, location.longitude);
        
        // Mover el mapa a la nueva ubicación
        _mapController.move(position, 12);
        
        // Obtener clima para la nueva ubicación
        await _getWeatherForLocation(position);
        
        setState(() => _showSearchBar = false);
        _searchController.clear();
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ubicación encontrada: $query'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'No se encontró la ubicación: $query';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró la ubicación: $query'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error buscando ubicación: $e');
      setState(() {
        _errorMessage = 'Error buscando ubicación. Verifica tu conexión a internet.';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al buscar la ubicación. Verifica tu conexión a internet.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  /// Mostrar detalles del clima en un modal
  void _showWeatherDetails(WeatherData weatherData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Weather content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getWeatherColor(weatherData.temperature),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            weatherData.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weatherData.temperature.round()}°C',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                weatherData.description,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Location
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              weatherData.locationName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Weather details grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildWeatherDetailCard(
                            'Humedad',
                            '${weatherData.humidity.round()}%',
                            Icons.water_drop,
                            Colors.blue,
                          ),
                          _buildWeatherDetailCard(
                            'Viento',
                            '${weatherData.windSpeed.round()} km/h',
                            Icons.air,
                            Colors.green,
                          ),
                          _buildWeatherDetailCard(
                            'Latitud',
                            weatherData.latitude.toStringAsFixed(4),
                            Icons.gps_fixed,
                            Colors.orange,
                          ),
                          _buildWeatherDetailCard(
                            'Longitud',
                            weatherData.longitude.toStringAsFixed(4),
                            Icons.gps_fixed,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Manejar tap en el mapa
  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    _selectLocation(position);
  }
  
  /// Seleccionar una ubicación en el mapa
  void _selectLocation(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _hasSelectedLocation = true;
    });
    
    // Obtener el nombre de la ubicación
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Construir el nombre en formato ciudad, departamento
        String city = '';
        String department = '';
        
        // Obtener ciudad (locality, subLocality, o subAdministrativeArea)
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          city = placemark.locality!;
        } else if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          city = placemark.subLocality!;
        } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
          city = placemark.subAdministrativeArea!;
        }
        
        // Obtener departamento (administrativeArea)
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          department = placemark.administrativeArea!;
        }
        
        // Construir el nombre final
        if (city.isNotEmpty && department.isNotEmpty) {
          _selectedLocationName = '$city, $department';
        } else if (city.isNotEmpty) {
          _selectedLocationName = city;
        } else if (department.isNotEmpty) {
          _selectedLocationName = department;
        } else {
          _selectedLocationName = 'Ubicación seleccionada';
        }
      } else {
        _selectedLocationName = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      _selectedLocationName = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    }
    
    // Obtener datos del clima para la ubicación seleccionada
    _getWeatherForLocation(position);
  }

  /// Controles de zoom
  void _zoomIn() {
    setState(() => _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0));
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  void _zoomOut() {
    setState(() => _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0));
    _mapController.move(_mapController.camera.center, _currentZoom);
  }

  /// Mover la cámara a la ubicación actual
  void _goToCurrentLocation() async {
    if (_currentPosition == const LatLng(4.7110, -74.0721)) {
      // Si aún tenemos la ubicación por defecto, obtener la ubicación real
      await _getCurrentLocation();
    }
    
    if (_currentPosition != const LatLng(4.7110, -74.0721)) {
      setState(() {
        _showMyLocationMarker = true;
      });
      _mapController.move(_currentPosition, 15.0); // Zoom más cercano para ubicación actual
      await _getWeatherForLocation(_currentPosition);
    } else {
      setState(() {
        _errorMessage = 'No se pudo obtener la ubicación actual';
      });
    }
  }

  /// Confirmar y persistir la ubicación seleccionada
  void _confirmLocation() async {
    if (_selectedPosition == null || _selectedLocationName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('selected_latitude', _selectedPosition!.latitude);
      await prefs.setDouble('selected_longitude', _selectedPosition!.longitude);
      await prefs.setString('selected_location_name', _selectedLocationName!);
      await prefs.setBool('has_selected_location', true);

      // Actualizar el estado global del clima
      final weatherProvider = Provider.of<WeatherStateProvider>(context, listen: false);
      if (_currentWeatherData != null) {
        weatherProvider.updateSelectedWeather(_currentWeatherData!);
      }

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ubicación confirmada: $_selectedLocationName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Regresar al dashboard
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la ubicación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Cambiar tipo de mapa
  void _changeMapType() {
    setState(() {
      switch (_mapType) {
        case 'standard':
          _mapType = 'satellite';
          break;
        case 'satellite':
          _mapType = 'terrain';
          break;
        case 'terrain':
          _mapType = 'standard';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clima en Mapa',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSans',
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            tooltip: _showSearchBar ? 'Cerrar búsqueda' : 'Buscar ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'Mi ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _changeMapType,
            tooltip: 'Cambiar tipo de mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa con OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: _currentZoom,
              onTap: _onMapTapped,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _currentZoom = position.zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _mapTypes[_mapType]!,
                userAgentPackageName: 'com.example.agrotrack',
                maxZoom: 18,
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  // Marcador de "Mi ubicación"
                  if (_showMyLocationMarker)
                    Marker(
                      point: _currentPosition,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Barra de búsqueda
          if (_showSearchBar)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar ubicación...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
            ),

          // Controles de zoom
          Positioned(
            right: 16,
            top: _showSearchBar ? 80 : 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Indicador de tipo de mapa
          Positioned(
            left: 16,
            top: _showSearchBar ? 80 : 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _mapType == 'standard' ? 'Estándar' : 
                _mapType == 'satellite' ? 'Satélite' : 'Terreno',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Indicador de carga de ubicación
          if (_isLoadingLocation)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Obteniendo ubicación...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Indicador de carga del clima
          if (_isLoadingWeather)
            Positioned(
              bottom: _currentWeatherData != null ? 180 : 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Obteniendo datos del clima...'),
                  ],
                ),
              ),
            ),

          // Mensaje de error
          if (_errorMessage != null)
            Positioned(
              bottom: _currentWeatherData != null ? 180 : 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _errorMessage = null),
                      color: Colors.red.shade600,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),

          // Panel de información del clima actual
          if (_currentWeatherData != null && !_isLoadingWeather)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getWeatherColor(_currentWeatherData!.temperature),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentWeatherData!.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentWeatherData!.temperature.round()}°C',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentWeatherData!.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showWeatherDetails(_currentWeatherData!),
                              tooltip: 'Ver detalles',
                            ),
                            Text(
                              'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentWeatherData!.locationName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '💨 ${_currentWeatherData!.windSpeed.round()} km/h',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '💧 ${_currentWeatherData!.humidity.round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Instrucciones de uso
          if (_currentWeatherData == null && !_isLoadingWeather && !_isLoadingLocation && _errorMessage == null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca cualquier lugar en el mapa para ver el clima',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Usa los controles de zoom y busca ubicaciones',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Botón de confirmar ubicación
          if (_hasSelectedLocation)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmLocation,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    'Confirmar ubicación: ${_selectedLocationName ?? 'Seleccionada'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}