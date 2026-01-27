// Template: Main Shell (Bottom Navigation)
//
// Location: lib/core/navigation/main_shell.dart
//
// Usage:
// 1. Copy to target location
// 2. Configure tabs based on features
// 3. Use with StatefulShellRoute in app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main shell with bottom navigation.
/// Preserves tab state using StatefulShellRoute.
///
/// Example usage in router:
/// ```dart
/// StatefulShellRoute.indexedStack(
///   builder: (context, state, navigationShell) {
///     return MainShell(navigationShell: navigationShell);
///   },
///   branches: [...],
/// )
/// ```
final class MainShell extends StatelessWidget {
  const MainShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home', // TODO: Use t.navigation.home
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile', // TODO: Use t.navigation.profile
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings', // TODO: Use t.navigation.settings
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Navigate to initial route when tapping current tab
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

// Alternative: BottomNavigationBar (Material 2 style)
//
// final class MainShellAlt extends StatelessWidget {
//   const MainShellAlt({
//     required this.navigationShell,
//     super.key,
//   });
//
//   final StatefulNavigationShell navigationShell;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: navigationShell,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: navigationShell.currentIndex,
//         onTap: _onDestinationSelected,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             activeIcon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             activeIcon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _onDestinationSelected(int index) {
//     navigationShell.goBranch(
//       index,
//       initialLocation: index == navigationShell.currentIndex,
//     );
//   }
// }
