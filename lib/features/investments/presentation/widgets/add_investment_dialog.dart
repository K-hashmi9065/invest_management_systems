import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddInvestmentDialog extends ConsumerStatefulWidget {
  const AddInvestmentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AddInvestmentDialog(),
    );
  }

  @override
  ConsumerState<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends ConsumerState<AddInvestmentDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _periodCtrl;
  late final TextEditingController _returnCtrl;
  late final TextEditingController _remarksCtrl;
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _typeCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _periodCtrl = TextEditingController(text: '12');
    _returnCtrl = TextEditingController();
    _remarksCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    _periodCtrl.dispose();
    _returnCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final amountPaise = CurrencyFormatter.rupeesToPaise(
        double.parse(_amountCtrl.text.trim()),
      );
      final returnPaise = CurrencyFormatter.rupeesToPaise(
        double.parse(_returnCtrl.text.trim()),
      );

      final repo = ref.read(appRepositoryProvider);
      await repo.createInvestment(
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        amountPaise: amountPaise,
        periodMonths: int.parse(_periodCtrl.text.trim()),
        expectedReturnPaise: returnPaise,
        actionBy: user?.username ?? 'Admin',
        remarks: _remarksCtrl.text.trim().isNotEmpty
            ? _remarksCtrl.text.trim()
            : null,
      );

      refreshAllFinancialProviders(ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment created successfully')),
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
        'Create Group Investment Record',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Investment Name',
                  hint: 'e.g. Commercial Real Estate / Mutual Fund A',
                  controller: _nameCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Type',
                  hint: 'e.g. Real Estate, Stocks, FD, Startup',
                  controller: _typeCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Type required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Amount (₹)',
                  hint: 'e.g. 500000',
                  keyboardType: TextInputType.number,
                  controller: _amountCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Investment Period (Months)',
                  hint: 'e.g. 12',
                  keyboardType: TextInputType.number,
                  controller: _periodCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Period required';
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Invalid period';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Expected Return Amount (₹)',
                  hint: 'e.g. 600000',
                  keyboardType: TextInputType.number,
                  controller: _returnCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Expected return required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Remarks / Notes',
                  hint: 'Optional notes',
                  controller: _remarksCtrl,
                ),
              ],
            ),
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
              : const Text('Create Investment'),
        ),
      ],
    );
  }
}
