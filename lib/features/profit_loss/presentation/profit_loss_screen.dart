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

class ProfitLossScreen extends ConsumerStatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  void _showDistributeProfitDialog(BuildContext context) {
    final investmentsAsync = ref.read(investmentsProvider);
    final investments = investmentsAsync.value ?? [];
    if (investments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No investments available for profit distribution.')),
      );
      return;
    }

    int selectedInvestmentId = investments.first.id;
    final profitCtrl = TextEditingController();
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
            'Distribute Investment Profit (Pro-Rata)',
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
                    'Select Investment',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedInvestmentId,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: investments.map((inv) {
                      return DropdownMenuItem<int>(
                        value: inv.id,
                        child: Text('${inv.name} (#${inv.id})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedInvestmentId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Total Realized Profit (₹)',
                    hint: 'e.g. 100000',
                    keyboardType: TextInputType.number,
                    controller: profitCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Profit required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Note: Profit will be split automatically among members based on their exact contribution percentage.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
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
                    final rupees = double.parse(profitCtrl.text);
                    final paise = CurrencyFormatter.rupeesToPaise(rupees);
                    final user = ref.read(currentUserProvider);

                    final repo = ref.read(appRepositoryProvider);
                    await repo.distributeProfit(
                      investmentId: selectedInvestmentId,
                      totalProfitPaise: paise,
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
              child: const Text('Distribute Profit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistributeLossDialog(BuildContext context) {
    final investmentsAsync = ref.read(investmentsProvider);
    final investments = investmentsAsync.value ?? [];
    if (investments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No investments available for loss distribution.')),
      );
      return;
    }

    int selectedInvestmentId = investments.first.id;
    final lossCtrl = TextEditingController();
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
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
              SizedBox(width: 8),
              Text(
                'Distribute Investment Loss (Pro-Rata)',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
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
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: Distributing loss will deduct funds pro-rata from member balances based on their active contribution percentages.',
                            style: TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Investment',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedInvestmentId,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: investments.map((inv) {
                      return DropdownMenuItem<int>(
                        value: inv.id,
                        child: Text('${inv.name} (#${inv.id})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedInvestmentId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Total Realized Loss (₹)',
                    hint: 'e.g. 50000',
                    keyboardType: TextInputType.number,
                    controller: lossCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Loss amount required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Invalid amount';
                      return null;
                    },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final rupees = double.parse(lossCtrl.text);
                    final paise = CurrencyFormatter.rupeesToPaise(rupees);
                    final user = ref.read(currentUserProvider);

                    final repo = ref.read(appRepositoryProvider);
                    await repo.distributeLoss(
                      investmentId: selectedInvestmentId,
                      totalLossPaise: paise,
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
              child: const Text('Distribute Loss'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final distributionsAsync = ref.watch(profitDistributionsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Row(
        children: [
          AppSidebar(currentRoute: '/profit-loss', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Profit & Loss Distributions',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Row(
                                children: [
                                  AppButton(
                                    text: 'Distribute Loss',
                                    icon: Icons.trending_down,
                                    isSecondary: true,
                                    onPressed: () =>
                                        _showDistributeLossDialog(context),
                                  ),
                                  const SizedBox(width: 12),
                                  AppButton(
                                    text: 'Distribute Profit',
                                    icon: Icons.trending_up,
                                    onPressed: () =>
                                        _showDistributeProfitDialog(context),
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
                                  : items
                                      .where((d) => d.memberId == user.memberId)
                                      .toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No profit/loss distributions recorded yet.',
                                    style:
                                        TextStyle(color: AppColors.textMuted),
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
                                      DataColumn(label: Text('INVESTMENT')),
                                      DataColumn(label: Text('MEMBER')),
                                      DataColumn(label: Text('MEMBER SHARE %')),
                                      DataColumn(label: Text('TYPE')),
                                      DataColumn(label: Text('ALLOCATED AMOUNT')),
                                      DataColumn(label: Text('DISTRIBUTED DATE')),
                                    ],
                                    rows: filtered.map((d) {
                                      final isLoss = d.profitAmountPaise < 0;
                                      final absAmount = isLoss
                                          ? -d.profitAmountPaise
                                          : d.profitAmountPaise;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('#${d.id}')),
                                          DataCell(Text(
                                            d.investmentName,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )),
                                          DataCell(Text(d.memberName)),
                                          DataCell(Text(
                                            '${d.memberPercentage.toStringAsFixed(2)}%',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isLoss
                                                    ? AppColors.danger
                                                        .withValues(alpha: 0.15)
                                                    : AppColors.positive
                                                        .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                                          DataCell(Text(
                                            '${isLoss ? "-" : "+"} ${CurrencyFormatter.formatPaise(absAmount)}',
                                            style: TextStyle(
                                              color: isLoss
                                                  ? AppColors.danger
                                                  : AppColors.positive,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )),
                                          DataCell(Text(
                                            DateFormatter.formatDate(
                                              DateTime.parse(d.distributedAt),
                                            ),
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),),
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
