import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    // Set page title for AppShell
    Future.microtask(() => ref.read(pageTitleProvider.notifier).state = 'Security & System Audit Logs');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Immutable Action Audit Trail',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AsyncValueWidget(
              value: logsAsync,
              data: (logs) {
                              if (logs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No audit logs recorded yet.',
                                    style:
                                        TextStyle(color: AppColors.textMuted),
                                  ),
                                );
                              }

                              return AppCard(
                                padding: EdgeInsets.zero,
                                child: HorizontalScrollableTable(
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('LOG ID')),
                                      DataColumn(label: Text('USERNAME')),
                                      DataColumn(label: Text('ACTION')),
                                      DataColumn(label: Text('DETAILS')),
                                      DataColumn(label: Text('TIMESTAMP')),
                                    ],
                                    rows: logs.map((log) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('#${log.id}')),
                                          DataCell(Text(
                                            log.username,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                log.action,
                                                style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(log.details)),
                                          DataCell(Text(
                                            DateFormatter.formatDateTime(
                                              DateTime.parse(log.timestamp),
                                            ),
                                          )),
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
                  );
  }
}
