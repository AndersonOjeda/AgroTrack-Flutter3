import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
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
          .maybeSingle();

      // 2) Fallback: buscar por email si no existe aún
      if (response == null && authUser.email != null) {
        response = await _client
            .from('usuarios')
            .select('*')
            .eq('email', authUser.email!)
            .maybeSingle();
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
              .insert(insertData)
              .select()
              .single();
        } catch (e) {
          // Si falla por RLS u otra razón, simplemente registrar y continuar
          print('Fallo al crear registro en usuarios: $e');
        }
      }

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        return _currentUser;
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Actualizar información del perfil usando UserModel
  static Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      final session = _client.auth.currentSession;
      if (session?.user == null) return false;

      // Preparar datos para actualización
      final updateData = updatedUser.toJson();
      updateData.remove('id'); // No actualizar el ID
      updateData.remove('auth_user_id'); // No actualizar el auth_user_id
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Actualizar en Supabase
      await _client
          .from('usuarios')
          .update(updateData)
          .eq('auth_user_id', session!.user.id);

      // Actualizar cache local
      _currentUser = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );

      // También actualizar en la base de datos local usando UserService
       await UserService.updateUserProfile(updatedUser);

      return true;
    } catch (e) {
      print('Error actualizando perfil: $e');
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
      print('Error actualizando perfil: $e');
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
      print('Error obteniendo estadísticas: $e');
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