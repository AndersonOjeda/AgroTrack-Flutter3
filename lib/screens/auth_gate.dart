import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isReady) {
      return const Scaffold(
        body: Center(child: Text('Set SUPABASE_URL and ANON_KEY in .env')),
      );
    }

    final client = SupabaseService.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Authentication error. Please try again')),
          );
        }

        // Mientras el stream conecta, renderiza según sesión para evitar pantalla en blanco
        if (snapshot.connectionState == ConnectionState.waiting) {
          return session == null ? const LoginScreen() : const MainNavigationScreen();
        }

        return session == null ? const LoginScreen() : const MainNavigationScreen();
      },
    );
  }
}