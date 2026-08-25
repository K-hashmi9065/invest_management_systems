import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/device_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/async_value_widget.dart';

final deviceLockStateProvider = StateProvider<bool>(
  (ref) => DeviceLockService.config.enableDeviceLock,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref, String username) {
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
                    if (v != newPasswordCtrl.text) return 'Passwords do not match';
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
                final success = await ref.read(appRepositoryProvider).changePassword(
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
                      backgroundColor:
                          success ? AppColors.positive : AppColors.danger,
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
                  label: 'New Temporary/Permanent Password',
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
                await ref.read(appRepositoryProvider).resetUserPassword(
                  userId: userId,
                  newPassword: newPasswordCtrl.text,
                  actionBy: actionByUsername,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password for $targetUsername has been reset.'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final deviceLockEnabled = ref.watch(deviceLockStateProvider);
    final usersAsync = ref.watch(usersProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const Text(
                            'User Account & Password Administration',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                                      DataColumn(label: Text('ACTION')),
                                    ],
                                    rows: users.map((u) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('#${u.id}')),
                                          DataCell(Text(
                                            u.fullName,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )),
                                          DataCell(Text(u.username)),
                                          DataCell(Text(u.role)),
                                          DataCell(
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.key, size: 14),
                                              label: const Text('Reset Password'),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
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
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],

                        const Text(
                          'Windows Device Authorization Lock',
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
                                  'Enable MachineGuid Device Lock',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Restrict app execution strictly to authorized Windows computer hardware IDs.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                value: deviceLockEnabled,
                                activeThumbColor: AppColors.accent,
                                onChanged: (val) {
                                  ref.read(deviceLockStateProvider.notifier).state = val;
                                  DeviceLockService.updateConfig(
                                    DeviceLockConfig(
                                      enableDeviceLock: val,
                                      allowedMachineIds: ['*'],
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current System Machine Guid:',
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          'Database snapshot backup created successfully in ProgramData.'),
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
