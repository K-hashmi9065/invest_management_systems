import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';
import '../../../core/widgets/status_badge.dart';
import 'widgets/add_member_dialog.dart';

final memberSearchQueryProvider = StateProvider<String>((ref) => '');

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  String _maskEmail(String email) {
    if (!email.contains('@')) return '***@***';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}***@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return '******';
    final prefix = phone.length > 6
        ? phone.substring(0, 3)
        : phone.substring(0, 2);
    final suffix = phone.substring(phone.length - 2);
    return '$prefix*****$suffix';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(membersProvider);
    final searchQuery = ref.watch(memberSearchQueryProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin =
        user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  minWidth: 220,
                ),
                child: TextField(
                  onChanged: (val) =>
                      ref.read(memberSearchQueryProvider.notifier).state = val,
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
                  onPressed: () => AddMemberDialog.show(context),
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
                      style: TextStyle(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: HorizontalScrollableTable(
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
                              DataCell(
                                Text(
                                  isAdmin ? m.email : _maskEmail(m.email),
                                ),
                              ),
                              DataCell(
                                Text(
                                  isAdmin ? m.phone : _maskPhone(m.phone),
                                ),
                              ),
                              DataCell(
                                Text(
                                  CurrencyFormatter.formatPaise(
                                    m.totalContributionPaise,
                                  ),
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
                                    m.allocatedProfitPaise,
                                  ),
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
                                          color: m.status ==
                                                  AppConstants.statusActive
                                              ? AppColors.danger
                                              : AppColors.positive,
                                        ),
                                        tooltip: m.status ==
                                                AppConstants.statusActive
                                            ? 'Deactivate Member'
                                            : 'Activate Member',
                                        onPressed: () async {
                                          final newStatus = m.status ==
                                                  AppConstants.statusActive
                                              ? AppConstants.statusInactive
                                              : AppConstants.statusActive;
                                          await ref
                                              .read(appRepositoryProvider)
                                              .updateMemberStatus(
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
