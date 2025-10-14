import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/ChatBot.dart';
import 'screens/AuthGate.dart';
import 'services/supabase_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  // Inicializar Supabase
  await SupabaseService.init();
  
  // Inicializar servicios de persistencia
  await UserService.initialize();
  
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Agrícola',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 206, 145, 32),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
