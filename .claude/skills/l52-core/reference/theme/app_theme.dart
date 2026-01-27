// Template: App Theme
//
// Location: lib/core/theme/app_theme.dart
//
// Features:
// - Material 3 enabled
// - Platform-neutral (no ripples, iOS transitions everywhere)
// - ThemeExtension for colors and typography
// - Complete button, input, and card themes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Theme configuration with light and dark modes.
///
/// Features:
/// - Material 3 enabled
/// - Platform-neutral (no ripples, iOS transitions everywhere)
/// - ThemeExtension for colors (`context.colors`) and typography (`context.typography`)
final class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(
        colors: AppColors.light,
        typography: AppTypography.standard,
        brightness: Brightness.light,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData get dark => _buildTheme(
        colors: AppColors.dark,
        typography: AppTypography.standard,
        brightness: Brightness.dark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData _buildTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    // Remove Material ripple effect for platform-neutral feel
    const noSplash = NoSplash.splashFactory;

    // iOS-style slide transitions on all platforms
    const pageTransitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      // ThemeExtensions for context.colors and context.typography
      extensions: [colors, typography],
      // Disable platform-specific effects (ripple, etc.)
      splashFactory: noSplash,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: colors.primary.withValues(alpha: 0.1),
      // Platform-neutral page transitions
      pageTransitionsTheme: pageTransitions,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.secondary,
        onSecondary: colors.secondaryForeground,
        surface: colors.background,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.border,
        error: colors.error,
        onError: colors.primaryForeground,
      ),
      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        displaySmall: typography.displaySmall,
        headlineLarge: typography.headlineLarge,
        headlineMedium: typography.headlineMedium,
        headlineSmall: typography.headlineSmall,
        titleLarge: typography.titleLarge,
        titleMedium: typography.titleMedium,
        titleSmall: typography.titleSmall,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
        labelLarge: typography.labelLarge,
        labelMedium: typography.labelMedium,
        labelSmall: typography.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: systemOverlayStyle,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          splashFactory: noSplash,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          splashFactory: noSplash,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          splashFactory: noSplash,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colors.primary.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          splashFactory: noSplash,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colors.primary.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: colors.primary.withValues(alpha: 0.1),
          splashFactory: noSplash,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
