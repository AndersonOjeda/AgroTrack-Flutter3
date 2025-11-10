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
  bool _isResending = false;
  String? _statusMessage;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail ?? '';
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
      // Ejecutar diagnósticos antes del reenvío
      await EmailService.diagnosticSupabaseConfig();
      await EmailService.testSupabaseConnection();
      
      final success = await EmailService.resendConfirmationEmail(_emailController.text);
      setState(() {
        _isResending = false;
        _statusMessage = success
            ? 'Correo de confirmación reenviado. Revisa tu bandeja y spam.'
            : 'Error al reenviar correo. Intenta nuevamente.';
      });
    } catch (e) {
      setState(() {
        _isResending = false;
        _statusMessage = 'Error al reenviar correo: $e';
      });
    }
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
                    const Text('Para completar tu registro en AgroTrack, confirma tu correo.'),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isResending ? null : _resendConfirmationEmail,
                        icon: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(_isResending ? 'Enviando…' : 'Reenviar confirmación'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2d5a27),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Card(
                color: _statusMessage!.contains('Error') ? Colors.red.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage!.contains('Error') ? Icons.error : Icons.check_circle,
                        color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMessage!)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('• Revisa tu bandeja de entrada y carpeta de spam'),
                    Text('• El enlace de confirmación expira en 24 horas'),
                    Text('• Al hacer clic en el enlace del correo, tu cuenta se confirma automáticamente'),
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