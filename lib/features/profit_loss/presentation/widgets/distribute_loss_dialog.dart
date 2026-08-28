import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../investments/domain/investment_model.dart';

class DistributeLossDialog extends ConsumerStatefulWidget {
  final List<InvestmentModel> investments;

  const DistributeLossDialog({
    super.key,
    required this.investments,
  });

  static Future<void> show(
      BuildContext context, List<InvestmentModel> investments) {
    return showDialog(
      context: context,
      builder: (ctx) => DistributeLossDialog(investments: investments),
    );
  }

  @override
  ConsumerState<DistributeLossDialog> createState() =>
      _DistributeLossDialogState();
}

class _DistributeLossDialogState extends ConsumerState<DistributeLossDialog> {
  late final TextEditingController _lossCtrl;
  final _formKey = GlobalKey<FormState>();

  late int _selectedInvestmentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lossCtrl = TextEditingController();
    _selectedInvestmentId = widget.investments.first.id;
  }

  @override
  void dispose() {
    _lossCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final rupees = double.parse(_lossCtrl.text.trim());
      final paise = CurrencyFormatter.rupeesToPaise(rupees);
      final user = ref.read(currentUserProvider);

      final repo = ref.read(appRepositoryProvider);
      await repo.distributeLoss(
        investmentId: _selectedInvestmentId,
        totalLossPaise: paise,
        actionBy: user?.username ?? 'Admin',
      );

      refreshAllFinancialProviders(ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loss distributed successfully')),
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
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 22,
          ),
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
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Distributing loss will deduct funds pro-rata from member balances based on their active contribution percentages.',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
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
                label: 'Total Realized Loss (₹)',
                hint: 'e.g. 50000',
                keyboardType: TextInputType.number,
                controller: _lossCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Loss amount required';
                  final parsed = double.tryParse(v.trim());
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
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
              : const Text('Distribute Loss'),
        ),
      ],
    );
  }
}
