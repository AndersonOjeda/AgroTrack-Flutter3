import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farm_location_model.dart';
import 'database_service.dart';
import 'logger_service.dart';


class FarmLocationService {
  static const String _tableName = 'farm_locations';
  static final FarmLocationService _instance = FarmLocationService._internal();
  factory FarmLocationService() => _instance;
  FarmLocationService._internal();

  final Uuid _uuid = const Uuid();
  static final SupabaseClient _client = Supabase.instance.client;

  /// Crear tabla de ubicaciones de fincas
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT,
        created_at TEXT,
        updated_at TEXT,
        needs_sync INTEGER DEFAULT 1
      )
    ''');

    // Crear índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_farm_locations_user_id ON $_tableName(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_farm_locations_sync ON $_tableName(needs_sync)');
  }

  /// Obtener todas las ubicaciones del usuario actual
  Future<List<FarmLocationModel>> getUserLocations() async {
    try {
      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) {
        LoggerService.warning('No hay usuario autenticado');
        return [];
      }

      final db = await DatabaseService().database;
      final maps = await db.query(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [authUser.id],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => FarmLocationModel.fromMap(map)).toList();
    } catch (e) {
      LoggerService.error('Error obteniendo ubicaciones del usuario: $e');
      return [];
    }
  }

  /// Agregar nueva ubicación de finca
  Future<bool> addLocation(String name, double latitude, double longitude, {String? description}) async {
    try {
      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) {
        LoggerService.warning('No hay usuario autenticado');
        throw Exception('Usuario no autenticado');
      }
      
      // Usar el ID del usuario autenticado de Supabase
      final userId = authUser.id;

      // Verificar si ya existe una ubicación con el mismo nombre para este usuario
      final existingLocations = await getUserLocations();
      final duplicateName = existingLocations.any((loc) => 
        loc.name.toLowerCase().trim() == name.toLowerCase().trim()
      );
      
      if (duplicateName) {
        LoggerService.info('Ubicación con nombre duplicado: $name');
        throw Exception('Ya existe una ubicación con el nombre "$name"');
      }

      // Verificar si ya existe una ubicación con coordenadas muy similares
      const double tolerance = 0.001; // ~100 metros de tolerancia
      final duplicateCoords = existingLocations.any((loc) => 
        (loc.latitude - latitude).abs() < tolerance && 
        (loc.longitude - longitude).abs() < tolerance
      );
      
      if (duplicateCoords) {
        LoggerService.info('Ubicación con coordenadas duplicadas: $latitude, $longitude');
        throw Exception('Ya existe una ubicación en estas coordenadas');
      }

      final location = FarmLocationModel(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: true,
      );

      final db = await DatabaseService().database;
      await db.insert(_tableName, location.toMap());

      LoggerService.info('Ubicación de finca agregada: $name');
      
      // Intentar sincronizar inmediatamente
      _syncToSupabase();
      
      return true;
    } catch (e) {
      LoggerService.error('Error agregando ubicación de finca: $e');
      rethrow; // Re-lanzar la excepción para que la UI pueda manejarla
    }
  }

  /// Eliminar ubicación de finca
  Future<bool> removeLocation(String locationId) async {
    try {
      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) {
        LoggerService.warning('No hay usuario autenticado');
        return false;
      }

      final db = await DatabaseService().database;
      final result = await db.delete(
        _tableName,
        where: 'id = ? AND user_id = ?',
        whereArgs: [locationId, authUser.id],
      );

      if (result > 0) {
        LoggerService.info('Ubicación de finca eliminada: $locationId');
        
        // Marcar para eliminación en Supabase
        _markForDeletionInSupabase(locationId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      LoggerService.error('Error eliminando ubicación de finca: $e');
      return false;
    }
  }



  /// Verificar conexión a internet
  static Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Sincronizar con Supabase
  Future<void> _syncToSupabase() async {
    try {
      if (!await _hasInternetConnection()) return;

      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) return;

      final db = await DatabaseService().database;
      final pendingSync = await db.query(
        _tableName,
        where: 'user_id = ? AND needs_sync = 1',
        whereArgs: [authUser.id],
      );

      for (final map in pendingSync) {
        final location = FarmLocationModel.fromMap(map);
        
        try {
          final response = await _client
              .from('farm_locations')
              .upsert(location.toJson())
              .select();

          if (response.isNotEmpty) {
            // Marcar como sincronizado
            await db.update(
              _tableName,
              {'needs_sync': 0},
              where: 'id = ?',
              whereArgs: [location.id],
            );
            
            LoggerService.info('Ubicación sincronizada: ${location.name}');
          }
        } catch (e) {
          LoggerService.error('Error sincronizando ubicación ${location.name}: $e');
        }
      }
    } catch (e) {
      LoggerService.error('Error en sincronización con Supabase: $e');
    }
  }

  /// Marcar ubicación para eliminación en Supabase
  Future<void> _markForDeletionInSupabase(String locationId) async {
    try {
      if (!await _hasInternetConnection()) return;
      
      await _client
          .from('farm_locations')
          .delete()
          .eq('id', locationId);
      
      LoggerService.info('Ubicación eliminada de Supabase: $locationId');
    } catch (e) {
      LoggerService.error('Error eliminando ubicación de Supabase: $e');
    }
  }

  /// Sincronizar ubicaciones desde Supabase
  Future<void> syncFromSupabase() async {
    try {
      if (!await _hasInternetConnection()) return;

      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) return;

      final response = await _client
          .from('farm_locations')
          .select()
          .eq('user_id', authUser.id);

      final db = await DatabaseService().database;
      
      for (final json in response) {
        final location = FarmLocationModel.fromJson(json).copyWith(needsSync: false);
        
        await db.insert(
          _tableName,
          location.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      LoggerService.info('Ubicaciones sincronizadas desde Supabase: ${response.length}');
    } catch (e) {
      LoggerService.error('Error sincronizando desde Supabase: $e');
    }
  }

  /// Limpiar todas las ubicaciones del usuario (para testing)
  Future<void> clearUserLocations() async {
    try {
      // Verificar autenticación usando Supabase directamente
      final session = _client.auth.currentSession;
      final authUser = session?.user;
      
      if (authUser == null) return;

      final db = await DatabaseService().database;
      await db.delete(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [authUser.id],
      );
      
      LoggerService.info('Ubicaciones del usuario limpiadas');
    } catch (e) {
      LoggerService.error('Error limpiando ubicaciones: $e');
    }
  }
}