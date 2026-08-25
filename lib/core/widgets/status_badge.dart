import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    Color bg;
    Color fg;

    switch (upper) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'ACTIVE':
        bg = AppColors.positiveBg;
        fg = AppColors.positive;
        break;
      case 'PENDING':
      case 'PROCESSING':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      default:
        bg = AppColors.infoBg;
        fg = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
