// Fix D: Error Handling Widget Test.
// Verifies that AsyncValueWidget displays user-friendly AppFailure error messages
// and graceful error UI states across async states.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:invest_management_systems/core/errors/app_failure.dart';
import 'package:invest_management_systems/core/widgets/async_value_widget.dart';

void main() {
  group('AsyncValueWidget Error Handling – Fix D', () {
    testWidgets('renders user-friendly message when AsyncValue has DatabaseFailure',
        (WidgetTester tester) async {
      const failure = DatabaseFailure(
        'A database conflict occurred while saving changes. Please try again.',
        technicalDetails: 'sqlite exception details',
      );

      final asyncValueError = AsyncValue<String>.error(
        failure,
        StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncValueError,
              data: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(
        find.text('A database conflict occurred while saving changes. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders mapped failure message when AsyncValue has raw exception',
        (WidgetTester tester) async {
      final rawException = Exception('UNIQUE constraint failed: users.username');
      final failure = FailureMapper.map(rawException);

      final asyncValueError = AsyncValue<String>.error(
        failure,
        StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncValueError,
              data: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );

      expect(
        find.text('That username is already taken. Please choose another username.'),
        findsOneWidget,
      );
    });

    testWidgets('renders custom errorWidget when provided',
        (WidgetTester tester) async {
      const failure = UnknownFailure('Something went wrong');
      final asyncValueError = AsyncValue<String>.error(
        failure,
        StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: asyncValueError,
              data: (data) => Text('Data: $data'),
              errorWidget: (err, st) => const Text('Custom Error UI'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Error UI'), findsOneWidget);
    });
  });
}
