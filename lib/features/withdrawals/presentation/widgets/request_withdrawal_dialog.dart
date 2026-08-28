import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/user_model.dart';
import '../../../members/domain/member_model.dart';

class RequestWithdrawalDialog extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final List<MemberModel> members;

  const RequestWithdrawalDialog({
    super.key,
    required this.currentUser,
    required this.members,
  });

  static Future<void> show(
    BuildContext context,
    UserModel currentUser,
    List<MemberModel> members,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => RequestWithdrawalDialog(
        currentUser: currentUser,
        members: members,
      ),
    );
  }

  @override
  ConsumerState<RequestWithdrawalDialog> createState() =>
      _RequestWithdrawalDialogState();
}

class _RequestWithdrawalDialogState
    extends ConsumerState<RequestWithdrawalDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _remarksCtrl;
  final _formKey = GlobalKey<FormState>();

  late int _selectedMemberId;
  late MemberModel _selectedMember;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _remarksCtrl = TextEditingController();

    _selectedMemberId = (widget.currentUser.memberId != null &&
            widget.members.any((m) => m.id == widget.currentUser.memberId))
        ? widget.currentUser.memberId!
        : widget.members.first.id;

    _selectedMember = widget.members.firstWhere(
      (m) => m.id == _selectedMemberId,
      orElse: () => widget.members.first,
    );
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
      final amountPaise = CurrencyFormatter.rupeesToPaise(
        double.parse(_amountCtrl.text.trim()),
      );

      final repo = ref.read(appRepositoryProvider);
      await repo.submitWithdrawalRequest(
        memberId: _selectedMemberId,
        amountPaise: amountPaise,
        actionBy: widget.currentUser.username,
        remarks: _remarksCtrl.text.trim().isNotEmpty
            ? _remarksCtrl.text.trim()
            : null,
      );

      refreshAllFinancialProviders(ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted successfully')),
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
    final isAdmin = widget.currentUser.role == AppConstants.roleAdmin ||
        widget.currentUser.role == AppConstants.roleSuperAdmin;
    final maxWithdrawablePaise = _selectedMember.availableBalancePaise;

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      title: Text(
        isAdmin
            ? 'Submit Withdrawal Request (Admin/Member)'
            : 'Submit Withdrawal Request',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAdmin) ...[
                const Text(
                  'Select Member Profile',
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
                      setState(() {
                        _selectedMemberId = val;
                        _selectedMember =
                            widget.members.firstWhere((m) => m.id == val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Balance:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(maxWithdrawablePaise),
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Requested Amount (₹)',
                hint: 'e.g. 25000',
                keyboardType: TextInputType.number,
                controller: _amountCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  final paise = CurrencyFormatter.rupeesToPaise(parsed);
                  if (paise > maxWithdrawablePaise) {
                    return 'Exceeds available balance (${CurrencyFormatter.formatPaise(maxWithdrawablePaise)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Reason / Remarks',
                hint: 'e.g. Medical emergency / Personal use',
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
