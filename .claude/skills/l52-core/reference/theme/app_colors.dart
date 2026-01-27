// Template: App Colors (ThemeExtension)
//
// Location: lib/core/theme/app_colors.dart
//
// Features:
// - ThemeExtension for automatic light/dark support
// - Access via context.colors extension
// - Proper copyWith and lerp for animations

import 'package:flutter/material.dart';

/// App color palette using ThemeExtension for automatic light/dark support.
///
/// Usage:
/// ```dart
/// final colors = Theme.of(context).extension<AppColors>()!;
/// // Or with extension:
/// final colors = context.colors;
/// ```
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.muted,
    required this.mutedForeground,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color muted;
  final Color mutedForeground;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// Light theme colors.
  /// TODO: Replace primary color (0xFF2D9D78) with your brand color.
  static const light = AppColors(
    primary: Color(0xFF2D9D78),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFECECF0),
    secondaryForeground: Color(0xFF424245),
    background: Color(0xFFFAFBFC),
    surface: Color(0xFFF5F5F5),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF262629),
    textSecondary: Color(0xFF727272),
    textTertiary: Color(0xFF8F8F8F),
    border: Color(0xFFE5E5E5),
    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF727272),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFC0483D),
    info: Color(0xFF3B82F6),
  );

  /// Dark theme colors.
  static const dark = AppColors(
    primary: Color(0xFF4FBB9F),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF262629),
    secondaryForeground: Color(0xFFF2F2F2),
    background: Color(0xFF141416),
    surface: Color(0xFF1F1F24),
    card: Color(0xFF1F1F24),
    textPrimary: Color(0xFFFAF8F5),
    textSecondary: Color(0xFFA0A0A0),
    textTertiary: Color(0xFF8F8F8F),
    border: Color(0xFF2A2A2A),
    muted: Color(0xFF262629),
    mutedForeground: Color(0xFF8F8F8F),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFE65A4D),
    info: Color(0xFF3B82F6),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Extension for convenient access to AppColors.
extension AppColorsExtension on BuildContext {
  /// Access app colors via `context.colors`.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
