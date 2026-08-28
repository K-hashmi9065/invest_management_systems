import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../members/domain/member_model.dart';

class MemberShareChart extends StatelessWidget {
  final List<MemberModel> members;

  const MemberShareChart({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.chartPalette;
    final hasMembers = members.any((m) => m.contributionPercentage > 0);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member Contribution Share %',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: hasMembers
                    ? members.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        final color = colors[i % colors.length];
                        return PieChartSectionData(
                          color: color,
                          value: m.contributionPercentage > 0
                              ? m.contributionPercentage
                              : 0.1,
                          title:
                              '${m.name.split(' ').first}\n${m.contributionPercentage.toStringAsFixed(1)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList()
                    : [
                        PieChartSectionData(
                          color: AppColors.border,
                          value: 100,
                          title: 'Empty',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
