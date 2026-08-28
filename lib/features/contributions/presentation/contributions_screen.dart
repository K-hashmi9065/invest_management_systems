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
import 'widgets/collect_payment_dialog.dart';

class ContributionsScreen extends ConsumerWidget {
  const ContributionsScreen({super.key});

  void _onCollectPaymentPressed(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add members first.')),
      );
      return;
    }
    CollectPaymentDialog.show(context, members);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final contributionsAsync = ref.watch(contributionsProvider);

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
                'Master Contribution Log',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                AppButton(
                  text: 'Collect Payment',
                  icon: Icons.add,
                  onPressed: () => _onCollectPaymentPressed(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AsyncValueWidget(
              value: contributionsAsync,
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No approved contributions recorded yet.',
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
                          DataColumn(label: Text('MEMBER')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('PAYMENT MODE')),
                          DataColumn(label: Text('REFERENCE')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('APPROVED BY')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: items.map((c) {
                          return DataRow(
                            cells: [
                              DataCell(Text('#${c.id}')),
                              DataCell(
                                Text(
                                  c.memberName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    c.amountPaise,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.positive,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(Text(c.paymentMode)),
                              DataCell(
                                Text(c.referenceNo ?? '-'),
                              ),
                              DataCell(
                                Text(
                                  DateFormatter.formatDate(
                                    DateTime.parse(
                                      c.contributionDate,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(c.approvedBy ?? 'System'),
                              ),
                              DataCell(
                                StatusBadge(status: c.status),
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
