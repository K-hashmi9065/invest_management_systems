import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../members/domain/member_model.dart';

/// Modal dialog for recording manual financial adjustments or refunds.
/// Ensures proper controller disposal and invalidates financial state on success.
class AddAdjustmentDialog extends ConsumerStatefulWidget {
  final List<MemberModel> members;

  const AddAdjustmentDialog({
    super.key,
    required this.members,
  });

  static Future<void> show(BuildContext context, List<MemberModel> members) {
    return showDialog(
      context: context,
      builder: (ctx) => AddAdjustmentDialog(members: members),
    );
  }

  @override
  ConsumerState<AddAdjustmentDialog> createState() =>
      _AddAdjustmentDialogState();
}

class _AddAdjustmentDialogState extends ConsumerState<AddAdjustmentDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _remarksCtrl;
  final _formKey = GlobalKey<FormState>();

  String _selectedType = AppConstants.txAdjustment;
  int? _selectedMemberId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _remarksCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final rupees = double.parse(_amountCtrl.text.trim());
      final paise = CurrencyFormatter.rupeesToPaise(rupees);
      final user = ref.read(currentUserProvider);

      await ref.read(appRepositoryProvider).recordAdjustmentOrRefund(
            memberId: _selectedMemberId,
            transactionType: _selectedType,
            amountPaise: paise,
            remarks: _remarksCtrl.text.trim(),
            actionBy: user?.username ?? 'Admin',
          );

      refreshAllFinancialProviders(ref);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adjustment / Refund recorded successfully.'),
            backgroundColor: AppColors.positive,
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
        'Record Manual Adjustment / Refund',
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
                'Transaction Type',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedType,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.txAdjustment,
                    child: Text('ADJUSTMENT (Internal Reversal / Correction)'),
                  ),
                  DropdownMenuItem(
                    value: 'REFUND',
                    child: Text('REFUND (Payout Reversal to Member)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
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
                isExpanded: true,
                initialValue: _selectedMemberId,
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
                  ...widget.members.map((m) {
                    return DropdownMenuItem<int?>(
                      value: m.id,
                      child: Text('${m.name} (#${m.id})'),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedMemberId = val);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Amount (₹)',
                hint: 'e.g. 5000 or -5000',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                controller: _amountCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed == 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Audit Remarks / Reason',
                hint: 'Enter detailed justification for audit record',
                controller: _remarksCtrl,
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
              : const Text('Record Adjustment'),
        ),
      ],
    );
  }
}
