import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class EnhancedWeatherWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const EnhancedWeatherWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  State<EnhancedWeatherWidget> createState() => _EnhancedWeatherWidgetState();
}

class _EnhancedWeatherWidgetState extends State<EnhancedWeatherWidget> {
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>> alerts = [];
  List<String> recommendations = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _fetchWeatherData();
    }
  }

  @override
  void didUpdateWidget(EnhancedWeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      if (widget.latitude != null && widget.longitude != null) {
        _fetchWeatherData();
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    if (widget.latitude == null || widget.longitude == null) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Obtener datos del clima extendido
      final extendedData = await WeatherService.getExtendedForecast(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      );

      if (extendedData != null) {
        // Generar recomendaciones y alertas automáticas
        final autoRecommendations = WeatherService.getAgriculturalRecommendations(extendedData);
        final autoAlerts = WeatherService.generateAutomaticAlerts(extendedData);

        setState(() {
          weatherData = extendedData;
          recommendations = autoRecommendations;
          alerts = autoAlerts;
          isLoading = false;
        });
      } else {
        // Fallback a la API gratuita si falla OpenWeather
        final freeData = await WeatherService.getCurrentWeatherFree(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
        );

        if (freeData != null) {
          setState(() {
            weatherData = {'current': freeData};
            recommendations = _generateBasicRecommendations(freeData);
            alerts = _generateBasicAlerts(freeData);
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Error al obtener datos del clima';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = 'Error de conexión';
        isLoading = false;
      });
    }
  }

  List<String> _generateBasicRecommendations(Map<String, dynamic> data) {
    final recommendations = <String>[];
    final temp = data['main']['temp']?.toDouble() ?? 0.0;
    final humidity = data['main']['humidity']?.toInt() ?? 0;

    if (humidity > 80) {
      recommendations.add("💨 Alta humedad ($humidity%) - Evita aplicar fertilizantes");
    }
    if (temp > 30) {
      recommendations.add("🔥 Temperatura alta (${temp.round()}°C) - Riega temprano");
    }
    if (recommendations.isEmpty) {
      recommendations.add("☀️ Condiciones normales - Mantén rutina de cuidados");
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _generateBasicAlerts(Map<String, dynamic> data) {
    final alerts = <Map<String, dynamic>>[];
    final temp = data['main']['temp']?.toDouble() ?? 0.0;

    if (temp > 35) {
      alerts.add({
        'type': 'warning',
        'title': 'Temperatura Alta',
        'message': 'Temperatura de ${temp.round()}°C. Protege tus cultivos.',
        'icon': '🔥',
        'priority': 'medium'
      });
    }

    return alerts;
  }

  IconData _getWeatherIconData(String? iconCode) {
    switch (iconCode) {
      case '01d': return Icons.wb_sunny;
      case '01n': return Icons.nights_stay;
      case '02d': case '02n': return Icons.wb_cloudy;
      case '03d': case '03n': return Icons.cloud;
      case '04d': case '04n': return Icons.cloud;
      case '09d': case '09n': return Icons.grain;
      case '10d': case '10n': return Icons.grain;
      case '11d': case '11n': return Icons.flash_on;
      case '13d': case '13n': return Icons.ac_unit;
      case '50d': case '50n': return Icons.blur_on;
      default: return Icons.wb_sunny;
    }
  }

  Color _getWeatherIconColor(String? iconCode) {
    switch (iconCode) {
      case '01d': return Colors.orange;
      case '01n': return Colors.indigo;
      case '02d': return Colors.amber;
      case '02n': return Colors.indigo;
      case '03d': case '03n': return Colors.grey;
      case '04d': case '04n': return Colors.blueGrey;
      case '09d': case '09n': return Colors.blue;
      case '10d': return Colors.lightBlue;
      case '10n': return Colors.blue;
      case '11d': case '11n': return Colors.deepPurple;
      case '13d': case '13n': return Colors.lightBlue;
      case '50d': case '50n': return Colors.grey;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude == null || widget.longitude == null) {
      return _buildPlaceholder('Selecciona una ubicación para ver el clima');
    }

    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (error != null) {
      return _buildErrorWidget();
    }

    if (weatherData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8), // Reducido de 16 a 8
      constraints: const BoxConstraints(
        maxHeight: 550, // Reducido de 600 a 550
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reducido de padding interno
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWeatherHeader(),
              if (alerts.isNotEmpty) ...[
                const SizedBox(height: 6), // Reducido de 8 a 6
                _buildAlertsSection(),
              ],
              const SizedBox(height: 6), // Reducido de 8 a 6
              _buildRecommendationsSection(),
              const SizedBox(height: 6), // Reducido de 8 a 6
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchWeatherData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherHeader() {
    final current = weatherData!['current'] ?? weatherData!;
    final temp = current['temp']?.round() ?? 0;
    final feelsLike = current['feels_like']?.round() ?? temp;
    final humidity = current['humidity'] ?? 0;
    final description = current['weather'] != null && current['weather'].isNotEmpty
        ? WeatherService.getWeatherDescription(current['weather'][0]['description'])
        : 'Desconocido';
    final iconCode = current['weather'] != null && current['weather'].isNotEmpty
        ? current['weather'][0]['icon']
        : '01d';

    return Padding(
      padding: const EdgeInsets.all(8), // Reducido de 20 a 8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ubicación
          if (widget.locationName != null)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.locationName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Temperatura principal y descripción
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+$temp°',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.black87,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'C',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Se siente $feelsLike°C',
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Colors.grey,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getWeatherIconColor(iconCode).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getWeatherIconData(iconCode),
                        size: 28,
                        color: _getWeatherIconColor(iconCode),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'NotoSans',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Métricas del clima
          Row(
            children: [
              Expanded(
                child: _buildWeatherMetric(
                  'Humedad',
                  '$humidity%',
                  Icons.water_drop_outlined,
                ),
              ),
              Expanded(
                child: _buildWeatherMetric(
                  'Precipitación',
                  '${current['rain']?['1h']?.toStringAsFixed(1) ?? '0.0'} mm',
                  Icons.grain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8), // Reducido de 20 a 8
      padding: const EdgeInsets.all(8), // Reducido de 16 a 8
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alertas Meteorológicas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reducido de 12 a 8
          ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['icon'] ?? '⚠️',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'NotoSans',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        alert['message'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontFamily: 'NotoSans',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      margin: const EdgeInsets.all(8), // Reducido de 20 a 8
      padding: const EdgeInsets.all(8), // Reducido de 16 a 8
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
              Icon(Icons.lightbulb_outline, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones Agrícolas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reducido de 12 a 8
          ...recommendations.take(3).map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.2,
                      fontFamily: 'NotoSans',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}