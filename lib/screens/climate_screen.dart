import 'package:flutter/material.dart';
import '../widgets/enhanced_weather_widget.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información Climática',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                'Información meteorológica detallada y recomendaciones agrícolas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: 20),
              
              // Widget de clima mejorado
              EnhancedWeatherWidget(
                latitude: widget.latitude,
                longitude: widget.longitude,
                locationName: widget.locationName,
              ),
              
              const SizedBox(height: 24),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información Importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Los datos meteorológicos se actualizan cada hora\n'
                      '• Las recomendaciones agrícolas se basan en condiciones locales\n'
                      '• Las alertas meteorológicas ayudan a proteger tus cultivos\n'
                      '• Selecciona una ubicación específica para mayor precisión',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                        height: 1.5,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}