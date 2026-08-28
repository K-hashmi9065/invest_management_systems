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
import 'widgets/add_investment_dialog.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final investmentsAsync = ref.watch(investmentsProvider);

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
                'Active & Completed Deployments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                AppButton(
                  text: 'Add Investment',
                  icon: Icons.add,
                  onPressed: () => AddInvestmentDialog.show(context),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AsyncValueWidget(
              value: investmentsAsync,
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No group investments recorded yet.',
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
                          DataColumn(label: Text('NAME')),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(
                            label: Text('EXPECTED RETURN'),
                          ),
                          DataColumn(
                            label: Text('ACTUAL RETURN'),
                          ),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: items.map((inv) {
                          return DataRow(
                            cells: [
                              DataCell(Text('#${inv.id}')),
                              DataCell(
                                Text(
                                  inv.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text(inv.type)),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    inv.amountPaise,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    inv.expectedReturnPaise,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    inv.actualReturnPaise,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.positive,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormatter.formatDate(
                                    DateTime.parse(
                                      inv.investmentDate,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                StatusBadge(status: inv.status),
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
