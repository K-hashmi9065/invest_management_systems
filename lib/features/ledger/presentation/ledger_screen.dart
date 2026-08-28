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
import '../../../core/widgets/status_badge.dart';
import 'widgets/add_adjustment_dialog.dart';

final ledgerFilterProvider = StateProvider<String>((ref) => 'ALL');

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  void _showAddAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];
    AddAdjustmentDialog.show(context, members);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedFilter = ref.watch(ledgerFilterProvider);

    // Set page title for AppShell
    Future.microtask(() => ref.read(pageTitleProvider.notifier).state = 'Financial Transaction Ledger');

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
                'Audit-Compliant Master Ledger',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                AppButton(
                  text: 'Add Adjustment / Refund',
                  icon: Icons.tune,
                  onPressed: () =>
                      _showAddAdjustmentDialog(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 16),

                        // Filter Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                'ALL',
                                AppConstants.txContribution,
                                AppConstants.txInvestment,
                                AppConstants.txProfit,
                                AppConstants.txLoss,
                                AppConstants.txWithdrawal,
                                AppConstants.txAdjustment,
                                'REFUND',
                              ].map((filter) {
                                final isSelected = selectedFilter == filter;
                                return ChoiceChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.accent,
                                  backgroundColor: AppColors.surfaceCard,
                                  onSelected: (val) {
                                    if (val) {
                                      ref
                                              .read(
                                                ledgerFilterProvider.notifier,
                                              )
                                              .state =
                                          filter;
                                    }
                                  },
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AsyncValueWidget(
                            value: transactionsAsync,
                            data: (txs) {
                              final filtered = txs.where((t) {
                                if (selectedFilter == 'ALL') return true;
                                return t.transactionType == selectedFilter;
                              }).toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No transactions found for this filter.',
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
                                        DataColumn(label: Text('TX ID')),
                                        DataColumn(label: Text('TYPE')),
                                        DataColumn(
                                          label: Text('MEMBER / PARTY'),
                                        ),
                                        DataColumn(label: Text('AMOUNT')),
                                        DataColumn(label: Text('DATE')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('REMARKS')),
                                        DataColumn(label: Text('CREATED BY')),
                                      ],
                                      rows: filtered.map((t) {
                                        final String sign;
                                        final Color textColor;
                                        final int absAmount = t.amountPaise.abs();
                                        if (t.transactionType == AppConstants.txWithdrawal ||
                                            t.transactionType == AppConstants.txInvestment ||
                                            t.transactionType == AppConstants.txLoss ||
                                            t.transactionType == 'REFUND') {
                                          sign = '-';
                                          textColor = AppColors.danger;
                                        } else if (t.transactionType == AppConstants.txAdjustment) {
                                          final isNegative = t.amountPaise < 0;
                                          sign = isNegative ? '-' : '+';
                                          textColor = isNegative ? AppColors.danger : AppColors.positive;
                                        } else {
                                          sign = '+';
                                          textColor = AppColors.positive;
                                        }

                                        return DataRow(
                                          cells: [
                                            DataCell(Text('#${t.id}')),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.surfaceElevated,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  t.transactionType,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                t.memberName ?? 'Group Pool',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '$sign${CurrencyFormatter.formatPaise(absAmount)}',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                DateFormatter.formatDate(
                                                  DateTime.parse(t.date),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              StatusBadge(status: t.status),
                                            ),
                                            DataCell(Text(t.remarks ?? '-')),
                                            DataCell(Text(t.createdBy)),
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
