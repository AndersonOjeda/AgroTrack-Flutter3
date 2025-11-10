import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'logger_service.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SupabaseClient _supabase = SupabaseService.client;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Inicializar servicio de sincronización
  void initialize() {
    _startPeriodicSync();
    _listenToConnectivity();
  }

  // Escuchar cambios de conectividad
  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // Cuando se recupera la conexión, sincronizar inmediatamente
        syncData();
      }
    });
  }

  // Iniciar sincronización periódica
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncData();
    });
  }

  // Verificar conectividad
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sincronización principal
  Future<SyncResult> syncData() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronización ya en progreso');
    }

    if (!await _hasInternetConnection()) {
      return SyncResult(success: false, message: 'Sin conexión a internet');
    }

    _isSyncing = true;
    
    try {
      LoggerService.info('Iniciando sincronización...');
      
      // 1. Sincronizar datos locales hacia Supabase
      final uploadResult = await _uploadLocalChanges();
      
      // 2. Descargar cambios desde Supabase
      final downloadResult = await _downloadRemoteChanges();
      
      // 3. Limpiar cola de sincronización exitosa
      await _cleanupSyncQueue();
      
      _isSyncing = false;
      
      if (uploadResult.success && downloadResult.success) {
        LoggerService.info('Sincronización completada exitosamente');
        return SyncResult(success: true, message: 'Sincronización completada');
      } else {
        return SyncResult(
          success: false, 
          message: 'Sincronización parcial: ${uploadResult.message}, ${downloadResult.message}'
        );
      }
      
    } catch (e) {
      _isSyncing = false;
      LoggerService.error('Error durante sincronización', error: e);
      return SyncResult(success: false, message: 'Error: $e');
    }
  }

  // Subir cambios locales a Supabase
  Future<SyncResult> _uploadLocalChanges() async {
    try {
      final pendingItems = await _databaseService.getPendingSyncItems();
      int successCount = 0;
      int errorCount = 0;

      for (final item in pendingItems) {
        try {
          final success = await _processSyncItem(item);
          if (success) {
            await _databaseService.markSyncItemAsProcessed(item['id']);
            successCount++;
          } else {
            await _databaseService.incrementSyncAttempts(item['id']);
            errorCount++;
          }
        } catch (e) {
          LoggerService.error('Error procesando item de sincronización ${item['id']}', error: e);
          await _databaseService.incrementSyncAttempts(item['id']);
          errorCount++;
        }
      }

      return SyncResult(
        success: errorCount == 0,
        message: 'Subida: $successCount exitosos, $errorCount errores'
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Error en subida: $e');
    }
  }

  // Procesar un item individual de sincronización
  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final tableName = item['table_name'];
      final operation = item['operation'];
      final data = item['data'] != null ? jsonDecode(item['data']) : null;

      switch (tableName) {
        case 'users':
          return await _syncUser(operation, data);
        case 'usuarios':
          // Compatibilidad: tratar entradas antiguas como 'users'
          return await _syncUser(operation, data);
        default:
          LoggerService.warning('Tabla no soportada para sincronización: $tableName');
          return false;
      }
    } catch (e) {
      LoggerService.error('Error procesando item de sincronización', error: e);
      return false;
    }
  }

  // Sincronizar usuario específico
  Future<bool> _syncUser(String operation, Map<String, dynamic>? userData) async {
    if (userData == null) return false;

    try {
      // Ensure correct mapping for Supabase: include auth_user_id/email
      final currentAuthUser = _supabase.auth.currentUser;
      if (currentAuthUser != null) {
        userData['auth_user_id'] = currentAuthUser.id;
        userData['email'] = userData['email'] ?? currentAuthUser.email;
      }

      // Determine conflict target for upsert
      final String conflictTarget =
          currentAuthUser != null ? 'auth_user_id' : 'email';

      switch (operation) {
        case 'INSERT':
        case 'UPDATE':
          final response = await _supabase
              .from('users')
              .upsert(userData, onConflict: conflictTarget)
              .select();
          return response.isNotEmpty;
        case 'DELETE':
          await _supabase
              .from('users')
              .delete()
              .eq('id', userData['id']);
          return true;
        default:
          return false;
      }
    } catch (e) {
      LoggerService.error('Error sincronizando usuario', error: e);
      return false;
    }
  }

  // Descargar cambios desde Supabase
  Future<SyncResult> _downloadRemoteChanges() async {
    try {
      if (!SupabaseService.isReady) {
        return SyncResult(success: false, message: 'Supabase no inicializado');
      }
      final lastSync = await _getLastSyncTimestamp();
      final response = await _supabase
          .from('users')
          .select('*')
          .gte('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: true);

      int syncedCount = 0;
      for (final userData in response) {
        try {
          final user = UserModel.fromJson(userData);
          
          // Verificar si hay conflictos
          final localUser = await _databaseService.getUserById(user.id!);
          if (localUser != null && localUser.updatedAt!.isAfter(user.updatedAt!)) {
            // Conflicto: versión local más reciente
            await _resolveConflict(localUser, user);
          } else {
            // Actualizar con versión remota
            await _databaseService.insertUser(user);
          }
          syncedCount++;
        } catch (e) {
          LoggerService.error('Error procesando usuario remoto', error: e);
        }
      }

      await _updateLastSyncTimestamp(DateTime.now());
      return SyncResult(
        success: true,
        message: 'Descarga: $syncedCount users synchronized'
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Error descargando cambios: $e');
    }
  }

  // Resolver conflictos entre versiones local y remota
  Future<UserModel?> _resolveConflict(UserModel localUser, UserModel remoteUser) async {
    // Estrategia: el más reciente gana
    final localUpdated = localUser.updatedAt;
    final remoteUpdated = remoteUser.updatedAt;
    
    if (localUpdated == null && remoteUpdated == null) {
      return remoteUser; // Preferir remoto si no hay timestamps
    }
    
    if (localUpdated == null) return remoteUser;
    if (remoteUpdated == null) return localUser;
    
    // Retornar el más reciente
    if (remoteUpdated.isAfter(localUpdated)) {
      return remoteUser;
    } else if (localUpdated.isAfter(remoteUpdated)) {
      return localUser;
    }
    
    // Si son iguales, preferir remoto
    return remoteUser;
  }

  // Obtener timestamp de última sincronización
  Future<DateTime> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('last_sync_at');
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Actualizar timestamp de última sincronización
  Future<void> _updateLastSyncTimestamp(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_at', time.millisecondsSinceEpoch);
  }

  // Limpiar cola de sincronización
  Future<void> _cleanupSyncQueue() async {
    // Remover elementos muy antiguos o con demasiados intentos
    final db = await _databaseService.database;
    
    // Remover elementos de más de 7 días
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    await db.delete(
      'sync_queue',
      where: 'created_at < ?',
      whereArgs: [weekAgo.toIso8601String()],
    );
  }

  // Sincronización manual forzada
  Future<SyncResult> forceSyncUser(UserModel user) async {
    if (!await _hasInternetConnection()) {
      return SyncResult(success: false, message: 'Sin conexión a internet');
    }

    try {
      if (!SupabaseService.isReady) {
        return SyncResult(success: false, message: 'Supabase no inicializado');
      }
      final data = user.toJson();
      // Ensure auth_user_id/email are present to target the correct row
      final currentAuthUser = _supabase.auth.currentUser;
      if (currentAuthUser != null) {
        data['auth_user_id'] = currentAuthUser.id;
        data['email'] = data['email'] ?? currentAuthUser.email;
      }
      final String conflictTarget =
          currentAuthUser != null ? 'auth_user_id' : 'email';

      final response = await _supabase
          .from('users')
          .upsert(data, onConflict: conflictTarget)
          .select();

      if (response.isNotEmpty) {
        await _databaseService.markUserAsSynced(user.id ?? user.email);
        return SyncResult(success: true, message: 'Usuario sincronizado correctamente');
      }

      return SyncResult(success: false, message: 'No se pudo sincronizar el usuario');
      
    } catch (e) {
      return SyncResult(success: false, message: 'Error sincronizando usuario: $e');
    }
  }

  // Obtener estado de sincronización
  Future<SyncStatus> getSyncStatus() async {
    final pendingItems = await _databaseService.getPendingSyncItems();
    final usersNeedingSync = await _databaseService.getUsersNeedingSync();
    final hasConnection = await _hasInternetConnection();
    
    return SyncStatus(
      isOnline: hasConnection,
      isSyncing: _isSyncing,
      pendingItems: pendingItems.length,
      usersNeedingSync: usersNeedingSync.length,
      lastSyncAt: await _getLastSyncTimestamp(),
    );
  }

  // Limpiar y detener servicio
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isSyncing = false;
  }
}

// Clases de resultado y estado
class SyncResult {
  final bool success;
  final String message;
  
  SyncResult({required this.success, required this.message});
}

class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingItems;
  final int usersNeedingSync;
  final DateTime? lastSyncAt;
  
  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingItems,
    required this.usersNeedingSync,
    this.lastSyncAt,
  });
}