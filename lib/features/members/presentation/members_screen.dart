import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/status_badge.dart';

final memberSearchQueryProvider = StateProvider<String>((ref) => '');

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
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
          'Add New Group Member',
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
                  hint: 'Enter member name',
                  controller: nameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email Address',
                  hint: 'Enter member email',
                  controller: emailCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  controller: phoneCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Portal Login Username',
                  hint: 'Enter login username',
                  controller: usernameCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Login Password',
                  hint: 'Enter password',
                  obscureText: true,
                  controller: passwordCtrl,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                  final user = ref.read(currentUserProvider);
                  final repo = ref.read(appRepositoryProvider);

                  final member = await repo.createMember(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    phone: phoneCtrl.text,
                    actionBy: user?.username ?? 'Admin',
                  );

                  await repo.createUser(
                    fullName: nameCtrl.text,
                    username: usernameCtrl.text,
                    password: passwordCtrl.text,
                    role: AppConstants.roleMember,
                    memberId: member.id,
                    actionBy: user?.username ?? 'Admin',
                  );

                  refreshAllFinancialProviders(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
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
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(membersProvider);
    final searchQuery = ref.watch(memberSearchQueryProvider);

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
          AppSidebar(currentRoute: '/members', userRole: user.role),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: 'Member Directory',
                  userName: user.fullName,
                  userRole: user.role,
                  onLogout: () {
                    ref.read(currentUserProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextField(
                                onChanged: (val) => ref
                                    .read(memberSearchQueryProvider.notifier)
                                    .state = val,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search members by name or email...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            if (isAdmin)
                              AppButton(
                                text: 'Add Member',
                                icon: Icons.add,
                                onPressed: () =>
                                    _showAddMemberDialog(context, ref),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: AsyncValueWidget(
                            value: membersAsync,
                            data: (members) {
                              final filtered = members.where((m) {
                                final query = searchQuery.toLowerCase();
                                return m.name.toLowerCase().contains(query) ||
                                    m.email.toLowerCase().contains(query);
                              }).toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No members found.',
                                    style:
                                        TextStyle(color: AppColors.textMuted),
                                  ),
                                );
                              }

                              return AppCard(
                                padding: EdgeInsets.zero,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('ID')),
                                      DataColumn(label: Text('NAME')),
                                      DataColumn(label: Text('EMAIL')),
                                      DataColumn(label: Text('PHONE')),
                                      DataColumn(label: Text('CONTRIBUTION')),
                                      DataColumn(label: Text('SHARE %')),
                                      DataColumn(label: Text('PROFIT')),
                                      DataColumn(label: Text('STATUS')),
                                    ],
                                    rows: filtered.map((m) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('#${m.id}')),
                                          DataCell(
                                            Text(
                                              m.name,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(m.email)),
                                          DataCell(Text(m.phone)),
                                          DataCell(
                                            Text(
                                              CurrencyFormatter.formatPaise(
                                                  m.totalContributionPaise),
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${m.contributionPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              CurrencyFormatter.formatPaise(
                                                  m.allocatedProfitPaise),
                                              style: const TextStyle(
                                                color: AppColors.positive,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                StatusBadge(status: m.status),
                                                if (isAdmin) ...[
                                                  const SizedBox(width: 4),
                                                  IconButton(
                                                    icon: Icon(
                                                      m.status == AppConstants.statusActive
                                                          ? Icons.block
                                                          : Icons.check_circle_outline,
                                                      size: 16,
                                                      color: m.status == AppConstants.statusActive
                                                          ? AppColors.danger
                                                          : AppColors.positive,
                                                    ),
                                                    tooltip: m.status == AppConstants.statusActive
                                                        ? 'Deactivate Member'
                                                        : 'Activate Member',
                                                    onPressed: () async {
                                                      final newStatus = m.status == AppConstants.statusActive
                                                          ? AppConstants.statusInactive
                                                          : AppConstants.statusActive;
                                                      await ref.read(appRepositoryProvider).updateMemberStatus(
                                                        memberId: m.id,
                                                        status: newStatus,
                                                        actionBy: user.username,
                                                      );
                                                      refreshAllFinancialProviders(ref);
                                                    },
                                                  ),
                                                ],
                                              ],
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
