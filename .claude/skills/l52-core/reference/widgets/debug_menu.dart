// Template: Debug Menu
//
// Location: lib/core/widgets/debug_menu.dart
//
// Debug menu shown when shaking the device (development only).
// Features: Toggle mock mode, clear storage, view debug info.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/debug_constants.dart';
import '../theme/app_colors.dart';

/// Debug menu shown when shaking the device (development only).
///
/// Features:
/// - Toggle mock mode
/// - Clear storage
/// - View debug info
final class DebugMenu extends StatefulWidget {
  const DebugMenu({super.key});

  @override
  State<DebugMenu> createState() => _DebugMenuState();
}

final class _DebugMenuState extends State<DebugMenu> {
  bool _mockMode = DebugConstants.mockModeEnabled.value;

  @override
  void initState() {
    super.initState();
    DebugConstants.mockModeEnabled.addListener(_onMockModeChanged);
  }

  @override
  void dispose() {
    DebugConstants.mockModeEnabled.removeListener(_onMockModeChanged);
    super.dispose();
  }

  void _onMockModeChanged() {
    setState(() {
      _mockMode = DebugConstants.mockModeEnabled.value;
    });
  }

  Future<void> _toggleMockMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await DebugConstants.setMockMode(prefs, value);
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage cleared. Restart the app.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      title: const Text('Debug Menu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Mock Mode'),
            subtitle: const Text('Use fake data instead of API'),
            value: _mockMode,
            onChanged: _toggleMockMode,
            activeColor: colors.primary,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.error),
            title: const Text('Clear Storage'),
            subtitle: const Text('Clear all local data'),
            onTap: _clearStorage,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
