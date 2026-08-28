import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../ledger/domain/transaction_model.dart';

class MonthlyActivityChart extends ConsumerWidget {
  const MonthlyActivityChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return AsyncValueWidget<List<TransactionModel>>(
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
}
