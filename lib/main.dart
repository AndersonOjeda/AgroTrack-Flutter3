import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/auth_gate.dart';
import 'screens/email_confirmation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart';

import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'services/user_service.dart';
import 'services/weather_state_provider.dart';
import 'services/deep_link_service.dart';

import 'providers/finance_provider.dart'; // <<< IMPORTANTE
import 'providers/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    DatabaseService.setDatabaseFactory(databaseFactoryFfiWeb);
  }

  await dotenv.load(fileName: '.env');
  await SupabaseService.init();

  Intl.defaultLocale = 'es_ES';
  await initializeDateFormatting('es_ES');

  await UserService.initialize();

  runApp(const TranslatorApp());
}

class TranslatorApp extends StatefulWidget {
  const TranslatorApp({super.key});

  @override
  State<TranslatorApp> createState() => _TranslatorAppState();
}

class _TranslatorAppState extends State<TranslatorApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentContext != null) {
        DeepLinkService.initialize(_navigatorKey.currentContext!);
      }
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherStateProvider()),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider(),
        ), // <<< AGREGADO
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Chat Agrícola',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 206, 145, 32),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
        routes: {
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/debug': (context) => const DebugScreen(),
          '/email-confirmation': (context) => const EmailConfirmationScreen(),
        },
      ),
    );
  }
}
