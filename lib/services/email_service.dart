import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'logger_service.dart';

class EmailService {
  static final SupabaseClient _client = SupabaseService.client;

  /// Reenvía el correo de confirmación (flujo estándar de Supabase)
  static Future<bool> resendConfirmationEmail(String email) async {
    try {
      LoggerService.info('=== INICIANDO REENVÍO DE CORREO ===');
      LoggerService.info('Email: $email');
      LoggerService.info('Redirect URL: ${SupabaseService.emailRedirectUrl}');
      LoggerService.info('Cliente Supabase inicializado: ${SupabaseService.isReady}');
      
      // Verificar si hay un usuario actual
      final currentUser = _client.auth.currentUser;
      LoggerService.info('Usuario actual: ${currentUser?.email ?? 'No hay usuario'}');
      
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseService.emailRedirectUrl,
      );
      
      LoggerService.info('=== CORREO REENVIADO EXITOSAMENTE ===');
      LoggerService.info('Email enviado a: $email');
      return true;
    } catch (e) {
      LoggerService.error('=== ERROR AL REENVIAR CORREO ===');
      LoggerService.error('Error completo: $e');
      LoggerService.error('Tipo de error: ${e.runtimeType}');
      
      if (e is AuthException) {
        LoggerService.error('AuthException código: ${e.statusCode}');
        LoggerService.error('AuthException mensaje: ${e.message}');
      }
      
      // Intentar obtener más detalles del error
      LoggerService.error('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Verifica si el email del usuario actual está confirmado
  static Future<bool> isEmailConfirmed() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      return user.emailConfirmedAt != null;
    } catch (e) {
      LoggerService.error('Error al verificar confirmación de email: $e');
      return false;
    }
  }

  /// Función de diagnóstico para verificar la configuración de Supabase
  static Future<Map<String, dynamic>> diagnosticSupabaseConfig() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      // Verificar inicialización de Supabase
      diagnostics['supabase_initialized'] = SupabaseService.isReady;
      diagnostics['redirect_url'] = SupabaseService.emailRedirectUrl;
      
      // Verificar usuario actual
      final currentUser = _client.auth.currentUser;
      diagnostics['current_user'] = currentUser?.email ?? 'No hay usuario';
      diagnostics['user_confirmed'] = currentUser?.emailConfirmedAt != null;
      
      // Verificar configuración del cliente
      diagnostics['client_initialized'] = _client.auth.currentSession != null;
      
      LoggerService.info('=== DIAGNÓSTICO SUPABASE ===');
      diagnostics.forEach((key, value) {
        LoggerService.info('$key: $value');
      });
      
    } catch (e) {
      diagnostics['error'] = e.toString();
      LoggerService.error('Error en diagnóstico: $e');
    }
    
    return diagnostics;
  }

  /// Prueba simple de conectividad con Supabase
  static Future<bool> testSupabaseConnection() async {
    try {
      LoggerService.info('=== PROBANDO CONEXIÓN SUPABASE ===');
      
      // Intentar obtener la sesión actual
      final session = _client.auth.currentSession;
      LoggerService.info('Sesión actual: ${session != null ? 'Existe' : 'No existe'}');
      
      // Intentar hacer una consulta simple contra tabla en inglés
      final response = await _client.from('users').select('count').limit(1);
      LoggerService.info('Consulta de prueba exitosa: ${response.toString()}');
      
      return true;
    } catch (e) {
      LoggerService.error('Error de conexión con Supabase: $e');
      return false;
    }
  }
}