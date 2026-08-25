import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_badge.dart';

final ledgerFilterProvider = StateProvider<String>((ref) => 'ALL');

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  void _showAddAdjustmentDialog(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];

    String selectedType = AppConstants.txAdjustment;
    int? selectedMemberId;
    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          title: const Text(
            'Record Manual Adjustment / Refund',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppConstants.txAdjustment,
                        child: Text(
                          'ADJUSTMENT (Internal Reversal / Correction)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'REFUND',
                        child: Text('REFUND (Payout Reversal to Member)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Associated Member (Optional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedMemberId,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Group Pool (General Ledger)'),
                      ),
                      ...members.map((m) {
                        return DropdownMenuItem<int?>(
                          value: m.id,
                          child: Text('${m.name} (#${m.id})'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedMemberId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Amount (₹)',
                    hint: 'e.g. 5000',
                    keyboardType: TextInputType.number,
                    controller: amountCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0){
                        return ('Invalid amount');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Audit Remarks / Reason',
                    hint: 'Enter detailed justification for audit record',
                    controller: remarksCtrl,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Remarks required for audit compliance'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final rupees = double.parse(amountCtrl.text);
                    final paise = CurrencyFormatter.rupeesToPaise(rupees);
                    final user = ref.read(currentUserProvider);

                    await ref
                        .read(appRepositoryProvider)
                        .recordAdjustmentOrRefund(
                          memberId: selectedMemberId,
                          transactionType: selectedType,
                          amountPaise: paise,
                          remarks: remarksCtrl.text.trim(),
                          actionBy: user?.username ?? 'Admin',
                        );

                    refreshAllFinancialProviders(ref);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e, st) {
                    final failure = FailureMapper.map(e, st);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(failure.userMessage)),
                      );
                    }
                  }
                }
              },
              child: const Text('Post Entry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final selectedFilter = ref.watch(ledgerFilterProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin =
        user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Row(
        children: [
          AppSidebar(currentRoute: '/ledger', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Financial Transaction Ledger',
                  userName: user.fullName,
                  userRole: user.role,
                  onLogout: () {
                    ref.read(currentUserProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                Expanded(
                  child: Padding(
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
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
                                        final isDebit =
                                            t.transactionType ==
                                                AppConstants.txWithdrawal ||
                                            t.transactionType ==
                                                AppConstants.txInvestment ||
                                            t.transactionType ==
                                                AppConstants.txLoss;

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
                                                '${isDebit ? "-" : "+"}${CurrencyFormatter.formatPaise(t.amountPaise)}',
                                                style: TextStyle(
                                                  color: isDebit
                                                      ? AppColors.danger
                                                      : AppColors.positive,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
