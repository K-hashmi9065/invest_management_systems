import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_providers.dart';
import '../theme/app_colors.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

/// Persistent shell layout with sidebar + top bar.
/// The [child] is swapped by GoRouter's ShellRoute on navigation,
/// so the sidebar and top bar are never rebuilt — eliminating the blink.
class AppShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({
    super.key,
    required this.child,
    required this.state,
  });

  String _getRouteTitle(String path) {
    switch (path) {
      case '/dashboard':
        return 'Dashboard Overview';
      case '/members':
        return 'Member Directory';
      case '/contributions':
        return 'Member Contributions';
      case '/contribution-requests':
        return 'Contribution Requests';
      case '/investments':
        return 'Group Investments Portfolio';
      case '/profit-loss':
        return 'Profit & Loss Distribution';
      case '/withdrawals':
        return 'Withdrawal Requests';
      case '/ledger':
        return 'Financial Ledger';
      case '/audit-logs':
        return 'System Audit Logs';
      case '/settings':
        return 'System & Profile Settings';
      default:
        return 'Investment System';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dynamicTitle = ref.watch(pageTitleProvider);
    final routeTitle = _getRouteTitle(state.matchedLocation);
    final title = routeTitle.isNotEmpty && routeTitle != 'Investment System'
        ? routeTitle
        : dynamicTitle;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Row(
        children: [
          AppSidebar(
            currentRoute: state.matchedLocation,
            userRole: user.role,
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: title,
                  userName: user.fullName,
                  userRole: user.role,
                  onLogout: () {
                    ref.read(currentUserProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
