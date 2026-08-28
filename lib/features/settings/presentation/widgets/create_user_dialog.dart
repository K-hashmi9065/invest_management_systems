import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Modal dialog for Super Admins to create new staff or administrative users.
/// Manages controller lifecycle cleanly and handles creation errors via FailureMapper.
class CreateUserDialog extends ConsumerStatefulWidget {
  final String actionByUsername;

  const CreateUserDialog({
    super.key,
    required this.actionByUsername,
  });

  static Future<void> show(BuildContext context, String actionByUsername) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateUserDialog(actionByUsername: actionByUsername),
    );
  }

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = AppConstants.roleAdmin;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(appRepositoryProvider).createUser(
            fullName: _fullNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _selectedRole,
            actionBy: widget.actionByUsername,
          );

      ref.invalidate(usersProvider);

      if (mounted) {
        final name = _fullNameCtrl.text.trim();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "$name" created successfully.'),
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
        'Create Administrative / Staff User',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full Name',
                hint: 'e.g. Finance Officer',
                controller: _fullNameCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email Address',
                hint: 'e.g. officer@example.com (Used for Login)',
                controller: _emailCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Mobile Number',
                hint: 'e.g. +91 9876543210 (Used for Login)',
                controller: _phoneCtrl,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Mobile number required'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Initial Password',
                hint: 'Enter password',
                obscureText: true,
                controller: _passwordCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Assigned Role',
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
                    value: AppConstants.roleAdmin,
                    child: Text('ADMIN (Operational Management)'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleSuperAdmin,
                    child: Text('SUPER_ADMIN (Full Control)'),
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
              : const Text('Create User'),
        ),
      ],
    );
  }
}
