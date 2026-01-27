// Template: Loading Button
//
// Location: lib/core/widgets/loading_button.dart
//
// A filled button that shows a loading indicator when isLoading is true.

import 'package:flutter/material.dart';

/// A filled button that shows a loading indicator when [isLoading] is true.
final class LoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;

  const LoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
