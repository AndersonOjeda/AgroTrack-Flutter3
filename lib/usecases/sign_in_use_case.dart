import '../services/auth_repository.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../utils/result.dart';
import '../services/logger_service.dart';

class SignInUseCase {
  final AuthRepository authRepository;
  final Future<UserModel> Function({
    required String email,
    required String password,
    bool performAuth,
  })
  _loadUser;

  SignInUseCase({
    required this.authRepository,
    Future<UserModel> Function({
      required String email,
      required String password,
      bool performAuth,
    })?
    loadUser,
  }) : _loadUser = loadUser ?? UserService.signIn;

  Future<Result<UserModel>> execute({
    required String email,
    required String password,
  }) async {
    LoggerService.info('SignInUseCase: iniciando proceso de login para $email');
    final authResult = await authRepository.signIn(
      email: email,
      password: password,
    );
    if (!authResult.isSuccess) {
      LoggerService.warning(
        'SignInUseCase: autenticación fallida para $email: ${authResult.error}',
      );
      return Result.failure(authResult.error);
    }

    try {
      final user = await _loadUser(
        email: email,
        password: password,
        performAuth: false,
      );
      LoggerService.info(
        'SignInUseCase: usuario cargado correctamente con id ${user.id}',
      );
      return Result.success(user);
    } catch (e) {
      LoggerService.error('SignInUseCase: error cargando usuario', error: e);
      return Result.failure(e.toString());
    }
  }
}
