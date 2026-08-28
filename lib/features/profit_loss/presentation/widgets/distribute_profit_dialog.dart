import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../investments/domain/investment_model.dart';

class DistributeProfitDialog extends ConsumerStatefulWidget {
  final List<InvestmentModel> investments;

  const DistributeProfitDialog({
    super.key,
    required this.investments,
  });

  static Future<void> show(
      BuildContext context, List<InvestmentModel> investments) {
    return showDialog(
      context: context,
      builder: (ctx) => DistributeProfitDialog(investments: investments),
    );
  }

  @override
  ConsumerState<DistributeProfitDialog> createState() =>
      _DistributeProfitDialogState();
}

class _DistributeProfitDialogState
    extends ConsumerState<DistributeProfitDialog> {
  late final TextEditingController _profitCtrl;
  final _formKey = GlobalKey<FormState>();

  late int _selectedInvestmentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profitCtrl = TextEditingController();
    _selectedInvestmentId = widget.investments.first.id;
  }

  @override
  void dispose() {
    _profitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final rupees = double.parse(_profitCtrl.text.trim());
      final paise = CurrencyFormatter.rupeesToPaise(rupees);
      final user = ref.read(currentUserProvider);

      final repo = ref.read(appRepositoryProvider);
      await repo.distributeProfit(
        investmentId: _selectedInvestmentId,
        totalProfitPaise: paise,
        actionBy: user?.username ?? 'Admin',
      );

      refreshAllFinancialProviders(ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profit distributed successfully'),
          ),
        );
      }
    } catch (e, st) {
      final failure = FailureMapper.map(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          key: _formKey,
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
                initialValue: _selectedInvestmentId,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                items: widget.investments.map((inv) {
                  return DropdownMenuItem<int>(
                    value: inv.id,
                    child: Text('${inv.name} (#${inv.id})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedInvestmentId = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Total Realized Profit (₹)',
                hint: 'e.g. 100000',
                keyboardType: TextInputType.number,
                controller: _profitCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Profit required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Profit will be split automatically among members based on their exact contribution percentage.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Distribute Profit'),
        ),
      ],
    );
  }
}
