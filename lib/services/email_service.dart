import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class EmailService {
  static final SupabaseClient _client = SupabaseService.client;

  /// Configura las URLs de redirección para la confirmación de email
  static Future<void> configureEmailSettings() async {
    // Esta configuración se debe hacer en el dashboard de Supabase
    // Authentication > Settings > Auth
    // Site URL: tu dominio de producción
    // Redirect URLs: agregar las URLs permitidas para redirección
  }

  /// Reenvía el correo de confirmación usando la función SQL personalizada
  static Future<Map<String, dynamic>> resendConfirmationEmailAdvanced(String email) async {
    try {
      // Usar la función SQL personalizada para reenvío
      final response = await _client.rpc('resend_confirmation_email', params: {
        'user_email': email,
      });
      
      if (response != null && response['success'] == true) {
        // Si la función SQL indica éxito, intentar el reenvío real
        await _client.auth.resend(
          type: OtpType.signup,
          email: email,
        );
        
        return {
          'success': true,
          'message': 'Correo de confirmación reenviado exitosamente',
          'email': email,
        };
      } else {
        return response ?? {
          'success': false,
          'error': 'Error desconocido',
          'message': 'No se pudo procesar la solicitud',
        };
      }
    } catch (e) {
      print('Error al reenviar correo de confirmación avanzado: $e');
      return {
        'success': false,
        'error': 'Error de conexión',
        'message': 'Error al procesar la solicitud: $e',
      };
    }
  }

  /// Reenvía el correo de confirmación
  static Future<bool> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return true;
    } catch (e) {
      print('Error al reenviar correo de confirmación: $e');
      return false;
    }
  }

  /// Confirma el email usando el token recibido
  static Future<bool> confirmEmail(String token, String email) async {
    try {
      final response = await _client.auth.verifyOTP(
        token: token,
        type: OtpType.signup,
        email: email,
      );
      
      if (response.user != null) {
        // Actualizar el estado de confirmación en la tabla usuarios
        await _client
            .from('usuarios')
            .update({
              'email_confirmado': true,
              'fecha_confirmacion_email': DateTime.now().toIso8601String(),
            })
            .eq('auth_user_id', response.user!.id);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error al confirmar email: $e');
      return false;
    }
  }

  /// Verifica si el email del usuario actual está confirmado
  static Future<bool> isEmailConfirmed() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('usuarios')
          .select('email_confirmado')
          .eq('auth_user_id', user.id)
          .single();

      return response['email_confirmado'] ?? false;
    } catch (e) {
      print('Error al verificar confirmación de email: $e');
      return false;
    }
  }

  /// Obtiene el estado de confirmación del usuario actual usando función SQL
  static Future<Map<String, dynamic>?> getEmailConfirmationStatusAdvanced(String email) async {
    try {
      final response = await _client.rpc('check_email_confirmation_status', params: {
        'user_email': email,
      });

      if (response != null && response['success'] == true) {
        return {
          'email': response['email'],
          'auth_confirmed': response['auth_confirmed'],
          'auth_confirmed_at': response['auth_confirmed_at'],
          'usuarios_confirmed': response['usuarios_confirmed'],
          'usuarios_confirmed_at': response['usuarios_confirmed_at'],
          'user_exists_in_usuarios': response['user_exists_in_usuarios'],
          'auth_user_id': response['auth_user_id'],
        };
      }
      
      return response;
    } catch (e) {
      print('Error al obtener estado de confirmación avanzado: $e');
      return {
        'success': false,
        'error': 'Error de conexión',
        'message': 'Error al verificar confirmación: $e',
      };
    }
  }

  /// Obtiene el estado de confirmación del usuario actual
  static Future<Map<String, dynamic>?> getEmailConfirmationStatus() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('usuarios')
          .select('email_confirmado, fecha_confirmacion_email, email')
          .eq('auth_user_id', user.id)
          .single();

      return {
        'email': response['email'],
        'confirmed': response['email_confirmado'] ?? false,
        'confirmation_date': response['fecha_confirmacion_email'],
      };
    } catch (e) {
      print('Error al obtener estado de confirmación: $e');
      return null;
    }
  }

  /// Maneja la URL de confirmación recibida
  static Future<bool> handleConfirmationUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final type = uri.queryParameters['type'];
      
      if (token != null && type == 'signup') {
        final response = await _client.auth.verifyOTP(
          token: token,
          type: OtpType.signup,
        );
        
        if (response.user != null) {
          // Actualizar estado en la base de datos
          await _client
              .from('usuarios')
              .update({
                'email_confirmado': true,
                'fecha_confirmacion_email': DateTime.now().toIso8601String(),
              })
              .eq('auth_user_id', response.user!.id);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error al manejar URL de confirmación: $e');
      return false;
    }
  }

  /// Obtiene el template HTML personalizado para el email de confirmación
  static String getConfirmationEmailTemplate({
    required String userName,
    required String confirmationUrl,
  }) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirma tu cuenta - AgroTrack</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f8f9fa; }
        .container { background: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { font-size: 32px; font-weight: bold; color: #2d5a27; margin-bottom: 10px; }
        .welcome-text { font-size: 24px; color: #2d5a27; margin-bottom: 20px; text-align: center; }
        .confirm-button { display: inline-block; background: linear-gradient(135deg, #4CAF50, #2d5a27); color: white; padding: 16px 32px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; text-align: center; margin: 20px 0; }
        .button-container { text-align: center; margin: 30px 0; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🌱 AgroTrack</div>
            <div class="welcome-text">¡Bienvenido a la comunidad agrícola!</div>
        </div>
        <div class="content">
            <p>Hola <strong>$userName</strong>,</p>
            <p>¡Gracias por unirte a AgroTrack! Para completar tu registro, confirma tu dirección de correo electrónico.</p>
            <div class="button-container">
                <a href="$confirmationUrl" class="confirm-button">✅ Confirmar mi cuenta</a>
            </div>
            <p><strong>Importante:</strong> Este enlace expirará en 24 horas por seguridad.</p>
        </div>
        <div class="footer">
            <p>Si no creaste esta cuenta, puedes ignorar este correo.</p>
            <p>© 2024 AgroTrack - Conectando agricultores, cultivando el futuro</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}