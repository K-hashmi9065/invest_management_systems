import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/app_providers.dart';
import '../core/constants/route_names.dart';
import '../core/security/app_permissions.dart';
import '../core/security/device_lock_service.dart';
import '../features/auth/presentation/device_unauthorized_screen.dart';
import '../features/auth/presentation/first_time_setup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/contributions/presentation/contributions_screen.dart';
import '../features/contribution_requests/presentation/contribution_requests_screen.dart';
import '../features/investments/presentation/investments_screen.dart';
import '../features/profit_loss/presentation/profit_loss_screen.dart';
import '../features/withdrawals/presentation/withdrawals_screen.dart';
import '../features/ledger/presentation/ledger_screen.dart';
import '../features/audit_logs/presentation/audit_logs_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(currentUserProvider, (previous, next) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

Future<String?> appRedirect({
  required ProviderReader read,
  required BuildContext context,
  required GoRouterState state,
}) async {
  // 1. Device Lock Check
  if (!DeviceLockService.isAuthorized()) {
    if (state.matchedLocation != RoutePaths.deviceUnauthorized) {
      return RoutePaths.deviceUnauthorized;
    }
    return null;
  }

  // 2. First-Time Setup Check
  final repo = read(appRepositoryProvider);
  final isSetupNeeded = await repo.isFirstTimeSetupNeeded();
  if (isSetupNeeded && state.matchedLocation != RoutePaths.setup) {
    return RoutePaths.setup;
  }

  // 3. Authentication Check
  final currentUser = read(currentUserProvider);
  final isLoggingIn = state.matchedLocation == RoutePaths.login;
  final isSettingUp = state.matchedLocation == RoutePaths.setup;
  final isUnauthorized = state.matchedLocation == RoutePaths.deviceUnauthorized;

  if (currentUser == null && !isLoggingIn && !isSettingUp && !isUnauthorized) {
    return RoutePaths.login;
  }

  if (currentUser != null && (isLoggingIn || isSettingUp)) {
    return RoutePaths.dashboard;
  }

  // 4. Route-Level RBAC Authorization Check
  if (currentUser != null && !isLoggingIn && !isSettingUp && !isUnauthorized) {
    final isAuthorizedForRoute = AuthorizationService.canAccessRoute(
      state.matchedLocation,
      currentUser,
    );

    if (!isAuthorizedForRoute) {
      // Redirect unauthorized access attempts safely to dashboard
      return RoutePaths.dashboard;
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: notifier,
    redirect: (context, state) =>
        appRedirect(read: ref.read, context: context, state: state),
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.setup,
        name: RouteNames.setup,
        builder: (context, state) => const FirstTimeSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.deviceUnauthorized,
        name: RouteNames.deviceUnauthorized,
        builder: (context, state) => const DeviceUnauthorizedScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.members,
        name: RouteNames.members,
        builder: (context, state) => const MembersScreen(),
      ),
      GoRoute(
        path: RoutePaths.contributions,
        name: RouteNames.contributions,
        builder: (context, state) => const ContributionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.contributionRequests,
        name: RouteNames.contributionRequests,
        builder: (context, state) => const ContributionRequestsScreen(),
      ),
      GoRoute(
        path: RoutePaths.investments,
        name: RouteNames.investments,
        builder: (context, state) => const InvestmentsScreen(),
      ),
      GoRoute(
        path: RoutePaths.profitLoss,
        name: RouteNames.profitLoss,
        builder: (context, state) => const ProfitLossScreen(),
      ),
      GoRoute(
        path: RoutePaths.withdrawals,
        name: RouteNames.withdrawals,
        builder: (context, state) => const WithdrawalsScreen(),
      ),
      GoRoute(
        path: RoutePaths.ledger,
        name: RouteNames.ledger,
        builder: (context, state) => const LedgerScreen(),
      ),
      GoRoute(
        path: RoutePaths.auditLogs,
        name: RouteNames.auditLogs,
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
