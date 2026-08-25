import 'package:flutter_test/flutter_test.dart';
import 'package:invest_management_systems/core/errors/app_failure.dart';

void main() {
  group('AppFailure & Exception Mapping Tests', () {
    test('Map unique username SQLite constraint failure to friendly message', () {
      final rawException = Exception('SqliteException(2067): UNIQUE constraint failed: users.username');
      final failure = FailureMapper.map(rawException);

      expect(failure, isA<DatabaseFailure>());
      expect(failure.userMessage, contains('username is already taken'));
      expect(failure.toString(), contains('username is already taken'));
    });

    test('Map unique email SQLite constraint failure to friendly message', () {
      final rawException = Exception('SqliteException(2067): UNIQUE constraint failed: members.email');
      final failure = FailureMapper.map(rawException);

      expect(failure, isA<DatabaseFailure>());
      expect(failure.userMessage, contains('email address already exists'));
    });

    test('Map generic unknown exception to safe user message without leaking raw trace', () {
      final rawException = StateError('Internal null reference crash');
      final failure = FailureMapper.map(rawException);

      expect(failure, isA<UnknownFailure>());
      expect(failure.userMessage, contains('An unexpected error occurred'));
      expect(failure.userMessage, isNot(contains('Internal null reference crash')));
      expect(failure.technicalDetails, contains('Internal null reference crash'));
    });
  });
}
