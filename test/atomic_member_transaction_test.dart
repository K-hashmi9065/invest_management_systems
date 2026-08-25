import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invest_management_systems/core/database/app_repository.dart';
import 'package:invest_management_systems/core/database/database_helper.dart';
import 'package:invest_management_systems/core/errors/app_failure.dart';
import 'package:invest_management_systems/core/security/device_lock_service.dart';

void main() {
  late AppRepository repo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DeviceLockService.initialize();
  });

  setUp(() async {
    DatabaseHelper.testDbPath = inMemoryDatabasePath;
    await DatabaseHelper.resetForTest();
    repo = AppRepository();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTest();
    DatabaseHelper.testDbPath = null;
  });

  group('Atomic Member & User Creation Tests', () {
    test(
      'createMemberWithUser creates both member and user record atomically and allows login via email or phone',
      () async {
        final member = await repo.createMemberWithUser(
          name: 'Alice Johnson',
          email: 'alice@example.com',
          phone: '+91 9876543210',
          password: 'Password123!',
          actionBy: 'Admin',
        );

        expect(member.id, isPositive);
        expect(member.name, equals('Alice Johnson'));

        // 1. Verify user can log in with Email
        final userByEmail = await repo.login(
          'alice@example.com',
          'Password123!',
        );
        expect(userByEmail, isNotNull);
        expect(userByEmail!.email, equals('alice@example.com'));
        expect(userByEmail.memberId, equals(member.id));
        expect(userByEmail.role, equals('MEMBER'));

        // 2. Verify user can log in with Mobile Number
        final userByPhone = await repo.login('+91 9876543210', 'Password123!');
        expect(userByPhone, isNotNull);
        expect(userByPhone!.id, equals(userByEmail.id));

        // 3. Verify Super Admin creation with email and phone, and login with email/phone
        final superAdmin = await repo.createSuperAdmin(
          fullName: 'Master Admin',
          email: 'superadmin@investment.com',
          phone: '+91 9000000000',
          password: 'AdminPassword123!',
        );
        expect(superAdmin.role, equals('SUPER_ADMIN'));

        final loginAdminByEmail = await repo.login(
          'superadmin@investment.com',
          'AdminPassword123!',
        );
        expect(loginAdminByEmail, isNotNull);
        expect(loginAdminByEmail!.role, equals('SUPER_ADMIN'));

        final loginAdminByPhone = await repo.login(
          '+91 9000000000',
          'AdminPassword123!',
        );
        expect(loginAdminByPhone, isNotNull);
        expect(loginAdminByPhone!.id, equals(superAdmin.id));
      },
    );

    test(
      'createMemberWithUser rolls back member creation on duplicate email/username',
      () async {
        // First user creation succeeds
        await repo.createMemberWithUser(
          name: 'First User',
          email: 'duplicate@example.com',
          phone: '+91 1111111111',
          password: 'Password123!',
          actionBy: 'Admin',
        );

        // Second user creation with same email must fail and rollback member insert
        expect(
          () async => await repo.createMemberWithUser(
            name: 'Second User',
            email: 'duplicate@example.com',
            phone: '+91 2222222222',
            password: 'Password123!',
            actionBy: 'Admin',
          ),
          throwsA(anything),
        );

        // Verify only 1 member exists in the database (no orphan member)
        final members = await repo.getMembers();
        expect(members.length, equals(1));
        expect(members.first.name, equals('First User'));
      },
    );
  });

  group('Withdrawal Overdraft Protection Tests', () {
    test(
      'reviewWithdrawalRequest prevents approval if requested amount exceeds available balance',
      () async {
        final member = await repo.createMemberWithUser(
          name: 'Bob Smith',
          email: 'bob@example.com',
          phone: '+91 9999999999',
          username: 'bob_s',
          password: 'Password123!',
          actionBy: 'Admin',
        );

        // Record contribution of 10,000 INR (1,000,000 paise)
        await repo.recordContribution(
          memberId: member.id,
          amountPaise: 1000000,
          paymentMode: 'UPI',
          actionBy: 'Admin',
        );

        // Submit withdrawal request for 15,000 INR (1,500,000 paise) -> exceeds balance!
        await repo.submitWithdrawalRequest(
          memberId: member.id,
          amountPaise: 1500000,
          remarks: 'Excess withdrawal request',
          actionBy: 'Bob',
        );

        final withdrawals = await repo.getWithdrawals();
        expect(withdrawals.isNotEmpty, isTrue);
        final reqId = withdrawals.first.id;

        // Approving this must throw FinancialFailure
        expect(
          () async => await repo.reviewWithdrawalRequest(
            withdrawalId: reqId,
            approve: true,
            actionBy: 'Admin',
          ),
          throwsA(isA<FinancialFailure>()),
        );
      },
    );
  });
}
