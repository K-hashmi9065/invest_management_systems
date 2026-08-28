import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/database/app_repository.dart';
import '../../../members/domain/member_model.dart';

class AdminStatCardsGrid extends StatelessWidget {
  final GroupFinancialSummary summary;
  final List<MemberModel> members;

  const AdminStatCardsGrid({
    super.key,
    required this.summary,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
  }
}
