# Update Dialogs Guide

Implementation patterns for force update, soft update, and maintenance screens.

## Dialog Types

### Force Update Screen

- **Non-dismissible:** User cannot bypass this screen
- **Single action:** Only "Update Now" button
- **No navigation:** Back button disabled via `PopScope(canPop: false)`

### Soft Update Dialog

- **Dismissible:** User can skip or remind later
- **Multiple actions:** "Update", "Remind Later", "Skip This Version"
- **Respectful frequency:** Don't show on every launch

### Maintenance Screen

- **Informative:** Show message from backend
- **No actions:** User can only wait
- **Auto-retry:** Periodically check if maintenance ended

## Soft Update Frequency

Implement smart frequency limits to avoid annoying users:

```dart
final class SoftUpdatePromptManager {
  static const _lastPromptKey = 'last_update_prompt';
  static const _skippedVersionKey = 'skipped_version';
  static const _promptCooldown = Duration(hours: 24);

  final SharedPreferences _prefs;

  /// Returns true if we should show the soft update prompt.
  Future<bool> shouldShowPrompt(String newVersion) async {
    // Never prompt for a version user explicitly skipped
    final skippedVersion = _prefs.getString(_skippedVersionKey);
    if (skippedVersion == newVersion) {
      return false;
    }

    // Check cooldown period
    final lastPrompt = _prefs.getInt(_lastPromptKey);
    if (lastPrompt != null) {
      final lastPromptTime = DateTime.fromMillisecondsSinceEpoch(lastPrompt);
      if (DateTime.now().difference(lastPromptTime) < _promptCooldown) {
        return false;
      }
    }

    return true;
  }

  Future<void> recordPromptShown() async {
    await _prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> recordVersionSkipped(String version) async {
    await _prefs.setString(_skippedVersionKey, version);
  }
}
```

### Prompt Behavior

| User Action | Next Prompt |
|-------------|-------------|
| Taps "Update" | Never (they updated) |
| Taps "Remind Later" | After 24 hours |
| Taps "Skip" | Never for this version |
| Dismisses dialog | After 24 hours |
| New version released | Reset all (show again) |

## Back Navigation Prevention

Force update and maintenance screens must prevent dismissal:

```dart
PopScope(
  canPop: false, // Prevent back navigation
  child: Scaffold(
    body: // ...
  ),
)
```

## Loading States

Show loading indicator when opening store:

```dart
bool _isLoading = false;

Future<void> _openStore() async {
  setState(() => _isLoading = true);

  try {
    await widget.onTap();
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

## Auto-Retry for Maintenance

Periodically check if maintenance ended:

```dart
Timer.periodic(const Duration(seconds: 30), (_) {
  if (_retryCount < _maxAutoRetries) {
    _checkMaintenanceStatus();
    _retryCount++;
  }
});
```

## Testing Checklist

- [ ] Force update: Back button does nothing
- [ ] Force update: Update button opens store
- [ ] Soft update: Can dismiss dialog
- [ ] Soft update: "Remind Later" sets cooldown
- [ ] Soft update: "Skip" blocks version
- [ ] Maintenance: Auto-retries periodically

## Next Steps

After implementing dialogs:
1. `/i18n` - Localize all user-facing strings
2. `/design` - Polish UI, loading states, visual feedback
3. `/a11y` - Add semantic labels, ensure contrast
