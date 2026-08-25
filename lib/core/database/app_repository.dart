import 'package:sqflite/sqflite.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/members/domain/member_model.dart';
import '../../features/contributions/domain/contribution_model.dart';
import '../../features/contribution_requests/domain/contribution_request_model.dart';
import '../../features/investments/domain/investment_model.dart';
import '../../features/profit_loss/domain/profit_distribution_model.dart';
import '../../features/withdrawals/domain/withdrawal_model.dart';
import '../../features/ledger/domain/transaction_model.dart';
import '../../features/audit_logs/domain/audit_log_model.dart';
import '../../features/notifications/domain/notification_model.dart';
import '../constants/app_constants.dart';
import '../calculations/contribution_calculator.dart';
import '../calculations/profit_calculator.dart';
import '../errors/app_failure.dart';
import '../security/password_hasher.dart';
import '../utils/date_formatter.dart';
import 'database_helper.dart';

class GroupFinancialSummary {
  final int totalApprovedContributionsPaise;
  final int totalInvestedPaise;
  final int totalRealizedReturnsPaise;
  final int totalApprovedWithdrawalsPaise;
  final int totalDistributedProfitPaise;
  final int availableBalancePaise;

  GroupFinancialSummary({
    required this.totalApprovedContributionsPaise,
    required this.totalInvestedPaise,
    required this.totalRealizedReturnsPaise,
    required this.totalApprovedWithdrawalsPaise,
    required this.totalDistributedProfitPaise,
    required this.availableBalancePaise,
  });
}

class AppRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // AUTH & USERS
  Future<bool> isFirstTimeSetupNeeded() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM users WHERE role = 'SUPER_ADMIN'",
      ),
    );
    return count == null || count == 0;
  }

  Future<UserModel?> login(String identifier, String password) async {
    final db = await _dbHelper.database;
    final cleanId = identifier.trim();

    // Match against username, email, phone in users table OR linked member email/phone
    final maps = await db.rawQuery(
      '''
      SELECT u.* FROM users u
      LEFT JOIN members m ON u.member_id = m.id
      WHERE u.username = ? 
         OR u.email = ? 
         OR u.phone = ?
         OR m.email = ?
         OR m.phone = ?
    ''',
      [cleanId, cleanId, cleanId, cleanId, cleanId],
    );

    if (maps.isEmpty) return null;

    final userMap = maps.first;
    final storedHash = userMap['password_hash'] as String;
    final salt = userMap['salt'] as String;

    final verifyResult = PasswordHasher.verifyPasswordDetailed(
      password,
      storedHash,
      salt,
    );
    if (!verifyResult.matched) return null;

    // Fix A: upgrade legacy SHA-256 hash to PBKDF2 on first successful login.
    if (verifyResult.usedLegacyHash) {
      final newSalt = PasswordHasher.generateSalt();
      final newHash = PasswordHasher.hashPassword(password, newSalt);
      await db.update(
        'users',
        {'password_hash': newHash, 'salt': newSalt},
        where: 'id = ?',
        whereArgs: [userMap['id']],
      );
    }

    return UserModel.fromMap(userMap);
  }

  Future<UserModel> createSuperAdmin({
    required String fullName,
    String? username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final db = await _dbHelper.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateFormatter.toIso(DateTime.now());
    final effectiveUsername = username?.trim().isNotEmpty == true
        ? username!.trim()
        : email.trim().toLowerCase();

    final id = await db.insert('users', {
      'username': effectiveUsername,
      'password_hash': hash,
      'salt': salt,
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': AppConstants.roleSuperAdmin,
      'created_at': now,
    });

    await logAudit(
      userId: id,
      username: effectiveUsername,
      action: 'SYSTEM_SETUP',
      details: 'Super Admin account created: $effectiveUsername ($fullName)',
    );

    return UserModel(
      id: id,
      username: effectiveUsername,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: AppConstants.roleSuperAdmin,
      createdAt: now,
    );
  }

  Future<UserModel> createUser({
    required String fullName,
    String? username,
    String? email,
    String? phone,
    required String password,
    required String role,
    int? memberId,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateFormatter.toIso(DateTime.now());

    final effectiveUsername = username?.trim().isNotEmpty == true
        ? username!.trim()
        : (email?.trim().isNotEmpty == true
              ? email!.trim().toLowerCase()
              : (phone?.trim().isNotEmpty == true
                    ? phone!.trim()
                    : fullName.trim().toLowerCase().replaceAll(
                        RegExp(r'\s+'),
                        '_',
                      )));

    final id = await db.insert('users', {
      'username': effectiveUsername,
      'password_hash': hash,
      'salt': salt,
      'full_name': fullName.trim(),
      'email': email?.trim(),
      'phone': phone?.trim(),
      'role': role,
      'member_id': memberId,
      'created_at': now,
    });

    await logAudit(
      username: actionBy,
      action: 'CREATE_USER',
      details: 'User created: $effectiveUsername ($role)',
    );

    return UserModel(
      id: id,
      username: effectiveUsername,
      fullName: fullName.trim(),
      email: email?.trim(),
      phone: phone?.trim(),
      role: role,
      memberId: memberId,
      createdAt: now,
    );
  }

  // MEMBERS & CALCULATIONS (Optimized Single Aggregated Query)
  Future<List<MemberModel>> getMembers() async {
    final db = await _dbHelper.database;
    final summary = await getGroupFinancialSummary();

    final memberMaps = await db.rawQuery('''
      SELECT 
        m.*,
        COALESCE(c.total_contrib, 0) AS total_contribution_paise,
        COALESCE(pd.total_profit, 0) AS allocated_profit_paise,
        COALESCE(w.total_withdraw, 0) AS total_withdrawal_paise
      FROM members m
      LEFT JOIN (
        SELECT member_id, SUM(amount_paise) AS total_contrib
        FROM contributions
        WHERE status = 'APPROVED'
        GROUP BY member_id
      ) c ON m.id = c.member_id
      LEFT JOIN (
        SELECT member_id, SUM(profit_amount_paise) AS total_profit
        FROM profit_distributions
        GROUP BY member_id
      ) pd ON m.id = pd.member_id
      LEFT JOIN (
        SELECT member_id, SUM(amount_paise) AS total_withdraw
        FROM withdrawals
        WHERE status = 'APPROVED'
        GROUP BY member_id
      ) w ON m.id = w.member_id
      ORDER BY m.id ASC
    ''');

    final List<MemberModel> members = [];

    for (final map in memberMaps) {
      final totalContribPaise =
          (map['total_contribution_paise'] as num?)?.toInt() ?? 0;
      final allocatedProfitPaise =
          (map['allocated_profit_paise'] as num?)?.toInt() ?? 0;
      final totalWithdrawalPaise =
          (map['total_withdrawal_paise'] as num?)?.toInt() ?? 0;

      // Calculate Contribution %
      final double contribPct = ContributionCalculator.percentageOf(
        totalContribPaise,
        summary.totalApprovedContributionsPaise,
      );

      // Calculate Member's Share of Investments
      final int investmentSharePaise = ProfitCalculator.memberShare(
        summary.totalInvestedPaise,
        contribPct,
      );

      // Calculate Available Balance
      final availableBalancePaise =
          totalContribPaise + allocatedProfitPaise - totalWithdrawalPaise;

      members.add(
        MemberModel.fromMap(
          map,
          totalContributionPaise: totalContribPaise,
          contributionPercentage: contribPct,
          investmentSharePaise: investmentSharePaise,
          allocatedProfitPaise: allocatedProfitPaise,
          totalWithdrawalPaise: totalWithdrawalPaise,
          availableBalancePaise: availableBalancePaise,
        ),
      );
    }

    return members;
  }

  /// Atomic Member + User account creation within a single SQLite transaction
  Future<MemberModel> createMemberWithUser({
    required String name,
    required String email,
    required String phone,
    String? username,
    required String password,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final effectiveUsername = username?.trim().isNotEmpty == true
        ? username!.trim()
        : email.trim().toLowerCase();

    int memberId = 0;

    await db.transaction((txn) async {
      memberId = await txn.insert('members', {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'joined_date': now,
        'status': AppConstants.statusActive,
      });

      await txn.insert('users', {
        'username': effectiveUsername,
        'password_hash': hash,
        'salt': salt,
        'full_name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': AppConstants.roleMember,
        'member_id': memberId,
        'created_at': now,
      });

      await txn.insert('audit_logs', {
        'username': actionBy,
        'action': 'ADD_MEMBER_WITH_USER',
        'details':
            'Added member $name (#$memberId) with login $effectiveUsername',
        'timestamp': now,
      });
    });

    return MemberModel(
      id: memberId,
      name: name,
      email: email,
      phone: phone,
      joinedDate: now,
      status: AppConstants.statusActive,
    );
  }

  Future<MemberModel> createMember({
    required String name,
    required String email,
    required String phone,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    final id = await db.insert('members', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'joined_date': now,
      'status': AppConstants.statusActive,
    });

    await logAudit(
      username: actionBy,
      action: 'ADD_MEMBER',
      details: 'Added member: $name',
    );

    return MemberModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      joinedDate: now,
      status: AppConstants.statusActive,
    );
  }

  // GROUP FINANCIAL SUMMARY
  Future<GroupFinancialSummary> getGroupFinancialSummary() async {
    final db = await _dbHelper.database;

    // Total Approved Contributions
    final contribRes = await db.rawQuery(
      "SELECT SUM(amount_paise) as total FROM contributions WHERE status = 'APPROVED'",
    );
    final totalContribPaise = (contribRes.first['total'] as int?) ?? 0;

    // Total Invested
    final investRes = await db.rawQuery(
      'SELECT SUM(amount_paise) as total FROM investments',
    );
    final totalInvestedPaise = (investRes.first['total'] as int?) ?? 0;

    // Realized Returns
    final returnRes = await db.rawQuery(
      'SELECT SUM(actual_return_paise) as total FROM investments',
    );
    final totalReturnsPaise = (returnRes.first['total'] as int?) ?? 0;

    // Total Approved Withdrawals
    final withdrawRes = await db.rawQuery(
      "SELECT SUM(amount_paise) as total FROM withdrawals WHERE status = 'APPROVED'",
    );
    final totalWithdrawalsPaise = (withdrawRes.first['total'] as int?) ?? 0;

    // Total Profit Distributed
    final profitRes = await db.rawQuery(
      'SELECT SUM(profit_amount_paise) as total FROM profit_distributions',
    );
    final totalProfitPaise = (profitRes.first['total'] as int?) ?? 0;

    // Available Group Balance = Approved Contributions - Invested - Withdrawals + Returns
    final availablePaise =
        totalContribPaise -
        totalInvestedPaise -
        totalWithdrawalsPaise +
        totalReturnsPaise;

    return GroupFinancialSummary(
      totalApprovedContributionsPaise: totalContribPaise,
      totalInvestedPaise: totalInvestedPaise,
      totalRealizedReturnsPaise: totalReturnsPaise,
      totalApprovedWithdrawalsPaise: totalWithdrawalsPaise,
      totalDistributedProfitPaise: totalProfitPaise,
      availableBalancePaise: availablePaise,
    );
  }

  // CONTRIBUTIONS & ADMIN COLLECTION
  Future<List<ContributionModel>> getContributions() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT c.*, m.name as member_name 
      FROM contributions c 
      JOIN members m ON c.member_id = m.id 
      ORDER BY c.id DESC
    ''');
    return maps.map((m) => ContributionModel.fromMap(m)).toList();
  }

  Future<void> recordContribution({
    required int memberId,
    required int amountPaise,
    required String paymentMode,
    String? referenceNo,
    String? remarks,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert('contributions', {
        'member_id': memberId,
        'amount_paise': amountPaise,
        'contribution_date': now,
        'payment_mode': paymentMode,
        'reference_no': referenceNo,
        'status': AppConstants.statusApproved,
        'approved_by': actionBy,
        'approved_at': now,
        'remarks': remarks,
        'created_at': now,
      });

      await txn.insert('transactions', {
        'transaction_type': AppConstants.txContribution,
        'member_id': memberId,
        'amount_paise': amountPaise,
        'date': now,
        'status': AppConstants.statusApproved,
        'reference_no': referenceNo,
        'remarks': remarks ?? 'Payment collected by admin $actionBy',
        'created_by': actionBy,
        'approved_by': actionBy,
      });
    });

    await logAudit(
      username: actionBy,
      action: 'RECORD_CONTRIBUTION',
      details:
          'Recorded approved contribution: ${amountPaise / 100} INR for Member #$memberId',
    );
  }

  // CONTRIBUTION REQUESTS
  Future<List<ContributionRequestModel>> getContributionRequests() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT r.*, m.name as member_name 
      FROM contribution_requests r 
      JOIN members m ON r.member_id = m.id 
      ORDER BY r.id DESC
    ''');
    return maps.map((m) => ContributionRequestModel.fromMap(m)).toList();
  }

  Future<void> submitContributionRequest({
    required int memberId,
    required int amountPaise,
    required String paymentMode,
    String? remarks,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert('contribution_requests', {
      'member_id': memberId,
      'amount_paise': amountPaise,
      'payment_mode': paymentMode,
      'status': AppConstants.statusPending,
      'requested_at': now,
      'remarks': remarks,
    });

    await logAudit(
      username: actionBy,
      action: 'SUBMIT_CONTRIBUTION_REQUEST',
      details:
          'Contribution request submitted: ${amountPaise / 100} INR by Member #$memberId',
    );
  }

  Future<void> reviewContributionRequest({
    required int requestId,
    required bool approve,
    required String actionBy,
    String? remarks,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    final reqs = await db.query(
      'contribution_requests',
      where: 'id = ?',
      whereArgs: [requestId],
    );
    if (reqs.isEmpty) return;

    final req = reqs.first;
    final memberId = req['member_id'] as int;
    final amountPaise = req['amount_paise'] as int;
    final paymentMode = req['payment_mode'] as String;

    if (approve) {
      await db.transaction((txn) async {
        await txn.update(
          'contribution_requests',
          {
            'status': AppConstants.statusApproved,
            'reviewed_by': actionBy,
            'reviewed_at': now,
            'remarks': remarks,
          },
          where: 'id = ?',
          whereArgs: [requestId],
        );

        await txn.insert('contributions', {
          'member_id': memberId,
          'amount_paise': amountPaise,
          'contribution_date': now,
          'payment_mode': paymentMode,
          'status': AppConstants.statusApproved,
          'approved_by': actionBy,
          'approved_at': now,
          'remarks': remarks ?? 'Approved from Request #$requestId',
          'created_at': now,
        });

        await txn.insert('transactions', {
          'transaction_type': AppConstants.txContribution,
          'member_id': memberId,
          'amount_paise': amountPaise,
          'date': now,
          'status': AppConstants.statusApproved,
          'remarks': 'Approved Contribution Request #$requestId',
          'created_by': actionBy,
          'approved_by': actionBy,
        });
      });
    } else {
      await db.update(
        'contribution_requests',
        {
          'status': AppConstants.statusRejected,
          'reviewed_by': actionBy,
          'reviewed_at': now,
          'remarks': remarks,
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
    }

    await logAudit(
      username: actionBy,
      action: approve ? 'APPROVE_CONTRIBUTION_REQ' : 'REJECT_CONTRIBUTION_REQ',
      details:
          '${approve ? "Approved" : "Rejected"} Contribution Request #$requestId',
    );
  }

  // INVESTMENTS
  Future<List<InvestmentModel>> getInvestments() async {
    final db = await _dbHelper.database;
    final maps = await db.query('investments', orderBy: 'id DESC');
    return maps.map((m) => InvestmentModel.fromMap(m)).toList();
  }

  Future<void> createInvestment({
    required String name,
    required String type,
    required int amountPaise,
    required int periodMonths,
    required int expectedReturnPaise,
    required String actionBy,
    String? remarks,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert('investments', {
        'name': name,
        'type': type,
        'amount_paise': amountPaise,
        'investment_date': now,
        'period_months': periodMonths,
        'expected_return_paise': expectedReturnPaise,
        'actual_return_paise': 0,
        'current_value_paise': amountPaise,
        'status': AppConstants.statusActive,
        'remarks': remarks,
        'created_by': actionBy,
      });

      await txn.insert('transactions', {
        'transaction_type': AppConstants.txInvestment,
        'amount_paise': amountPaise,
        'date': now,
        'status': AppConstants.statusCompleted,
        'remarks': 'Investment made: $name',
        'created_by': actionBy,
      });
    });

    await logAudit(
      username: actionBy,
      action: 'CREATE_INVESTMENT',
      details: 'Created investment: $name (${amountPaise / 100} INR)',
    );
  }

  // PROFIT DISTRIBUTION
  Future<List<ProfitDistributionModel>> getProfitDistributions() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT pd.*, i.name as investment_name, m.name as member_name
      FROM profit_distributions pd
      JOIN investments i ON pd.investment_id = i.id
      JOIN members m ON pd.member_id = m.id
      ORDER BY pd.id DESC
    ''');
    return maps.map((m) => ProfitDistributionModel.fromMap(m)).toList();
  }

  Future<void> distributeProfit({
    required int investmentId,
    required int totalProfitPaise,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final members = await getMembers();
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      for (final member in members) {
        if (member.contributionPercentage > 0) {
          final memberProfitPaise = ProfitCalculator.memberShare(
            totalProfitPaise,
            member.contributionPercentage,
          );

          await txn.insert('profit_distributions', {
            'investment_id': investmentId,
            'member_id': member.id,
            'member_percentage': member.contributionPercentage,
            'profit_amount_paise': memberProfitPaise,
            'distributed_at': now,
          });

          await txn.insert('transactions', {
            'transaction_type': AppConstants.txProfit,
            'member_id': member.id,
            'amount_paise': memberProfitPaise,
            'date': now,
            'status': AppConstants.statusApproved,
            'remarks': 'Profit distributed for Investment #$investmentId',
            'created_by': actionBy,
          });
        }
      }

      await txn.rawUpdate(
        'UPDATE investments SET actual_return_paise = actual_return_paise + ?, status = ? WHERE id = ?',
        [totalProfitPaise, AppConstants.statusCompleted, investmentId],
      );
    });

    await logAudit(
      username: actionBy,
      action: 'DISTRIBUTE_PROFIT',
      details:
          'Distributed profit of ${totalProfitPaise / 100} INR for Investment #$investmentId',
    );
  }

  Future<void> distributeLoss({
    required int investmentId,
    required int totalLossPaise,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final members = await getMembers();
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      for (final member in members) {
        if (member.contributionPercentage > 0) {
          final memberLossPaise = ProfitCalculator.memberShare(
            totalLossPaise,
            member.contributionPercentage,
          );

          await txn.insert('profit_distributions', {
            'investment_id': investmentId,
            'member_id': member.id,
            'member_percentage': member.contributionPercentage,
            'profit_amount_paise': -memberLossPaise,
            'distributed_at': now,
          });

          await txn.insert('transactions', {
            'transaction_type': AppConstants.txLoss,
            'member_id': member.id,
            'amount_paise': memberLossPaise,
            'date': now,
            'status': AppConstants.statusApproved,
            'remarks': 'Loss distributed for Investment #$investmentId',
            'created_by': actionBy,
          });
        }
      }

      await txn.rawUpdate(
        'UPDATE investments SET actual_return_paise = actual_return_paise - ?, status = ? WHERE id = ?',
        [totalLossPaise, AppConstants.statusCompleted, investmentId],
      );
    });

    await logAudit(
      username: actionBy,
      action: 'DISTRIBUTE_LOSS',
      details:
          'Distributed loss of ${totalLossPaise / 100} INR for Investment #$investmentId',
    );
  }

  // USER & SECURITY MANAGEMENT
  Future<List<UserModel>> getUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', orderBy: 'id ASC');
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<void> updateUserRole({
    required int userId,
    required String newRole,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'role': newRole},
      where: 'id = ?',
      whereArgs: [userId],
    );

    await logAudit(
      username: actionBy,
      action: 'UPDATE_USER_ROLE',
      details: 'Updated User #$userId role to $newRole',
    );
  }

  Future<void> deleteUser({
    required int userId,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    final username = users.isNotEmpty
        ? users.first['username']
        : 'User #$userId';

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);

    await logAudit(
      username: actionBy,
      action: 'DELETE_USER',
      details: 'Deleted user account: $username (ID: $userId)',
    );
  }

  Future<void> updateMemberStatus({
    required int memberId,
    required String status,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'members',
      {'status': status},
      where: 'id = ?',
      whereArgs: [memberId],
    );

    await logAudit(
      username: actionBy,
      action: 'UPDATE_MEMBER_STATUS',
      details: 'Updated Member #$memberId status to $status',
    );
  }

  Future<void> resetUserPassword({
    required int userId,
    required String newPassword,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(newPassword, salt);

    await db.update(
      'users',
      {'password_hash': hash, 'salt': salt},
      where: 'id = ?',
      whereArgs: [userId],
    );

    await logAudit(
      username: actionBy,
      action: 'RESET_USER_PASSWORD',
      details: 'Reset password for User #$userId',
    );
  }

  Future<bool> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = await login(username, oldPassword);
    if (user == null) return false;

    final db = await _dbHelper.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(newPassword, salt);

    await db.update(
      'users',
      {'password_hash': hash, 'salt': salt},
      where: 'username = ?',
      whereArgs: [username],
    );

    await logAudit(
      username: username,
      action: 'CHANGE_PASSWORD',
      details: 'User $username successfully changed their password',
    );

    return true;
  }

  // WITHDRAWALS
  Future<List<WithdrawalModel>> getWithdrawals() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT w.*, m.name as member_name
      FROM withdrawals w
      JOIN members m ON w.member_id = m.id
      ORDER BY w.id DESC
    ''');
    return maps.map((m) => WithdrawalModel.fromMap(m)).toList();
  }

  Future<void> submitWithdrawalRequest({
    required int memberId,
    required int amountPaise,
    String? remarks,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert('withdrawals', {
      'member_id': memberId,
      'amount_paise': amountPaise,
      'status': AppConstants.statusPending,
      'requested_at': now,
      'remarks': remarks,
    });

    await logAudit(
      username: actionBy,
      action: 'SUBMIT_WITHDRAWAL_REQ',
      details:
          'Submitted withdrawal request of ${amountPaise / 100} INR for Member #$memberId',
    );
  }

  Future<void> reviewWithdrawalRequest({
    required int withdrawalId,
    required bool approve,
    required String actionBy,
    String? remarks,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    final withdraws = await db.query(
      'withdrawals',
      where: 'id = ?',
      whereArgs: [withdrawalId],
    );
    if (withdraws.isEmpty) return;

    final w = withdraws.first;
    final memberId = w['member_id'] as int;
    final amountPaise = w['amount_paise'] as int;

    if (approve) {
      await db.transaction((txn) async {
        // Overdraft prevention check within transaction
        final contribRes = await txn.rawQuery(
          "SELECT SUM(amount_paise) as total FROM contributions WHERE member_id = ? AND status = 'APPROVED'",
          [memberId],
        );
        final totalContrib = (contribRes.first['total'] as int?) ?? 0;

        final profitRes = await txn.rawQuery(
          'SELECT SUM(profit_amount_paise) as total FROM profit_distributions WHERE member_id = ?',
          [memberId],
        );
        final totalProfit = (profitRes.first['total'] as int?) ?? 0;

        final priorWithdrawRes = await txn.rawQuery(
          "SELECT SUM(amount_paise) as total FROM withdrawals WHERE member_id = ? AND status = 'APPROVED'",
          [memberId],
        );
        final priorWithdraw = (priorWithdrawRes.first['total'] as int?) ?? 0;

        final currentBalance = totalContrib + totalProfit - priorWithdraw;
        if (currentBalance < amountPaise) {
          throw FinancialFailure(
            'Cannot approve withdrawal of ₹${amountPaise / 100}. Member available balance is only ₹${currentBalance / 100}.',
          );
        }

        await txn.update(
          'withdrawals',
          {
            'status': AppConstants.statusApproved,
            'approved_by': actionBy,
            'approved_at': now,
            'remarks': remarks,
          },
          where: 'id = ?',
          whereArgs: [withdrawalId],
        );

        await txn.insert('transactions', {
          'transaction_type': AppConstants.txWithdrawal,
          'member_id': memberId,
          'amount_paise': amountPaise,
          'date': now,
          'status': AppConstants.statusApproved,
          'remarks': 'Approved Withdrawal #$withdrawalId',
          'created_by': actionBy,
          'approved_by': actionBy,
        });
      });
    } else {
      await db.update(
        'withdrawals',
        {
          'status': AppConstants.statusRejected,
          'approved_by': actionBy,
          'approved_at': now,
          'remarks': remarks,
        },
        where: 'id = ?',
        whereArgs: [withdrawalId],
      );
    }

    await logAudit(
      username: actionBy,
      action: approve ? 'APPROVE_WITHDRAWAL' : 'REJECT_WITHDRAWAL',
      details: '${approve ? "Approved" : "Rejected"} Withdrawal #$withdrawalId',
    );
  }

  // TRANSACTIONS & LEDGER
  Future<List<TransactionModel>> getTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT t.*, m.name as member_name
      FROM transactions t
      LEFT JOIN members m ON t.member_id = m.id
      ORDER BY t.id DESC
    ''');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // AUDIT LOGS
  Future<List<AuditLogModel>> getAuditLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('audit_logs', orderBy: 'id DESC');
    return maps.map((m) => AuditLogModel.fromMap(m)).toList();
  }

  Future<void> logAudit({
    int? userId,
    required String username,
    required String action,
    required String details,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert('audit_logs', {
      'user_id': userId,
      'username': username,
      'action': action,
      'details': details,
      'timestamp': now,
    });
  }

  // MANUAL ADJUSTMENT & REFUND TRANSACTIONS
  Future<void> recordAdjustmentOrRefund({
    int? memberId,
    required String transactionType,
    required int amountPaise,
    required String remarks,
    required String actionBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.transaction((txn) async {
      await txn.insert('transactions', {
        'transaction_type': transactionType,
        'member_id': memberId,
        'amount_paise': amountPaise,
        'date': now,
        'status': AppConstants.statusApproved,
        'remarks': remarks,
        'created_by': actionBy,
        'approved_by': actionBy,
      });
    });

    await createNotification(
      title: 'Ledger $transactionType Posted',
      message:
          '$transactionType of ₹${amountPaise / 100} posted by $actionBy: $remarks',
      type: transactionType,
    );

    await logAudit(
      username: actionBy,
      action: 'RECORD_$transactionType',
      details: 'Recorded $transactionType: ${amountPaise / 100} INR ($remarks)',
    );
  }

  // NOTIFICATIONS
  Future<List<NotificationModel>> getNotifications({int? userId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'notifications',
        where: 'user_id IS NULL OR user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query('notifications', orderBy: 'id DESC');
    }
    return maps.map((m) => NotificationModel.fromMap(m)).toList();
  }

  Future<void> createNotification({
    int? userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final db = await _dbHelper.database;
    final now = DateFormatter.toIso(DateTime.now());

    await db.insert('notifications', {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'created_at': now,
      'is_read': 0,
    });
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final db = await _dbHelper.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllNotificationsAsRead({int? userId}) async {
    final db = await _dbHelper.database;
    if (userId != null) {
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'user_id IS NULL OR user_id = ?',
        whereArgs: [userId],
      );
    } else {
      await db.update('notifications', {'is_read': 1});
    }
  }
}
