import 'package:flutter/material.dart';
import '../services/email_service.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String? userEmail;
  
  const EmailConfirmationScreen({
    super.key,
    this.userEmail,
  });

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  String? _statusMessage;
  Map<String, dynamic>? _confirmationStatus;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail ?? '';
    _checkConfirmationStatus();
  }

  Future<void> _checkConfirmationStatus() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final status = await EmailService.getEmailConfirmationStatusAdvanced(_emailController.text);
      setState(() {
        _confirmationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al verificar estado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendConfirmationEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Por favor ingresa tu correo electrónico';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    try {
      final result = await EmailService.resendConfirmationEmailAdvanced(_emailController.text);
      
      setState(() {
        _isResending = false;
        if (result['success'] == true) {
          _statusMessage = result['message'] ?? 'Correo reenviado exitosamente';
        } else {
          _statusMessage = result['message'] ?? 'Error al reenviar correo';
        }
      });

      // Actualizar estado después del reenvío
      await Future.delayed(const Duration(seconds: 2));
      await _checkConfirmationStatus();
      
    } catch (e) {
      setState(() {
        _isResending = false;
        _statusMessage = 'Error al reenviar correo: $e';
      });
    }
  }

  Widget _buildStatusCard() {
    if (_confirmationStatus == null) return const SizedBox.shrink();

    final isSuccess = _confirmationStatus!['success'] == true;
    if (!isSuccess) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_confirmationStatus!['message'] ?? 'Error desconocido'),
            ],
          ),
        ),
      );
    }

    final authConfirmed = _confirmationStatus!['auth_confirmed'] ?? false;
    final usuariosConfirmed = _confirmationStatus!['usuarios_confirmed'] ?? false;
    final userExistsInUsuarios = _confirmationStatus!['user_exists_in_usuarios'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Confirmación',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Email en Auth', authConfirmed),
            _buildStatusRow('Email en Usuarios', usuariosConfirmed),
            _buildStatusRow('Usuario existe en tabla', userExistsInUsuarios),
            const SizedBox(height: 16),
            if (_confirmationStatus!['auth_confirmed_at'] != null)
              Text(
                'Confirmado en Auth: ${_confirmationStatus!['auth_confirmed_at']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (_confirmationStatus!['usuarios_confirmed_at'] != null)
              Text(
                'Confirmado en Usuarios: ${_confirmationStatus!['usuarios_confirmed_at']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            status ? 'Confirmado' : 'Pendiente',
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación de Email'),
        backgroundColor: const Color(0xFF2d5a27),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📧 Confirmación de Correo Electrónico',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2d5a27),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Para completar tu registro en AgroTrack, necesitas confirmar tu dirección de correo electrónico.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _checkConfirmationStatus,
                            icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                            label: Text(_isLoading ? 'Verificando...' : 'Verificar Estado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2d5a27),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isResending ? null : _resendConfirmationEmail,
                            icon: _isResending 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                            label: Text(_isResending ? 'Enviando...' : 'Reenviar Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Card(
                color: _statusMessage!.contains('Error') 
                  ? Colors.red.shade50 
                  : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage!.contains('Error') 
                          ? Icons.error 
                          : Icons.check_circle,
                        color: _statusMessage!.contains('Error') 
                          ? Colors.red 
                          : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMessage!)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información Importante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Revisa tu bandeja de entrada y carpeta de spam'),
                    const Text('• El enlace de confirmación expira en 24 horas'),
                    const Text('• Puedes reenviar el correo si no lo recibes'),
                    const Text('• Contacta soporte si persisten los problemas'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}