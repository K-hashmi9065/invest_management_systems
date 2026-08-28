import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/security/device_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';
import '../../../core/widgets/status_badge.dart';
import 'widgets/admin_reset_password_dialog.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/create_user_dialog.dart';
import 'widgets/edit_user_role_dialog.dart';

final deviceLockStateProvider = StateProvider<bool>(
  (ref) => DeviceLockService.config.enableDeviceLock,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
              try {
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
              } catch (e, st) {
                final failure = FailureMapper.map(e, st);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(failure.userMessage),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
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

    // Set page title for AppShell
    Future.microtask(() => ref.read(pageTitleProvider.notifier).state = 'System Settings & Security');

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSuperAdmin = user.role == AppConstants.roleSuperAdmin;
    final isAdmin = isSuperAdmin || user.role == AppConstants.roleAdmin;

    return SingleChildScrollView(
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
                  onPressed: () => ChangePasswordDialog.show(
                    context,
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
                    onPressed: () => CreateUserDialog.show(
                      context,
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
                  child: HorizontalScrollableTable(
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
                                (!isSuperAdmin && u.role == AppConstants.roleSuperAdmin)
                                    ? const Text('—')
                                    : Row(
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
                                                AdminResetPasswordDialog.show(
                                                  context: context,
                                                  userId: u.id,
                                                  targetUsername: u.username,
                                                  actionByUsername: user.username,
                                                ),
                                          ),
                                          if (isSuperAdmin &&
                                              !isSelf) ...[
                                            const SizedBox(width: 6),
                                            OutlinedButton.icon(
                                              icon: const Icon(
                                                Icons.admin_panel_settings,
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
                                                  EditUserRoleDialog.show(
                                                    context: context,
                                                    userId: u.id,
                                                    targetUsername: u.username,
                                                    currentRole: u.role,
                                                    actionByUsername: user.username,
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
                  onPressed: () async {
                    try {
                      final path = await ref
                          .read(appRepositoryProvider)
                          .exportBackup(actionBy: user.username);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Database backup exported successfully to: $path',
                            ),
                          ),
                        );
                      }
                    } catch (e, st) {
                      final failure = FailureMapper.map(e, st);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(failure.userMessage),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
