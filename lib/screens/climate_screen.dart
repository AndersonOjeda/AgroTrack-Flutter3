import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/weather_state_provider.dart';
import '../services/weather_service.dart';
import '../providers/task_provider.dart';
import '../models/weather_data.dart';
import '../models/daily_forecast.dart';
import 'map_weather_screen.dart';
import '../widgets/requirement_status_card.dart';

class ClimateScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const ClimateScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  final WeatherService _weatherService = WeatherService();
  Timer? _autoRefreshTimer;
  WeatherData? _lastForecastLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final provider = context.read<WeatherStateProvider>();
    await provider.loadCachedWeather();
    if (provider.selectedWeatherData != null) {
      _maybeLoadForecast(provider.selectedWeatherData!);
    }
  }

  void _maybeLoadForecast(WeatherData data) {
    if (_lastForecastLocation != null &&
        _lastForecastLocation!.latitude == data.latitude &&
        _lastForecastLocation!.longitude == data.longitude) {
      return;
    }
    _lastForecastLocation = data;
    _loadDailyForecast(data);
    _scheduleAutoRefresh();
  }

  Future<void> _loadDailyForecast(WeatherData data) async {
    final provider = context.read<WeatherStateProvider>();
    provider.setLoadingDaily(true);
    try {
      final forecast = await _weatherService.getWeatherForecast(
        data.latitude,
        data.longitude,
        data.locationName,
      );
      provider.updateDailyForecast(forecast);
    } finally {
      if (provider.isLoadingDaily) {
        provider.setLoadingDaily(false);
      }
    }
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _refreshWeather();
    });
  }

  Future<void> _refreshWeather() async {
    final provider = context.read<WeatherStateProvider>();
    final current = provider.selectedWeatherData;
    if (current == null) return;

    try {
      provider.setLoading(true);
      final updated = await _weatherService.getWeatherData(
        current.latitude,
        current.longitude,
        current.locationName,
      );
      if (updated != null) {
        provider.updateWeather(updated, updated.locationName);
        _lastForecastLocation = updated;
      }
      await _loadDailyForecast(updated ?? current);
    } catch (e) {
      provider.setError('No se pudo actualizar clima automaticamente');
    } finally {
      provider.setLoading(false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información Climática',
          style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'NotoSans'),
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
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapWeatherScreen(),
                ),
              );
            },
            tooltip: 'Seleccionar ubicación en mapa',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<WeatherStateProvider>(
          builder: (context, weatherProvider, child) {
            final hasData = weatherProvider.hasWeatherData;
            if (weatherProvider.isLoading && !hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Obteniendo datos del clima...'),
                  ],
                ),
              );
            }

            if (weatherProvider.errorMessage != null && !hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al obtener datos del clima',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapWeatherScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Seleccionar ubicación'),
                    ),
                  ],
                ),
              );
            }

            if (!weatherProvider.hasWeatherData) {
              return _buildNoDataView(context);
            }

            _maybeLoadForecast(weatherProvider.selectedWeatherData!);

            return RefreshIndicator(
              onRefresh: _refreshWeather,
              child: _buildWeatherView(
                context,
                weatherProvider.selectedWeatherData!,
                weatherProvider,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Text(
            'Condiciones Actuales',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una ubicación en el mapa para ver información meteorológica detallada',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 32),

          // Instrucciones para seleccionar ubicación
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.location_on, size: 64, color: Colors.blue.shade600),
                const SizedBox(height: 16),
                Text(
                  'Selecciona una ubicación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca el botón del mapa para seleccionar cualquier ubicación y obtener información climática detallada',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapWeatherScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Abrir mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Información Importante',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Los datos meteorológicos se actualizan en tiempo real\n'
                  '• Las recomendaciones agrícolas se basan en condiciones locales\n'
                  '• Puedes seleccionar cualquier ubicación en el mapa\n'
                  '• Los datos incluyen temperatura, humedad y velocidad del viento',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade800,
                    height: 1.5,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtremeAlertCard(
    BuildContext context,
    WeatherData weatherData,
    List<DailyForecast>? forecast,
  ) {
    final alerts = <String>[];
    final desc = weatherData.description.toLowerCase();
    if (weatherData.temperature >= 35) {
      alerts.add('Calor extremo hoy, evita labores pesadas al mediodA-a');
    }
    if (weatherData.temperature <= 5) {
      alerts.add('Posible helada, protege cultivos sensibles');
    }
    if (weatherData.windSpeed >= 25) {
      alerts.add('Viento fuerte >25 km/h, asegura invernaderos y plA-sticos');
    }
    if (desc.contains('lluvia')) {
      alerts.add('Lluvias actuales, revisa drenajes y evita fumigaciones');
    }
    if (forecast != null) {
      DailyForecast? upcomingRain;
      for (final day in forecast) {
        if (day.weatherCode >= 61 && day.weatherCode <= 82) {
          upcomingRain = day;
          break;
        }
      }
      if (upcomingRain != null) {
        alerts.add(
          'Lluvia prevista el ${DateFormat('EEE d', 'es').format(upcomingRain.date)}, planifica cosechas previas',
        );
      }
    }

    final MaterialColor colorBase = alerts.isEmpty ? Colors.green : Colors.red;
    final icon = alerts.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alerts.isEmpty ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBase.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorBase),
              const SizedBox(width: 8),
              Text(
                'Alertas de clima',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorBase.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            Text(
              'Sin eventos extremos detectados.',
              style: TextStyle(color: Colors.green.shade700),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: alerts
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '�?� $a',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecast(
    BuildContext context,
    WeatherStateProvider provider,
  ) {
    if (provider.isLoadingDaily) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    final forecast = provider.dailyForecast;
    if (forecast == null || forecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text('Selecciona ubicaciA3n para ver pronA3stico extendido'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PronA3stico 7 dA-as',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final day = forecast[index];
              return Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    Text(
                      DateFormat('EEE', 'es').format(day.date).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(day.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      '${day.maxTemperature.round()}A� / ${day.minTemperature.round()}A�',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      day.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: forecast.length,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskIntegrationCard(
    BuildContext context,
    WeatherData weatherData,
  ) {
    final taskProvider = context.watch<TaskProvider>();
    final now = DateTime.now();
    final todaysTasks = taskProvider.tasks
        .where(
          (t) =>
              t.dueDate.year == now.year &&
              t.dueDate.month == now.month &&
              t.dueDate.day == now.day,
        )
        .toList();

    String weatherAdvice;
    final desc = weatherData.description.toLowerCase();
    if (desc.contains('lluvia')) {
      weatherAdvice = 'Lluvia prevista hoy, prioriza tareas bajo techo.';
    } else if (weatherData.temperature > 30) {
      weatherAdvice = 'Temperaturas altas, agenda labores fuertes temprano.';
    } else if (weatherData.windSpeed > 20) {
      weatherAdvice = 'Viento fuerte, evita fumigaciones y asegura insumos.';
    } else {
      weatherAdvice = 'Clima estable, ideal para completar pendientes.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Clima + tareas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(weatherAdvice, style: TextStyle(color: Colors.orange.shade900)),
          const SizedBox(height: 12),
          if (todaysTasks.isEmpty)
            Text(
              'No hay tareas programadas para hoy.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            Column(
              children: todaysTasks.take(3).map((task) {
                final dueLabel = DateFormat('HH:mm').format(task.dueDate);
                final statusColor =
                    task.status == 'completed' ? Colors.green : Colors.orange;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.status == 'completed'
                        ? Icons.check_circle
                        : Icons.schedule,
                    color: statusColor,
                  ),
                  title: Text(task.title),
                  subtitle: Text('Vence hoy a las $dueLabel'),
                  trailing: Text(
                    task.priority.toUpperCase(),
                    style: TextStyle(
                      color: task.priority == 'high'
                          ? Colors.red
                          : task.priority == 'medium'
                              ? Colors.orange
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherView(
    BuildContext context,
    WeatherData weatherData,
    WeatherStateProvider weatherProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequirementStatusCard(
            title: 'Requerimientos pantalla Clima',
            icon: Icons.cloud_queue_rounded,
            items: const [
              RequirementStatusItem(
                label: 'RF1 Mostrar clima actual por ubicacion',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RF2 Mostrar pronostico 5-7 dias',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RF3 Alertas de clima extremo',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RF4 Cambiar ubicacion manualmente',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RF5 Recomendaciones agricolas segun clima',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RF6 Integrar clima con tareas',
                state: RequirementState.completed,
              ),
              RequirementStatusItem(
                label: 'RNF1 Funcionar con mala conexion usando cache local',
                state: RequirementState.completed,
                note: 'Datos se guardan y cargan offline',
              ),
              RequirementStatusItem(
                label: 'RNF2 Actualizaciones automaticas cada 30 min',
                state: RequirementState.completed,
                note: 'Refresco en background cada 30 min',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Encabezado con ubicación
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getWeatherColor(weatherData.temperature),
                  _getWeatherColor(weatherData.temperature).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${weatherData.locationName} - ${weatherData.description}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weatherData.icon,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weatherData.temperature.round()}°C',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${(weatherData.temperature * 9 / 5 + 32).round()}°F',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detalles del Clima
          Text(
            'Detalles del Clima',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildDetailCard(
                'Humedad',
                '${weatherData.humidity.round()}%',
                Icons.water_drop,
                Colors.blue,
              ),
              _buildDetailCard(
                'Viento',
                '${weatherData.windSpeed.round()} km/h',
                Icons.air,
                Colors.green,
              ),
              _buildDetailCard(
                'Latitud',
                weatherData.latitude.toStringAsFixed(4),
                Icons.gps_fixed,
                Colors.orange,
              ),
              _buildDetailCard(
                'Longitud',
                weatherData.longitude.toStringAsFixed(4),
                Icons.gps_fixed,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildExtremeAlertCard(
            context,
            weatherData,
            weatherProvider.dailyForecast,
          ),

          const SizedBox(height: 16),

          _buildWeeklyForecast(context, weatherProvider),

          const SizedBox(height: 24),



          // Recomendaciones agrícolas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.agriculture,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recomendaciones Agrícolas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getAgriculturalRecommendations(weatherData),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade800,
                    height: 1.5,
                    fontFamily: 'NotoSans',
                  ),
                ),
                if (weatherProvider.dailyForecast != null &&
                    weatherProvider.dailyForecast!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PrA3ximos 5 dA-as',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: weatherProvider.dailyForecast!
                              .take(5)
                              .map(
                                (day) => Chip(
                                  label: Text(
                                    '${DateFormat('EEE', 'es').format(day.date)}: ${day.maxTemperature.round()}A� / ${day.minTemperature.round()}A�',
                                  ),
                                  avatar: Text(day.icon),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildTaskIntegrationCard(context, weatherData),

          const SizedBox(height: 24),



          // Botón para cambiar ubicación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapWeatherScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Cambiar ubicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Icon(icon, color: color, size: 32),
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
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Color _getWeatherColor(double temperature) {
    if (temperature < 0) return Colors.blue.shade700;
    if (temperature < 10) return Colors.blue.shade500;
    if (temperature < 20) return Colors.green.shade500;
    if (temperature < 30) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  String _getAgriculturalRecommendations(WeatherData weatherData) {
    final temp = weatherData.temperature;
    final humidity = weatherData.humidity;
    final windSpeed = weatherData.windSpeed;

    List<String> recommendations = [];

    // Recomendaciones basadas en temperatura
    if (temp < 5) {
      recommendations.add('• Protege los cultivos sensibles al frío');
      recommendations.add('• Considera el uso de invernaderos o túneles');
    } else if (temp > 35) {
      recommendations.add('• Aumenta la frecuencia de riego');
      recommendations.add('• Proporciona sombra a cultivos sensibles');
    } else if (temp >= 15 && temp <= 25) {
      recommendations.add('• Condiciones ideales para la mayoría de cultivos');
    }

    // Recomendaciones basadas en humedad
    if (humidity < 30) {
      recommendations.add('• Humedad baja: aumenta el riego');
    } else if (humidity > 80) {
      recommendations.add('• Humedad alta: vigila enfermedades fúngicas');
      recommendations.add('• Mejora la ventilación en invernaderos');
    }

    // Recomendaciones basadas en viento
    if (windSpeed > 20) {
      recommendations.add('• Vientos fuertes: protege plantas jóvenes');
    }

    if (recommendations.isEmpty) {
      recommendations.add('• Condiciones climáticas estables');
      recommendations.add('• Mantén rutinas normales de cuidado');
    }

    return recommendations.join('\n');
  }
}
