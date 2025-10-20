import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../widgets/weather_widget.dart';
import 'ProfileScreen.dart';

class LocationSuggestion {
  final String display;
  final double lat;
  final double lng;
  LocationSuggestion({required this.display, required this.lat, required this.lng});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();
  final List<LocationSuggestion> _suggestions = [];
  Timer? _searchDebounce;
  bool _showSuggestions = false;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _locationFocus.addListener(() {
      if (!_locationFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature: próximamente')),
    );
  }

  void _onLocationChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _fetchLocationSuggestionsOSM(query);
      setState(() {
        _suggestions
          ..clear()
          ..addAll(results);
        _showSuggestions = _suggestions.isNotEmpty;
      });
    });
  }

  Future<List<LocationSuggestion>> _fetchLocationSuggestionsOSM(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'co',
        'q': query,
      });
      final resp = await http.get(uri, headers: {
        'User-Agent': 'AgroTrack/1.0 (+https://example.com)'
      });
      if (resp.statusCode != 200) return [];
      final List data = jsonDecode(resp.body) as List;
      final List<LocationSuggestion> suggestions = [];
      for (final item in data) {
        final addr = item['address'] ?? {};
        final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? addr['municipality'] ?? '').toString();
        final state = (addr['state'] ?? addr['region'] ?? addr['county'] ?? '').toString();
        final display = [city, state].where((e) => e.isNotEmpty).join(', ');
        final lat = double.tryParse(item['lat']?.toString() ?? '0');
        final lng = double.tryParse(item['lon']?.toString() ?? '0');
        if (display.isNotEmpty && lat != null && lng != null) {
          // Evitar duplicados exactos
          if (!suggestions.any((s) => s.display == display)) {
            suggestions.add(LocationSuggestion(display: display, lat: lat, lng: lng));
          }
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activa los servicios de ubicación')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de ubicación denegado')));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final display = await _reverseGeocodeOSM(pos.latitude, pos.longitude);
      setState(() {
        _locationController.text = display;
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
        _showSuggestions = false;
      });
      if (display.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ubicación detectada: $display')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error obteniendo ubicación: $e')));
    }
  }

  Future<String> _reverseGeocodeOSM(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'json',
        'addressdetails': '1',
        'zoom': '12',
        'lat': lat.toString(),
        'lon': lng.toString(),
        'accept-language': 'es',
        'countrycodes': 'co',
      });
      final resp = await http.get(uri, headers: {
        'User-Agent': 'AgroTrack/1.0 (+https://example.com)'
      });
      if (resp.statusCode != 200) return '';
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] ?? {};
      final rawCity = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? addr['municipality'] ?? '').toString();
      String rawState = (addr['state'] ?? addr['region'] ?? addr['county'] ?? '').toString();
      // Normalizar estados tipo "Departamento de Nariño"
      rawState = rawState.replaceFirst(RegExp(r'^Departamento\s+de\s+', caseSensitive: false), '');
      final display = [rawCity, rawState].where((e) => e.isNotEmpty).join(', ');
      return display;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Clima', 'icon': Icons.wb_sunny},
      {'label': 'Cultivos', 'icon': Icons.eco},
      {'label': 'Inventario', 'icon': Icons.inventory},
      {'label': 'Tareas', 'icon': Icons.task_alt},
      {'label': 'Finanzas', 'icon': Icons.attach_money},
      {'label': 'Reportes', 'icon': Icons.bar_chart},
      {'label': 'Mercado', 'icon': Icons.store},
      {'label': 'Configuración', 'icon': Icons.settings},
    ];

    final size = MediaQuery.of(context).size;
    final headerHeight = (size.height / 7).clamp(200.0, 260.0);
    final now = DateTime.now();
    final greeting = () {
      final h = now.hour;
      if (h < 12) return 'Buenos días';
      if (h < 18) return 'Buenas tardes';
      return 'Buenas noches';
    }();
    final fecha = DateFormat('EEEE, dd MMM yyyy', 'es_ES').format(now);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header 1/7 de pantalla
            SizedBox(
              width: double.infinity,
              height: headerHeight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Hola, ', style: TextStyle(color: Colors.white)),
                                  TextSpan(
                                    text: greeting,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              style: Theme.of(context).textTheme.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fecha[0].toUpperCase() + fecha.substring(1),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(Icons.search, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              focusNode: _locationFocus,
                              onChanged: _onLocationChanged,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'Buscar ubicación...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.white),
                            onPressed: _useCurrentLocation,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showSuggestions)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final s = _suggestions[index];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _locationController.text = s.display;
                                  _selectedLat = s.lat;
                                  _selectedLng = s.lng;
                                  _showSuggestions = false;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, color: Colors.white70, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.display,
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contenido: barra de navegación vertical + clima + grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de navegación vertical con iconos
                    Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            for (final item in items) ...[
                              IconButton(
                                tooltip: item['label'] as String,
                                icon: Icon(item['icon'] as IconData),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () => _comingSoon(context, item['label'] as String),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Panel derecho: clima arriba + grid abajo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Widget de clima
                          WeatherWidget(
                            latitude: _selectedLat,
                            longitude: _selectedLng,
                            locationName: _locationController.text.isNotEmpty ? _locationController.text : null,
                          ),
                          const SizedBox(height: 8),

                          // Grid de funciones
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return InkWell(
                                  onTap: () => _comingSoon(context, item['label'] as String),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          size: 48,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          item['label'] as String,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
}