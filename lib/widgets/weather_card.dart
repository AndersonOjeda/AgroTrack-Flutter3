import 'package:flutter/material.dart';
import '../models/weather_data.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weatherData;
  final bool isCompact;
  final VoidCallback? onSaveLocation;
  final bool showSaveButton;

  const WeatherCard({
    super.key,
    required this.weatherData,
    this.isCompact = false,
    this.onSaveLocation,
    this.showSaveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    } else {
      return _buildFullCard(context);
    }
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono del clima
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getWeatherColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getWeatherEmoji(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weatherData.locationName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _capitalizeFirst(weatherData.description),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Temperatura
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weatherData.temperature.round()}°',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getWeatherColor(),
                  ),
                ),
                Text(
                  '${weatherData.humidity}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getWeatherColor().withValues(alpha: 0.1),
              _getWeatherColor().withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con temperatura principal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weatherData.temperature.round()}°C',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getWeatherColor(),
                        ),
                      ),
                      Text(
                        'Sensación: ${weatherData.feelsLike.round()}°C',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getWeatherColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getWeatherEmoji(),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Descripción del clima
              Text(
                _capitalizeFirst(weatherData.description),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Detalles del clima
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            context,
                            Icons.water_drop,
                            'Humedad',
                            '${weatherData.humidity}%',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            context,
                            Icons.air,
                            'Viento',
                            '${weatherData.windSpeed.toStringAsFixed(1)} m/s',
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            context,
                            Icons.compress,
                            'Presión',
                            '${weatherData.pressure} hPa',
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            context,
                            Icons.access_time,
                            'Actualizado',
                            _formatTime(weatherData.timestamp),
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Pronóstico si está disponible
              if (weatherData.forecast.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Pronóstico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weatherData.forecast.take(5).length,
                    itemBuilder: (context, index) {
                      final forecast = weatherData.forecast[index];
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatForecastTime(forecast.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getWeatherEmojiFromIcon(forecast.icon),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${forecast.maxTemp.round()}°',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Botón de guardar ubicación
              if (showSaveButton && onSaveLocation != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSaveLocation,
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Guardar en mis ubicaciones'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getWeatherColor() {
    final temp = weatherData.temperature;
    if (temp >= 30) return Colors.red;
    if (temp >= 25) return Colors.orange;
    if (temp >= 20) return Colors.amber;
    if (temp >= 15) return Colors.green;
    if (temp >= 10) return Colors.blue;
    return Colors.indigo;
  }

  String _getWeatherEmoji() {
    return _getWeatherEmojiFromIcon(weatherData.icon);
  }

  String _getWeatherEmojiFromIcon(String icon) {
    switch (icon) {
      case '01d': return '☀️'; // clear sky day
      case '01n': return '🌙'; // clear sky night
      case '02d': return '⛅'; // few clouds day
      case '02n': return '☁️'; // few clouds night
      case '03d':
      case '03n': return '☁️'; // scattered clouds
      case '04d':
      case '04n': return '☁️'; // broken clouds
      case '09d':
      case '09n': return '🌧️'; // shower rain
      case '10d': return '🌦️'; // rain day
      case '10n': return '🌧️'; // rain night
      case '11d':
      case '11n': return '⛈️'; // thunderstorm
      case '13d':
      case '13n': return '❄️'; // snow
      case '50d':
      case '50n': return '🌫️'; // mist
      default: return '🌤️';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatForecastTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour == 0) return '12AM';
    if (hour < 12) return '${hour}AM';
    if (hour == 12) return '12PM';
    return '${hour - 12}PM';
  }
}