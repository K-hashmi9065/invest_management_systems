import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

final sidebarHoveredRouteProvider = StateProvider<String?>((ref) => null);

class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  final String userRole;
  final StatefulNavigationShell? navigationShell;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.userRole,
    this.navigationShell,
  });

  int _indexForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return 0;
      case '/members':
        return 1;
      case '/contributions':
        return 2;
      case '/contribution-requests':
        return 3;
      case '/investments':
        return 4;
      case '/profit-loss':
        return 5;
      case '/withdrawals':
        return 6;
      case '/ledger':
        return 7;
      case '/audit-logs':
        return 8;
      case '/settings':
        return 9;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = userRole == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || userRole == AppConstants.roleAdmin;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCompact ? 68 : 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1219),
        border: Border(right: BorderSide(color: Color(0xFF232833), width: 0.5)),
      ),
      child: Column(
        children: [
          // Logo & Header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
            alignment: isCompact ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7F77DD), Color(0xFF635BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7F77DD).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'INVEST PRO',
                    style: TextStyle(
                      color: Color(0xFFF3F4F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF232833)),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (!isCompact) _buildSectionHeader('MAIN'),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.people_outline,
                  title: 'Members',
                  route: '/members',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.payments_outlined,
                  title: 'Contributions',
                  route: '/contributions',
                  isCompact: isCompact,
                ),
                if (!isAdmin)
                  _buildNavItem(
                    context: context,
                    ref: ref,
                    icon: Icons.add_circle_outline,
                    title: 'Add Money Request',
                    route: '/contribution-requests',
                    isCompact: isCompact,
                  ),
                if (isAdmin)
                  _buildNavItem(
                    context: context,
                    ref: ref,
                    icon: Icons.fact_check_outlined,
                    title: 'Pending Requests',
                    route: '/contribution-requests',
                    isCompact: isCompact,
                  ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.trending_up,
                  title: 'Investments',
                  route: '/investments',
                  isCompact: isCompact,
                ),

                if (!isCompact) _buildSectionHeader('FINANCE'),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.pie_chart_outline,
                  title: 'Profit / Loss',
                  route: '/profit-loss',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.account_balance_outlined,
                  title: 'Withdrawals',
                  route: '/withdrawals',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  ref: ref,
                  icon: Icons.receipt_long_outlined,
                  title: 'Financial Ledger',
                  route: '/ledger',
                  isCompact: isCompact,
                ),

                if (isAdmin) ...[
                  if (!isCompact) _buildSectionHeader('SYSTEM'),
                  if (isSuperAdmin)
                    _buildNavItem(
                      context: context,
                      ref: ref,
                      icon: Icons.security_outlined,
                      title: 'Audit Logs',
                      route: '/audit-logs',
                      isCompact: isCompact,
                    ),
                  _buildNavItem(
                    context: context,
                    ref: ref,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    route: '/settings',
                    isCompact: isCompact,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String route,
    required bool isCompact,
  }) {
    final targetIndex = _indexForRoute(route);
    final isActive = navigationShell != null
        ? navigationShell!.currentIndex == targetIndex
        : currentRoute == route;
    final hoveredRoute = ref.watch(sidebarHoveredRouteProvider);
    final isHovered = hoveredRoute == route;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 2,
      ),
      child: Tooltip(
        message: isCompact ? title : '',
        waitDuration: const Duration(milliseconds: 300),
        child: MouseRegion(
          onEnter: (_) =>
              ref.read(sidebarHoveredRouteProvider.notifier).state = route,
          onExit: (_) =>
              ref.read(sidebarHoveredRouteProvider.notifier).state = null,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (navigationShell != null) {
                  navigationShell!.goBranch(
                    targetIndex,
                    initialLocation:
                        targetIndex == navigationShell!.currentIndex,
                  );
                } else {
                  context.go(route);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1C2128)
                      : isHovered
                          ? const Color(0xFF161B22)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? Border.all(color: const Color(0xFF7F77DD), width: 0.5)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: isCompact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isActive
                          ? const Color(0xFF7F77DD)
                          : isHovered
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF9CA3AF),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFF3F4F6)
                                : isHovered
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFF9CA3AF),
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


