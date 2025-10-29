import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/global_location_service.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _currentLocation = const LatLng(4.7110, -74.0721); // Bogotá por defecto
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  bool _isLoading = false;
  bool _isSearching = false;
  List<GlobalLocationData> _searchResults = [];
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.length >= 3) {
        _searchLocations(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

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

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
      });

      _mapController.move(_currentLocation, 13.0);
      await _getLocationName(_currentLocation);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error obteniendo ubicación: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocationName(LatLng location) async {
    try {
      final locationData = await GlobalLocationService.getLocationFromCoordinates(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _selectedLocationName = locationData?.displayName ?? 'Ubicación desconocida';
      });
    } catch (e) {
      setState(() {
        _selectedLocationName = 'Ubicación desconocida';
      });
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await GlobalLocationService.searchLocations(query, limit: 10);
      setState(() {
        _searchResults = results;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error buscando ubicaciones: ${e.toString()}';
        _searchResults = [];
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedLocationName = null;
      _searchResults = [];
    });
    
    _getLocationName(point);
  }

  void _selectSearchResult(GlobalLocationData location) {
    final latLng = LatLng(location.latitude, location.longitude);
    
    setState(() {
      _selectedLocation = latLng;
      _selectedLocationName = location.displayName;
      _searchResults = [];
      _searchController.clear();
    });

    _mapController.move(latLng, 15.0);
    
    // Navegar automáticamente de vuelta con la ubicación seleccionada
    _confirmLocation();
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      final result = {
        'location': _selectedLocation,
        'locationName': _selectedLocationName ?? 'Ubicación seleccionada',
      };
      print('DEBUG: Confirmando ubicación - enviando: $result');
      Navigator.pop(context, result);
    } else {
      print('DEBUG: _selectedLocation es null, no se puede confirmar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
              tooltip: 'Confirmar ubicación',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar ubicación en el mundo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),

                ),
              ],
            ),
          ),

          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              color: Colors.white,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.green),
                    title: Text(location.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.displayName),
                        if (location.country?.isNotEmpty == true)
                          Text(
                            location.country!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _selectSearchResult(location),
                  );
                },
              ),
            ),

          // Mapa
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 6.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    // Sin restricciones geográficas para permitir búsqueda mundial
                    onTap: _onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.agro',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Indicador de carga
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Botón para centrar en ubicación actual
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(_currentLocation, 13.0);
                    },
                    child: Icon(Icons.my_location, color: Colors.green[700]),
                  ),
                ),

                // Botón de confirmación
                if (_selectedLocation != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      onPressed: _confirmLocation,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar Ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}