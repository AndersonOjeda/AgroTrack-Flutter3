import 'dart:async';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'logger_service.dart';

class DeepLinkService {
  static bool _isInitialized = false;

  /// Inicializar el servicio de deep links
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      LoggerService.info('Deep link service inicializado (modo simplificado)');
    } catch (e) {
      LoggerService.error('Error inicializando deep link service: $e');
    }
  }

  /// Manejar deep links entrantes
  static Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
    LoggerService.info('Deep link recibido: $uri');

    try {
      // Verificar si es un link de confirmación de email
      if (_isEmailConfirmationLink(uri)) {
        await _handleEmailConfirmation(context, uri);
      }
      // Agregar más tipos de deep links aquí en el futuro
    } catch (e) {
      LoggerService.error('Error al manejar deep link: $e');
      _showErrorDialog(context, 'Error al procesar el enlace');
    }
  }

  /// Verificar si el URI es un link de confirmación de email
  static bool _isEmailConfirmationLink(Uri uri) {
    // Detect custom app scheme
    if (uri.scheme == 'agrotrack' && uri.host == 'email-confirmation') {
      return true;
    }

    // Detect confirmation via HTTPS verified domain
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'agrotrack.app') {
      if (uri.path.contains('email-confirmation') ||
          uri.path.contains('/auth/confirm')) {
        return true;
      }
    }

    // Fallback: generic Supabase patterns
    return (uri.fragment.contains('access_token') &&
            uri.fragment.contains('type=signup')) ||
        uri.queryParameters.containsKey('access_token') ||
        uri.path.contains('/auth/confirm');
  }

  /// Manejar confirmación de email
  static Future<void> _handleEmailConfirmation(
    BuildContext context,
    Uri uri,
  ) async {
    try {
      LoggerService.info('Procesando confirmación de email...');

      // Extraer tokens del URI
      String? accessToken;
      String? refreshToken;

      // Verificar si los tokens están en el fragment (formato #access_token=...)
      if (uri.fragment.isNotEmpty) {
        final fragmentParams = _parseFragment(uri.fragment);
        accessToken = fragmentParams['access_token'];
        refreshToken = fragmentParams['refresh_token'];
      }

      // Si no están en el fragment, verificar query parameters
      if (accessToken == null) {
        accessToken = uri.queryParameters['access_token'];
        refreshToken = uri.queryParameters['refresh_token'];
      }

      if (accessToken != null) {
        LoggerService.info(
          'Email confirmado exitosamente - tokens encontrados',
        );

        // Esperar un momento para que Supabase procese la confirmación automáticamente
        await Future.delayed(const Duration(seconds: 1));

        // Verificar si ahora tenemos una sesión activa
        final currentSession = SupabaseService.client.auth.currentSession;

        if (currentSession != null) {
          // Navegar automáticamente a la pantalla principal
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡Perfil confirmado exitosamente! Bienvenido a AgroTrack',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          LoggerService.warning('Sesión no establecida automáticamente');
          _showErrorDialog(
            context,
            'Confirmación procesada, por favor inicia sesión',
          );
        }
      } else {
        LoggerService.warning('No se encontraron tokens en el deep link');
        _showErrorDialog(context, 'Enlace de confirmación inválido');
      }
    } catch (e) {
      LoggerService.error('Error al confirmar email: $e');
      _showErrorDialog(context, 'Error al confirmar el perfil: $e');
    }
  }

  /// Parsear fragment de URL (#param1=value1&param2=value2)
  static Map<String, String> _parseFragment(String fragment) {
    final params = <String, String>{};

    // Remover el # inicial si existe
    final cleanFragment = fragment.startsWith('#')
        ? fragment.substring(1)
        : fragment;

    // Dividir por & y procesar cada parámetro
    for (final param in cleanFragment.split('&')) {
      final parts = param.split('=');
      if (parts.length == 2) {
        params[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      }
    }

    return params;
  }

  /// Mostrar diálogo de éxito
  static void _showSuccessDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  /// Mostrar diálogo de error
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  /// Limpiar recursos
  static void dispose() {
    _isInitialized = false;
  }

  /// Generar URL de deep link para confirmación de email
  static String generateEmailConfirmationUrl() {
    // Use custom scheme aligned with AndroidManifest
    return 'agrotrack://email-confirmation';
  }
}
