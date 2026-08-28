import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_management_systems/features/auth/domain/user_model.dart';
import 'package:invest_management_systems/features/members/domain/member_model.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/create_user_dialog.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/admin_reset_password_dialog.dart';
import 'package:invest_management_systems/features/settings/presentation/widgets/edit_user_role_dialog.dart';
import 'package:invest_management_systems/features/ledger/presentation/widgets/add_adjustment_dialog.dart';
import 'package:invest_management_systems/features/contribution_requests/presentation/widgets/raise_contribution_request_dialog.dart';

void main() {
  group('Modular Dialogs Widget Tests', () {
    testWidgets('ChangePasswordDialog renders fields and validates password match', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(username: 'testuser'),
            ),
          ),
        ),
      );

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('CreateUserDialog renders form fields and role selector', (tester) async {
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
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Initial Password'), findsOneWidget);
    });

    testWidgets('AdminResetPasswordDialog renders target username and new password field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminResetPasswordDialog(
                userId: 1,
                targetUsername: 'staffuser',
                actionByUsername: 'superadmin',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reset Password for "staffuser"'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
    });

    testWidgets('EditUserRoleDialog renders role selector for target user', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditUserRoleDialog(
                userId: 2,
                targetUsername: 'john_doe',
                currentRole: 'MEMBER',
                actionByUsername: 'superadmin',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Change Role for "john_doe"'), findsOneWidget);
      expect(find.text('Save Role'), findsOneWidget);
    });

    testWidgets('AddAdjustmentDialog renders transaction type and amount fields', (tester) async {
      final List<MemberModel> sampleMembers = [
        MemberModel(
          id: 1,
          name: 'Kamran Hashmi',
          email: 'kamran@example.com',
          phone: '+91 9876543210',
          joinedDate: '2026-01-01T00:00:00.000',
          status: 'ACTIVE',
          totalContributionPaise: 1000000,
          contributionPercentage: 50.0,
          investmentSharePaise: 500000,
          allocatedProfitPaise: 10000,
          totalWithdrawalPaise: 0,
          availableBalancePaise: 1010000,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddAdjustmentDialog(members: sampleMembers),
            ),
          ),
        ),
      );

      expect(find.text('Record Manual Adjustment / Refund'), findsOneWidget);
      expect(find.text('Transaction Type'), findsOneWidget);
      expect(find.text('Amount (₹)'), findsOneWidget);
    });

    testWidgets('RaiseContributionRequestDialog renders amount and payment mode options', (tester) async {
      final user = UserModel(
        id: 1,
        username: 'gufran@gmail.com',
        fullName: 'Gufran Hashmi',
        role: 'MEMBER',
        memberId: 2,
        createdAt: '2026-01-01T00:00:00.000',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RaiseContributionRequestDialog(user: user),
            ),
          ),
        ),
      );

      expect(find.text('Raise Add Money Request'), findsOneWidget);
      expect(find.text('Requested Amount (₹)'), findsOneWidget);
      expect(find.text('Intended Payment Mode'), findsOneWidget);
    });
  });
}
