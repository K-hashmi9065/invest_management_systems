import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/create_user_dialog.dart';

void main() {
  group('Dialog Resource Disposal Tests', () {
    testWidgets('ChangePasswordDialog disposes controllers cleanly when popped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(username: 'admin'),
            ),
          ),
        ),
      );

      expect(find.text('Change Password'), findsOneWidget);

      // Enter input in fields
      await tester.enterText(find.byType(TextField).at(0), 'oldPass123');
      await tester.enterText(find.byType(TextField).at(1), 'newPass123');
      await tester.enterText(find.byType(TextField).at(2), 'newPass123');

      // Cancel and pop dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsNothing);
    });

    testWidgets('CreateUserDialog disposes controllers cleanly when popped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateUserDialog(actionByUsername: 'superadmin'),
            ),
          ),
        ),
      );

      expect(find.text('Create Administrative / Staff User'), findsOneWidget);

      // Enter input in fields
      await tester.enterText(find.byType(TextField).at(0), 'Officer Name');
      await tester.enterText(find.byType(TextField).at(1), 'officer@test.com');
      await tester.enterText(find.byType(TextField).at(2), '+919999999999');
      await tester.enterText(find.byType(TextField).at(3), 'pass123456');

      // Cancel and pop dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Administrative / Staff User'), findsNothing);
    });
  });
}
