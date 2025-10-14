import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DatabaseService _databaseService = DatabaseService();
  
  // Cache en memoria para acceso rápido
  final Map<String, UserModel> _userCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Configuración de cache
  static const Duration _cacheExpiration = Duration(minutes: 30);
  static const int _maxCacheSize = 100;
  
  // Claves para SharedPreferences
  static const String _currentUserKey = 'current_user';
  static const String _userSessionKey = 'user_session';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _offlineModeKey = 'offline_mode';

  // Obtener usuario actual desde cache
  Future<UserModel?> getCurrentUser() async {
    try {
      // Primero intentar desde cache en memoria
      final cachedUser = _getCachedUser(_currentUserKey);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Luego desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        _setCachedUser(_currentUserKey, user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error obteniendo usuario actual desde cache: $e');
      return null;
    }
  }

  // Guardar usuario actual en cache
  Future<void> setCurrentUser(UserModel user) async {
    try {
      // Guardar en cache en memoria
      _setCachedUser(_currentUserKey, user);
      
      // Guardar en SharedPreferences para persistencia
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      
      // También guardar en base de datos local
      await _databaseService.insertUser(user);
      
    } catch (e) {
      print('Error guardando usuario actual en cache: $e');
    }
  }

  // Obtener usuario por email con cache
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      // Verificar cache en memoria primero
      final cacheKey = 'user_$email';
      final cachedUser = _getCachedUser(cacheKey);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Buscar en base de datos local
      final user = await _databaseService.getUserByEmail(email);
      if (user != null) {
        _setCachedUser(cacheKey, user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error obteniendo usuario por email desde cache: $e');
      return null;
    }
  }

  // Obtener usuario por ID con cache
  Future<UserModel?> getUserById(String id) async {
    try {
      // Verificar cache en memoria primero
      final cacheKey = 'user_id_$id';
      final cachedUser = _getCachedUser(cacheKey);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Buscar en base de datos local
      final user = await _databaseService.getUserById(id);
      if (user != null) {
        _setCachedUser(cacheKey, user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error obteniendo usuario por ID desde cache: $e');
      return null;
    }
  }

  // Actualizar usuario en cache
  Future<void> updateUserCache(UserModel user) async {
    try {
      // Actualizar todos los posibles caches del usuario
      final emailKey = 'user_${user.email}';
      final idKey = user.id != null ? 'user_id_${user.id}' : null;
      
      _setCachedUser(emailKey, user);
      if (idKey != null) {
        _setCachedUser(idKey, user);
      }
      
      // Si es el usuario actual, actualizar también
      final currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.email == user.email) {
        await setCurrentUser(user);
      }
      
      // Actualizar en base de datos
      await _databaseService.updateUser(user);
      
    } catch (e) {
      print('Error actualizando usuario en cache: $e');
    }
  }

  // Invalidar cache de usuario
  void invalidateUserCache(String email) {
    final emailKey = 'user_$email';
    _userCache.remove(emailKey);
    _cacheTimestamps.remove(emailKey);
    
    // También invalidar por ID si existe
    final user = _userCache.values.firstWhere(
      (u) => u.email == email,
      orElse: () => UserModel(nombre: '', email: ''),
    );
    
    if (user.id != null) {
      final idKey = 'user_id_${user.id}';
      _userCache.remove(idKey);
      _cacheTimestamps.remove(idKey);
    }
  }

  // Limpiar usuario actual
  Future<void> clearCurrentUser() async {
    try {
      // Limpiar cache en memoria
      _userCache.remove(_currentUserKey);
      _cacheTimestamps.remove(_currentUserKey);
      
      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_userSessionKey);
      
    } catch (e) {
      print('Error limpiando usuario actual: $e');
    }
  }

  // Gestión de sesión de usuario
  Future<void> setUserSession(String sessionToken, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'token': sessionToken,
        'expires_at': (DateTime.now().add(expiration ?? const Duration(days: 7))).toIso8601String(),
      };
      
      await prefs.setString(_userSessionKey, jsonEncode(sessionData));
    } catch (e) {
      print('Error guardando sesión de usuario: $e');
    }
  }

  Future<String?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_userSessionKey);
      
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson);
        final expiresAt = DateTime.parse(sessionData['expires_at']);
        
        if (DateTime.now().isBefore(expiresAt)) {
          return sessionData['token'];
        } else {
          // Sesión expirada, limpiarla
          await prefs.remove(_userSessionKey);
        }
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo sesión de usuario: $e');
      return null;
    }
  }

  // Gestión de timestamp de sincronización
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimestampKey, timestamp.toIso8601String());
    } catch (e) {
      print('Error guardando timestamp de sincronización: $e');
    }
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_lastSyncTimestampKey);
      
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo timestamp de sincronización: $e');
      return null;
    }
  }

  // Modo offline
  Future<void> setOfflineMode(bool isOffline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, isOffline);
    } catch (e) {
      print('Error configurando modo offline: $e');
    }
  }

  Future<bool> isOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_offlineModeKey) ?? false;
    } catch (e) {
      print('Error obteniendo modo offline: $e');
      return false;
    }
  }

  // Precargar datos frecuentemente usados
  Future<void> preloadFrequentData() async {
    try {
      // Precargar usuario actual
      await getCurrentUser();
      
      // Precargar usuarios que necesitan sincronización
      final usersNeedingSync = await _databaseService.getUsersNeedingSync();
      for (final user in usersNeedingSync.take(10)) { // Limitar a 10
        _setCachedUser('user_${user.email}', user);
        if (user.id != null) {
          _setCachedUser('user_id_${user.id}', user);
        }
      }
      
    } catch (e) {
      print('Error precargando datos: $e');
    }
  }

  // Métodos privados para gestión de cache en memoria
  UserModel? _getCachedUser(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) > _cacheExpiration) {
      // Cache expirado
      _userCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _userCache[key];
  }

  void _setCachedUser(String key, UserModel user) {
    // Limpiar cache si está lleno
    if (_userCache.length >= _maxCacheSize) {
      _cleanupOldestCacheEntries();
    }
    
    _userCache[key] = user;
    _cacheTimestamps[key] = DateTime.now();
  }

  void _cleanupOldestCacheEntries() {
    // Remover las 20 entradas más antiguas
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (int i = 0; i < 20 && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _userCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Limpiar todo el cache
  Future<void> clearAllCache() async {
    try {
      // Limpiar cache en memoria
      _userCache.clear();
      _cacheTimestamps.clear();
      
      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_userSessionKey);
      await prefs.remove(_lastSyncTimestampKey);
      await prefs.remove(_offlineModeKey);
      
    } catch (e) {
      print('Error limpiando todo el cache: $e');
    }
  }

  // Obtener estadísticas del cache
  CacheStats getCacheStats() {
    final now = DateTime.now();
    int expiredEntries = 0;
    
    for (final timestamp in _cacheTimestamps.values) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredEntries++;
      }
    }
    
    return CacheStats(
      totalEntries: _userCache.length,
      expiredEntries: expiredEntries,
      memoryUsage: _userCache.length * 1024, // Estimación aproximada
      hitRate: 0.0, // Se podría implementar contadores para esto
    );
  }

  // Limpiar entradas expiradas
  void cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiration) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _userCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}

// Estadísticas del cache
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int memoryUsage; // En bytes (aproximado)
  final double hitRate;
  
  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.memoryUsage,
    required this.hitRate,
  });
  
  int get activeEntries => totalEntries - expiredEntries;
  double get memoryUsageKB => memoryUsage / 1024;
}