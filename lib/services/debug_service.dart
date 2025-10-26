import 'package:supabase_flutter/supabase_flutter.dart';

class DebugService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Verificar el estado de autenticación actual
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final session = _client.auth.currentSession;
      final user = session?.user;
      
      return {
        'has_session': session != null,
        'user_id': user?.id,
        'user_email': user?.email,
        'email_confirmed': user?.emailConfirmedAt != null,
        'session_expires': session?.expiresAt,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Verificar si existe el usuario en la tabla usuarios
  static Future<Map<String, dynamic>> checkUserInDatabase() async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user == null) {
        return {'error': 'No hay sesión activa'};
      }

      // Buscar por auth_user_id
      final response = await _client
          .from('usuarios')
          .select('*')
          .eq('auth_user_id', session!.user.id)
          .maybeSingle();

      return {
        'user_exists': response != null,
        'user_data': response,
        'auth_user_id': session.user.id,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Crear usuario manualmente en la tabla usuarios
  static Future<Map<String, dynamic>> createUserInDatabase() async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user == null) {
        return {'error': 'No hay sesión activa'};
      }

      final user = session!.user;
      
      // Crear registro en la tabla usuarios
      final response = await _client
          .from('usuarios')
          .insert({
            'auth_user_id': user.id,
            'email': user.email,
            'nombre': user.userMetadata?['nombre'] ?? 'Usuario',
            'apellido': user.userMetadata?['apellido'] ?? '',
            'telefono': user.userMetadata?['telefono'],
            'ubicacion': user.userMetadata?['ubicacion'],
            'experiencia_agricola': user.userMetadata?['experiencia_agricola'],
            'tamano_finca': user.userMetadata?['tamano_finca'],
            'tipo_agricultura': user.userMetadata?['tipo_agricultura'],
            'fecha_nacimiento': user.userMetadata?['fecha_nacimiento'],
            'email_confirmado': user.emailConfirmedAt != null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'user_created': response,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Obtener todos los usuarios para debug
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await _client
          .from('usuarios')
          .select('*')
          .order('created_at', ascending: false);

      return {
        'total_users': response.length,
        'users': response,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Diagnóstico completo
  static Future<Map<String, dynamic>> fullDiagnosis() async {
    final authStatus = await checkAuthStatus();
    final userInDb = await checkUserInDatabase();
    final allUsers = await getAllUsers();

    return {
      'auth_status': authStatus,
      'user_in_database': userInDb,
      'all_users': allUsers,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}