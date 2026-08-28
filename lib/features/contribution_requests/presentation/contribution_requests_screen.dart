import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/horizontal_scrollable_table.dart';
import '../../../core/widgets/status_badge.dart';
import 'widgets/raise_contribution_request_dialog.dart';

class ContributionRequestsScreen extends ConsumerStatefulWidget {
  const ContributionRequestsScreen({super.key});

  @override
  ConsumerState<ContributionRequestsScreen> createState() =>
      _ContributionRequestsScreenState();
}

class _ContributionRequestsScreenState
    extends ConsumerState<ContributionRequestsScreen> {
  void _showRaiseRequestDialog(BuildContext context) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account is not linked to a member profile. Cannot raise request.',
          ),
        ),
      );
      return;
    }

    RaiseContributionRequestDialog.show(context, user);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(contributionRequestsProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }



    final isAdmin =
        user.role == AppConstants.roleAdmin ||
        user.role == AppConstants.roleSuperAdmin;

    // Set page title for AppShell
    Future.microtask(() => ref.read(pageTitleProvider.notifier).state =
        isAdmin ? 'Review Contribution Requests' : 'My Money Requests');

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
                            Text(
                              isAdmin
                                  ? 'Member Contribution Approval Queue'
                                  : 'Submitted Add Money Requests',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isAdmin)
                              AppButton(
                                text: 'Raise Request',
                                icon: Icons.add,
                                onPressed: () =>
                                    _showRaiseRequestDialog(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: AsyncValueWidget(
                            value: requestsAsync,
                            data: (requests) {
                              final filtered = isAdmin
                                  ? requests
                                  : requests
                                        .where(
                                          (r) => r.memberId == user.memberId,
                                        )
                                        .toList();

                              if (filtered.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No contribution requests pending.',
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
                                        DataColumn(label: Text('REQ ID')),
                                        DataColumn(label: Text('MEMBER')),
                                        DataColumn(label: Text('AMOUNT')),
                                        DataColumn(label: Text('MODE')),
                                        DataColumn(label: Text('REQUESTED AT')),
                                        DataColumn(label: Text('APPROVED BY')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('ACTION')),
                                      ],
                                      rows: filtered.map((req) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text('#${req.id}')),
                                            DataCell(
                                              Text(
                                                req.memberName,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                CurrencyFormatter.formatPaise(
                                                  req.amountPaise,
                                                ),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(req.paymentMode)),
                                            DataCell(
                                              Text(
                                                DateFormatter.formatDate(
                                                  DateTime.parse(
                                                    req.requestedAt,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(req.reviewedBy ?? '-')),
                                            DataCell(
                                              StatusBadge(status: req.status),
                                            ),
                                            DataCell(
                                              isAdmin &&
                                                      req.status ==
                                                          AppConstants
                                                              .statusPending
                                                  ? Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.check_circle,
                                                            color: AppColors
                                                                .positive,
                                                            size: 20,
                                                          ),
                                                          tooltip: 'Approve',
                                                          onPressed: () async {
                                                            try {
                                                              final repo = ref.read(
                                                                appRepositoryProvider,
                                                              );
                                                              await repo
                                                                  .reviewContributionRequest(
                                                                    requestId:
                                                                        req.id,
                                                                    approve:
                                                                        true,
                                                                    actionBy: user
                                                                        .username,
                                                                  );
                                                              refreshAllFinancialProviders(
                                                                ref,
                                                              );
                                                            } catch (e, st) {
                                                              final failure =
                                                                  FailureMapper.map(
                                                                    e,
                                                                    st,
                                                                  );
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      failure
                                                                          .userMessage,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.cancel,
                                                            color: AppColors
                                                                .danger,
                                                            size: 20,
                                                          ),
                                                          tooltip: 'Reject',
                                                          onPressed: () async {
                                                            try {
                                                              final repo = ref.read(
                                                                appRepositoryProvider,
                                                              );
                                                              await repo
                                                                  .reviewContributionRequest(
                                                                    requestId:
                                                                        req.id,
                                                                    approve:
                                                                        false,
                                                                    actionBy: user
                                                                        .username,
                                                                  );
                                                              refreshAllFinancialProviders(
                                                                ref,
                                                              );
                                                            } catch (e, st) {
                                                              final failure =
                                                                  FailureMapper.map(
                                                                    e,
                                                                    st,
                                                                  );
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      failure
                                                                          .userMessage,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    )
                                                   : const Text(
                                                       '-',
                                                       style: TextStyle(
                                                         color:
                                                             AppColors.textMuted,
                                                       ),
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
