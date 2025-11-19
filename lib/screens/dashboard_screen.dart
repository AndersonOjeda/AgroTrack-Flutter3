import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'chat_bot.dart';
import 'inventory_screen.dart';
import 'map_weather_screen.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/weather_state_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/dashboard_weather_widget.dart';
import '../widgets/requirement_status_card.dart';

class LocationSuggestion {
  final String display;
  final double lat;
  final double lng;
  LocationSuggestion({
    required this.display,
    required this.lat,
    required this.lng,
  });
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
  final List<LocationData> _colombianSuggestions = [];
  Timer? _searchDebounce;
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false; // Bandera para evitar conflictos
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature: próximamente')));
  }

  void _handleNavigation(BuildContext context, String action, String label) {
    switch (action) {
      case 'chatbot':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatBot()),
        );
        break;
      case 'climate':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapWeatherScreen()),
        );
        break;
      case 'inventory':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
        break;
      case 'coming_soon':
      default:
        _comingSoon(context, label);
        break;
    }
  }

  void _onLocationChanged(String query) {
    // Si estamos seleccionando una sugerencia, no procesar cambios
    if (_isSelectingSuggestion) {
      return;
    }

    _searchDebounce?.cancel();

    // Permitir que el usuario escriba libremente sin restricciones
    // Solo limpiar sugerencias si el texto está vacío
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
        _colombianSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    // Si el texto es muy corto (menos de 2 caracteres), no mostrar sugerencias
    // pero permitir que el usuario siga escribiendo
    if (query.trim().length < 2) {
      setState(() {
        _suggestions.clear();
        _colombianSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    // Búsqueda inmediata en ciudades colombianas
    final colombianResults = LocationService.searchCities(query);

    setState(() {
      _colombianSuggestions
        ..clear()
        ..addAll(colombianResults.take(8)); // Limitar a 8 resultados
      _showSuggestions = _colombianSuggestions.isNotEmpty;
    });

    // Búsqueda con debounce en OpenStreetMap como respaldo
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length >= 3) {
        final osmResults = await _fetchLocationSuggestionsOSM(query);
        setState(() {
          _suggestions
            ..clear()
            ..addAll(osmResults);
          // Solo mostrar OSM si no hay resultados colombianos
          if (_colombianSuggestions.isEmpty) {
            _showSuggestions = _suggestions.isNotEmpty;
          }
        });
      }
    });
  }

  void _onLocationSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      // Usar el texto ingresado directamente como ubicación
      setState(() {
        _showSuggestions = false;
        _suggestions.clear();
        _colombianSuggestions.clear();
        // Mantener el texto tal como lo escribió el usuario
        _locationController.text = value.trim();
        // Limpiar las coordenadas para indicar que es una ubicación manual
        _selectedLat = null;
        _selectedLng = null;
      });
      // Quitar el foco del campo de texto
      _locationFocus.unfocus();
    }
  }

  Future<List<LocationSuggestion>> _fetchLocationSuggestionsOSM(
    String query,
  ) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'co',
        'q': query,
      });
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'AgroTrack/1.0 (+https://example.com)'},
      );
      if (resp.statusCode != 200) return [];
      final List data = jsonDecode(resp.body) as List;
      final List<LocationSuggestion> suggestions = [];
      for (final item in data) {
        final addr = item['address'] ?? {};
        final city =
            (addr['city'] ??
                    addr['town'] ??
                    addr['village'] ??
                    addr['hamlet'] ??
                    addr['municipality'] ??
                    '')
                .toString();
        final state = (addr['state'] ?? addr['region'] ?? addr['county'] ?? '')
            .toString();
        final display = [city, state].where((e) => e.isNotEmpty).join(', ');
        final lat = double.tryParse(item['lat']?.toString() ?? '0');
        final lng = double.tryParse(item['lon']?.toString() ?? '0');
        if (display.isNotEmpty && lat != null && lng != null) {
          // Evitar duplicados exactos
          if (!suggestions.any((s) => s.display == display)) {
            suggestions.add(
              LocationSuggestion(display: display, lat: lat, lng: lng),
            );
          }
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  Widget _buildColombianSuggestionTile(LocationData location) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Activar bandera para evitar conflictos
          _isSelectingSuggestion = true;

          setState(() {
            _locationController.text = location.fullName;
            // Para ciudades colombianas, usamos coordenadas aproximadas
            _selectedLat = _getApproximateLatitude(location);
            _selectedLng = _getApproximateLongitude(location);
            _showSuggestions = false;
            _colombianSuggestions.clear();
            _suggestions.clear();
          });
          _locationFocus.unfocus();

          // Sincronizar con el widget de clima
          _updateWeatherWidget(_selectedLat!, _selectedLng!, location.fullName);

          // Navegar automáticamente al mapa
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapWeatherScreen()),
              );
            }
          });

          // Desactivar bandera después de un breve delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _isSelectingSuggestion = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.location_city,
                  color: Colors.green.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.city,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      location.department,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOSMSuggestionTile(LocationSuggestion suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Activar bandera para evitar conflictos
          _isSelectingSuggestion = true;

          setState(() {
            _locationController.text = suggestion.display;
            _selectedLat = suggestion.lat;
            _selectedLng = suggestion.lng;
            _showSuggestions = false;
            _colombianSuggestions.clear();
            _suggestions.clear();
          });
          _locationFocus.unfocus();

          // Sincronizar con el widget de clima
          _updateWeatherWidget(suggestion.lat, suggestion.lng, suggestion.display);

          // Navegar automáticamente al mapa
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapWeatherScreen()),
              );
            }
          });

          // Desactivar bandera después de un breve delay
          Future.delayed(const Duration(milliseconds: 100), () {
            _isSelectingSuggestion = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.place, color: Colors.blue.shade600, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.display,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getApproximateLatitude(LocationData location) {
    // Coordenadas aproximadas para las principales ciudades colombianas
    switch (location.city.toLowerCase()) {
      case 'bogotá':
        return 4.7110;
      case 'medellín':
        return 6.2442;
      case 'cali':
        return 3.4516;
      case 'barranquilla':
        return 10.9639;
      case 'cartagena':
        return 10.3910;
      case 'bucaramanga':
        return 7.1253;
      case 'pereira':
        return 4.8133;
      case 'santa marta':
        return 11.2408;
      case 'ibagué':
        return 4.4389;
      case 'cúcuta':
        return 7.8939;
      case 'pasto':
        return 1.2136;
      case 'manizales':
        return 5.0700;
      case 'neiva':
        return 2.9273;
      case 'villavicencio':
        return 4.1420;
      case 'armenia':
        return 4.5339;
      case 'valledupar':
        return 10.4631;
      case 'montería':
        return 8.7479;
      case 'sincelejo':
        return 9.3047;
      case 'popayán':
        return 2.4448;
      case 'tunja':
        return 5.5353;
      default:
        return 4.7110; // Bogotá por defecto
    }
  }

  double _getApproximateLongitude(LocationData location) {
    // Coordenadas aproximadas para las principales ciudades colombianas
    switch (location.city.toLowerCase()) {
      case 'bogotá':
        return -74.0721;
      case 'medellín':
        return -75.5812;
      case 'cali':
        return -76.5320;
      case 'barranquilla':
        return -74.7813;
      case 'cartagena':
        return -75.4794;
      case 'bucaramanga':
        return -73.1198;
      case 'pereira':
        return -75.6961;
      case 'santa marta':
        return -74.1990;
      case 'ibagué':
        return -75.2322;
      case 'cúcuta':
        return -72.5078;
      case 'pasto':
        return -77.2811;
      case 'manizales':
        return -75.5200;
      case 'neiva':
        return -75.2819;
      case 'villavicencio':
        return -73.6266;
      case 'armenia':
        return -75.6811;
      case 'valledupar':
        return -73.2532;
      case 'montería':
        return -75.8814;
      case 'sincelejo':
        return -75.3978;
      case 'popayán':
        return -76.6147;
      case 'tunja':
        return -73.3678;
      default:
        return -74.0721; // Bogotá por defecto
    }
  }

  Future<void> _useCurrentLocation() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Activa los servicios de ubicación')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final display = await _reverseGeocodeOSM(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _locationController.text = display;
          _selectedLat = pos.latitude;
          _selectedLng = pos.longitude;
          _showSuggestions = false;
        });
        if (display.isNotEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Ubicación detectada: $display')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e'))
        );
      }
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
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'AgroTrack/1.0 (+https://example.com)'},
      );
      if (resp.statusCode != 200) return '';
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = data['address'] ?? {};
      final rawCity =
          (addr['city'] ??
                  addr['town'] ??
                  addr['village'] ??
                  addr['hamlet'] ??
                  addr['municipality'] ??
                  '')
              .toString();
      String rawState =
          (addr['state'] ?? addr['region'] ?? addr['county'] ?? '').toString();
      // Normalizar estados tipo "Departamento de Nariño"
      rawState = rawState.replaceFirst(
        RegExp(r'^Departamento\s+de\s+', caseSensitive: false),
        '',
      );
      final display = [rawCity, rawState].where((e) => e.isNotEmpty).join(', ');
      return display;
    } catch (_) {
      return '';
    }
  }

  // Método para sincronizar con el widget de clima
  void _updateWeatherWidget(double lat, double lng, String locationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Usar las mismas claves que el widget de clima para sincronización
      await prefs.setDouble('selected_latitude', lat);
      await prefs.setDouble('selected_longitude', lng);
      await prefs.setString('selected_location', locationName);
      
      // Marcar timestamp para que el widget detecte el cambio
      await prefs.setInt('location_update_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      print('Ubicación sincronizada desde header: $locationName ($lat, $lng)');
      
      // Actualizar el WeatherStateProvider directamente
      if (mounted) {
        final weatherProvider = Provider.of<WeatherStateProvider>(context, listen: false);
        final weatherService = WeatherService();
        
        weatherProvider.setLoading(true);
        
        try {
          final weatherData = await weatherService.getWeatherData(lat, lng, locationName);
          if (weatherData != null) {
            weatherProvider.updateSelectedWeather(weatherData);
            print('WeatherStateProvider actualizado con: $locationName');
          } else {
            weatherProvider.setError('No se pudieron obtener los datos del clima');
          }
        } catch (e) {
          weatherProvider.setError('Error al obtener el clima: ${e.toString()}');
          print('Error obteniendo datos del clima: $e');
        }
      }
      
    } catch (e) {
      print('Error actualizando widget de clima: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Chatbot', 'icon': Icons.smart_toy, 'action': 'chatbot'},
      {'label': 'Clima', 'icon': Icons.wb_sunny, 'action': 'climate'},
      {'label': 'Cultivos', 'icon': Icons.eco, 'action': 'coming_soon'},
      {'label': 'Inventario', 'icon': Icons.inventory, 'action': 'inventory'},
      {'label': 'Tareas', 'icon': Icons.task_alt, 'action': 'coming_soon'},
      {
        'label': 'Finanzas',
        'icon': Icons.attach_money,
        'action': 'coming_soon',
      },
      {'label': 'Reportes', 'icon': Icons.bar_chart, 'action': 'coming_soon'},
      {'label': 'Mercado', 'icon': Icons.store, 'action': 'coming_soon'},
      {
        'label': 'Configuración',
        'icon': Icons.settings,
        'action': 'coming_soon',
      },
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
        child: Stack(
          children: [
            Column(
              children: [
                // Header 1/7 de pantalla
                SizedBox(
                  width: double.infinity,
                  height: headerHeight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                          color: Colors.black.withValues(alpha: 0.1),
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
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Hola, ',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        TextSpan(
                                          text: greeting,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fecha[0].toUpperCase() + fecha.substring(1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
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
                                  onSubmitted: _onLocationSubmitted,
                                  textInputAction: TextInputAction.search,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar ubicación... (presiona Enter para usar texto)',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                ),
                                onPressed: _useCurrentLocation,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Contenido scrollable tipo Facebook
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Widget del clima compacto
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MapWeatherScreen()),
                              );
                            },
                            child: const DashboardWeatherWidget(),
                          ),
                        ),
                      ),
                      // Vista general del clima del dA-a (RF1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Consumer<WeatherStateProvider>(
                            builder: (context, weatherProvider, _) {
                              return _buildWeatherSummary(context, weatherProvider);
                            },
                          ),
                        ),
                      ),

                      // Alertas importantes (RF3)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Consumer3<WeatherStateProvider, FinanceProvider, TaskProvider>(
                            builder: (context, weatherProvider, financeProvider, taskProvider, _) {
                              return _buildAlertsCard(
                                context,
                                weatherProvider,
                                financeProvider,
                                taskProvider,
                              );
                            },
                          ),
                        ),
                      ),

                      // Resumen rA?pido de finanzas (RF4)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Consumer<FinanceProvider>(
                            builder: (context, financeProvider, _) {
                              return _buildFinanceSummary(context, financeProvider);
                            },
                          ),
                        ),
                      ),

                      // Resumen de tareas del dA-a (RF5)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Consumer<TaskProvider>(
                            builder: (context, taskProvider, _) {
                              return _buildTaskSummary(context, taskProvider);
                            },
                          ),
                        ),
                      ),

                      // Espaciado
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                      
                      // Grid de funciones como sliver
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = items[index];
                              return _buildGridItem(
                                context,
                                item['label'] as String,
                                item['icon'] as IconData,
                                item['action'] as String,
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                      ),
                      
                      // Espaciado final para mejor UX
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Dropdown de sugerencias posicionado absolutamente
            if (_showSuggestions)
              Positioned(
                top: headerHeight - 10,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _colombianSuggestions.isNotEmpty
                            ? _colombianSuggestions.length
                            : _suggestions.length,
                        itemBuilder: (context, index) {
                          if (_colombianSuggestions.isNotEmpty) {
                            final location = _colombianSuggestions[index];
                            return _buildColombianSuggestionTile(location);
                          } else {
                            final s = _suggestions[index];
                            return _buildOSMSuggestionTile(s);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String label,
    IconData icon,
    String action,
  ) {
    return InkWell(
      onTap: () => _handleNavigation(context, action, label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSummary(
    BuildContext context,
    WeatherStateProvider weatherProvider,
  ) {
    final colors = Theme.of(context).colorScheme;
    final data = weatherProvider.selectedWeatherData;

    if (weatherProvider.isLoading) {
      return _sectionCard(
        context: context,
        title: 'Clima del dA-a',
        icon: Icons.wb_sunny_rounded,
        child: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (data == null) {
      return _sectionCard(
        context: context,
        title: 'Clima del dA-a',
        icon: Icons.wb_sunny_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sin ubicaciA3n seleccionada.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapWeatherScreen()),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Elegir ubicaciA3n'),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      context: context,
      title: 'Clima del dA-a',
      icon: Icons.wb_sunny_rounded,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.locationName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.water_drop, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                  Text('${data.humidity.round()}%'),
                  const SizedBox(width: 12),
                  Icon(Icons.air, size: 16, color: colors.secondary),
                  const SizedBox(width: 4),
                  Text('${data.windSpeed.round()} km/h'),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.temperature.round()}A�C',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
              Text(
                '${(data.temperature * 9 / 5 + 32).round()}A�F',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(
    BuildContext context,
    WeatherStateProvider weatherProvider,
    FinanceProvider financeProvider,
    TaskProvider taskProvider,
  ) {
    final alerts = <_AlertItem>[];
    final weather = weatherProvider.selectedWeatherData;

    if (taskProvider.overdueCount > 0) {
      alerts.add(_AlertItem(
        icon: Icons.warning_amber_rounded,
        color: Colors.red.shade600,
        title: 'Tareas vencidas',
        message: '${taskProvider.overdueCount} tareas necesitan atenciA3n hoy',
      ));
    }

    if (financeProvider.balance < 0) {
      alerts.add(_AlertItem(
        icon: Icons.trending_down_rounded,
        color: Colors.red.shade600,
        title: 'Balance negativo',
        message:
            'Balance actual \$${financeProvider.balance.toStringAsFixed(0)}',
      ));
    }

    if (weather != null) {
      if (weather.temperature > 35) {
        alerts.add(_AlertItem(
          icon: Icons.heat_pump_rounded,
          color: Colors.orange.shade700,
          title: 'Calor extremo',
          message: 'Temperatura alta, protege cultivos sensibles',
        ));
      } else if (weather.temperature < 5) {
        alerts.add(_AlertItem(
          icon: Icons.ac_unit_rounded,
          color: Colors.blue.shade700,
          title: 'FrA-o intenso',
          message: 'Riesgo por bajas temperaturas',
        ));
      }

      if (weather.humidity > 80) {
        alerts.add(_AlertItem(
          icon: Icons.cloud_queue_rounded,
          color: Colors.purple.shade700,
          title: 'Humedad alta',
          message: 'Vigila enfermedades fA�ngicas',
        ));
      }
    }

    if (alerts.isEmpty) {
      return _sectionCard(
        context: context,
        title: 'Alertas importantes',
        icon: Icons.notifications_active_rounded,
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sin alertas crA�ticas por el momento'),
          ],
        ),
      );
    }

    return _sectionCard(
      context: context,
      title: 'Alertas importantes',
      icon: Icons.notifications_active_rounded,
      child: Column(
        children: alerts
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.message,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFinanceSummary(
    BuildContext context,
    FinanceProvider financeProvider,
  ) {
    final colors = Theme.of(context).colorScheme;
    if (financeProvider.loading) {
      return _sectionCard(
        context: context,
        title: 'Finanzas',
        icon: Icons.account_balance_wallet_rounded,
        child: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return _sectionCard(
      context: context,
      title: 'Finanzas',
      icon: Icons.account_balance_wallet_rounded,
      child: Row(
        children: [
          _miniStat(
            context,
            label: 'Ingresos',
            value: '\$${financeProvider.totalIncome.toStringAsFixed(0)}',
            color: Colors.green,
          ),
          _miniStat(
            context,
            label: 'Gastos',
            value: '\$${financeProvider.totalExpense.toStringAsFixed(0)}',
            color: Colors.red,
          ),
          _miniStat(
            context,
            label: 'Balance',
            value: '\$${financeProvider.balance.toStringAsFixed(0)}',
            color: financeProvider.balance >= 0 ? colors.primary : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSummary(
    BuildContext context,
    TaskProvider taskProvider,
  ) {
    if (taskProvider.loading) {
      return _sectionCard(
        context: context,
        title: 'Tareas del dA-a',
        icon: Icons.checklist_rounded,
        child: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return _sectionCard(
      context: context,
      title: 'Tareas del dA-a',
      icon: Icons.checklist_rounded,
      child: Row(
        children: [
          _miniStat(
            context,
            label: 'Pendientes',
            value: '${taskProvider.pendingCount}',
            color: Colors.orange,
          ),
          _miniStat(
            context,
            label: 'Completadas',
            value: '${taskProvider.completedCount}',
            color: Colors.green,
          ),
          _miniStat(
            context,
            label: 'Vencidas',
            value: '${taskProvider.overdueCount}',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AlertItem {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _AlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}
