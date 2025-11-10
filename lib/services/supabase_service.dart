import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
// Importación condicional para diferentes plataformas
import 'web_url_helper.dart' if (dart.library.io) 'mobile_url_helper.dart';
import 'deep_link_service.dart';

class SupabaseService {
  static bool _initialized = false;

  static bool get isReady => _initialized;
  static SupabaseClient get client => Supabase.instance.client;

  static String get emailRedirectUrl {
    // Leer desde .env para manejar enlaces de Supabase de forma centralizada
    final envRedirect = dotenv.env['SUPABASE_REDIRECT_URL'];
    if (envRedirect != null && envRedirect.isNotEmpty) {
      return envRedirect;
    }
    // Fallback por plataforma si la variable no está definida
    if (kIsWeb) {
      return getCurrentWebUrl();
    }
    return 'agrotrack://email-confirmation';
  }

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null ||
        url.startsWith('https://your-project-ref.supabase.co') ||
        anonKey.startsWith('your-anon-key')) {
      // No inicializamos si faltan valores o son placeholders.
      _initialized = false;
      return;
    }
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }
}