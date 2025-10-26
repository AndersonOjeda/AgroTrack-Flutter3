import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'logger_service.dart';
import 'user_service.dart';

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;
  static UserModel? _currentUser;

  /// Obtener el usuario actual con tolerancia a faltantes en la tabla usuarios
  static Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    try {
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      if (authUser == null) return null;

      // 1) Buscar por auth_user_id
      Map<String, dynamic>? response = await _client
          .from('usuarios')
          .select('*')
          .eq('auth_user_id', authUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));

      // 2) Fallback: buscar por email si no existe aún
      if (response == null && authUser.email != null) {
        response = await _client
            .from('usuarios')
            .select('*')
            .eq('email', authUser.email!)
            .maybeSingle()
            .timeout(const Duration(seconds: 12));
      }

      // 3) Fallback: crear registro mínimo si no existe y políticas lo permiten
      if (response == null) {
        final insertData = {
          'auth_user_id': authUser.id,
          'email': authUser.email,
          'nombre': authUser.userMetadata?['nombre'] ?? (authUser.email ?? 'Usuario'),
          'email_confirmado': authUser.emailConfirmedAt != null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          response = await _client
              .from('usuarios')
              .upsert(insertData, onConflict: 'auth_user_id')
              .select()
              .maybeSingle()
              .timeout(const Duration(seconds: 12));
        } catch (e) {
          // Si falla por RLS u otra razón, simplemente registrar y continuar
          LoggerService.error('Fallo al crear registro en usuarios', error: e);
        }
      }

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        return _currentUser;
      }
      
      return null;
    } catch (e) {
      LoggerService.error('Error obteniendo usuario actual', error: e);
      return null;
    }
  }

  /// Actualizar información del perfil usando UserModel
  static Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user == null) return false;
      final authUser = session!.user;

      // Preparar datos para actualización/upsert
      final updateData = updatedUser.toJson();
      updateData['auth_user_id'] = authUser.id; // asegurar vínculo
      updateData.remove('id'); // Evitar colisión con PK si es nulo
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Comprobar si ya existe registro para este auth_user_id
      final existing = await _client
          .from('usuarios')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      final hasExisting = existing != null;
      if (!hasExisting) {
        updateData['email'] = updatedUser.email; // requerido para inserción
      } else {
        updateData.remove('email'); // evitar violar unique email en update
      }

      // Normalizar tipos antes de enviar
      final tf = updateData['tamano_finca'];
      if (tf is String) {
        final t = tf.trim();
        if (t.isEmpty) {
          updateData.remove('tamano_finca');
        } else {
          final parsed = double.tryParse(t);
          if (parsed != null) {
            updateData['tamano_finca'] = parsed;
          } else {
            updateData.remove('tamano_finca');
          }
        }
      }
      final fn = updateData['fecha_nacimiento'];
      if (fn is String && fn.isNotEmpty) {
        // Enviar sólo YYYY-MM-DD si viene en ISO
        if (fn.length >= 10) {
          updateData['fecha_nacimiento'] = fn.substring(0, 10);
        }
      }

      // Upsert en Supabase (actualiza si existe, crea si falta) usando conflicto en auth_user_id
      Map<String, dynamic>? response;
      try {
        response = await _client
            .from('usuarios')
            .upsert(updateData, onConflict: 'auth_user_id')
            .select()
            .maybeSingle()
            .timeout(const Duration(seconds: 15));
      } on PostgrestException catch (pe) {
        // Si falla por email duplicado, intentar vincular fila existente
        final msg = pe.message;
        if (msg.contains('usuarios_email_key') || msg.contains('duplicate key')) {
          await _client.rpc('link_existing_usuario_to_auth_user', params: {
            'user_email': updatedUser.email,
          });
          // Reintentar upsert sin email
          updateData.remove('email');
          response = await _client
              .from('usuarios')
              .upsert(updateData, onConflict: 'auth_user_id')
              .select()
              .maybeSingle()
              .timeout(const Duration(seconds: 15));
        } else {
          rethrow;
        }
      }

      if (response == null) {
        throw Exception('No se pudo actualizar/crear registro remoto');
      }

      // Actualizar cache local
      final refreshed = UserModel.fromJson(response);
      _currentUser = refreshed;

      // También actualizar en la base de datos local usando UserService
      await UserService.updateUserProfile(refreshed);

      return true;
    } catch (e) {
      LoggerService.error('Error actualizando perfil', error: e);
      return false;
    }
  }

  /// Actualizar información del perfil (método legacy mantenido para compatibilidad)
  static Future<bool> updateProfileLegacy({
    String? nombre,
    String? apellido,
    String? telefono,
    String? ubicacion,
    String? biografia,
    DateTime? fechaNacimiento,
    String? experienciaAgricola,
    String? tamanoFinca,
    String? tipoAgricultura,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user == null) return false;

      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      // Crear usuario actualizado con los nuevos datos
      final updatedUser = currentUser.copyWith(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        ubicacion: ubicacion,
        fechaNacimiento: fechaNacimiento,
        experienciaAgricola: experienciaAgricola,
        tamanoFinca: tamanoFinca,
        tipoAgricultura: tipoAgricultura,
        bio: biografia,
        updatedAt: DateTime.now(),
      );

      // Usar el método principal updateProfile
      return await updateProfile(updatedUser);
    } catch (e) {
      LoggerService.error('Error actualizando perfil: $e');
      return false;
    }
  }

  /// Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return {};

      // Aquí puedes agregar consultas para obtener estadísticas reales
      // Por ahora retornamos datos de ejemplo
      return {
        'cultivos_activos': 5,
        'tareas_completadas': 23,
        'dias_activos': _calculateActiveDays(user.createdAt),
        'experiencia_nivel': _getExperienceLevel(user.experienciaAgricola),
      };
    } catch (e) {
      LoggerService.error('Error obteniendo estadísticas', error: e);
      return {};
    }
  }

  /// Calcular días activos desde el registro
  static int _calculateActiveDays(DateTime? createdAt) {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Obtener nivel de experiencia
  static String _getExperienceLevel(String? experiencia) {
    switch (experiencia?.toLowerCase()) {
      case 'principiante':
        return 'Novato';
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Experto';
      default:
        return 'Sin definir';
    }
  }

  /// Limpiar cache del usuario (útil para logout)
  static void clearUserCache() {
    _currentUser = null;
  }

  /// Refrescar datos del usuario
  static Future<UserModel?> refreshUser() async {
    _currentUser = null;
    return await getCurrentUser();
  }

  /// Validar si el perfil está completo
  static bool isProfileComplete(UserModel user) {
    return user.nombre.isNotEmpty &&
           user.email.isNotEmpty &&
           user.telefono != null &&
           user.telefono!.isNotEmpty &&
           user.ubicacion != null &&
           user.ubicacion!.isNotEmpty &&
           user.fechaNacimiento != null &&
           user.experienciaAgricola != null &&
           user.tamanoFinca != null &&
           user.tipoAgricultura != null;
  }

  /// Obtener porcentaje de completitud del perfil
  static double getProfileCompleteness(UserModel user) {
    int completedFields = 0;
    int totalFields = 8;

    if (user.nombre.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.telefono?.isNotEmpty == true) completedFields++;
    if (user.ubicacion?.isNotEmpty == true) completedFields++;
    if (user.fechaNacimiento != null) completedFields++;
    if (user.experienciaAgricola?.isNotEmpty == true) completedFields++;
    if (user.tamanoFinca?.isNotEmpty == true) completedFields++;
    if (user.tipoAgricultura?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }
}