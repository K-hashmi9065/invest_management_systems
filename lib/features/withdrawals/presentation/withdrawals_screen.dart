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
import '../../../core/widgets/horizontal_scrollable_table.dart';
import '../../../core/widgets/status_badge.dart';

class WithdrawalsScreen extends ConsumerStatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  ConsumerState<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends ConsumerState<WithdrawalsScreen> {
  void _showRequestWithdrawalDialog(BuildContext context) {
    final user = ref.read(currentUserProvider);
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];

    final member =
        members.where((m) => m.id == user?.memberId).firstOrNull;

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account is not linked to a member profile. Please contact an administrator.',
          ),
        ),
      );
      return;
    }

    final maxWithdrawablePaise = member.availableBalancePaise;
    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: const Text(
          'Submit Withdrawal Request',
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance:',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(maxWithdrawablePaise),
                        style: const TextStyle(
                          color: AppColors.positive,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Requested Withdrawal Amount (₹)',
                  hint: 'e.g. 10000',
                  keyboardType: TextInputType.number,
                  controller: amountCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount required';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) return 'Invalid amount';
                    final requestedPaise = CurrencyFormatter.rupeesToPaise(
                      parsed,
                    );
                    if (requestedPaise > maxWithdrawablePaise) {
                      return 'Exceeds available balance (${CurrencyFormatter.formatPaise(maxWithdrawablePaise)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Reason / Remarks',
                  hint: 'Optional withdrawal reason',
                  controller: remarksCtrl,
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
                  final repo = ref.read(appRepositoryProvider);

                  await repo.submitWithdrawalRequest(
                    memberId: member.id,
                    amountPaise: paise,
                    remarks: remarksCtrl.text.isNotEmpty
                        ? remarksCtrl.text
                        : null,
                    actionBy: user?.username ?? 'Member',
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
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final withdrawalsAsync = ref.watch(withdrawalsProvider);

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
          AppSidebar(currentRoute: '/withdrawals', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Withdrawal Management',
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
                            if (!isAdmin)
                              AppButton(
                                text: 'Request Withdrawal',
                                icon: Icons.remove_circle_outline,
                                onPressed: () =>
                                    _showRequestWithdrawalDialog(context),
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
                                  : items
                                        .where(
                                          (w) => w.memberId == user.memberId,
                                        )
                                        .toList();

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
                                                      w.status ==
                                                          AppConstants
                                                              .statusPending
                                                  ? Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.check_circle,
                                                            color: AppColors
                                                                .positive,
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
                                                                    withdrawalId:
                                                                        w.id,
                                                                    approve:
                                                                        true,
                                                                    actionBy: user
                                                                        .username,
                                                                  );
                                                              refreshAllFinancialProviders(
                                                                ref,
                                                              );
                                                            } catch (e, st) {
                                                              final failure =
                                                                  FailureMapper.map(
                                                                    e,
                                                                    st,
                                                                  );
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      failure
                                                                          .userMessage,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.cancel,
                                                            color: AppColors
                                                                .danger,
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
                                                                    withdrawalId:
                                                                        w.id,
                                                                    approve:
                                                                        false,
                                                                    actionBy: user
                                                                        .username,
                                                                  );
                                                              refreshAllFinancialProviders(
                                                                ref,
                                                              );
                                                            } catch (e, st) {
                                                              final failure =
                                                                  FailureMapper.map(
                                                                    e,
                                                                    st,
                                                                  );
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      failure
                                                                          .userMessage,
                                                                    ),
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
                                                         color:
                                                             AppColors.textMuted,
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
