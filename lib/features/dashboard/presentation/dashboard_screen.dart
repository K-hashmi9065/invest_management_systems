import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/stat_card.dart';

import '../../auth/domain/user_model.dart';
import '../../ledger/domain/transaction_model.dart';
import '../../members/domain/member_model.dart';
import '../../../core/database/app_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(groupSummaryProvider);
    final membersAsync = ref.watch(membersProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isSuperAdmin = user.role == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || user.role == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Row(
        children: [
          AppSidebar(currentRoute: '/dashboard', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Dashboard Overview',
                  userName: user.fullName,
                  userRole: user.role,
                  onLogout: () {
                    ref.read(currentUserProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AsyncValueWidget(
                      value: summaryAsync,
                      data: (summary) {
                        return AsyncValueWidget(
                          value: membersAsync,
                          data: (members) {
                            if (!isAdmin) {
                              return _buildMemberDashboard(
                                context,
                                user,
                                summary,
                                members,
                              );
                            }
                            return _buildAdminDashboard(
                              context,
                              user,
                              summary,
                              members,
                              transactionsAsync,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDashboard(
    BuildContext context,
    UserModel user,
    GroupFinancialSummary summary,
    List<MemberModel> members,
  ) {
    final MemberModel? member = members
        .where((m) => m.id == user.memberId)
        .firstOrNull;

    if (member == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Portfolio Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No Linked Member Profile',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your user account is not linked to any member profile in the system. Please ask an Administrator or Super Admin to link this account in settings.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final myContribPaise = member.totalContributionPaise;
    final myPct = member.contributionPercentage;
    final mySharePaise = member.investmentSharePaise;
    final myProfitPaise = member.allocatedProfitPaise;
    final myAvailablePaise = member.availableBalancePaise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Portfolio Summary',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100
                ? 3
                : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  title: 'My Approved Contribution',
                  value: CurrencyFormatter.formatPaise(myContribPaise),
                  subtitle: 'Total principal invested in pool',
                  icon: Icons.payments,
                  iconColor: AppColors.accent,
                ),
                StatCard(
                  title: 'My Contribution Share',
                  value: '${myPct.toStringAsFixed(2)}%',
                  subtitle: 'Pro-rata share of group total',
                  icon: Icons.pie_chart,
                  iconColor: AppColors.info,
                ),
                StatCard(
                  title: 'My Investment Share',
                  value: CurrencyFormatter.formatPaise(mySharePaise),
                  subtitle: 'Value allocated in active investments',
                  icon: Icons.trending_up,
                  iconColor: AppColors.positive,
                ),
                StatCard(
                  title: 'My Allocated Profit',
                  value: CurrencyFormatter.formatPaise(myProfitPaise),
                  subtitle: 'Realized profit distributed to date',
                  icon: Icons.attach_money,
                  iconColor: AppColors.positive,
                ),
                StatCard(
                  title: 'My Withdrawable Balance',
                  value: CurrencyFormatter.formatPaise(myAvailablePaise),
                  subtitle: 'Available for withdrawal request',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.warning,
                ),
                StatCard(
                  title: 'Total Group Pool',
                  value: CurrencyFormatter.formatPaise(
                      summary.totalApprovedContributionsPaise),
                  subtitle: 'Combined pool across all members',
                  icon: Icons.groups,
                  iconColor: AppColors.textMuted,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberContributionChart(List<MemberModel> members) {
    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.positive,
      AppColors.warning,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.orangeAccent,
    ];

    final hasMembers = members.any((m) => m.contributionPercentage > 0);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member Contribution Share %',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: hasMembers
                    ? members.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        final color = colors[i % colors.length];
                        return PieChartSectionData(
                          color: color,
                          value: m.contributionPercentage > 0
                              ? m.contributionPercentage
                              : 0.1,
                          title: '${m.name.split(' ').first}\n${m.contributionPercentage.toStringAsFixed(1)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList()
                    : [
                        PieChartSectionData(
                          color: AppColors.border,
                          value: 100,
                          title: 'Empty',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyActivityBarChart(
      AsyncValue<List<TransactionModel>> transactionsAsync) {
    return AsyncValueWidget(
      value: transactionsAsync,
      data: (transactions) {
        final now = DateTime.now();
        final List<String> monthLabels = [];
        final List<double> monthlyContribs = [];
        final List<double> monthlyWithdraws = [];

        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        for (int i = 5; i >= 0; i--) {
          final dt = DateTime(now.year, now.month - i, 1);
          final label = "${monthNames[dt.month - 1]} '${dt.year.toString().substring(2)}";
          monthLabels.add(label);

          double contrib = 0;
          double withdraw = 0;

          for (final tx in transactions) {
            if (tx.status != AppConstants.statusApproved) continue;
            try {
              final txDt = DateTime.parse(tx.date);
              if (txDt.year == dt.year && txDt.month == dt.month) {
                if (tx.transactionType == AppConstants.txContribution) {
                  contrib += tx.amountPaise / 100.0;
                } else if (tx.transactionType == AppConstants.txWithdrawal) {
                  withdraw += tx.amountPaise / 100.0;
                }
              }
            } catch (_) {}
          }

          monthlyContribs.add(contrib);
          monthlyWithdraws.add(withdraw);
        }

        double maxVal = 1000;
        for (var c in monthlyContribs) {
          if (c > maxVal) maxVal = c;
        }
        for (var w in monthlyWithdraws) {
          if (w > maxVal) maxVal = w;
        }

        return AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Contributions vs Withdrawals',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.positive,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Contributions',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Withdrawals',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.15,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (val, meta) {
                            if (val == 0) return const SizedBox.shrink();
                            return Text(
                              CurrencyFormatter.formatPaise((val * 100).toInt()),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 9),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (index, meta) {
                            final i = index.toInt();
                            if (i >= 0 && i < monthLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  monthLabels[i],
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(6, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthlyContribs[i],
                            color: AppColors.positive,
                            width: 12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: monthlyWithdraws[i],
                            color: AppColors.danger,
                            width: 12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminDashboard(
    BuildContext context,
    UserModel user,
    GroupFinancialSummary summary,
    List<MemberModel> members,
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
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
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1100
                ? 4
                : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 4 ? 2.0 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  title: 'Total Approved Pool',
                  value: CurrencyFormatter.formatPaise(
                      summary.totalApprovedContributionsPaise),
                  subtitle: '${members.length} Active Members',
                  icon: Icons.account_balance,
                  iconColor: AppColors.accent,
                ),
                StatCard(
                  title: 'Total Invested Fund',
                  value: CurrencyFormatter.formatPaise(summary.totalInvestedPaise),
                  subtitle: 'Active portfolio deployments',
                  icon: Icons.show_chart,
                  iconColor: AppColors.info,
                ),
                StatCard(
                  title: 'Total Profit Distributed',
                  value: CurrencyFormatter.formatPaise(
                      summary.totalDistributedProfitPaise),
                  subtitle: 'Distributed pro-rata',
                  icon: Icons.savings,
                  iconColor: AppColors.positive,
                ),
                StatCard(
                  title: 'Available Group Fund',
                  value: CurrencyFormatter.formatPaise(summary.availableBalancePaise),
                  subtitle: 'Uninvested cash balance',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.warning,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Visual Charts & Analytics Section
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final fundAllocationCard = AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fund Allocation Breakdown',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.info,
                            value: summary.totalInvestedPaise > 0
                                ? summary.totalInvestedPaise.toDouble()
                                : 1,
                            title: 'Invested',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.positive,
                            value: summary.availableBalancePaise > 0
                                ? summary.availableBalancePaise.toDouble()
                                : 1,
                            title: 'Available',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.danger,
                            value: summary.totalApprovedWithdrawalsPaise > 0
                                ? summary.totalApprovedWithdrawalsPaise
                                    .toDouble()
                                : 0,
                            title: 'Withdrawn',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            final memberShareCard = _buildMemberContributionChart(members);
            final leaderboardCard = AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Member Contribution Breakdown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/members'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1.2),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text('Member Name',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                          Text('Contribution',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                          Text('Share %',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      ...members.take(5).map((m) {
                        return TableRow(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                CurrencyFormatter.formatPaise(
                                    m.totalContributionPaise),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '${m.contributionPercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  fundAllocationCard,
                  const SizedBox(height: 16),
                  memberShareCard,
                  const SizedBox(height: 16),
                  _buildMonthlyActivityBarChart(transactionsAsync),
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
                    Expanded(flex: 3, child: _buildMonthlyActivityBarChart(transactionsAsync)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: leaderboardCard),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
