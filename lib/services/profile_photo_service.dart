import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

class ProfilePhotoService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'avatars';

  /// Descarga, comprime y sube la foto; retorna la URL pA-oblica.
  static Future<String?> uploadFromUrl(String imageUrl, String userId) async {
    try {
      final resp = await http.get(Uri.parse(imageUrl));
      if (resp.statusCode != 200) {
        throw Exception('No se pudo descargar la imagen');
      }

      final compressed = _compress(resp.bodyBytes);
      final path = 'profile_$userId.jpg';

      await _client.storage.from(_bucket).uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      LoggerService.error('Error subiendo foto de perfil', error: e);
      return null;
    }
  }

  static Uint8List _compress(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = img.copyResize(decoded, width: 720);
    final encoded = img.encodeJpg(resized, quality: 75);
    return Uint8List.fromList(encoded);
  }
}
