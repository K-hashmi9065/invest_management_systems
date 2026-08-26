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

class ContributionsScreen extends ConsumerStatefulWidget {
  const ContributionsScreen({super.key});

  @override
  ConsumerState<ContributionsScreen> createState() =>
      _ContributionsScreenState();
}

class _ContributionsScreenState extends ConsumerState<ContributionsScreen> {
  void _showCollectPaymentDialog(BuildContext context) {
    final membersAsync = ref.read(membersProvider);
    final members = membersAsync.value ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add members first.')),
      );
      return;
    }

    int selectedMemberId = members.first.id;
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
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
            'Record Payment Collection (Admin)',
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
                    'Select Member',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMemberId,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: members.map((m) {
                      return DropdownMenuItem<int>(
                        value: m.id,
                        child: Text('${m.name} (#${m.id})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedMemberId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Contribution Amount (₹)',
                    hint: 'e.g. 50000',
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
                    'Payment Mode',
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
                    label: 'Reference / UTR Number',
                    hint: 'e.g. UTR12345678',
                    controller: refCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Remarks / Notes',
                    hint: 'Optional notes',
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
                    final currentUser = ref.read(currentUserProvider);

                    final repo = ref.read(appRepositoryProvider);
                    await repo.recordContribution(
                      memberId: selectedMemberId,
                      amountPaise: paise,
                      paymentMode: paymentMode,
                      referenceNo: refCtrl.text.isNotEmpty
                          ? refCtrl.text
                          : null,
                      remarks: remarksCtrl.text.isNotEmpty
                          ? remarksCtrl.text
                          : null,
                      actionBy: currentUser?.username ?? 'Admin',
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
              child: const Text('Record Contribution'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final contributionsAsync = ref.watch(contributionsProvider);

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
          AppSidebar(currentRoute: '/contributions', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Approved Contributions',
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
                                onPressed: () =>
                                    _showCollectPaymentDialog(context),
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
