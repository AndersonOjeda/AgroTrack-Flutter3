import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'agrotrack.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefono TEXT,
        ubicacion TEXT,
        fecha_nacimiento TEXT,
        experiencia_agricola TEXT,
        tamano_finca TEXT,
        tipo_agricultura TEXT,
        email_confirmado INTEGER DEFAULT 0,
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

    // Índices para mejorar rendimiento
    await db.execute('CREATE INDEX idx_usuarios_email ON usuarios(email)');
    await db.execute('CREATE INDEX idx_usuarios_needs_sync ON usuarios(needs_sync)');
    await db.execute('CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar actualizaciones de esquema aquí
    if (oldVersion < 2) {
      // Ejemplo de migración futura
      // await db.execute('ALTER TABLE usuarios ADD COLUMN nueva_columna TEXT');
    }
  }

  // CRUD para usuarios
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    
    try {
      final userMap = user.toMap();
      userMap['created_at'] = DateTime.now().toIso8601String();
      userMap['updated_at'] = DateTime.now().toIso8601String();
      userMap['needs_sync'] = 1; // Marcar para sincronización
      
      await db.insert('usuarios', userMap, conflictAlgorithm: ConflictAlgorithm.replace);
      
      // Agregar a cola de sincronización
      await _addToSyncQueue('usuarios', user.id ?? user.email, 'INSERT', userMap);
      
      return 1;
    } catch (e) {
      print('Error insertando usuario: $e');
      return 0;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario por ID: $e');
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
        'usuarios',
        userMap,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      
      // Agregar a cola de sincronización
      await _addToSyncQueue('usuarios', user.id!, 'UPDATE', userMap);
      
      return result;
    } catch (e) {
      print('Error actualizando usuario: $e');
      return 0;
    }
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    
    try {
      final result = await db.delete(
        'usuarios',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Agregar a cola de sincronización
      await _addToSyncQueue('usuarios', id, 'DELETE', null);
      
      return result;
    } catch (e) {
      print('Error eliminando usuario: $e');
      return 0;
    }
  }

  Future<List<UserModel>> getUsersNeedingSync() async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'usuarios',
        where: 'needs_sync = ?',
        whereArgs: [1],
      );

      return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
    } catch (e) {
      print('Error obteniendo usuarios para sincronizar: $e');
      return [];
    }
  }

  Future<void> markUserAsSynced(String id) async {
    final db = await database;
    
    try {
      await db.update(
        'usuarios',
        {
          'needs_sync': 0,
          'last_sync_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marcando usuario como sincronizado: $e');
    }
  }

  // Manejo de cola de sincronización
  Future<void> _addToSyncQueue(String tableName, String recordId, String operation, Map<String, dynamic>? data) async {
    final db = await database;
    
    try {
      await db.insert('sync_queue', {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': data != null ? data.toString() : null,
        'created_at': DateTime.now().toIso8601String(),
        'attempts': 0,
      });
    } catch (e) {
      print('Error agregando a cola de sincronización: $e');
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
      print('Error obteniendo elementos de sincronización: $e');
      return [];
    }
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    
    try {
      await db.delete(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error removiendo elemento de sincronización: $e');
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
      print('Error incrementando intentos de sincronización: $e');
    }
  }

  // Limpiar datos
  Future<void> clearAllData() async {
    final db = await database;
    
    try {
      await db.delete('usuarios');
      await db.delete('sync_queue');
    } catch (e) {
      print('Error limpiando datos: $e');
    }
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}