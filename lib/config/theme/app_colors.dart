import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B6B4A); // Deep Emerald
  static const Color primaryLight = Color(0xFF2D9166);
  static const Color primaryDark = Color(0xFF124A33);

  static const Color secondary = Color(0xFFF5A623); // Gold
  static const Color secondaryLight = Color(0xFFF7BB55);
  static const Color secondaryDark = Color(0xFFD4881A);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF8F0); // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EFE7);

  static const Color dark = Color(0xFF1A1A2E); // Deep navy
  static const Color darkMedium = Color(0xFF2D2D44);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFD1D5DB);
  static const Color greyExtraLight = Color(0xFFF3F4F6);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE85D4A);
  static const Color errorLight = Color(0xFFFFEDEB);
  static const Color success = Color(0xFF4ADE80);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1A1A2E);

  // ── Overlays ─────────────────────────────────────────────────────────────
  static const Color overlay = Color(0x801A1A2E);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);

  // ── Badge ────────────────────────────────────────────────────────────────
  static const Color badgeFree = Color(0xFF4ADE80);
  static const Color badgeFreeText = Color(0xFF166534);
  static const Color badgePaid = Color(0xFFF5A623);
  static const Color badgePaidText = Color(0xFF7C3F00);
}
