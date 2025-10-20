import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'DashboardScreen.dart';
import 'LoginScreen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isReady) {
      return const Scaffold(
        body: Center(child: Text('Configura SUPABASE_URL y ANON_KEY en .env')),
      );
    }

    final client = SupabaseService.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error de autenticación. Intenta nuevamente')),
          );
        }

        // Mientras el stream conecta, renderiza según sesión para evitar pantalla en blanco
        if (snapshot.connectionState == ConnectionState.waiting) {
          return session == null ? const LoginScreen() : const DashboardScreen();
        }

        return session == null ? const LoginScreen() : const DashboardScreen();
      },
    );
  }
}