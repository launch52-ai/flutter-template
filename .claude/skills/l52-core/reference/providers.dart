// Template: Core Providers
//
// Location: lib/core/providers.dart
//
// Usage:
// 1. Copy to target location
// 2. Export all providers from this file
// 3. Add feature-specific providers as features are created

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'services/secure_storage_service.dart';
import 'services/shared_prefs_service.dart';

// Conditionally import based on project setup:
// import 'services/supabase_service.dart';
// import 'network/dio_client.dart';

part 'providers.g.dart';

// ============================================================================
// Theme Providers
// ============================================================================

/// Theme mode provider.
/// Persists user preference to SharedPreferences.
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadSavedMode();
    return ThemeMode.system;
  }

  Future<void> _loadSavedMode() async {
    final prefs = ref.read(sharedPrefsProvider);
    final saved = prefs.getString(_key);

    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_key, mode.name);
  }

  void toggleTheme() {
    final newMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    setThemeMode(newMode);
  }
}

// ============================================================================
// Lifecycle Providers
// ============================================================================

/// App lifecycle state provider.
/// Useful for pausing/resuming operations.
@riverpod
class AppLifecycleNotifier extends _$AppLifecycleNotifier {
  @override
  AppLifecycleState build() {
    return AppLifecycleState.resumed;
  }

  void updateState(AppLifecycleState state) {
    this.state = state;
  }
}

// ============================================================================
// Export Services
// ============================================================================

// Services are exported via their own providers:
// - secureStorageProvider (from secure_storage_service.dart)
// - sharedPrefsProvider (from shared_prefs_service.dart)
// - supabaseClientProvider (from supabase_service.dart)
// - dioClientProvider (from dio_client.dart)
// - routerProvider (from app_router.dart)

// ============================================================================
// Example: Repository Provider Pattern
// ============================================================================

// When adding feature repositories, follow this pattern:
//
// @riverpod
// AuthRepository authRepository(Ref ref) {
//   if (DebugConstants.useMockAuth) {
//     return MockAuthRepository();
//   }
//
//   // Choose implementation based on backend
//   final supabase = ref.watch(supabaseClientProvider);
//   return AuthRepositoryImpl(supabase);
//
//   // OR for custom API:
//   // final dio = ref.watch(dioClientProvider);
//   // return AuthRepositoryImpl(dio);
// }
