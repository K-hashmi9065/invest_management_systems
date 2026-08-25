// lib/core/theme/app_colors.dart
//
// Centralized color tokens — dark, modern fintech palette
// (Stripe/Linear-inspired). Never hardcode a color literal
// outside this file.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Surfaces — layered near-black, not pure black
  static const Color surfacePage = Color(0xFF0B0E14);
  static const Color surfaceCard = Color(0xFF12161F);
  static const Color surfaceElevated = Color(0xFF1C2128);
  static const Color surfaceHover = Color(0xFF1A1F28);

  // Borders — hairline, not shadows
  static const Color border = Color(0xFF232833);
  static const Color borderStrong = Color(0xFF2E3542);

  // Text
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF6B7280);

  // Semantic accents — one meaning each, used sparingly
  static const Color positive = Color(0xFF5DCAA5); // approved / profit / up
  static const Color positiveBg = Color(0xFF1C3A2E);
  static const Color warning = Color(0xFFEF9F27); // pending / review
  static const Color warningBg = Color(0xFF3A2A1C);
  static const Color danger = Color(0xFFE24B4A); // rejected / loss
  static const Color dangerBg = Color(0xFF3A1C1C);
  static const Color info = Color(0xFF378ADD); // neutral / investment
  static const Color infoBg = Color(0xFF1C2838);

  // Brand accent — sparing use, primary CTAs only
  static const Color accent = Color(0xFF7F77DD);
}
