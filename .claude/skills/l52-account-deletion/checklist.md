# Account Deletion Checklist

Verification checklist for App Store, Play Store, and GDPR compliant account deletion.

---

## Quick Validation

```bash
dart run .claude/skills/account-deletion/scripts/check.dart
```

---

## Domain Layer

- [ ] `AccountDeletionFailure` sealed class exists
  - [ ] `AccountDeletionNetworkFailure` variant
  - [ ] `AccountDeletionServerFailure` variant
  - [ ] `AccountDeletionAuthFailure` variant
  - [ ] `AccountDeletionConfirmationFailure` variant (if using typed confirmation)
- [ ] Repository interface has `deleteAccount()` method
- [ ] Return type is `Future<Either<AccountDeletionFailure, void>>`

---

## Data Layer

- [ ] Repository implementation exists
- [ ] Backend deletion implemented:
  - [ ] Supabase: Edge function or admin API call
  - [ ] Firebase: `FirebaseAuth.currentUser?.delete()`
  - [ ] Custom: DELETE endpoint called
- [ ] User data cleanup:
  - [ ] SecureStorage cleared (tokens, PII)
  - [ ] SharedPreferences user data cleared
  - [ ] Analytics user ID reset
- [ ] Auth sign-out called after deletion
- [ ] Error handling for all failure cases

---

## Presentation Layer

### Notifier

- [ ] `AccountDeletionNotifier` exists
- [ ] Uses disposal-safe pattern (`_disposed` flag)
- [ ] Has proper states (initial, loading, success, error)
- [ ] Calls repository `deleteAccount()`
- [ ] Handles all failure types

### Widgets

- [ ] `DeleteAccountButton` widget exists
  - [ ] Danger styling (red color)
  - [ ] Opens confirmation dialog on tap
  - [ ] Listens to notifier state
- [ ] `DeleteAccountDialog` widget exists
  - [ ] Warning text explains consequences
  - [ ] Confirmation method implemented
  - [ ] Cancel button works
  - [ ] Delete button triggers deletion
  - [ ] `barrierDismissible: false` set
  - [ ] Loading state during deletion

### Settings Screen

- [ ] Delete account option visible in settings
- [ ] Located in "Danger Zone" or similar section
- [ ] Visually separated from other options
- [ ] Easy to find (App Store requirement)

---

## UX Requirements

- [ ] **Discoverability:** Easy to find in Settings
- [ ] **Clarity:** Clear explanation of what will be deleted
- [ ] **Confirmation:** Explicit user action required
- [ ] **Feedback:** Loading indicator during deletion
- [ ] **Error handling:** User-friendly error messages
- [ ] **Success:** Clear navigation away from app (to login)

---

## Compliance

### App Store Requirements (Apple)

- [ ] Account deletion option exists in app settings
- [ ] Option is easy to find
- [ ] Complete account deletion (not just deactivation)
- [ ] Works without contacting support

### Play Store Requirements (Google)

- [ ] In-app deletion option (cannot be web-only)
- [ ] Clear explanation of what data will be deleted
- [ ] User can request deletion of all associated data
- [ ] Deletion request processed within reasonable timeframe

### GDPR Requirements

- [ ] All user data deleted from backend
- [ ] Clear consent for deletion obtained
- [ ] Deletion is complete and permanent
- [ ] (Optional) Data export available before deletion

---

## Localization

- [ ] All strings use slang (`t.settings.deleteAccount.*`)
- [ ] Warning text is clear and translated
- [ ] Confirmation prompt is translated
- [ ] Button labels are translated
- [ ] Error messages are translated

---

## Testing

Run `/testing settings` to generate tests for the deletion flow.

**Manual verification:**
- [ ] Delete account from fresh install
- [ ] Cannot sign back in after deletion
- [ ] Backend data actually deleted

---

## Security

- [ ] Rate limiting on deletion endpoint
- [ ] Audit logging for deletions
- [ ] Re-authentication required (if high-security app)
- [ ] No PII retained after deletion
- [ ] Confirmation email sent (optional)

---

## Common Issues

| Issue | Check |
|-------|-------|
| Dialog dismissed accidentally | `barrierDismissible: false` set? |
| Data remains after deletion | All storage cleared? |
| User not authenticated error | Auth check before deletion? |
| Network error not handled | All failure types mapped? |
| Stuck on loading | Disposal check after async? |
