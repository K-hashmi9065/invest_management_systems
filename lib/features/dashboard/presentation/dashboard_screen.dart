import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_widget.dart';
import 'widgets/dashboard_stat_cards.dart';
import 'widgets/fund_allocation_chart.dart';
import 'widgets/member_leaderboard_table.dart';
import 'widgets/member_portfolio_summary.dart';
import 'widgets/member_share_chart.dart';
import 'widgets/monthly_activity_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(groupSummaryProvider);
    final membersAsync = ref.watch(membersProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSuperAdmin = user.role == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || user.role == AppConstants.roleAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AsyncValueWidget(
        value: summaryAsync,
        data: (summary) {
          return AsyncValueWidget(
            value: membersAsync,
            data: (members) {
              if (!isAdmin) {
                return MemberPortfolioSummaryWidget(
                  user: user,
                  summary: summary,
                  members: members,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Financial Performance',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminStatCardsGrid(summary: summary, members: members),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;

                      final fundAllocationCard =
                          FundAllocationChart(summary: summary);
                      final memberShareCard =
                          MemberShareChart(members: members);
                      final leaderboardCard =
                          MemberLeaderboardTable(members: members);

                      if (isNarrow) {
                        return Column(
                          children: [
                            fundAllocationCard,
                            const SizedBox(height: 16),
                            memberShareCard,
                            const SizedBox(height: 16),
                            const MonthlyActivityChart(),
                            const SizedBox(height: 16),
                            leaderboardCard,
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: fundAllocationCard),
                              const SizedBox(width: 16),
                              Expanded(child: memberShareCard),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                flex: 3,
                                child: MonthlyActivityChart(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: leaderboardCard,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
