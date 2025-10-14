import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
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
      print('Iniciando sincronización...');
      
      // 1. Sincronizar datos locales hacia Supabase
      final uploadResult = await _uploadLocalChanges();
      
      // 2. Descargar cambios desde Supabase
      final downloadResult = await _downloadRemoteChanges();
      
      // 3. Limpiar cola de sincronización exitosa
      await _cleanupSyncQueue();
      
      _isSyncing = false;
      
      if (uploadResult.success && downloadResult.success) {
        print('Sincronización completada exitosamente');
        return SyncResult(success: true, message: 'Sincronización completada');
      } else {
        return SyncResult(
          success: false, 
          message: 'Sincronización parcial: ${uploadResult.message}, ${downloadResult.message}'
        );
      }
      
    } catch (e) {
      _isSyncing = false;
      print('Error durante sincronización: $e');
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
            await _databaseService.removeSyncItem(item['id']);
            successCount++;
          } else {
            await _databaseService.incrementSyncAttempts(item['id']);
            errorCount++;
            
            // Remover elementos con demasiados intentos fallidos
            if (item['attempts'] >= 5) {
              await _databaseService.removeSyncItem(item['id']);
              print('Removiendo elemento con demasiados intentos fallidos: ${item['id']}');
            }
          }
        } catch (e) {
          print('Error procesando elemento de sincronización: $e');
          await _databaseService.incrementSyncAttempts(item['id']);
          errorCount++;
        }
      }

      return SyncResult(
        success: errorCount == 0,
        message: 'Subida: $successCount exitosos, $errorCount errores'
      );
      
    } catch (e) {
      return SyncResult(success: false, message: 'Error subiendo cambios: $e');
    }
  }

  // Procesar elemento individual de sincronización
  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'];
    final recordId = item['record_id'];
    final operation = item['operation'];
    
    if (tableName == 'usuarios') {
      return await _syncUserRecord(recordId, operation, item['data']);
    }
    
    return false;
  }

  // Sincronizar registro de usuario específico
  Future<bool> _syncUserRecord(String recordId, String operation, String? data) async {
    try {
      switch (operation) {
        case 'INSERT':
        case 'UPDATE':
          final user = await _databaseService.getUserById(recordId) ?? 
                      await _databaseService.getUserByEmail(recordId);
          
          if (user != null) {
            final userJson = user.toJson();
            
            // Verificar si el usuario ya existe en Supabase
            final existingUser = await _supabase
                .from('usuarios')
                .select()
                .eq('email', user.email)
                .maybeSingle();
            
            if (existingUser != null) {
              // Actualizar usuario existente
              await _supabase
                  .from('usuarios')
                  .update(userJson)
                  .eq('email', user.email);
            } else {
              // Insertar nuevo usuario
              await _supabase
                  .from('usuarios')
                  .insert(userJson);
            }
            
            // Marcar como sincronizado localmente
            await _databaseService.markUserAsSynced(user.id ?? user.email);
            return true;
          }
          break;
          
        case 'DELETE':
          await _supabase
              .from('usuarios')
              .delete()
              .eq('id', recordId);
          return true;
      }
      
      return false;
    } catch (e) {
      print('Error sincronizando usuario $recordId: $e');
      return false;
    }
  }

  // Descargar cambios desde Supabase
  Future<SyncResult> _downloadRemoteChanges() async {
    try {
      // Obtener timestamp de última sincronización
      final lastSync = await _getLastSyncTimestamp();
      
      // Consultar usuarios modificados desde la última sincronización
      final query = _supabase
          .from('usuarios')
          .select();
      
      if (lastSync != null) {
        query.gt('updated_at', lastSync.toIso8601String());
      }
      
      final remoteUsers = await query;
      int syncedCount = 0;
      
      for (final userData in remoteUsers) {
        try {
          final remoteUser = UserModel.fromJson(userData);
          final localUser = await _databaseService.getUserByEmail(remoteUser.email);
          
          if (localUser == null) {
            // Usuario no existe localmente, insertarlo
            await _databaseService.insertUser(remoteUser);
            await _databaseService.markUserAsSynced(remoteUser.id ?? remoteUser.email);
            syncedCount++;
          } else {
            // Resolver conflictos si es necesario
            final resolvedUser = await _resolveConflict(localUser, remoteUser);
            if (resolvedUser != null) {
              await _databaseService.updateUser(resolvedUser);
              await _databaseService.markUserAsSynced(resolvedUser.id ?? resolvedUser.email);
              syncedCount++;
            }
          }
        } catch (e) {
          print('Error procesando usuario remoto: $e');
        }
      }
      
      // Actualizar timestamp de última sincronización
      await _updateLastSyncTimestamp();
      
      return SyncResult(
        success: true,
        message: 'Descarga: $syncedCount usuarios sincronizados'
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
  Future<DateTime?> _getLastSyncTimestamp() async {
    // Implementar almacenamiento de timestamp en SharedPreferences o SQLite
    // Por simplicidad, retornamos null por ahora
    return null;
  }

  // Actualizar timestamp de última sincronización
  Future<void> _updateLastSyncTimestamp() async {
    // Implementar almacenamiento de timestamp
    // Por ahora no hace nada
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
      final userJson = user.toJson();
      
      // Verificar si existe en Supabase
      final existingUser = await _supabase
          .from('usuarios')
          .select()
          .eq('email', user.email)
          .maybeSingle();
      
      if (existingUser != null) {
        await _supabase
            .from('usuarios')
            .update(userJson)
            .eq('email', user.email);
      } else {
        await _supabase
            .from('usuarios')
            .insert(userJson);
      }
      
      // Marcar como sincronizado
      await _databaseService.markUserAsSynced(user.id ?? user.email);
      
      return SyncResult(success: true, message: 'Usuario sincronizado exitosamente');
      
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