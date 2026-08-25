/// Base class for all application failures.
abstract class AppFailure implements Exception {
  final String userMessage;
  final String? technicalDetails;
  final Object? originalException;

  const AppFailure(
    this.userMessage, {
    this.technicalDetails,
    this.originalException,
  });

  @override
  String toString() => userMessage;
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class DeviceAuthorizationFailure extends AppFailure {
  const DeviceAuthorizationFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class FinancialFailure extends AppFailure {
  const FinancialFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(
    super.userMessage, {
    super.technicalDetails,
    super.originalException,
  });
}

/// Helper utility to convert raw exceptions into safe, user-friendly AppFailures.
class FailureMapper {
  FailureMapper._();

  static AppFailure map(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('unique constraint failed') ||
        errorString.contains('sqliteexception')) {
      if (errorString.contains('username')) {
        return DatabaseFailure(
          'That username is already taken. Please choose another username.',
          technicalDetails: error.toString(),
          originalException: error,
        );
      }
      if (errorString.contains('email')) {
        return DatabaseFailure(
          'A member with that email address already exists.',
          technicalDetails: error.toString(),
          originalException: error,
        );
      }
      return DatabaseFailure(
        'A database conflict occurred while saving changes. Please try again.',
        technicalDetails: error.toString(),
        originalException: error,
      );
    }

    return UnknownFailure(
      'An unexpected error occurred. Please try again or contact support.',
      technicalDetails: error.toString(),
      originalException: error,
    );
  }
}
