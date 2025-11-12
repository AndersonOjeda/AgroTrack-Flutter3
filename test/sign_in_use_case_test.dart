import 'package:flutter_test/flutter_test.dart';
import 'package:example_ia/services/auth_repository.dart';
import 'package:example_ia/usecases/sign_in_use_case.dart';
import 'package:example_ia/models/user_model.dart';
import 'package:example_ia/utils/result.dart';

class FakeAuthRepositorySuccess implements AuthRepository {
  @override
  Future<Result<void>> signIn({required String email, required String password}) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    return const Result.success(null);
  }
}

class FakeAuthRepositoryFailure implements AuthRepository {
  @override
  Future<Result<void>> signIn({required String email, required String password}) async {
    return const Result.failure('Invalid login credentials');
  }

  @override
  Future<Result<void>> signOut() async {
    return const Result.success(null);
  }
}

void main() {
  group('SignInUseCase', () {
    test('retorna éxito y usuario cuando AuthRepository tiene éxito', () async {
      final repo = FakeAuthRepositorySuccess();
      bool loaderCalled = false;
      final useCase = SignInUseCase(
        authRepository: repo,
        loadUser: ({required String email, required String password, bool performAuth = false}) async {
          loaderCalled = true;
          return UserModel(
            id: 'user-123',
            nombre: 'Juan',
            email: email,
            primaryCrops: 'coffee',
            emailConfirmado: true,
          );
        },
      );

      final result = await useCase.execute(email: 'test@example.com', password: 'secret');

      expect(result.isSuccess, isTrue);
      expect(loaderCalled, isTrue);
      final user = result.data!;
      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.emailConfirmado, isTrue);
    });

    test('retorna fallo cuando AuthRepository falla y no llama loader', () async {
      final repo = FakeAuthRepositoryFailure();
      bool loaderCalled = false;
      final useCase = SignInUseCase(
        authRepository: repo,
        loadUser: ({required String email, required String password, bool performAuth = false}) async {
          loaderCalled = true;
          return UserModel(
            id: 'user-123',
            nombre: 'Juan',
            email: email,
          );
        },
      );

      final result = await useCase.execute(email: 'wrong@example.com', password: 'bad');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid login credentials');
      expect(loaderCalled, isFalse);
    });
  });
}