import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../members/domain/member_model.dart';

class CollectPaymentDialog extends ConsumerStatefulWidget {
  final List<MemberModel> members;

  const CollectPaymentDialog({
    super.key,
    required this.members,
  });

  static Future<void> show(BuildContext context, List<MemberModel> members) {
    return showDialog(
      context: context,
      builder: (ctx) => CollectPaymentDialog(members: members),
    );
  }

  @override
  ConsumerState<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends ConsumerState<CollectPaymentDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _refCtrl;
  late final TextEditingController _remarksCtrl;
  final _formKey = GlobalKey<FormState>();

  late int _selectedMemberId;
  String _paymentMode = 'Bank Transfer';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _refCtrl = TextEditingController();
    _remarksCtrl = TextEditingController();
    _selectedMemberId = widget.members.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
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

      final repo = ref.read(appRepositoryProvider);
      await repo.recordContribution(
        memberId: _selectedMemberId,
        amountPaise: amountPaise,
        paymentMode: _paymentMode,
        referenceNo: _refCtrl.text.trim().isNotEmpty
            ? _refCtrl.text.trim()
            : null,
        remarks: _remarksCtrl.text.trim().isNotEmpty
            ? _remarksCtrl.text.trim()
            : null,
        actionBy: user?.username ?? 'Admin',
      );

      refreshAllFinancialProviders(ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment collection recorded successfully')),
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
        'Record Payment Collection (Admin)',
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
                'Select Member',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _selectedMemberId,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                items: widget.members.map((m) {
                  return DropdownMenuItem<int>(
                    value: m.id,
                    child: Text('${m.name} (#${m.id})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMemberId = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Contribution Amount (₹)',
                hint: 'e.g. 50000',
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
                label: 'Reference / UTR Number',
                hint: 'e.g. UTR12345678',
                controller: _refCtrl,
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
              : const Text('Record Collection'),
        ),
      ],
    );
  }
}
