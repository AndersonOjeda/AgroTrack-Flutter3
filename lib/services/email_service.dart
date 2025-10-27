import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'logger_service.dart';

class EmailService {
  static final SupabaseClient _client = SupabaseService.client;

  /// Reenvía el correo de confirmación (flujo estándar de Supabase)
  static Future<bool> resendConfirmationEmail(String email) async {
    try {
      LoggerService.info('Reenviando correo a: $email con URL: ${SupabaseService.emailRedirectUrl}');
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseService.emailRedirectUrl,
      );
      LoggerService.info('Correo de confirmación reenviado a: $email');
      return true;
    } catch (e) {
      LoggerService.error('Error al reenviar correo de confirmación: $e');
      if (e is AuthException) {
        LoggerService.error('AuthException: ${e.message}');
      }
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
}