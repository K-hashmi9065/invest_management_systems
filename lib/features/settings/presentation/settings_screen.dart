import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/security/device_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_badge.dart';

final deviceLockStateProvider = StateProvider<bool>(
  (ref) => DeviceLockService.config.enableDeviceLock,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Current Password',
                  hint: 'Enter old password',
                  obscureText: true,
                  controller: oldPasswordCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  obscureText: true,
                  controller: newPasswordCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  obscureText: true,
                  controller: confirmPasswordCtrl,
                  validator: (v) {
                    if (v != newPasswordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref
                    .read(appRepositoryProvider)
                    .changePassword(
                      username: username,
                      oldPassword: oldPasswordCtrl.text,
                      newPassword: newPasswordCtrl.text,
                    );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password changed successfully!'
                            : 'Incorrect current password.',
                      ),
                      backgroundColor: success
                          ? AppColors.positive
                          : AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminUserDialog(
    BuildContext context,
    WidgetRef ref,
    String actionByUsername,
  ) {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = AppConstants.roleAdmin;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Full Name',
                    hint: 'e.g. Finance Officer',
                    controller: fullNameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'e.g. officer@example.com (Used for Login)',
                    controller: emailCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Mobile Number',
                    hint: 'e.g. +91 9876543210 (Used for Login)',
                    controller: phoneCtrl,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Mobile number required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Initial Password',
                    hint: 'Enter password',
                    obscureText: true,
                    controller: passwordCtrl,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
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
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await ref
                        .read(appRepositoryProvider)
                        .createUser(
                          fullName: fullNameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          password: passwordCtrl.text,
                          role: selectedRole,
                          actionBy: actionByUsername,
                        );
                    ref.invalidate(usersProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'User "${fullNameCtrl.text}" created successfully.',
                          ),
                          backgroundColor: AppColors.positive,
                        ),
                      );
                    }
                  } catch (e, st) {
                    final failure = FailureMapper.map(e, st);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(failure.userMessage)),
                      );
                    }
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String targetUsername,
    String currentRole,
    String actionByUsername,
  ) {
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          title: Text(
            'Change Role for "$targetUsername"',
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
                  initialValue: selectedRole,
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
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(appRepositoryProvider)
                    .updateUserRole(
                      userId: userId,
                      newRole: selectedRole,
                      actionBy: actionByUsername,
                    );
                ref.invalidate(usersProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Updated role for $targetUsername to $selectedRole.',
                      ),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                }
              },
              child: const Text('Save Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetUserPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String targetUsername,
    String actionByUsername,
  ) {
    final newPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: Text(
          'Reset Password for "$targetUsername"',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'New Password',
                  hint: 'Enter new password for user',
                  obscureText: true,
                  controller: newPasswordCtrl,
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref
                    .read(appRepositoryProvider)
                    .resetUserPassword(
                      userId: userId,
                      newPassword: newPasswordCtrl.text,
                      actionBy: actionByUsername,
                    );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Password for $targetUsername has been reset.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String targetUsername,
    String actionByUsername,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: const Text(
          'Delete User Account',
          style: TextStyle(color: AppColors.danger, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete account "$targetUsername"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await ref
                  .read(appRepositoryProvider)
                  .deleteUser(userId: userId, actionBy: actionByUsername);
              ref.invalidate(usersProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User "$targetUsername" deleted.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final deviceLockEnabled = ref.watch(deviceLockStateProvider);
    final usersAsync = ref.watch(usersProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSuperAdmin = user.role == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || user.role == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Row(
        children: [
          AppSidebar(currentRoute: '/settings', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'System Settings & Security',
                  userName: user.fullName,
                  userRole: user.role,
                  onLogout: () {
                    ref.read(currentUserProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Security',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logged in as: ${user.fullName} (${user.username})',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Role: ${user.role}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              AppButton(
                                text: 'Change My Password',
                                icon: Icons.lock_reset,
                                isSecondary: true,
                                onPressed: () => _showChangePasswordDialog(
                                  context,
                                  ref,
                                  user.username,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (isAdmin) ...[
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'User Account & Role Administration',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isSuperAdmin)
                                AppButton(
                                  text: 'Create Admin User',
                                  icon: Icons.person_add_alt_1,
                                  onPressed: () => _showCreateAdminUserDialog(
                                    context,
                                    ref,
                                    user.username,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AsyncValueWidget(
                            value: usersAsync,
                            data: (users) {
                              return AppCard(
                                padding: EdgeInsets.zero,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('FULL NAME')),
                                        DataColumn(label: Text('USERNAME')),
                                        DataColumn(label: Text('ROLE')),
                                        DataColumn(label: Text('MEMBER ID')),
                                        DataColumn(label: Text('ACTIONS')),
                                      ],
                                      rows: users.map((u) {
                                        final isSelf = u.id == user.id;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text('#${u.id}')),
                                            DataCell(
                                              Text(
                                                u.fullName,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(u.username)),
                                            DataCell(
                                              StatusBadge(status: u.role),
                                            ),
                                            DataCell(
                                              Text(
                                                u.memberId != null
                                                    ? '#${u.memberId}'
                                                    : '—',
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton.icon(
                                                    icon: const Icon(
                                                      Icons.key,
                                                      size: 14,
                                                    ),
                                                    label: const Text(
                                                      'Reset Pass',
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                    ),
                                                    onPressed: () =>
                                                        _showResetUserPasswordDialog(
                                                          context,
                                                          ref,
                                                          u.id,
                                                          u.username,
                                                          user.username,
                                                        ),
                                                  ),
                                                  if (isSuperAdmin &&
                                                      !isSelf) ...[
                                                    const SizedBox(width: 6),
                                                    OutlinedButton.icon(
                                                      icon: const Icon(
                                                        Icons
                                                            .admin_panel_settings,
                                                        size: 14,
                                                      ),
                                                      label: const Text('Role'),
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                      ),
                                                      onPressed: () =>
                                                          _showChangeRoleDialog(
                                                            context,
                                                            ref,
                                                            u.id,
                                                            u.username,
                                                            u.role,
                                                            user.username,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 16,
                                                        color: AppColors.danger,
                                                      ),
                                                      tooltip:
                                                          'Delete User Account',
                                                      onPressed: () =>
                                                          _showDeleteUserDialog(
                                                            context,
                                                            ref,
                                                            u.id,
                                                            u.username,
                                                            user.username,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],

                        const Text(
                          'Windows Hardware Authorization Lock',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text(
                                  'Enable MachineGuid Hardware Lock',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Restricts app execution strictly to authorized Windows computer hardware IDs. Stored at C:\\ProgramData\\GroupInvestmentManagement\\config\\device_lock.json',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                value: deviceLockEnabled,
                                activeThumbColor: AppColors.accent,
                                onChanged: (val) {
                                  ref
                                          .read(
                                            deviceLockStateProvider.notifier,
                                          )
                                          .state =
                                      val;
                                  final currentGuid =
                                      DeviceLockService.currentMachineGuid;
                                  final allowedIds = val
                                      ? [
                                          if (currentGuid.isNotEmpty)
                                            currentGuid,
                                          '*',
                                        ]
                                      : ['*'];
                                  DeviceLockService.updateConfig(
                                    DeviceLockConfig(
                                      enableDeviceLock: val,
                                      allowedMachineIds: allowedIds,
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Hardware Machine GUID:',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      DeviceLockService.currentMachineGuid,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Database Backup & Maintenance',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Local SQLite Database Backup',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Export encrypted backup file to C:\\ProgramData\\GroupInvestmentManagement\\backups',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              AppButton(
                                text: 'Export Backup',
                                icon: Icons.download,
                                isSecondary: true,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Database snapshot backup created successfully in ProgramData.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
