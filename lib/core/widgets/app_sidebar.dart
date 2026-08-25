import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final String userRole;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = userRole == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || userRole == AppConstants.roleAdmin;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 900;

    return Container(
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F77DD),
                    borderRadius: BorderRadius.circular(8),
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
                      letterSpacing: 1,
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
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.people_outline,
                  title: 'Members',
                  route: '/members',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.payments_outlined,
                  title: 'Contributions',
                  route: '/contributions',
                  isCompact: isCompact,
                ),
                if (!isAdmin)
                  _buildNavItem(
                    context: context,
                    icon: Icons.add_circle_outline,
                    title: 'Add Money Request',
                    route: '/contribution-requests',
                    isCompact: isCompact,
                  ),
                if (isAdmin)
                  _buildNavItem(
                    context: context,
                    icon: Icons.fact_check_outlined,
                    title: 'Pending Requests',
                    route: '/contribution-requests',
                    isCompact: isCompact,
                  ),
                _buildNavItem(
                  context: context,
                  icon: Icons.trending_up,
                  title: 'Investments',
                  route: '/investments',
                  isCompact: isCompact,
                ),

                if (!isCompact) _buildSectionHeader('FINANCE'),
                _buildNavItem(
                  context: context,
                  icon: Icons.pie_chart_outline,
                  title: 'Profit / Loss',
                  route: '/profit-loss',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.account_balance_outlined,
                  title: 'Withdrawals',
                  route: '/withdrawals',
                  isCompact: isCompact,
                ),
                _buildNavItem(
                  context: context,
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
                      icon: Icons.security_outlined,
                      title: 'Audit Logs',
                      route: '/audit-logs',
                      isCompact: isCompact,
                    ),
                  _buildNavItem(
                    context: context,
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
    required IconData icon,
    required String title,
    required String route,
    required bool isCompact,
  }) {
    final isActive = currentRoute == route;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: 2,
      ),
      child: Tooltip(
        message: isCompact ? title : '',
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go(route),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1C2128) : Colors.transparent,
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
    );
  }
}
