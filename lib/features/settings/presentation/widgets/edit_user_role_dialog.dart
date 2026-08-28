import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal dialog for Super Admin to edit authorization role of a user.
class EditUserRoleDialog extends ConsumerStatefulWidget {
  final int userId;
  final String targetUsername;
  final String currentRole;
  final String actionByUsername;

  const EditUserRoleDialog({
    super.key,
    required this.userId,
    required this.targetUsername,
    required this.currentRole,
    required this.actionByUsername,
  });

  static Future<void> show({
    required BuildContext context,
    required int userId,
    required String targetUsername,
    required String currentRole,
    required String actionByUsername,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => EditUserRoleDialog(
        userId: userId,
        targetUsername: targetUsername,
        currentRole: currentRole,
        actionByUsername: actionByUsername,
      ),
    );
  }

  @override
  ConsumerState<EditUserRoleDialog> createState() =>
      _EditUserRoleDialogState();
}

class _EditUserRoleDialogState extends ConsumerState<EditUserRoleDialog> {
  late String _selectedRole;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      await ref.read(appRepositoryProvider).updateUserRole(
            userId: widget.userId,
            newRole: _selectedRole,
            actionBy: widget.actionByUsername,
          );

      ref.invalidate(usersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated role for ${widget.targetUsername} to $_selectedRole.',
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
        'Change Role for "${widget.targetUsername}"',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select new authorization role:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedRole,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfacePage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              dropdownColor: AppColors.surfaceCard,
              items: const [
                DropdownMenuItem(
                  value: AppConstants.roleMember,
                  child: Text('MEMBER (Read-Only Portal)'),
                ),
                DropdownMenuItem(
                  value: AppConstants.roleAdmin,
                  child: Text('ADMIN (Operational Access)'),
                ),
                DropdownMenuItem(
                  value: AppConstants.roleSuperAdmin,
                  child: Text('SUPER_ADMIN (Full System Access)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRole = val);
                }
              },
            ),
          ],
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
              : const Text('Save Role'),
        ),
      ],
    );
  }
}
