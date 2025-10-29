import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../services/logger_service.dart';
import '../services/weather_state_provider.dart';
import '../widgets/simple_weather_widget.dart';
import 'chat_bot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = '';
  String _currentDate = '';
  String _userName = '';
  String _userLocation = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _loadUserData();
    // Actualizar la hora cada minuto
    Future.delayed(const Duration(minutes: 1), _updateDateTime);
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(now);
    });
  }

  void _loadUserData() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _userName = user?.nombre ?? 'Usuario';
      // Inicializar con la ubicación del usuario, pero se actualizará con el clima
      _userLocation = user?.ubicacion ?? 'Obteniendo ubicación...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherStateProvider>(
      builder: (context, weatherProvider, child) {
        // Sincronizar la ubicación con el clima cuando esté disponible
        String displayLocation = _userLocation;
        if (weatherProvider.hasWeatherData && weatherProvider.currentLocation.isNotEmpty) {
          displayLocation = weatherProvider.currentLocation;
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Sección superior (mitad de la pantalla)
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Imagen de fondo del campo
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1500382017468-9049fed747ef?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2532&q=80',
                              ),
                              fit: BoxFit.cover,
                              opacity: 0.3,
                            ),
                          ),
                        ),
                        // Overlay con gradiente
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        // Contenido de la sección superior
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecera con ubicación sincronizada
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      displayLocation,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          const SizedBox(height: 30),

                          // Saludo personalizado
                          Text(
                            'Hola $_userName,',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Widgets de información
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Widget de fecha y hora
                                Container(
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
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentTime,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              _currentDate,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Widget del clima
                                const SimpleWeatherWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sección inferior (mitad de la pantalla)
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Funciones de AgroTrack',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid de funciones
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildFunctionCard(
                            icon: Icons.smart_toy,
                            title: 'Chatbot Agrícola',
                            subtitle: 'Asistente con IA',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatBot(),
                                ),
                              );
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.people,
                            title: 'Comunidad',
                            subtitle: 'Conecta con agricultores',
                            color: Colors.green,
                            onTap: () {
                              // TODO: Implementar navegación a comunidad
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.analytics,
                            title: 'Análisis',
                            subtitle: 'Datos de tu cultivo',
                            color: Colors.purple,
                            onTap: () {
                              // TODO: Implementar navegación a análisis
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.calendar_today,
                            title: 'Calendario',
                            subtitle: 'Planifica actividades',
                            color: Colors.orange,
                            onTap: () {
                              // TODO: Implementar navegación a calendario
                            },
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
      },
    );
  }

  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
