import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/user_model.dart';

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, UserModel?>(() {
      return LoginController();
    });

class LoginController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return null;
  }

  Future<UserModel?> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(appRepositoryProvider);
      final user = await repo.login(identifier, password);

      if (user == null) {
        throw const AuthenticationFailure('Invalid email/mobile or password');
      }

      ref.read(currentUserProvider.notifier).setUser(user);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      final failure = FailureMapper.map(e, st);
      state = AsyncValue.error(failure, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
