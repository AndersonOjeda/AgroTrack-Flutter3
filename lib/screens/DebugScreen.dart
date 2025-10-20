import 'package:flutter/material.dart';
import '../services/debug_service.dart';
import '../services/profile_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
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
      final diagnosis = await DebugService.fullDiagnosis();
      setState(() {
        _debugData = diagnosis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugData = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await DebugService.createUserInDatabase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true 
            ? 'Usuario creado exitosamente' 
            : 'Error: ${result['error']}'),
        ),
      );
      
      // Refrescar diagnóstico
      await _runDiagnosis();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Diagnóstico'),
        backgroundColor: Colors.red,
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
                  _buildSection('Estado de Autenticación', _debugData?['auth_status']),
                  const SizedBox(height: 16),
                  _buildSection('Usuario en Base de Datos', _debugData?['user_in_database']),
                  const SizedBox(height: 16),
                  _buildSection('Todos los Usuarios', _debugData?['all_users']),
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Crear Usuario en DB'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ProfileService.refreshUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache refrescado')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refrescar Cache'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatData(data),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    
    try {
      // Formatear JSON de manera legible
      return data.toString().replaceAllMapped(
        RegExp(r'([{,])(\s*)'),
        (match) => '${match.group(1)}\n  ',
      ).replaceAll('}', '\n}');
    } catch (e) {
      return data.toString();
    }
  }
}