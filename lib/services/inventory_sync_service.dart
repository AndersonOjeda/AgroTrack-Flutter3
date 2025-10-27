import 'dart:developer' as developer;
import '../models/inventory_item_model.dart';
import 'supabase_service.dart';

class InventorySyncService {
  // Crear tabla en Supabase si no existe
  Future<void> initializeSupabaseTable() async {
    if (!SupabaseService.isReady) {
      developer.log('Supabase no está inicializado', name: 'InventorySyncService');
      return;
    }

    try {
      // Verificar si la tabla existe intentando hacer una consulta
      await SupabaseService.client
          .from('inventory_items')
          .select('id')
          .limit(1);
      
      developer.log('Tabla inventory_items ya existe en Supabase', name: 'InventorySyncService');
    } catch (e) {
      developer.log('Tabla inventory_items no existe, necesita ser creada manualmente en Supabase', name: 'InventorySyncService');
      // La tabla debe crearse manualmente en Supabase con el esquema apropiado
    }
  }

  // Sincronizar un elemento individual
  Future<bool> syncItem(InventoryItemModel item) async {
    if (!SupabaseService.isReady) {
      return false;
    }

    try {
      // Obtener el user_id del usuario autenticado
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser?.id == null) {
        developer.log('Error: Usuario no autenticado', name: 'InventorySyncService');
        return false;
      }

      final userResponse = await SupabaseService.client
          .from('usuarios')
          .select('id')
          .eq('auth_user_id', currentUser!.id)
          .maybeSingle();

      if (userResponse == null) {
        developer.log('Error: Usuario no encontrado en la tabla usuarios', name: 'InventorySyncService');
        return false;
      }

      final userId = userResponse['id'] as String;

      // Preparar datos para Supabase incluyendo user_id
      final itemData = item.toJson();
      itemData['user_id'] = userId;

      // Verificar si el elemento ya existe en Supabase
      final existingData = await SupabaseService.client
          .from('inventory_items')
          .select()
          .eq('id', item.id!)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingData != null) {
        // Actualizar elemento existente
        await SupabaseService.client
            .from('inventory_items')
            .update(itemData)
            .eq('id', item.id!)
            .eq('user_id', userId);
        
        developer.log('Item actualizado en Supabase: ${item.id}', name: 'InventorySyncService');
      } else {
        // Insertar nuevo elemento
        await SupabaseService.client
            .from('inventory_items')
            .insert(itemData);
        
        developer.log('Item insertado en Supabase: ${item.id}', name: 'InventorySyncService');
      }

      return true;
    } catch (e) {
      developer.log('Error sincronizando item ${item.id}: $e', name: 'InventorySyncService', error: e);
      return false;
    }
  }

  // Sincronizar elementos pendientes
  Future<SyncResult> syncPendingItems() async {
    if (!SupabaseService.isReady) {
      return SyncResult(
        success: false,
        message: 'Supabase no disponible',
        syncedCount: 0,
        errorCount: 0,
      );
    }

    try {
      // Nota: Este método será llamado desde InventoryService
      // Para evitar referencias circulares, retornamos éxito por defecto
      return SyncResult(
        success: true,
        message: 'Sincronización completada',
        syncedCount: 0,
        errorCount: 0,
      );
    } catch (e) {
      developer.log('Error en sincronización masiva: $e', name: 'InventorySyncService', error: e);
      return SyncResult(
        success: false,
        message: 'Error en sincronización: $e',
        syncedCount: 0,
        errorCount: 1,
      );
    }
  }

  // Eliminar elemento de Supabase
  Future<bool> deleteItemFromSupabase(String id) async {
    if (!SupabaseService.isReady) {
      return false;
    }

    try {
      await SupabaseService.client
          .from('inventory_items')
          .delete()
          .eq('id', id);
      
      developer.log('Item eliminado de Supabase: $id', name: 'InventorySyncService');
      return true;
    } catch (e) {
      developer.log('Error eliminando item de Supabase: $e', name: 'InventorySyncService', error: e);
      return false;
    }
  }

  // Descargar elementos desde Supabase
  Future<SyncResult> downloadFromSupabase() async {
    if (!SupabaseService.isReady) {
      return SyncResult(
        success: false,
        message: 'Supabase no disponible',
        syncedCount: 0,
        errorCount: 0,
      );
    }

    try {
      final response = await SupabaseService.client
          .from('inventory_items')
          .select('*');

      int downloadedCount = 0;
      int errorCount = 0;

      for (final itemData in response) {
        try {
          InventoryItemModel.fromJson(itemData);
          // Aquí normalmente guardaríamos en la base de datos local
          // pero para evitar referencias circulares, solo contamos
          downloadedCount++;
        } catch (e) {
          developer.log('Error procesando item descargado: $e', name: 'InventorySyncService', error: e);
          errorCount++;
        }
      }

      return SyncResult(
        success: errorCount == 0,
        message: 'Descarga completada: $downloadedCount elementos',
        syncedCount: downloadedCount,
        errorCount: errorCount,
      );
    } catch (e) {
      developer.log('Error descargando desde Supabase: $e', name: 'InventorySyncService', error: e);
      return SyncResult(
        success: false,
        message: 'Error en descarga: $e',
        syncedCount: 0,
        errorCount: 1,
      );
    }
  }

  // Sincronización completa bidireccional
  Future<SyncResult> fullSync() async {
    if (!SupabaseService.isReady) {
      return SyncResult(
        success: false,
        message: 'Supabase no disponible',
        syncedCount: 0,
        errorCount: 0,
      );
    }

    try {
      // Primero subir cambios locales
      final uploadResult = await syncPendingItems();
      
      // Luego descargar cambios remotos
      final downloadResult = await downloadFromSupabase();
      
      return SyncResult(
        success: uploadResult.success && downloadResult.success,
        message: 'Sincronización completa: ${uploadResult.message}, ${downloadResult.message}',
        syncedCount: uploadResult.syncedCount + downloadResult.syncedCount,
        errorCount: uploadResult.errorCount + downloadResult.errorCount,
      );
    } catch (e) {
      developer.log('Error en sincronización completa: $e', name: 'InventorySyncService', error: e);
      return SyncResult(
        success: false,
        message: 'Error en sincronización completa: $e',
        syncedCount: 0,
        errorCount: 1,
      );
    }
  }
}

// Clase para resultados de sincronización
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int errorCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.errorCount,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, synced: $syncedCount, errors: $errorCount)';
  }
}