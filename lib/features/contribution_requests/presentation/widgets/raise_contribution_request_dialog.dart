import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/user_model.dart';

/// Modal dialog for members to raise an add-money contribution request.
/// Handles text controller cleanup and maps failures to user-friendly messages.
class RaiseContributionRequestDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const RaiseContributionRequestDialog({
    super.key,
    required this.user,
  });

  static Future<void> show(BuildContext context, UserModel user) {
    return showDialog(
      context: context,
      builder: (ctx) => RaiseContributionRequestDialog(user: user),
    );
  }

  @override
  ConsumerState<RaiseContributionRequestDialog> createState() =>
      _RaiseContributionRequestDialogState();
}

class _RaiseContributionRequestDialogState
    extends ConsumerState<RaiseContributionRequestDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _remarksCtrl;
  final _formKey = GlobalKey<FormState>();

  String _paymentMode = 'Bank Transfer';
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

      await ref.read(appRepositoryProvider).submitContributionRequest(
            memberId: widget.user.memberId!,
            amountPaise: paise,
            paymentMode: _paymentMode,
            remarks: _remarksCtrl.text.trim().isNotEmpty
                ? _remarksCtrl.text.trim()
                : null,
            actionBy: widget.user.username,
          );

      refreshAllFinancialProviders(ref);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribution request submitted successfully.'),
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
        'Raise Add Money Request',
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
              AppTextField(
                label: 'Requested Amount (₹)',
                hint: 'e.g. 25000',
                keyboardType: TextInputType.number,
                controller: _amountCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
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
                initialValue: _paymentMode,
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
                    setState(() => _paymentMode = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Remarks / Notes',
                hint: 'Optional notes for admin',
                controller: _remarksCtrl,
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
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}
