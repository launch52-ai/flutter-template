// Template: Root wrapper widget for connectivity monitoring
//
// Location: lib/core/widgets/connectivity_wrapper.dart
//
// Usage:
// 1. Copy to target location
// 2. Wrap MaterialApp with this widget in main.dart
// 3. Banner will automatically show/hide based on connectivity

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Update imports to match your project structure
import '../providers/connectivity_provider.dart';
import 'connectivity_banner.dart';

/// Wrapper widget that displays an offline banner when device loses connectivity.
///
/// Place this widget above [MaterialApp] in the widget tree to ensure
/// the banner appears above all other content.
///
/// Example:
/// ```dart
/// ConnectivityWrapper(
///   child: MaterialApp(
///     // ...
///   ),
/// )
/// ```
final class ConnectivityWrapper extends ConsumerWidget {
  const ConnectivityWrapper({
    required this.child,
    super.key,
  });

  /// The child widget, typically [MaterialApp].
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          _BannerAnimator(isVisible: !isOnline),
        ],
      ),
    );
  }
}

/// Internal widget that handles banner animation.
final class _BannerAnimator extends StatefulWidget {
  const _BannerAnimator({required this.isVisible});

  final bool isVisible;

  @override
  State<_BannerAnimator> createState() => _BannerAnimatorState();
}

final class _BannerAnimatorState extends State<_BannerAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_BannerAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: const ConnectivityBanner(),
    );
  }
}
