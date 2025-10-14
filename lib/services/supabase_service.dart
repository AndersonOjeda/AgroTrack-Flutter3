import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static bool _initialized = false;

  static bool get isReady => _initialized;
  static SupabaseClient get client => Supabase.instance.client;

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