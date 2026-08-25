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

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  void _showAddInvestmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final periodCtrl = TextEditingController(text: '12');
    final returnCtrl = TextEditingController();
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
          'Create Group Investment Record',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Investment Name',
                  hint: 'e.g. Commercial Real Estate / Mutual Fund A',
                  controller: nameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Type',
                  hint: 'e.g. Real Estate, Stocks, FD, Startup',
                  controller: typeCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Amount (₹)',
                  hint: 'e.g. 500000',
                  keyboardType: TextInputType.number,
                  controller: amountCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount required';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Period (Months)',
                  hint: 'e.g. 12',
                  keyboardType: TextInputType.number,
                  controller: periodCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Expected Return Amount (₹)',
                  hint: 'e.g. 600000',
                  keyboardType: TextInputType.number,
                  controller: returnCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                  final user = ref.read(currentUserProvider);
                  final amountPaise = CurrencyFormatter.rupeesToPaise(
                    double.parse(amountCtrl.text),
                  );
                  final returnPaise = CurrencyFormatter.rupeesToPaise(
                    double.parse(returnCtrl.text),
                  );

                  final repo = ref.read(appRepositoryProvider);
                  await repo.createInvestment(
                    name: nameCtrl.text,
                    type: typeCtrl.text,
                    amountPaise: amountPaise,
                    periodMonths: int.parse(periodCtrl.text),
                    expectedReturnPaise: returnPaise,
                    actionBy: user?.username ?? 'Admin',
                    remarks: remarksCtrl.text.isNotEmpty
                        ? remarksCtrl.text
                        : null,
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
            child: const Text('Create Investment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final investmentsAsync = ref.watch(investmentsProvider);

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
          AppSidebar(currentRoute: '/investments', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Group Investments Portfolio',
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
                                onPressed: () =>
                                    _showAddInvestmentDialog(context),
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
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
