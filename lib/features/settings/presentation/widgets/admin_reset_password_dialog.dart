import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Modal dialog for Super Admin to reset password for a target user.
class AdminResetPasswordDialog extends ConsumerStatefulWidget {
  final int userId;
  final String targetUsername;
  final String actionByUsername;

  const AdminResetPasswordDialog({
    super.key,
    required this.userId,
    required this.targetUsername,
    required this.actionByUsername,
  });

  static Future<void> show({
    required BuildContext context,
    required int userId,
    required String targetUsername,
    required String actionByUsername,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AdminResetPasswordDialog(
        userId: userId,
        targetUsername: targetUsername,
        actionByUsername: actionByUsername,
      ),
    );
  }

  @override
  ConsumerState<AdminResetPasswordDialog> createState() =>
      _AdminResetPasswordDialogState();
}

class _AdminResetPasswordDialogState
    extends ConsumerState<AdminResetPasswordDialog> {
  late final TextEditingController _newPasswordCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _newPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(appRepositoryProvider).resetUserPassword(
            userId: widget.userId,
            newPassword: _newPasswordCtrl.text,
            actionBy: widget.actionByUsername,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password for ${widget.targetUsername} has been reset.',
            ),
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
      title: Text(
        'Reset Password for "${widget.targetUsername}"',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'New Password',
                hint: 'Enter new password for user',
                obscureText: true,
                controller: _newPasswordCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Minimum 6 characters';
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
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}
