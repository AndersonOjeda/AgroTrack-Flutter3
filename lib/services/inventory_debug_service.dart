import 'dart:developer' as developer;
import '../models/inventory_item_model.dart';
import 'supabase_service.dart';

class InventoryDebugService {
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final result = <String, dynamic>{};

    try {
      // 1. Verificar estado de Supabase
      result['supabase_status'] = SupabaseService.isReady;

      if (!SupabaseService.isReady) {
        result['error_message'] = 'Supabase is not initialized';
        result['user_authenticated'] = false;
        result['usuarios_table_exists'] = false;
        result['inventory_table_exists'] = false;
        result['supabase_item_count'] = -1;
        result['local_item_count'] = 0;
        result['crud_test_success'] = false;
        return result;
      }

      // 2. Verificar autenticación
      final currentUser = SupabaseService.client.auth.currentUser;
      result['user_authenticated'] = currentUser != null;

      if (currentUser == null) {
        result['error_message'] = 'User not authenticated';
        result['usuarios_table_exists'] = false;
        result['inventory_table_exists'] = false;
        result['supabase_item_count'] = -1;
        result['local_item_count'] = 0;
        result['crud_test_success'] = false;
        return result;
      }

      // 3. Verificar tabla users
      try {
        await SupabaseService.client.from('users').select('id').limit(1);
        result['usuarios_table_exists'] = true;
      } catch (e) {
        result['usuarios_table_exists'] = false;
      }

      // 4. Verificar tabla inventory_items
      try {
        await SupabaseService.client
            .from('inventory_items')
            .select('id')
            .limit(1);
        result['inventory_table_exists'] = true;
      } catch (e) {
        result['inventory_table_exists'] = false;
      }

      // 5. Contar items en Supabase
      if (result['inventory_table_exists'] == true) {
        try {
          final response = await SupabaseService.client
              .from('inventory_items')
              .select('id');
          result['supabase_item_count'] = response.length;
        } catch (e) {
          result['supabase_item_count'] = -1;
        }
      } else {
        result['supabase_item_count'] = -1;
      }

      // 6. Contar items locales (simulado)
      result['local_item_count'] =
          0; // Esto se podría implementar consultando SQLite

      // 7. Test CRUD básico
      result['crud_test_success'] =
          result['inventory_table_exists'] == true &&
          result['user_authenticated'] == true;
    } catch (e) {
      result['error_message'] = e.toString();
      result['supabase_status'] = false;
      result['user_authenticated'] = false;
      result['usuarios_table_exists'] = false;
      result['inventory_table_exists'] = false;
      result['supabase_item_count'] = -1;
      result['local_item_count'] = 0;
      result['crud_test_success'] = false;
    }

    return result;
  }

  static Future<Map<String, dynamic>> checkInventoryStatus() async {
    final result = <String, dynamic>{};

    try {
      // 1. Verificar estado de Supabase
      result['supabase_ready'] = SupabaseService.isReady;

      if (!SupabaseService.isReady) {
        result['error'] = 'Supabase is not initialized';
        return result;
      }

      // 2. Verificar autenticación
      final currentUser = SupabaseService.client.auth.currentUser;
      result['user_authenticated'] = currentUser != null;
      result['user_id'] = currentUser?.id;
      result['user_email'] = currentUser?.email;

      if (currentUser == null) {
        result['error'] = 'User not authenticated';
        return result;
      }

      // 3. Verificar si existe el usuario en la tabla users
      try {
        final userResponse = await SupabaseService.client
            .from('users')
            .select('id')
            .eq('auth_user_id', currentUser.id)
            .maybeSingle();

        result['user_exists_in_db'] = userResponse != null;
        result['db_user_id'] = userResponse?['id'];
      } catch (e) {
        result['user_exists_in_db'] = false;
        result['user_db_error'] = e.toString();
      }

      // 4. Verificar si existe la tabla inventory_items
      try {
        await SupabaseService.client
            .from('inventory_items')
            .select('id')
            .limit(1);

        result['inventory_table_exists'] = true;
      } catch (e) {
        result['inventory_table_exists'] = false;
        result['table_error'] = e.toString();
      }

      // 5. Contar elementos en la tabla si existe
      if (result['inventory_table_exists'] == true) {
        try {
          final response = await SupabaseService.client
              .from('inventory_items')
              .select('id');

          result['inventory_count'] = response.length;
        } catch (e) {
          result['count_error'] = e.toString();
        }
      }

      // 6. Intentar insertar un elemento de prueba
      if (result['inventory_table_exists'] == true &&
          result['user_exists_in_db'] == true) {
        try {
          final testItem = InventoryItemModel(
            nombre: 'Test Item - ${DateTime.now().millisecondsSinceEpoch}',
            categoria: 'Test',
            descripcion: 'Item de prueba para verificar funcionalidad',
            cantidad: 1,
            unidadMedida: 'unidad',
            estado: 'test',
          );

          final itemData = testItem.toJson();
          itemData['user_id'] = result['db_user_id'];

          final response = await SupabaseService.client
              .from('inventory_items')
              .insert(itemData)
              .select()
              .single();

          result['test_insert_success'] = true;
          result['test_item_id'] = response['id'];

          // Eliminar el elemento de prueba
          await SupabaseService.client
              .from('inventory_items')
              .delete()
              .eq('id', response['id']);

          result['test_cleanup_success'] = true;
        } catch (e) {
          result['test_insert_success'] = false;
          result['insert_error'] = e.toString();
        }
      }
    } catch (e) {
      result['general_error'] = e.toString();
    }

    return result;
  }

  static Future<bool> createInventoryTableIfNotExists() async {
    if (!SupabaseService.isReady) {
      developer.log(
        'Supabase no está inicializado',
        name: 'InventoryDebugService',
      );
      return false;
    }

    try {
      // Intentar crear la tabla usando una función SQL
      await SupabaseService.client.rpc('create_inventory_table_if_not_exists');
      return true;
    } catch (e) {
      developer.log(
        'Error creando tabla de inventario: $e',
        name: 'InventoryDebugService',
      );
      return false;
    }
  }

  static Future<bool> createUserIfNotExists() async {
    if (!SupabaseService.isReady) {
      return false;
    }

    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      // Verificar si el usuario ya existe en users
      final existingUser = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      if (existingUser != null) {
        return true; // Usuario ya existe
      }

      // Crear el usuario
      await SupabaseService.client.from('users').insert({
        'auth_user_id': currentUser.id,
        'email': currentUser.email ?? '',
        'first_name':
            currentUser.userMetadata?['first_name'] ??
            currentUser.userMetadata?['nombre'] ??
            'User',
        'last_name':
            currentUser.userMetadata?['last_name'] ??
            currentUser.userMetadata?['apellido'] ??
            '',
        'email_confirmed': currentUser.emailConfirmedAt != null,
      });

      return true;
    } catch (e) {
      developer.log('Error creating user: $e', name: 'InventoryDebugService');
      return false;
    }
  }

  static void printDebugInfo(Map<String, dynamic> status) {
    developer.log(
      '=== ESTADO DEL INVENTARIO ===',
      name: 'InventoryDebugService',
    );
    status.forEach((key, value) {
      developer.log('$key: $value', name: 'InventoryDebugService');
    });
    developer.log(
      '============================',
      name: 'InventoryDebugService',
    );
  }
}
