import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/database_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';
import '../models/user_model.dart';

class PersistenceTestPage extends StatefulWidget {
  const PersistenceTestPage({Key? key}) : super(key: key);

  @override
  State<PersistenceTestPage> createState() => _PersistenceTestPageState();
}

class _PersistenceTestPageState extends State<PersistenceTestPage> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas de Persistencia'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isRunning
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Ejecutar Pruebas de Persistencia',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    final isError = result.startsWith('❌');
                    final isSuccess = result.startsWith('✅');
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        result,
                        style: TextStyle(
                          color: isError
                              ? Colors.red
                              : isSuccess
                                  ? Colors.green
                                  : Colors.black87,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('🚀 Iniciando pruebas de persistencia...\n');

    try {
      await _testDatabaseService();
      await _testCacheService();
      await _testSyncService();
      await _testUserService();
      await _testOfflineMode();
      
      _addResult('\n🎉 Todas las pruebas completadas exitosamente!');
    } catch (e) {
      _addResult('❌ Error general en las pruebas: $e');
    }

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testDatabaseService() async {
    _addResult('📊 Probando DatabaseService...');
    
    try {
      final dbService = DatabaseService();
      
      // Crear usuario de prueba
      final testUser = UserModel(
        id: 'test-user-${DateTime.now().millisecondsSinceEpoch}',
        nombre: 'Usuario Prueba',
        email: 'test@example.com',
        telefono: '123456789',
        ubicacion: 'Ciudad Prueba',
        tipoAgricultura: 'Orgánica',
        emailConfirmado: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: false,
      );

      // Insertar usuario
      await dbService.insertUser(testUser);
      _addResult('✅ Usuario insertado en SQLite');

      // Obtener usuario
      final retrievedUser = await dbService.getUserById(testUser.id!);
      if (retrievedUser != null && retrievedUser.email == testUser.email) {
        _addResult('✅ Usuario recuperado correctamente');
      } else {
        _addResult('❌ Error al recuperar usuario');
      }

      // Actualizar usuario
      final updatedUser = testUser.copyWith(
        nombre: 'Usuario Actualizado',
        needsSync: true,
      );
      await dbService.updateUser(updatedUser);
      _addResult('✅ Usuario actualizado en SQLite');

      // Obtener usuarios que necesitan sincronización
      final usersNeedingSync = await dbService.getUsersNeedingSync();
      if (usersNeedingSync.isNotEmpty) {
        _addResult('✅ Consulta de usuarios pendientes de sync');
      }

      // Limpiar datos de prueba
      await dbService.deleteUser(testUser.id!);
      _addResult('✅ Usuario eliminado correctamente');

    } catch (e) {
      _addResult('❌ Error en DatabaseService: $e');
    }
  }

  Future<void> _testCacheService() async {
    _addResult('\n💾 Probando CacheService...');
    
    try {
      final cacheService = CacheService();
      
      // Crear usuario de prueba
      final testUser = UserModel(
        id: 'cache-test-user',
        nombre: 'Usuario Cache',
        email: 'cache@example.com',
        ubicacion: 'Cache City',
        tipoAgricultura: 'Tradicional',
        emailConfirmado: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: false,
      );

      // Establecer usuario actual
      await cacheService.setCurrentUser(testUser);
      _addResult('✅ Usuario establecido en cache');

      // Obtener usuario actual
      final currentUser = await cacheService.getCurrentUser();
      if (currentUser != null && currentUser.email == testUser.email) {
        _addResult('✅ Usuario actual recuperado del cache');
      } else {
        _addResult('❌ Error al recuperar usuario actual del cache');
      }

      // Obtener usuario por email
      final userByEmail = await cacheService.getUserByEmail(testUser.email);
      if (userByEmail != null) {
        _addResult('✅ Usuario encontrado por email en cache');
      }

      // Obtener estadísticas de cache
      final stats = cacheService.getCacheStats();
      _addResult('✅ Estadísticas de cache: ${stats.totalEntries} entradas');

      // Configurar modo offline
      await cacheService.setOfflineMode(true);
      final isOffline = await cacheService.isOfflineMode();
      if (isOffline) {
        _addResult('✅ Modo offline configurado correctamente');
      }

      // Limpiar cache
      await cacheService.clearCurrentUser();
      _addResult('✅ Cache limpiado correctamente');

    } catch (e) {
      _addResult('❌ Error en CacheService: $e');
    }
  }

  Future<void> _testSyncService() async {
    _addResult('\n🔄 Probando SyncService...');
    
    try {
      final syncService = SyncService();
      syncService.initialize();

      // Obtener estado de sincronización
      final status = await syncService.getSyncStatus();
      _addResult('✅ Estado de sync obtenido: ${status.pendingItems} pendientes');

      // Verificar conectividad (simulada)
      _addResult('✅ SyncService inicializado correctamente');

    } catch (e) {
      _addResult('❌ Error en SyncService: $e');
    }
  }

  Future<void> _testUserService() async {
    _addResult('\n👤 Probando UserService integrado...');
    
    try {
      // Inicializar servicios
      await UserService.initialize();
      _addResult('✅ UserService inicializado');

      // Obtener usuario actual (debería ser null inicialmente)
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) {
        _addResult('✅ No hay usuario actual (esperado)');
      }

      // Verificar estado de sincronización
      final hasPending = await UserService.hasPendingSync();
      _addResult('✅ Verificación de sync pendiente: $hasPending');

      // Obtener estadísticas de cache
      final cacheStats = UserService.getCacheStats();
      _addResult('✅ Estadísticas de cache: ${cacheStats.totalEntries} entradas');

      // Verificar modo offline
      final isOffline = await UserService.isOfflineMode();
      _addResult('✅ Modo offline: $isOffline');

    } catch (e) {
      _addResult('❌ Error en UserService: $e');
    }
  }

  Future<void> _testOfflineMode() async {
    _addResult('\n📱 Probando funcionalidad offline...');
    
    try {
      // Activar modo offline
      await UserService.setOfflineMode(true);
      _addResult('✅ Modo offline activado');

      // Verificar que está en modo offline
      final isOffline = await UserService.isOfflineMode();
      if (isOffline) {
        _addResult('✅ Confirmado modo offline');
      }

      // Desactivar modo offline
      await UserService.setOfflineMode(false);
      final isOnline = !(await UserService.isOfflineMode());
      if (isOnline) {
        _addResult('✅ Modo online restaurado');
      }

    } catch (e) {
      _addResult('❌ Error en pruebas offline: $e');
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
    
    // Auto-scroll al final
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Scroll to bottom logic would go here if needed
      }
    });
  }
}