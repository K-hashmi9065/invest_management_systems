import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/database/app_repository.dart';

class FundAllocationChart extends StatelessWidget {
  final GroupFinancialSummary summary;

  const FundAllocationChart({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                        ? summary.totalApprovedWithdrawalsPaise.toDouble()
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
  }
}
