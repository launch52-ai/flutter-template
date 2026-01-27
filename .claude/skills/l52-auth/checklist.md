# Auth Implementation Checklist

Complete verification checklist for base authentication setup.

---

## Directory Structure

- [ ] `lib/features/auth/` directory exists
- [ ] `lib/features/auth/data/models/` exists
- [ ] `lib/features/auth/data/repositories/` exists
- [ ] `lib/features/auth/domain/failures/` exists
- [ ] `lib/features/auth/domain/repositories/` exists
- [ ] `lib/features/auth/presentation/providers/` exists
- [ ] `lib/features/auth/presentation/screens/` exists
- [ ] `lib/features/auth/i18n/` exists

---

## Domain Layer

### Repository Interface

- [ ] `auth_repository.dart` exists in `domain/repositories/`
- [ ] `AuthRepository` interface defined
- [ ] `getCurrentUser()` method declared
- [ ] `signOut()` method declared
- [ ] `authStateChanges` stream declared
- [ ] `isAuthenticated` getter declared
- [ ] `refreshSession()` method declared

### Failures

- [ ] `auth_failures.dart` exists in `domain/failures/`
- [ ] `AuthFailure` sealed class extends core `Failure`
- [ ] `AuthSessionExpiredFailure` defined
- [ ] `AuthNotAuthenticatedFailure` defined
- [ ] `AuthNetworkFailure` defined
- [ ] `AuthServerFailure` defined
- [ ] `AuthUnknownFailure` defined

---

## Data Layer

### Models

- [ ] `user_profile.dart` exists in `data/models/`
- [ ] `UserProfile` is a Freezed class
- [ ] Required fields: `id` (String)
- [ ] Optional fields: `email`, `displayName`, `avatarUrl`, `phoneNumber`
- [ ] `fromJson` factory exists
- [ ] `fromSupabaseUser` factory helper exists

- [ ] `auth_result.dart` exists in `data/models/`
- [ ] `AuthResult` is a Freezed class
- [ ] Contains `user: UserProfile`
- [ ] Contains `isNewUser: bool`
- [ ] Contains `method: AuthMethod?`

### Repositories

- [ ] `auth_repository_impl.dart` exists in `data/repositories/`
- [ ] Implements `AuthRepository`
- [ ] Uses `SupabaseClient` (or your backend client)
- [ ] All methods handle exceptions and map to failures
- [ ] `authStateChanges` properly maps Supabase events

- [ ] `mock_auth_repository.dart` exists in `data/repositories/`
- [ ] Implements `AuthRepository`
- [ ] Configurable via constructor (mockUser, shouldFail, delay)
- [ ] Factory constructors for common scenarios
- [ ] Test helpers (simulateSignIn, simulateSignOut)

---

## Presentation Layer

### Providers

- [ ] `auth_state.dart` exists in `presentation/providers/`
- [ ] `AuthState` is a Freezed sealed class
- [ ] States: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`
- [ ] `AuthAuthenticated` has `user` and `isNewUser` fields
- [ ] State helper extensions exist (isAuthenticated, user, etc.)

- [ ] `auth_provider.dart` exists in `presentation/providers/`
- [ ] `AuthNotifier` extends `_$AuthNotifier` (Riverpod codegen)
- [ ] `_disposed` flag for disposal safety
- [ ] `_safeSetState` method uses disposal check
- [ ] `build()` sets up disposal, checks initial state, listens to changes
- [ ] `signOut()` method implemented
- [ ] `refreshSession()` method implemented
- [ ] `clearError()` method implemented

### Screens

- [ ] `login_screen.dart` exists in `presentation/screens/`
- [ ] Uses `ConsumerWidget`
- [ ] Watches `authNotifierProvider`
- [ ] Shows loading state
- [ ] Handles error state with snackbar
- [ ] Has placeholder for auth buttons (or actual buttons if methods added)

---

## Integration

### Router

- [ ] `/login` route added to `app_router.dart`
- [ ] Login route points to `LoginScreen`
- [ ] Redirect logic protects authenticated routes
- [ ] Redirect sends unauthenticated users to login

### Providers Registration

- [ ] `authRepositoryProvider` is defined
- [ ] Uses mock in debug mode, real impl otherwise
- [ ] Provider is accessible app-wide

---

## Code Generation

- [ ] `dart run build_runner build` executed
- [ ] `user_profile.freezed.dart` generated
- [ ] `user_profile.g.dart` generated
- [ ] `auth_result.freezed.dart` generated
- [ ] `auth_state.freezed.dart` generated
- [ ] `auth_provider.g.dart` generated
- [ ] No build_runner errors

---

## Functional Tests

### Initial State

- [ ] App shows login screen when not authenticated
- [ ] App shows home screen when authenticated
- [ ] Auth state persists across app restart

### Sign Out

- [ ] Sign out clears user data
- [ ] Sign out redirects to login
- [ ] Sign out handles network errors gracefully

### Error Handling

- [ ] Network errors show appropriate message
- [ ] Server errors show appropriate message
- [ ] Session expired triggers re-auth flow
- [ ] Error state can be cleared

### Loading States

- [ ] Loading indicator shows during auth operations
- [ ] UI is disabled during loading
- [ ] Loading state properly transitions to success/error

---

## Auth Methods (After Running Specific Skills)

### Social Login (if using /social-login)

- [ ] `signInWithGoogle()` method in AuthNotifier
- [ ] `signInWithApple()` method in AuthNotifier
- [ ] `SocialAuthRepository` interface implemented
- [ ] `SocialLoginButton` widget available
- [ ] Social buttons added to LoginScreen

### Phone Auth (if using /phone-auth)

- [ ] `PhoneAuthRepository` interface exists
- [ ] `PhoneAuthNotifier` exists
- [ ] `countries.json` in assets
- [ ] Phone formatting utils available
- [ ] Phone auth screens exist

### Email Auth (if implementing)

- [ ] `EmailAuthRepository` interface implemented
- [ ] `signInWithEmail()` method in AuthNotifier
- [ ] `signUpWithEmail()` method in AuthNotifier
- [ ] Email form added to LoginScreen (or separate screen)

---

## i18n Strings

- [ ] `/i18n auth` run
- [ ] `auth.welcome` string exists
- [ ] `auth.sign_in_to_continue` string exists
- [ ] `auth.buttons.*` strings exist
- [ ] `auth.errors.*` strings exist
- [ ] Strings use slang format (t.auth.*)

---

## Verification Commands

```bash
# Check feature structure
ls -la lib/features/auth/

# Check generated files
ls lib/features/auth/**/*.g.dart lib/features/auth/**/*.freezed.dart

# Run build_runner
dart run build_runner build --delete-conflicting-outputs

# Check for compile errors
flutter analyze

# Run tests (after /testing)
flutter test test/features/auth/

# Check i18n coverage (after /i18n)
dart run .claude/skills/i18n/scripts/check.dart --audit auth
```

---

## Common Issues

| Issue | Check |
|-------|-------|
| Provider not found | Run `dart run build_runner build` |
| Import errors | Check relative import paths |
| State not updating | Verify `ref.watch` vs `ref.read` |
| Mock not working | Check `DebugConstants.useMockAuth` value |
| Supabase errors | Verify `.env` has correct credentials |

---

## Next Steps

After completing this checklist:

1. **Add auth methods:** `/social-login`, `/phone-auth`
2. **Add i18n:** `/i18n auth`
3. **Write tests:** `/testing auth`
4. **Polish UI:** `/design`
5. **Accessibility:** `/a11y`
