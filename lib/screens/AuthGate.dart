import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'ChatBot.dart';
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
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }
        return const ChatBot();
      },
    );
  }
}