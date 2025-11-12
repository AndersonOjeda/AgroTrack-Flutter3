import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'logger_service.dart';
import 'inventory_service.dart';

// Variable global para el databaseFactory
DatabaseFactory? _databaseFactory;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Método para establecer el databaseFactory
  static void setDatabaseFactory(DatabaseFactory factory) {
    _databaseFactory = factory;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_databaseFactory == null) {
      throw Exception(
        'DatabaseFactory no ha sido inicializado. Llama a DatabaseService.setDatabaseFactory() primero.',
      );
    }

    // Para web, usar un path simple
    String path = 'agrotrack.db';

    return await _databaseFactory!.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        location TEXT,
        birth_date TEXT,
        farming_experience TEXT,
        farm_size TEXT,
        primary_crops TEXT,
        bio TEXT,
        profile_image_url TEXT,
        email_confirmed INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        last_sync_at TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');

    // Tabla para manejar sincronización pendiente
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        attempts INTEGER DEFAULT 0
      )
    ''');

    // Crear tabla de inventario
    await InventoryService.createTable(db);

    // Crear tabla de ubicaciones de fincas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farm_locations (
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

    // Índices para mejorar rendimiento
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_needs_sync ON users(needs_sync)');
    await db.execute(
      'CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)',
    );
    await db.execute(
      'CREATE INDEX idx_farm_locations_user_id ON farm_locations(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_farm_locations_sync ON farm_locations(needs_sync)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar actualizaciones de esquema aquí
    if (oldVersion < 2) {
      // Ejemplo de migración futura
      // await db.execute('ALTER TABLE users ADD COLUMN new_column TEXT');
    }
  }

  // CRUD para users
  Future<int> insertUser(UserModel user) async {
    final db = await database;

    try {
      final userMap = user.toMap();
      userMap['created_at'] = DateTime.now().toIso8601String();
      userMap['updated_at'] = DateTime.now().toIso8601String();
      userMap['needs_sync'] = 1; // Marcar para sincronización

      await db.insert(
        'users',
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Agregar a cola de sincronización
      await _addToSyncQueue('users', user.id ?? user.email, 'INSERT', userMap);

      return 1;
    } catch (e) {
      LoggerService.error('Error insertando usuario', error: e);
      return 0;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error obteniendo usuario', error: e);
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error obteniendo usuario por ID', error: e);
      return null;
    }
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;

    try {
      final userMap = user.toMap();
      userMap['updated_at'] = DateTime.now().toIso8601String();
      userMap['needs_sync'] = 1; // Marcar para sincronización

      final result = await db.update(
        'users',
        userMap,
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Agregar a cola de sincronización
      await _addToSyncQueue('users', user.id!, 'UPDATE', userMap);

      return result;
    } catch (e) {
      LoggerService.error('Error actualizando usuario', error: e);
      return 0;
    }
  }

  Future<int> deleteUser(String id) async {
    final db = await database;

    try {
      final result = await db.delete('users', where: 'id = ?', whereArgs: [id]);

      // Agregar a cola de sincronización
      await _addToSyncQueue('users', id, 'DELETE', null);

      return result;
    } catch (e) {
      LoggerService.error('Error eliminando usuario', error: e);
      return 0;
    }
  }

  Future<List<UserModel>> getUsersNeedingSync() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'needs_sync = ?',
        whereArgs: [1],
      );

      return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
    } catch (e) {
      LoggerService.error('Error obteniendo usuarios para sincronizar: $e');
      return [];
    }
  }

  Future<void> markUserAsSynced(String id) async {
    final db = await database;

    try {
      await db.update(
        'users',
        {'needs_sync': 0, 'last_sync_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      LoggerService.error('Error marcando usuario como sincronizado: $e');
    }
  }

  // Manejo de cola de sincronización
  Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic>? data,
  ) async {
    final db = await database;

    try {
      await db.insert('sync_queue', {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': data != null ? jsonEncode(data) : null,
        'created_at': DateTime.now().toIso8601String(),
        'attempts': 0,
      });
    } catch (e) {
      LoggerService.error('Error agregando a cola de sincronización: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;

    try {
      return await db.query(
        'sync_queue',
        orderBy: 'created_at ASC',
        limit: 50, // Procesar en lotes
      );
    } catch (e) {
      LoggerService.error('Error obteniendo elementos de sincronización: $e');
      return [];
    }
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;

    try {
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      LoggerService.error('Error removiendo elemento de sincronización: $e');
    }
  }

  Future<void> incrementSyncAttempts(int id) async {
    final db = await database;

    try {
      await db.rawUpdate(
        'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
        [id],
      );
    } catch (e) {
      LoggerService.error('Error incrementando intentos de sincronización: $e');
    }
  }

  Future<void> markSyncItemAsProcessed(int id) async {
    final db = await database;

    try {
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      LoggerService.error('Error marcando elemento como procesado: $e');
    }
  }

  // Limpiar datos
  Future<void> clearAllData() async {
    final db = await database;

    try {
      await db.delete('users');
      await db.delete('sync_queue');
    } catch (e) {
      LoggerService.error('Error limpiando datos', error: e);
    }
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
