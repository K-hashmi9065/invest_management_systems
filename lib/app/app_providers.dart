import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_repository.dart';
import '../features/auth/domain/user_model.dart';
import '../features/members/domain/member_model.dart';
import '../features/contributions/domain/contribution_model.dart';
import '../features/contribution_requests/domain/contribution_request_model.dart';
import '../features/investments/domain/investment_model.dart';
import '../features/profit_loss/domain/profit_distribution_model.dart';
import '../features/withdrawals/domain/withdrawal_model.dart';
import '../features/ledger/domain/transaction_model.dart';
import '../features/audit_logs/domain/audit_log_model.dart';
import '../features/notifications/domain/notification_model.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  CurrentUserNotifier() : super(null);

  void setUser(UserModel user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier();
});

final isFirstTimeSetupProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.isFirstTimeSetupNeeded();
});

final groupSummaryProvider = FutureProvider<GroupFinancialSummary>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getGroupFinancialSummary();
});

final membersProvider = FutureProvider<List<MemberModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getMembers();
});

final contributionsProvider =
    FutureProvider<List<ContributionModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getContributions();
});

final contributionRequestsProvider =
    FutureProvider<List<ContributionRequestModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getContributionRequests();
});

final investmentsProvider = FutureProvider<List<InvestmentModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getInvestments();
});

final profitDistributionsProvider =
    FutureProvider<List<ProfitDistributionModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getProfitDistributions();
});

final withdrawalsProvider = FutureProvider<List<WithdrawalModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getWithdrawals();
});

final transactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getTransactions();
});

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getAuditLogs();
});

final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  return await repo.getUsers();
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.watch(appRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return await repo.getNotifications(userId: currentUser?.id);
});

void refreshAllFinancialProviders(dynamic ref) {
  ref.invalidate(groupSummaryProvider);
  ref.invalidate(membersProvider);
  ref.invalidate(contributionsProvider);
  ref.invalidate(contributionRequestsProvider);
  ref.invalidate(investmentsProvider);
  ref.invalidate(profitDistributionsProvider);
  ref.invalidate(withdrawalsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(auditLogsProvider);
  ref.invalidate(usersProvider);
  ref.invalidate(notificationsProvider);
}
