import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'cache_service.dart';
import 'sync_service.dart';
import '../services/logger_service.dart';
import 'supabase_service.dart';
import '../utils/date_utils.dart';

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
    String? apellido,
    String? telefono,
    String? ubicacion,
    String? fechaNacimiento,
    String? experienciaAgricola,
    String? tamanoFinca,
    String? primaryCrops,
  }) async {
    try {
      // 1. Registrar en Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseService.emailRedirectUrl,
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear usuario en autenticación');
      }

      // 2. Crear modelo de usuario
      final user = UserModel(
        id: authResponse.user!.id,
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        ubicacion: ubicacion,
        fechaNacimiento: DateUtilsAgro.parseBirthDate(fechaNacimiento),
        experienciaAgricola: experienciaAgricola,
        tamanoFinca: tamanoFinca,
        primaryCrops: primaryCrops,
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
    bool performAuth = true,
  }) async {
    try {
      // 1. Autenticar con Supabase (opcional si ya se autenticó antes)
      if (performAuth) {
        final authResponse = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (authResponse.user == null) {
          throw Exception('Invalid credentials');
        }
      }

      // 2. Buscar usuario en cache/local primero
      UserModel? user = await _cacheService.getUserByEmail(email);
      
      if (user == null) {
        // 3. Si no está local, buscar en Supabase
        final responseUsers = await _client
            .from('users')
            .select('id, email, first_name as nombre, last_name as apellido, phone as telefono, location as ubicacion, primary_crops, farming_experience as experiencia_agricola, farm_size as tamano_finca, birth_date as fecha_nacimiento, bio, profile_image_url, email_confirmed as email_confirmado, created_at, updated_at')
            .eq('email', email)
            .maybeSingle();

        if (responseUsers != null) {
          user = UserModel.fromJson(responseUsers);
          await _databaseService.insertUser(user);
        }
      }

      if (user != null) {
        // 3b. Actualizar estado de confirmación de email desde Auth
        final authUser = _client.auth.currentUser;
        final isEmailConfirmed = authUser?.emailConfirmedAt != null;
        if (isEmailConfirmed && user.emailConfirmado != true) {
          final updatedUser = user.copyWith(emailConfirmado: true, updatedAt: DateTime.now(), needsSync: true);
          await _databaseService.updateUser(updatedUser);
          // Sincronizar de forma no bloqueante
          _syncService.forceSyncUser(updatedUser);
          user = updatedUser;
        }

        // 4. Actualizar cache de usuario actual
        await _cacheService.setCurrentUser(user);
        
        // 5. Sincronizar datos en segundo plano
        _syncService.syncData();
        
        return user;
      }

      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  /// Cierra sesión y limpia datos locales
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _cacheService.clearCurrentUser();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  /// Obtiene el usuario actual desde cache/local
  static Future<UserModel?> getCurrentUser() async {
    try {
      return await _cacheService.getCurrentUser();
    } catch (e) {
      LoggerService.error('Error obteniendo usuario actual', error: e);
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

      // 2. Intentar sincronizar inmediatamente (no bloquear)
      // Ejecutar sin await para no dejar la UI cargando
      _syncService.forceSyncUser(userWithTimestamp);

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
          .from('users')
          .select('id, email, first_name as nombre, last_name as apellido, phone as telefono, location as ubicacion, primary_crops, farming_experience as experiencia_agricola, farm_size as tamano_finca, birth_date as fecha_nacimiento, bio, profile_image_url, email_confirmed as email_confirmado, created_at, updated_at')
          .or('first_name.ilike.%$query%,location.ilike.%$query%,primary_crops.ilike.%$query%')
          .order('updated_at', ascending: false);

      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      LoggerService.error('Error en búsqueda remota', error: e);
      // Retornar lista vacía si hay error
      return [];
    }
  }

  /// Obtiene usuarios por ubicación
  static Future<List<UserModel>> getUsersByLocation(String location) async {
    try {
      final response = await _client
          .from('users')
          .select('id, email, first_name as nombre, last_name as apellido, phone as telefono, location as ubicacion, primary_crops, farming_experience as experiencia_agricola, farm_size as tamano_finca, birth_date as fecha_nacimiento, bio, profile_image_url, email_confirmed as email_confirmado, created_at, updated_at')
          .ilike('location', '%$location%')
          .order('updated_at', ascending: false);

      return response.map<UserModel>((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      LoggerService.error('Error obteniendo usuarios por ubicación', error: e);
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