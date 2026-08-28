import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_management_systems/app/app_providers.dart';
import 'package:invest_management_systems/core/errors/app_failure.dart';
import 'package:invest_management_systems/features/auth/domain/user_model.dart';

void main() {
  group('Riverpod Provider State Management Tests', () {
    test('currentUserProvider defaults to null and updates on setUser', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentUserProvider), null);

      final testUser = UserModel(
        id: 1,
        username: 'admin@invest.com',
        fullName: 'Admin User',
        role: 'SUPER_ADMIN',
        createdAt: '2026-01-01T00:00:00.000',
      );

      container.read(currentUserProvider.notifier).setUser(testUser);
      expect(container.read(currentUserProvider), testUser);

      container.read(currentUserProvider.notifier).logout();
      expect(container.read(currentUserProvider), null);
    });

    test('pageTitleProvider state updates cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pageTitleProvider), 'Dashboard Overview');

      container.read(pageTitleProvider.notifier).state = 'Member Directory';
      expect(container.read(pageTitleProvider), 'Member Directory');
    });

    test('refreshAllFinancialProviders invalidates financial providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => refreshAllFinancialProviders(container), returnsNormally);
    });
  });

  group('FailureMapper Unit Tests', () {
    test('FailureMapper passes through AppFailure instances intact', () {
      const failure = ValidationFailure('Invalid amount');
      final mapped = FailureMapper.map(failure);
      expect(mapped, isA<ValidationFailure>());
      expect(mapped.userMessage, 'Invalid amount');
    });

    test('FailureMapper maps sqlite unique username error to DatabaseFailure', () {
      final sqfliteException = Exception('UNIQUE constraint failed: users.username');
      final mapped = FailureMapper.map(sqfliteException);
      expect(mapped, isA<DatabaseFailure>());
      expect(mapped.userMessage, contains('username is already taken'));
    });

    test('FailureMapper maps sqlite unique email error to DatabaseFailure', () {
      final sqfliteException = Exception('UNIQUE constraint failed: members.email');
      final mapped = FailureMapper.map(sqfliteException);
      expect(mapped, isA<DatabaseFailure>());
      expect(mapped.userMessage, contains('member with that email address already exists'));
    });

    test('FailureMapper maps unknown exception to UnknownFailure', () {
      final exception = FormatException('Bad data format');
      final mapped = FailureMapper.map(exception);
      expect(mapped, isA<UnknownFailure>());
      expect(mapped.userMessage, contains('unexpected error occurred'));
    });
  });
}
