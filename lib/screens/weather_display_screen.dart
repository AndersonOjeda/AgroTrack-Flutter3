import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../services/weather_state_provider.dart';
import '../services/weather_service.dart';
import '../widgets/simple_weather_widget.dart';
import 'location_map_screen.dart';

class WeatherDisplayScreen extends StatelessWidget {
  const WeatherDisplayScreen({super.key});

  Future<void> _loadWeatherForLocation(
    BuildContext context,
    LatLng location,
    String locationName,
  ) async {
    print(
      'DEBUG: _loadWeatherForLocation iniciado para $locationName en ${location.latitude}, ${location.longitude}',
    );

    final weatherProvider = Provider.of<WeatherStateProvider>(
      context,
      listen: false,
    );
    final weatherService = WeatherService();

    // Mostrar estado de carga
    weatherProvider.setLoading(true);
    print('DEBUG: Estado de carga activado');

    try {
      // Obtener datos del clima
      final weatherData = await weatherService.getWeatherData(
        location.latitude,
        location.longitude,
        locationName,
      );

      if (weatherData != null) {
        // Actualizar el estado con los nuevos datos
        weatherProvider.updateSelectedWeather(weatherData);

        // Mostrar mensaje de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Datos del clima cargados para $locationName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        weatherProvider.setError(
          'No se pudieron obtener datos del clima para esta ubicación',
        );
      }
    } catch (e) {
      weatherProvider.setError(
        'Error al obtener datos del clima: ${e.toString()}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del clima: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      weatherProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Datos Climáticos',
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
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationMapScreen(),
                ),
              );

              print('DEBUG: Resultado recibido de LocationMapScreen: $result');

              if (result != null && result is Map<String, dynamic>) {
                final location = result['location'] as LatLng?;
                final locationName = result['locationName'] as String?;

                print(
                  'DEBUG: Location: $location, LocationName: $locationName',
                );

                if (location != null && locationName != null) {
                  print('DEBUG: Llamando _loadWeatherForLocation...');
                  await _loadWeatherForLocation(
                    context,
                    location,
                    locationName,
                  );
                } else {
                  print('DEBUG: Location o LocationName son null');
                }
              } else {
                print('DEBUG: Result es null o no es Map<String, dynamic>');
              }
            },
            tooltip: 'Seleccionar ubicación',
          ),
        ],
      ),
      body: Consumer<WeatherStateProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return _buildLoadingView(context);
          }

          if (weatherProvider.errorMessage != null) {
            return _buildErrorView(context, weatherProvider.errorMessage);
          }

          if (!weatherProvider.hasWeatherData) {
            return _buildNoDataView(context);
          }

          return _buildWeatherView(
            context,
            weatherProvider.selectedWeatherData!,
          );
        },
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Obteniendo datos del clima...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error al obtener datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationMapScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Seleccionar ubicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }

  Widget _buildNoDataView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin datos climáticos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una ubicación para ver los datos del clima',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'NotoSans',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationMapScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Seleccionar ubicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }

  Widget _buildWeatherView(BuildContext context, weatherData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta principal del clima
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getWeatherColor(weatherData.temperature),
                  _getWeatherColor(weatherData.temperature).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weatherData.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'NotoSans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(weatherData.icon, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  '${weatherData.temperature.round()}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  weatherData.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detalles adicionales
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  context,
                  'Humedad',
                  '${weatherData.humidity.round()}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailCard(
                  context,
                  'Viento',
                  '${weatherData.windSpeed.round()} km/h',
                  Icons.air,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recomendaciones agrícolas
          _buildAgriculturalRecommendations(context, weatherData),

          const SizedBox(height: 24),

          // Botón para cambiar ubicación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationMapScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Cambiar ubicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgriculturalRecommendations(BuildContext context, weatherData) {
    List<String> recommendations = _getAgriculturalRecommendations(weatherData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones Agrícolas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getAgriculturalRecommendations(weatherData) {
    List<String> recommendations = [];

    // Recomendaciones basadas en temperatura
    if (weatherData.temperature < 10) {
      recommendations.add('Protege los cultivos sensibles al frío');
      recommendations.add('Considera el uso de invernaderos o túneles');
    } else if (weatherData.temperature > 30) {
      recommendations.add('Aumenta la frecuencia de riego');
      recommendations.add('Proporciona sombra a cultivos sensibles');
    } else {
      recommendations.add('Temperatura ideal para la mayoría de cultivos');
    }

    // Recomendaciones basadas en humedad
    if (weatherData.humidity > 80) {
      recommendations.add('Vigila posibles enfermedades fúngicas');
      recommendations.add('Mejora la ventilación en invernaderos');
    } else if (weatherData.humidity < 40) {
      recommendations.add('Considera sistemas de riego por aspersión');
      recommendations.add('Monitorea el estrés hídrico en las plantas');
    }

    // Recomendaciones basadas en viento
    if (weatherData.windSpeed > 20) {
      recommendations.add('Protege cultivos altos del viento fuerte');
      recommendations.add('Revisa estructuras de soporte');
    }

    return recommendations;
  }

  Color _getWeatherColor(double temperature) {
    if (temperature < 0) return Colors.blue.shade700;
    if (temperature < 10) return Colors.blue.shade500;
    if (temperature < 20) return Colors.green.shade500;
    if (temperature < 30) return Colors.orange.shade500;
    return Colors.red.shade500;
  }
}
