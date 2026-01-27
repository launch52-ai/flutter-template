// Template: Offline banner widget
//
// Location: lib/core/widgets/connectivity_banner.dart
//
// Usage:
// 1. Copy to target location
// 2. Run /i18n to localize the message
// 3. Run /design to customize styling

import 'package:flutter/material.dart';

/// A banner displayed at the top of the screen when device is offline.
///
/// Appears with a slide-down animation and displays a message
/// indicating no internet connection.
final class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    this.message = 'No internet connection',
    this.backgroundColor,
    this.textColor,
    this.icon = Icons.wifi_off,
  });

  /// Message displayed in the banner.
  final String message;

  /// Background color of the banner.
  final Color? backgroundColor;

  /// Text and icon color.
  final Color? textColor;

  /// Icon displayed before the message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.error;
    final fgColor = textColor ?? theme.colorScheme.onError;

    return Material(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: fgColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
