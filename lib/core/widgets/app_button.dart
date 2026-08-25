import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isLoading;
  final IconData? icon;
  final double? height;
  final double? width;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.icon,
    this.height = 48.0,
    this.width,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.0;
    final minSize = Size(width ?? 0, effectiveHeight);

    if (isSecondary) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(context, AppColors.textPrimary),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: minSize,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(context, Colors.white),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    final effectiveFontSize = fontSize ?? 14.5;
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
        fontSize: effectiveFontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
