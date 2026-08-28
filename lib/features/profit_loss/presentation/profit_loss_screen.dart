import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';
import 'widgets/distribute_loss_dialog.dart';
import 'widgets/distribute_profit_dialog.dart';

class ProfitLossScreen extends ConsumerWidget {
  const ProfitLossScreen({super.key});

  void _onDistributeProfitPressed(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.read(investmentsProvider);
    final investments = investmentsAsync.value ?? [];
    if (investments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No investments available for profit distribution.'),
        ),
      );
      return;
    }
    DistributeProfitDialog.show(context, investments);
  }

  void _onDistributeLossPressed(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.read(investmentsProvider);
    final investments = investmentsAsync.value ?? [];
    if (investments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No investments available for loss distribution.'),
        ),
      );
      return;
    }
    DistributeLossDialog.show(context, investments);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final distributionsAsync = ref.watch(profitDistributionsProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin =
        user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Historical Profit & Loss Allocations',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      text: 'Distribute Loss',
                      icon: Icons.trending_down,
                      isSecondary: true,
                      onPressed: () => _onDistributeLossPressed(context, ref),
                    ),
                    AppButton(
                      text: 'Distribute Profit',
                      icon: Icons.trending_up,
                      onPressed: () => _onDistributeProfitPressed(context, ref),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AsyncValueWidget(
              value: distributionsAsync,
              data: (items) {
                final filtered = isAdmin
                    ? items
                    : items.where((d) => d.memberId == user.memberId).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No profit/loss distributions recorded yet.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: HorizontalScrollableTable(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('INVESTMENT')),
                          DataColumn(label: Text('MEMBER')),
                          DataColumn(
                            label: Text('MEMBER SHARE %'),
                          ),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(
                            label: Text('ALLOCATED AMOUNT'),
                          ),
                          DataColumn(
                            label: Text('DISTRIBUTED DATE'),
                          ),
                        ],
                        rows: filtered.map((d) {
                          final isLoss = d.profitAmountPaise < 0;
                          final absAmount =
                              isLoss ? -d.profitAmountPaise : d.profitAmountPaise;
                          return DataRow(
                            cells: [
                              DataCell(Text('#${d.id}')),
                              DataCell(
                                Text(
                                  d.investmentName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text(d.memberName)),
                              DataCell(
                                Text(
                                  '${d.memberPercentage.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLoss
                                        ? AppColors.danger.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppColors.positive.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLoss ? 'LOSS' : 'PROFIT',
                                    style: TextStyle(
                                      color: isLoss
                                          ? AppColors.danger
                                          : AppColors.positive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${isLoss ? "-" : "+"} ${CurrencyFormatter.formatPaise(absAmount)}',
                                  style: TextStyle(
                                    color: isLoss
                                        ? AppColors.danger
                                        : AppColors.positive,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormatter.formatDate(
                                    DateTime.parse(
                                      d.distributedAt,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
