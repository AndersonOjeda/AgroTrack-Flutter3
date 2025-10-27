import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import '../models/inventory_item_model.dart';
import 'database_service.dart';
import 'inventory_sync_service.dart';

class InventoryService {
  final DatabaseService _databaseService = DatabaseService();
  final InventorySyncService _syncService = InventorySyncService();

  static const String _tableName = 'inventory_items';

  // Crear tabla de inventario
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        descripcion TEXT,
        cantidad REAL NOT NULL,
        unidad_medida TEXT NOT NULL,
        precio_unitario REAL,
        valor_total REAL,
        proveedor TEXT,
        fecha_compra TEXT,
        fecha_vencimiento TEXT,
        ubicacion_almacen TEXT,
        lote TEXT,
        cantidad_minima REAL,
        estado TEXT,
        notas TEXT,
        imagen_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        needs_sync INTEGER DEFAULT 0
      )
    ''');

    // Crear índices para optimizar consultas
    await db.execute('CREATE INDEX idx_inventory_categoria ON $_tableName(categoria)');
    await db.execute('CREATE INDEX idx_inventory_estado ON $_tableName(estado)');
    await db.execute('CREATE INDEX idx_inventory_needs_sync ON $_tableName(needs_sync)');
    await db.execute('CREATE INDEX idx_inventory_fecha_vencimiento ON $_tableName(fecha_vencimiento)');
  }

  // Crear nuevo elemento del inventario
  Future<String?> createItem(InventoryItemModel item) async {
    try {
      final db = await _databaseService.database;
      
      // Insertar en la base de datos local
      await db.insert(_tableName, item.toMap());
      
      // Marcar para sincronización
      await _markForSync(item.id!);
      
      // Intentar sincronizar inmediatamente si hay conexión
      await _syncService.syncItem(item);
      
      return item.id;
    } catch (e) {
      developer.log('Error creando item: $e', name: 'InventoryService', error: e);
      return null;
    }
  }

  // Obtener todos los elementos del inventario
  Future<List<InventoryItemModel>> getAllItems() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      
      return List.generate(maps.length, (i) {
        return InventoryItemModel.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('Error obteniendo items: $e', name: 'InventoryService', error: e);
      return [];
    }
  }

  // Obtener elemento por ID
  Future<InventoryItemModel?> getItemById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return InventoryItemModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error obteniendo item por ID: $e', name: 'InventoryService', error: e);
      return null;
    }
  }

  // Actualizar elemento del inventario
  Future<bool> updateItem(InventoryItemModel item) async {
    try {
      final db = await _databaseService.database;
      
      final count = await db.update(
        _tableName,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (count > 0) {
        // Marcar para sincronización
        await _markForSync(item.id!);
        
        // Intentar sincronizar inmediatamente si hay conexión
        await _syncService.syncItem(item);
        
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error actualizando item: $e', name: 'InventoryService', error: e);
      return false;
    }
  }

  // Eliminar elemento del inventario
  Future<bool> deleteItem(String id) async {
    try {
      final db = await _databaseService.database;
      
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count > 0) {
        // Eliminar de Supabase también
        await _syncService.deleteItemFromSupabase(id);
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error eliminando item: $e', name: 'InventoryService', error: e);
      return false;
    }
  }

  // Buscar elementos por nombre o categoría
  Future<List<InventoryItemModel>> searchItems(String query) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'nombre LIKE ? OR categoria LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      
      return List.generate(maps.length, (i) {
        return InventoryItemModel.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('Error buscando items: $e', name: 'InventoryService', error: e);
      return [];
    }
  }

  // Obtener elementos por categoría
  Future<List<InventoryItemModel>> getItemsByCategory(String categoria) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'categoria = ?',
        whereArgs: [categoria],
      );
      
      return List.generate(maps.length, (i) {
        return InventoryItemModel.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('Error obteniendo items por categoría: $e', name: 'InventoryService', error: e);
      return [];
    }
  }

  // Obtener elementos con stock bajo
  Future<List<InventoryItemModel>> getLowStockItems() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM $_tableName 
        WHERE cantidad <= cantidad_minima 
        AND cantidad_minima IS NOT NULL
      ''');
      
      return List.generate(maps.length, (i) {
        return InventoryItemModel.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('Error obteniendo items con stock bajo: $e', name: 'InventoryService', error: e);
      return [];
    }
  }

  // Obtener elementos próximos a vencer
  Future<List<InventoryItemModel>> getExpiringItems(int daysAhead) async {
    try {
      final db = await _databaseService.database;
      final DateTime futureDate = DateTime.now().add(Duration(days: daysAhead));
      final String futureDateStr = futureDate.toIso8601String().split('T')[0];
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'fecha_vencimiento <= ? AND fecha_vencimiento IS NOT NULL',
        whereArgs: [futureDateStr],
      );
      
      return List.generate(maps.length, (i) {
        return InventoryItemModel.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('Error obteniendo items próximos a vencer: $e', name: 'InventoryService', error: e);
      return [];
    }
  }

  // Obtener estadísticas del inventario
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final db = await _databaseService.database;
      
      // Total de items
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final totalItems = totalResult.first['count'] as int;
      
      // Items con stock bajo
      final lowStockResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $_tableName 
        WHERE cantidad <= cantidad_minima 
        AND cantidad_minima IS NOT NULL
      ''');
      final lowStockItems = lowStockResult.first['count'] as int;
      
      // Items próximos a vencer (próximos 30 días)
      final DateTime futureDate = DateTime.now().add(const Duration(days: 30));
      final String futureDateStr = futureDate.toIso8601String().split('T')[0];
      
      final expiringResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $_tableName 
        WHERE fecha_vencimiento <= ? 
        AND fecha_vencimiento IS NOT NULL
      ''', [futureDateStr]);
      final expiringItems = expiringResult.first['count'] as int;
      
      // Valor total del inventario
      final valueResult = await db.rawQuery('''
        SELECT SUM(valor_total) as total FROM $_tableName 
        WHERE valor_total IS NOT NULL
      ''');
      final totalValue = valueResult.first['total'] as double? ?? 0.0;
      
      return {
        'totalItems': totalItems,
        'lowStockItems': lowStockItems,
        'expiringItems': expiringItems,
        'totalValue': totalValue,
      };
    } catch (e) {
      developer.log('Error obteniendo estadísticas: $e', name: 'InventoryService', error: e);
      return {
        'totalItems': 0,
        'lowStockItems': 0,
        'expiringItems': 0,
        'totalValue': 0.0,
      };
    }
  }

  // Marcar elemento para sincronización
  Future<void> _markForSync(String id) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        _tableName,
        {'needs_sync': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error marcando item para sync: $e', name: 'InventoryService', error: e);
    }
  }

  // Sincronizar elementos pendientes
  Future<SyncResult> syncPendingItems() async {
    try {
      final db = await _databaseService.database;
      
      // Obtener elementos que necesitan sincronización
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'needs_sync = ?',
        whereArgs: [1],
      );

      int syncedCount = 0;
      int errorCount = 0;

      for (final map in maps) {
        final item = InventoryItemModel.fromMap(map);
        final success = await _syncService.syncItem(item);
        
        if (success) {
          // Marcar como sincronizado
          await db.update(
            _tableName,
            {'needs_sync': 0},
            where: 'id = ?',
            whereArgs: [item.id],
          );
          syncedCount++;
        } else {
          errorCount++;
        }
      }

      return SyncResult(
        success: errorCount == 0,
        message: 'Sincronizados: $syncedCount, Errores: $errorCount',
        syncedCount: syncedCount,
        errorCount: errorCount,
      );
    } catch (e) {
      developer.log('Error sincronizando items pendientes: $e', name: 'InventoryService', error: e);
      return SyncResult(
        success: false,
        message: 'Error en sincronización: $e',
        syncedCount: 0,
        errorCount: 1,
      );
    }
  }

  // Sincronización completa
  Future<SyncResult> fullSync() async {
    try {
      // Primero sincronizar cambios locales
      final localSyncResult = await syncPendingItems();
      
      // Luego descargar cambios remotos
      final remoteSyncResult = await _syncService.downloadFromSupabase();
      
      return SyncResult(
        success: localSyncResult.success && remoteSyncResult.success,
        message: 'Local: ${localSyncResult.message}, Remoto: ${remoteSyncResult.message}',
        syncedCount: localSyncResult.syncedCount + remoteSyncResult.syncedCount,
        errorCount: localSyncResult.errorCount + remoteSyncResult.errorCount,
      );
    } catch (e) {
      developer.log('Error en sincronización completa: $e', name: 'InventoryService', error: e);
      return SyncResult(
        success: false,
        message: 'Error en sincronización completa: $e',
        syncedCount: 0,
        errorCount: 1,
      );
    }
  }
}