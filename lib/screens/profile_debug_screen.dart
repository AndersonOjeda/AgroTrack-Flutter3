import 'package:flutter/material.dart';
import '../services/debug_service.dart';
import '../services/profile_service.dart';

class ProfileDebugScreen extends StatefulWidget {
  const ProfileDebugScreen({super.key});

  @override
  State<ProfileDebugScreen> createState() => _ProfileDebugScreenState();
}

class _ProfileDebugScreenState extends State<ProfileDebugScreen> {
  Map<String, dynamic>? _debugData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    setState(() => _isLoading = true);
    
    try {
      // Ejecutar diagnóstico completo
      final authStatus = await DebugService.checkAuthStatus();
      final userInDb = await DebugService.checkUserInDatabase();
      final profileDebug = await ProfileService.debugProfileUpdate();
      
      setState(() {
        _debugData = {
          'auth_status': authStatus,
          'user_in_database': userInDb,
          'profile_debug': profileDebug,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugData = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Actualización de Perfil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnosis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_debugData != null) ...[
                    _buildSection('Estado de Autenticación', _debugData!['auth_status']),
                    const SizedBox(height: 16),
                    _buildSection('Usuario en Base de Datos', _debugData!['user_in_database']),
                    const SizedBox(height: 16),
                    _buildSection('Debug de Actualización de Perfil', _debugData!['profile_debug']),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ] else
                    const Center(child: Text('No hay datos de debug disponibles')),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (data != null)
              ...data.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              color: entry.key.contains('error') 
                                  ? Colors.red 
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              const Text('No hay datos disponibles'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acciones de Debug',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _createUserInDatabase,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Crear Usuario en Base de Datos'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _testProfileUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Probar Actualización de Perfil'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _runDiagnosis,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ejecutar Diagnóstico Completo'),
        ),
      ],
    );
  }

  Future<void> _createUserInDatabase() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await DebugService.createUserInDatabase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true 
                  ? 'Usuario creado exitosamente' 
                  : 'Error: ${result['error']}',
            ),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        
        // Actualizar diagnóstico
        await _runDiagnosis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testProfileUpdate() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await ProfileService.getCurrentUser();
      
      if (currentUser != null) {
        final testUser = currentUser.copyWith(
          bio: 'Test de actualización - ${DateTime.now().millisecondsSinceEpoch}',
        );
        
        final success = await ProfileService.updateProfile(testUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                    ? 'Actualización de perfil exitosa' 
                    : 'Error en actualización de perfil',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          
          // Actualizar diagnóstico
          await _runDiagnosis();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener el usuario actual'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
}