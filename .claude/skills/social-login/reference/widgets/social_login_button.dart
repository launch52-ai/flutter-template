// Template: Social Login Button Widget
//
// Location: lib/core/widgets/social_login_button.dart
//
// A reusable button for social login providers.
// Follows platform conventions for styling.

import 'dart:io';

import 'package:flutter/material.dart';

/// Social login provider types.
enum SocialProvider { google, apple }

/// A branded button for social login providers.
///
/// Follows platform design guidelines:
/// - Google: Outlined style with Google "G" icon
/// - Apple: Filled black/white based on theme
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
        return const _GoogleIcon();
      case SocialProvider.apple:
        return Icon(
          Icons.apple,
          size: 24,
          color: _getForegroundColor(isDark),
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

/// Google "G" logo icon.
///
/// Uses the official Google colors for the logo.
final class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Using a simple "G" text as placeholder
    // Replace with actual Google logo asset or SVG in production
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4), // Google Blue
          ),
        ),
      ),
    );
  }
}
