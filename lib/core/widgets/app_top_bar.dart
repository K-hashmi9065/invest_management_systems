import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_providers.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';

class AppTopBar extends ConsumerWidget {
  final String title;
  final String userName;
  final String userRole;
  final VoidCallback onLogout;

  const AppTopBar({
    super.key,
    required this.title,
    required this.userName,
    required this.userRole,
    required this.onLogout,
  });

  void _showNotificationsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final notificationsAsync = ref.watch(notificationsProvider);

          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Notifications Center',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final currentUser = ref.read(currentUserProvider);
                    await ref
                        .read(appRepositoryProvider)
                        .markAllNotificationsAsRead(userId: currentUser?.id);
                    ref.invalidate(notificationsProvider);
                  },
                  child: const Text('Mark All Read', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              height: 380,
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading notifications: $err')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: n.isRead
                              ? AppColors.surfaceElevated
                              : AppColors.accent.withValues(alpha: 0.2),
                          child: Icon(
                            n.isRead ? Icons.done_all : Icons.notifications,
                            size: 14,
                            color: n.isRead ? AppColors.textMuted : AppColors.accent,
                          ),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.message,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatDate(DateTime.parse(n.createdAt)),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!n.isRead) {
                            await ref
                                .read(appRepositoryProvider)
                                .markNotificationAsRead(n.id);
                            ref.invalidate(notificationsProvider);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.value
            ?.where((n) => !n.isRead)
            .length ??
        0;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfacePage,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              // Notification Bell Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () => _showNotificationsDialog(context, ref),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    userRole.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                tooltip: 'Logout',
                onPressed: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
