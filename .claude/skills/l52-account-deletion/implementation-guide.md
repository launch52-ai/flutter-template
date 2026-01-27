# Account Deletion Implementation Guide

Step-by-step guide for implementing App Store, Play Store, and GDPR compliant account deletion.

---

## Prerequisites

Before implementing account deletion:
- `/auth` skill completed (provides AuthRepository)
- Settings feature exists (or run `/feature-init settings`)
- Backend authentication configured (Supabase/Firebase/Custom)

---

## Phase 1: Domain Layer

### 1.1 Create AccountDeletionFailure

**Location:** `lib/features/settings/domain/failures/account_deletion_failure.dart`

**See:** `reference/failures/account_deletion_failure.dart`

Key failure types:
- `AccountDeletionNetworkFailure` - Connection issues
- `AccountDeletionServerFailure` - Backend errors
- `AccountDeletionAuthFailure` - User not authenticated
- `AccountDeletionConfirmationFailure` - Wrong confirmation input

### 1.2 Extend Repository Interface

Add to `lib/features/settings/domain/repositories/settings_repository.dart`:

```dart
/// Permanently deletes the user's account and all associated data.
/// Returns [AccountDeletionFailure] on error.
Future<Either<AccountDeletionFailure, void>> deleteAccount();
```

---

## Phase 2: Data Layer

### 2.1 Implement Repository Method

Add to `lib/features/settings/data/repositories/settings_repository_impl.dart`:

**See:** `reference/repositories/` for backend-specific implementations:
- `settings_repository_supabase.dart` - Supabase implementation
- `settings_repository_firebase.dart` - Firebase implementation
- `settings_repository_api.dart` - Custom API implementation

### 2.2 Data Cleanup

Ensure all user data is removed:

```dart
Future<void> _cleanupUserData() async {
  // Clear secure storage (tokens, PII)
  await _secureStorage.deleteAll();

  // Clear shared preferences (user flags)
  await _sharedPrefs.remove(StorageKeys.hasUser);
  await _sharedPrefs.remove(StorageKeys.userId);

  // Reset analytics user ID
  await _analytics.setUserId(null);
  await _analytics.resetAnalyticsData();
}
```

---

## Phase 3: Presentation Layer

### 3.1 Create AccountDeletionNotifier

**Location:** `lib/features/settings/presentation/providers/account_deletion_notifier.dart`

**See:** `reference/providers/account_deletion_notifier.dart`

Key features:
- Disposal-safe async state management
- Loading/success/error states
- Calls repository and handles cleanup

### 3.2 Create Confirmation Dialog

**Location:** `lib/features/settings/presentation/widgets/delete_account_dialog.dart`

**See:** `reference/widgets/delete_account_dialog.dart`

Dialog includes:
- Clear warning text explaining consequences
- Confirmation input (password, "DELETE", or checkbox)
- Cancel and Delete buttons
- Loading state during deletion

### 3.3 Create Delete Account Button

**Location:** `lib/features/settings/presentation/widgets/delete_account_button.dart`

**See:** `reference/widgets/delete_account_button.dart`

Button features:
- Danger styling (red text/border)
- Opens confirmation dialog
- Listens to deletion state

### 3.4 Integrate with Settings Screen

Add to `lib/features/settings/presentation/screens/settings_screen.dart`:

```dart
// In the settings list
const SizedBox(height: 32),
const Divider(),
const SizedBox(height: 16),
Text(
  t.settings.dangerZone,
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    color: AppColors.error,
  ),
),
const SizedBox(height: 8),
const DeleteAccountButton(),
```

---

## Phase 4: Navigation

### 4.1 Handle Success

After successful deletion, navigate to login:

```dart
ref.listen(accountDeletionNotifierProvider, (_, state) {
  state.whenOrNull(
    success: () {
      // Navigate to login and clear stack
      context.go('/login');
    },
  );
});
```

### 4.2 Handle Errors

Show appropriate error messages:

```dart
state.whenOrNull(
  error: (failure) {
    final message = switch (failure) {
      AccountDeletionNetworkFailure() => t.errors.networkError,
      AccountDeletionServerFailure() => t.errors.serverError,
      AccountDeletionAuthFailure() => t.errors.sessionExpired,
      AccountDeletionConfirmationFailure() => t.settings.wrongConfirmation,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  },
);
```

---

## Phase 5: Localization

Run `/i18n settings` to migrate hardcoded strings to i18n files.

The reference templates contain `// TODO: Use t.settings.xxx` comments indicating which strings need localization.

---

## Backend-Specific Notes

### Supabase

```dart
// Delete user via Supabase Auth Admin API (requires service role)
// OR use Edge Function for secure deletion
await supabase.functions.invoke('delete-user', body: {'userId': userId});

// Then sign out locally
await supabase.auth.signOut();
```

**Edge Function Example:** See `templates/supabase-delete-user-function.ts`

### Firebase

```dart
// Firebase Auth user deletion
await FirebaseAuth.instance.currentUser?.delete();

// Delete Firestore user document
await FirebaseFirestore.instance.collection('users').doc(userId).delete();
```

**Note:** Firebase requires recent authentication. Handle re-auth if needed.

### Custom API

```dart
// Call deletion endpoint
await dio.delete('/api/users/me');

// Clear local auth tokens
await secureStorage.delete(key: StorageKeys.accessToken);
await secureStorage.delete(key: StorageKeys.refreshToken);
```

---

## Testing Checklist

Manual testing steps:
1. Navigate to Settings > Delete Account
2. Tap "Delete My Account" button
3. Verify warning dialog appears
4. Cancel and verify nothing happens
5. Complete confirmation and tap Delete
6. Verify loading state shown
7. Verify navigation to login screen
8. Verify cannot sign back in with same credentials
9. Test error handling (disconnect network, etc.)

---

## Security Considerations

1. **Rate limiting:** Prevent deletion spam
2. **Audit logging:** Log deletion events server-side
3. **Grace period:** Consider 30-day soft delete before hard delete
4. **Re-authentication:** Require for high-security apps
5. **Email confirmation:** Send deletion confirmation email
