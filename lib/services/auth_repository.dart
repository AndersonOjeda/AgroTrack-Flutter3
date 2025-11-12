import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/result.dart';
import '../services/logger_service.dart';

abstract class AuthRepository {
  Future<Result<void>> signIn({required String email, required String password});
  Future<Result<void>> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  @override
  Future<Result<void>> signIn({required String email, required String password}) async {
    try {
      LoggerService.info('AuthRepository: intentando login para $email');
      await _client.auth.signInWithPassword(email: email, password: password);
      LoggerService.info('AuthRepository: login exitoso para $email');
      return const Result.success(null);
    } on AuthException catch (e) {
      LoggerService.warning('AuthRepository: error de autenticación para $email: ${e.message}');
      return Result.failure(e.message);
    } catch (e) {
      LoggerService.error('AuthRepository: error de conexión durante login', error: e);
      return Result.failure('Connection error');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      LoggerService.info('AuthRepository: cerrando sesión');
      await _client.auth.signOut();
      LoggerService.info('AuthRepository: sesión cerrada');
      return const Result.success(null);
    } catch (e) {
      LoggerService.error('AuthRepository: error al cerrar sesión', error: e);
      return Result.failure(e.toString());
    }
  }
}