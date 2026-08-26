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
import '../../../core/widgets/horizontal_scrollable_table.dart';

class ContributionRequestsScreen extends ConsumerStatefulWidget {
  const ContributionRequestsScreen({super.key});

  @override
  ConsumerState<ContributionRequestsScreen> createState() =>
      _ContributionRequestsScreenState();
}

class _ContributionRequestsScreenState
    extends ConsumerState<ContributionRequestsScreen> {
  void _showRaiseRequestDialog(BuildContext context) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account is not linked to a member profile. Cannot raise request.',
          ),
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String paymentMode = 'Bank Transfer';
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
            'Raise Add Money Request',
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
                  AppTextField(
                    label: 'Requested Amount (₹)',
                    hint: 'e.g. 25000',
                    keyboardType: TextInputType.number,
                    controller: amountCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0){
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Intended Payment Mode',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMode,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: ['Bank Transfer', 'UPI', 'Cash', 'Cheque']
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => paymentMode = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Remarks / Notes',
                    hint: 'Optional notes for admin',
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

                    await repo.submitContributionRequest(
                      memberId: user.memberId!,
                      amountPaise: paise,
                      paymentMode: paymentMode,
                      remarks: remarksCtrl.text.isNotEmpty
                          ? remarksCtrl.text
                          : null,
                      actionBy: user.username,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(contributionRequestsProvider);

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
          AppSidebar(
            currentRoute: '/contribution-requests',
            userRole: user.role,
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: isAdmin
                      ? 'Review Contribution Requests'
                      : 'My Money Requests',
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
                                  ? 'Member Contribution Approval Queue'
                                  : 'Submitted Add Money Requests',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isAdmin)
                              AppButton(
                                text: 'Raise Request',
                                icon: Icons.add,
                                onPressed: () =>
                                    _showRaiseRequestDialog(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AsyncValueWidget(
                            value: requestsAsync,
                            data: (requests) {
                              final filtered = isAdmin
                                  ? requests
                                  : requests
                                        .where(
                                          (r) => r.memberId == user.memberId,
                                        )
                                        .toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No contribution requests pending.',
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
                                        DataColumn(label: Text('REQ ID')),
                                        DataColumn(label: Text('MEMBER')),
                                        DataColumn(label: Text('AMOUNT')),
                                        DataColumn(label: Text('MODE')),
                                        DataColumn(label: Text('REQUESTED AT')),
                                        DataColumn(label: Text('APPROVED BY')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('ACTION')),
                                      ],
                                      rows: filtered.map((req) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text('#${req.id}')),
                                            DataCell(
                                              Text(
                                                req.memberName,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                CurrencyFormatter.formatPaise(
                                                  req.amountPaise,
                                                ),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(req.paymentMode)),
                                            DataCell(
                                              Text(
                                                DateFormatter.formatDate(
                                                  DateTime.parse(
                                                    req.requestedAt,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(req.reviewedBy ?? '-')),
                                            DataCell(
                                              StatusBadge(status: req.status),
                                            ),
                                            DataCell(
                                              isAdmin &&
                                                      req.status ==
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
                                                                  .reviewContributionRequest(
                                                                    requestId:
                                                                        req.id,
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
                                                                  .reviewContributionRequest(
                                                                    requestId:
                                                                        req.id,
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
