import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'cache_service.dart';
import 'sync_service.dart';

class UserService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final DatabaseService _databaseService = DatabaseService();
  static final CacheService _cacheService = CacheService();
  static final SyncService _syncService = SyncService();

  /// Inicializar servicios
  static Future<void> initialize() async {
    _syncService.initialize();
    await _cacheService.preloadFrequentData();
  }

  /// Registra un nuevo usuario con persistencia local y sincronización
  static Future<UserModel> registerUser({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    String? ubicacion,
    String? fechaNacimiento,
    String? experienciaAgricola,
    String? tamanoFinca,
    String? tipoAgricultura,
  }) async {
    try {
      // 1. Registrar en Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear usuario en autenticación');
      }

      // 2. Crear modelo de usuario
      final user = UserModel(
        id: authResponse.user!.id,
        nombre: nombre,
        email: email,
        telefono: telefono,
        ubicacion: ubicacion,
        fechaNacimiento: fechaNacimiento != null ? DateTime.tryParse(fechaNacimiento) : null,
        experienciaAgricola: experienciaAgricola,
        tamanoFinca: tamanoFinca,
        tipoAgricultura: tipoAgricultura,
        emailConfirmado: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
      );

      // 3. Guardar localmente primero
      await _databaseService.insertUser(user);
      await _cacheService.setCurrentUser(user);

      // 4. Intentar sincronizar con Supabase
      await _syncService.forceSyncUser(user);

      return user;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Inicia sesión con persistencia local
  static Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Supabase
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Credenciales inválidas');
      }

      // 2. Buscar usuario en cache/local primero
      UserModel? user = await _cacheService.getUserByEmail(email);
      
      if (user == null) {
        // 3. Si no está local, buscar en Supabase
        final response = await _client
            .from('usuarios')
            .select('*')
            .eq('email', email)
            .maybeSingle();

        if (response != null) {
          user = UserModel.fromJson(response);
          // Guardar localmente para futuras consultas
          await _databaseService.insertUser(user);
        }
      }

      if (user != null) {
        // 4. Actualizar cache de usuario actual
        await _cacheService.setCurrentUser(user);
        
        // 5. Sincronizar datos en segundo plano
        _syncService.syncData();
        
        return user;
      }

      throw Exception('Usuario no encontrado');
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cierra sesión y limpia datos locales
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _cacheService.clearCurrentUser();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Obtiene el usuario actual desde cache/local
  static Future<UserModel?> getCurrentUser() async {
    try {
      return await _cacheService.getCurrentUser();
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Actualiza el perfil del usuario con sincronización
  static Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    try {
      // 1. Actualizar localmente
       final userWithTimestamp = updatedUser.copyWith(
         updatedAt: DateTime.now(),
         needsSync: true,
       );
      
      await _databaseService.updateUser(userWithTimestamp);
      await _cacheService.updateUserCache(userWithTimestamp);

      // 2. Intentar sincronizar inmediatamente
      await _syncService.forceSyncUser(userWithTimestamp);

      return userWithTimestamp;
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Busca usuarios (primero local, luego remoto si hay conexión)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Por ahora, buscar solo en Supabase
      // En el futuro se podría implementar búsqueda local
      final response = await _client
          .from('usuarios')
          .select('*')
          .or('nombre.ilike.%$query%,ubicacion.ilike.%$query%,tipo_agricultura.ilike.%$query%')
          .order('updated_at', ascending: false);

      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      print('Error en búsqueda remota: $e');
      // Retornar lista vacía si hay error
      return [];
    }
  }

  /// Obtiene usuarios por ubicación
  static Future<List<UserModel>> getUsersByLocation(String location) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('*')
          .ilike('ubicacion', '%$location%')
          .order('updated_at', ascending: false);

      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      print('Error obteniendo usuarios por ubicación: $e');
      return [];
    }
  }

  /// Obtiene el estado de sincronización
  static Future<SyncStatus> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }

  /// Fuerza sincronización manual
  static Future<SyncResult> forcSync() async {
    return await _syncService.syncData();
  }

  /// Verifica si hay datos pendientes de sincronización
  static Future<bool> hasPendingSync() async {
    final status = await getSyncStatus();
    return status.pendingItems > 0 || status.usersNeedingSync > 0;
  }

  /// Limpia todos los datos locales (usar con precaución)
  static Future<void> clearAllLocalData() async {
    try {
      await _databaseService.clearAllData();
      await _cacheService.clearAllCache();
    } catch (e) {
      throw Exception('Error limpiando datos locales: $e');
    }
  }

  /// Obtiene estadísticas de cache
  static CacheStats getCacheStats() {
    return _cacheService.getCacheStats();
  }

  /// Limpia entradas de cache expiradas
  static void cleanupCache() {
    _cacheService.cleanupExpiredEntries();
  }

  /// Configura modo offline
  static Future<void> setOfflineMode(bool isOffline) async {
    await _cacheService.setOfflineMode(isOffline);
  }

  /// Verifica si está en modo offline
  static Future<bool> isOfflineMode() async {
    return await _cacheService.isOfflineMode();
  }

  /// Libera recursos
  static void dispose() {
    _syncService.dispose();
  }
}