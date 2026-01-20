// Template: Local auth settings provider
//
// Location: lib/core/providers/local_auth_settings.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'local_auth_settings.freezed.dart';
part 'local_auth_settings.g.dart';

/// Settings state for local authentication.
@freezed
class LocalAuthSettingsState with _$LocalAuthSettingsState {
  const factory LocalAuthSettingsState({
    /// Whether local auth is enabled by user.
    @Default(false) bool enabled,

    /// Minutes in background before requiring re-auth.
    /// 0 = immediate (every resume)
    /// -1 = never (only on fresh launch)
    @Default(5) int timeoutMinutes,
  }) = _LocalAuthSettingsState;
}

/// Timeout options to display in settings UI.
enum AuthTimeout {
  immediate(0, 'Immediately'),
  oneMinute(1, '1 minute'),
  fiveMinutes(5, '5 minutes'),
  fifteenMinutes(15, '15 minutes'),
  thirtyMinutes(30, '30 minutes'),
  oneHour(60, '1 hour'),
  never(-1, 'Never');

  final int minutes;
  final String label;

  const AuthTimeout(this.minutes, this.label);

  /// Find timeout option by minutes value.
  static AuthTimeout fromMinutes(int minutes) {
    return AuthTimeout.values.firstWhere(
      (t) => t.minutes == minutes,
      orElse: () => AuthTimeout.fiveMinutes,
    );
  }
}

/// Manages local auth settings persistence.
@riverpod
class LocalAuthSettings extends _$LocalAuthSettings {
  static const _enabledKey = 'local_auth_enabled';
  static const _timeoutKey = 'local_auth_timeout_minutes';

  @override
  Future<LocalAuthSettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();

    return LocalAuthSettingsState(
      enabled: prefs.getBool(_enabledKey) ?? false,
      timeoutMinutes: prefs.getInt(_timeoutKey) ?? 5,
    );
  }

  /// Enable or disable local auth.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(enabled: enabled));
    }
  }

  /// Set timeout in minutes.
  ///
  /// 0 = immediate (every resume)
  /// -1 = never (only on fresh launch)
  Future<void> setTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeoutKey, minutes);

    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(timeoutMinutes: minutes));
    }
  }

  /// Clear all settings (call on logout).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enabledKey);
    await prefs.remove(_timeoutKey);

    state = const AsyncData(LocalAuthSettingsState());
  }
}
