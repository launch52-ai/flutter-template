# Architecture Reference

This document defines the established architecture patterns for the Flutter template. Feature specs build on these patterns.

---

## Common Patterns

| Aspect | Pattern |
|--------|---------|
| **Architecture** | Clean Architecture + DDD |
| **State Management** | Riverpod 3.x AsyncNotifier |
| **Code Generation** | Freezed + JSON Serializable + Riverpod Generator |
| **Routing** | GoRouter with StatefulShellRoute |
| **HTTP Client** | Dio with auth interceptors |
| **Storage** | SecureStorage (PII) + SharedPrefs (flags) |
| **Auth Backend** | Supabase with PKCE flow |
| **Theme** | Material 3, platform-neutral (no ripples) |

---

## Feature Module Structure

Each feature follows Clean Architecture:

```
feature/
├── data/
│   ├── models/          # Freezed DTOs
│   └── repositories/    # Concrete implementations
├── domain/
│   └── repositories/    # Abstract interfaces
├── i18n/
│   ├── *.i18n.yaml      # Feature strings (slang)
│   └── *.g.dart         # Generated
└── presentation/
    ├── providers/       # Riverpod notifiers
    ├── screens/         # Full-screen widgets
    └── widgets/         # Reusable components
```

---

## Riverpod AsyncNotifier Pattern

Disposal-safe pattern for async state management:

```dart
@riverpod
final class ExampleNotifier extends _$ExampleNotifier {
  bool _disposed = false;

  @override
  ExampleState build() {
    _disposed = false;
    ref.onDispose(() { _disposed = true; });
    return const ExampleState.initial();
  }

  void _safeSetState(ExampleState newState) {
    if (!_disposed) state = newState;
  }

  Future<void> doSomething() async {
    _safeSetState(const ExampleState.loading());
    final result = await someAsyncOperation();
    if (_disposed) return; // Check after await
    _safeSetState(ExampleState.success(result));
  }
}
```

---

## Storage Strategy

| Data Type | Storage | Example |
|-----------|---------|---------|
| **Tokens** | SecureStorage | access_token, refresh_token |
| **PII** | SecureStorage | user_id, email, name |
| **Flags** | SharedPrefs | has_user, theme_mode |

---

## Dio Client

- Base URL from `.env` file
- Auth interceptor adds Bearer token
- Error interceptor handles 401 + token refresh
- Logging interceptor (debug only)

---

## GoRouter Setup

- Initial route based on: onboarding → auth → dashboard
- StatefulShellRoute for bottom navigation (preserves tab state)
- Full-screen routes outside shell (no bottom nav)

---

## Theme System

- Material 3 enabled
- Platform-neutral: No ripples, iOS transitions everywhere
- Light/Dark mode support via Riverpod provider
- AppColors, AppTypography, AppTheme classes

---

## Code Style

- Keep classes `final` where possible
- Keep functions `private` where possible
- Use `final` for variables where possible
- Screen files: 100-200 lines max
- Extract widgets when files exceed 200 lines
- One class per file (except small helpers)
- All TextFields: `autocorrect: false`
- No hardcoded strings → use slang (`t.feature.key`)
- No hardcoded colors → use `AppColors` or `Theme.of(context)`

---

## Core Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── storage_keys.dart
│   │   └── debug_constants.dart
│   ├── i18n/
│   │   ├── common.i18n.yaml
│   │   └── translations.g.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── dio_client.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── navigation/
│   │   └── main_shell.dart
│   ├── services/
│   │   ├── secure_storage_service.dart
│   │   ├── shared_prefs_service.dart
│   │   └── supabase_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── utils/
│   ├── widgets/
│   └── providers.dart
└── features/
```
