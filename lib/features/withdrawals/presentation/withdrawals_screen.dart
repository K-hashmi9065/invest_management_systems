import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';
import '../../../core/widgets/status_badge.dart';
import 'widgets/request_withdrawal_dialog.dart';

class WithdrawalsScreen extends ConsumerWidget {
  const WithdrawalsScreen({super.key});

  void _onRequestWithdrawalPressed(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];

    if (user == null || members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members available for withdrawal.')),
      );
      return;
    }
    RequestWithdrawalDialog.show(context, user, members);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final withdrawalsAsync = ref.watch(withdrawalsProvider);

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
              Text(
                isAdmin
                    ? 'Withdrawal Approval Requests'
                    : 'My Withdrawal History',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppButton(
                text: 'Request Withdrawal',
                icon: Icons.remove_circle_outline,
                onPressed: () => _onRequestWithdrawalPressed(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AsyncValueWidget(
              value: withdrawalsAsync,
              data: (items) {
                final filtered = isAdmin
                    ? items
                    : items.where((w) => w.memberId == user.memberId).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No withdrawal requests found.',
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
                          DataColumn(label: Text('REQUESTED AT')),
                          DataColumn(label: Text('APPROVED BY')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTION')),
                        ],
                        rows: filtered.map((w) {
                          return DataRow(
                            cells: [
                              DataCell(Text('#${w.id}')),
                              DataCell(
                                Text(
                                  w.memberName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    w.amountPaise,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormatter.formatDate(
                                    DateTime.parse(w.requestedAt),
                                  ),
                                ),
                              ),
                              DataCell(Text(w.approvedBy ?? '-')),
                              DataCell(
                                StatusBadge(status: w.status),
                              ),
                              DataCell(
                                isAdmin &&
                                        w.status == AppConstants.statusPending
                                    ? Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: AppColors.positive,
                                              size: 20,
                                            ),
                                            tooltip: 'Approve',
                                            onPressed: () async {
                                              try {
                                                final repo = ref.read(
                                                  appRepositoryProvider,
                                                );
                                                await repo
                                                    .reviewWithdrawalRequest(
                                                  withdrawalId: w.id,
                                                  approve: true,
                                                  actionBy: user.username,
                                                );
                                                refreshAllFinancialProviders(
                                                  ref,
                                                );
                                              } catch (e, st) {
                                                final failure =
                                                    FailureMapper.map(e, st);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        failure.userMessage,
                                                      ),
                                                      backgroundColor:
                                                          AppColors.danger,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            tooltip: 'Reject',
                                            onPressed: () async {
                                              try {
                                                final repo = ref.read(
                                                  appRepositoryProvider,
                                                );
                                                await repo
                                                    .reviewWithdrawalRequest(
                                                  withdrawalId: w.id,
                                                  approve: false,
                                                  actionBy: user.username,
                                                );
                                                refreshAllFinancialProviders(
                                                  ref,
                                                );
                                              } catch (e, st) {
                                                final failure =
                                                    FailureMapper.map(e, st);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        failure.userMessage,
                                                      ),
                                                      backgroundColor:
                                                          AppColors.danger,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        '-',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
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
