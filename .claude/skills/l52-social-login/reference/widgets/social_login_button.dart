// Template: Social Login Button Widget
//
// Location: lib/core/widgets/social_login_button.dart
//
// A reusable button for social login providers.
// Follows platform conventions for styling.
//
// Required assets (copy from skill assets to lib/assets/icons/):
//   - assets/icons/google.svg
//   - assets/icons/apple.svg
//
// Add to pubspec.yaml:
//   flutter_svg: ^2.0.10+1
//
//   flutter:
//     assets:
//       - assets/icons/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Social login provider types.
enum SocialProvider { google, apple }

/// A branded button for social login providers.
///
/// Follows platform design guidelines:
/// - Google: Outlined style with official Google "G" logo
/// - Apple: Filled black/white based on theme with Apple logo
///
/// Usage:
/// ```dart
/// SocialLoginButton(
///   provider: SocialProvider.google,
///   onPressed: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
///   isLoading: isLoading,
/// )
/// ```
final class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final SocialProvider provider;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _getBackgroundColor(isDark),
          foregroundColor: _getForegroundColor(isDark),
          side: _getBorderSide(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getForegroundColor(isDark),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(isDark),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return SvgPicture.asset(
          'assets/icons/google.svg',
          width: 20,
          height: 20,
        );
      case SocialProvider.apple:
        return SvgPicture.asset(
          'assets/icons/apple.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            _getForegroundColor(isDark),
            BlendMode.srcIn,
          ),
        );
    }
  }

  Color _getBackgroundColor(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return Colors.transparent;
      case SocialProvider.apple:
        return isDark ? Colors.white : Colors.black;
    }
  }

  Color _getForegroundColor(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return isDark ? Colors.white : Colors.black87;
      case SocialProvider.apple:
        return isDark ? Colors.black : Colors.white;
    }
  }

  BorderSide _getBorderSide(bool isDark) {
    switch (provider) {
      case SocialProvider.google:
        return BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
        );
      case SocialProvider.apple:
        return BorderSide.none;
    }
  }
}
