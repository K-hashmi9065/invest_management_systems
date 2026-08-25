import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/user_model.dart';

final setupControllerProvider =
    AsyncNotifierProvider<SetupController, UserModel?>(() {
  return SetupController();
});

class SetupController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return null;
  }

  Future<UserModel?> completeSetup({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      final failure = const ValidationFailure('Passwords do not match');
      state = AsyncValue.error(failure, StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(appRepositoryProvider);
      final user = await repo.createSuperAdmin(
        fullName: fullName.trim(),
        username: username.trim(),
        password: password,
      );

      ref.read(currentUserProvider.notifier).setUser(user);
      refreshAllFinancialProviders(ref);
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
