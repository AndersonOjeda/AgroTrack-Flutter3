import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const WeatherWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.locationName,
  }) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? weatherData;
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
  void didUpdateWidget(WeatherWidget oldWidget) {
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
      // Usando Open-Meteo API (gratuita, sin necesidad de API key)
      final data = await WeatherService.getCurrentWeatherFree(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      );

      if (data != null) {
        setState(() {
          weatherData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Error al obtener datos del clima';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error de conexión';
        isLoading = false;
      });
    }
  }

  String _getWeatherIcon(String? iconCode) {
    return WeatherService.getWeatherEmoji(iconCode);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude == null || widget.longitude == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Selecciona una ubicación para ver el clima',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
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

    if (weatherData == null) {
      return const SizedBox.shrink();
    }

    final temp = weatherData!['main']['temp'].round();
    final feelsLike = weatherData!['main']['feels_like'].round();
    final humidity = weatherData!['main']['humidity'];
    final pressure = weatherData!['main']['pressure'];
    final windSpeed = weatherData!['wind']['speed'];
    final description = WeatherService.getWeatherDescription(weatherData!['weather'][0]['description']);
    final iconCode = weatherData!['weather'][0]['icon'];
    final precipitation = weatherData!['rain']?['1h']?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    _getWeatherIcon(iconCode),
                    style: const TextStyle(fontSize: 48),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
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
                  WeatherService.formatPrecipitation(precipitation),
                  Icons.grain,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildWeatherMetric(
                  'Presión',
                  WeatherService.formatPressure(pressure),
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildWeatherMetric(
                  'Viento',
                  '${windSpeed.toStringAsFixed(1)} m/s',
                  Icons.air,
                ),
              ),
            ],
          ),
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