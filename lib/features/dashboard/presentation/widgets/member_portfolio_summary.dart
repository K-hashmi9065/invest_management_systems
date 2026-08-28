import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/database/app_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../../../members/domain/member_model.dart';

class MemberPortfolioSummaryWidget extends StatelessWidget {
  final UserModel user;
  final GroupFinancialSummary summary;
  final List<MemberModel> members;

  const MemberPortfolioSummaryWidget({
    super.key,
    required this.user,
    required this.summary,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final MemberModel? member =
        members.where((m) => m.id == user.memberId).firstOrNull;

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
}
