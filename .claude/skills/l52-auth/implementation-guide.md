# Auth Implementation Guide

Step-by-step guide to implementing the base authentication feature.

---

## Overview

The `/auth` skill creates the foundation that specific auth methods build upon:

```
/auth (this skill)
├── Creates: AuthRepository, AuthNotifier, AuthState, UserProfile, LoginScreen
│
├── /social-login
│   └── Adds: signInWithGoogle, signInWithApple, SocialLoginButton
│
└── /phone-auth
    └── Adds: PhoneAuthRepository, PhoneAuthNotifier, country picker
```

---

## Step 1: Create Directory Structure

```bash
mkdir -p lib/features/auth/{data/{models,repositories},domain/{failures,repositories},presentation/{providers,screens},i18n}
```

Result:
```
lib/features/auth/
├── data/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── failures/
│   └── repositories/
├── presentation/
│   ├── providers/
│   └── screens/
└── i18n/
```

---

## Step 2: Copy Domain Layer

### 2.1 Auth Repository Interface

Copy `reference/repositories/auth_repository.dart` to:
```
lib/features/auth/domain/repositories/auth_repository.dart
```

This defines the base contract for authentication operations.

### 2.2 Auth Failures

Copy `reference/failures/auth_failures.dart` to:
```
lib/features/auth/domain/failures/auth_failures.dart
```

Update the import for core Failure:
```dart
import '../../../../core/errors/failures.dart';
```

---

## Step 3: Copy Data Layer

### 3.1 Models

Copy from `reference/models/`:
- `user_profile.dart` → `lib/features/auth/data/models/`
- `auth_result.dart` → `lib/features/auth/data/models/`

### 3.2 Repository Implementation

Copy `reference/repositories/auth_repository_impl.dart` to:
```
lib/features/auth/data/repositories/auth_repository_impl.dart
```

Update imports:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/auth_failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';
```

### 3.3 Mock Repository

Copy `reference/repositories/mock_auth_repository.dart` to:
```
lib/features/auth/data/repositories/mock_auth_repository.dart
```

---

## Step 4: Copy Presentation Layer

### 4.1 Auth State

Copy `reference/providers/auth_state.dart` to:
```
lib/features/auth/presentation/providers/auth_state.dart
```

### 4.2 Auth Provider

Copy `reference/providers/auth_provider.dart` to:
```
lib/features/auth/presentation/providers/auth_provider.dart
```

Update the repository provider to use your actual implementation:
```dart
@riverpod
AuthRepository authRepository(Ref ref) {
  if (DebugConstants.useMockAuth) {
    return MockAuthRepository.authenticated();
  }
  return AuthRepositoryImpl(Supabase.instance.client);
}
```

### 4.3 Login Screen

Copy `reference/screens/login_screen.dart` to:
```
lib/features/auth/presentation/screens/login_screen.dart
```

---

## Step 5: Register in Core

### 5.1 Add Route

In `lib/core/router/app_router.dart`:

```dart
import '../../features/auth/presentation/screens/login_screen.dart';

// Inside routes list:
GoRoute(
  path: '/login',
  name: 'login',
  builder: (context, state) => const LoginScreen(),
),
```

### 5.2 Add Redirect Logic

```dart
redirect: (context, state) {
  final authState = ref.read(authNotifierProvider);
  final isLoggedIn = authState.isAuthenticated;
  final isLoggingIn = state.matchedLocation == '/login';

  if (!isLoggedIn && !isLoggingIn) {
    return '/login';
  }
  if (isLoggedIn && isLoggingIn) {
    return '/'; // or '/dashboard'
  }
  return null;
},
```

---

## Step 6: Run Build

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `user_profile.freezed.dart`
- `user_profile.g.dart`
- `auth_result.freezed.dart`
- `auth_state.freezed.dart`
- `auth_provider.g.dart`

---

## Step 7: Add Auth Methods

Based on your selection, run the appropriate skills:

### Social Login (Google + Apple)

```bash
/social-login
```

This will:
1. Add `signInWithGoogle()` and `signInWithApple()` to AuthNotifier
2. Add `SocialAuthRepository` interface
3. Create `SocialLoginButton` widget
4. Configure platform files (Info.plist, AndroidManifest.xml)

### Phone OTP

```bash
/phone-auth
```

This will:
1. Create `PhoneAuthRepository` and `PhoneAuthNotifier`
2. Add phone input and OTP screens
3. Add countries.json data
4. Add phone formatting utilities

### Email/Password

If using email auth, add to `AuthRepositoryImpl`:

```dart
// In auth_repository_impl.dart, add EmailAuthRepository to implements:
final class AuthRepositoryImpl implements AuthRepository, EmailAuthRepository {
  // ...

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }
}
```

Add provider methods:

```dart
// In auth_provider.dart
Future<void> signInWithEmail(String email, String password) async {
  _safeSetState(const AuthState.loading());

  try {
    final repository = ref.read(authRepositoryProvider) as EmailAuthRepository;
    await repository.signInWithEmail(email, password);

    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (_disposed) return;

    if (user != null) {
      _safeSetState(AuthState.authenticated(user: user));
    }
  } catch (e) {
    if (_disposed) return;
    _safeSetState(AuthState.error(ErrorUtils.getUserFriendlyMessage(e)));
  }
}
```

---

## Step 8: Add i18n

Run the i18n skill to add localized strings:

```bash
/i18n auth
```

Required strings:
```yaml
auth:
  welcome: "Welcome"
  sign_in_to_continue: "Sign in to continue"
  terms_and_privacy: "By continuing, you agree to our Terms of Service and Privacy Policy"

  buttons:
    continue_with_google: "Continue with Google"
    continue_with_apple: "Continue with Apple"
    continue_with_phone: "Continue with Phone"
    continue_with_email: "Continue with Email"
    sign_out: "Sign Out"

  errors:
    session_expired: "Your session has expired. Please sign in again."
    network: "Connection failed. Please check your internet."
    server: "Server error. Please try again later."
    unknown: "An unexpected error occurred."
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      LoginScreen                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │   │
│  │  │ Email Form   │  │ Social Btns  │  │ Phone Input  │       │   │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │   │
│  └─────────┼─────────────────┼─────────────────┼───────────────┘   │
└────────────┼─────────────────┼─────────────────┼───────────────────┘
             │                 │                 │
             ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     AuthNotifier                              │   │
│  │  signInWithEmail()  signInWithGoogle()  signInWithApple()    │   │
│  │  signOut()          refreshSession()    clearError()          │   │
│  │                                                               │   │
│  │  State: AuthState (initial|loading|authenticated|error)       │   │
│  └───────────────────────────────┬───────────────────────────────┘   │
└──────────────────────────────────┼──────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    AuthRepository                             │   │
│  │  getCurrentUser()  signOut()  authStateChanges  refreshSession│   │
│  └───────────────────────────────────────────────────────────────┘   │
│  ┌───────────────────┐ ┌──────────────────┐ ┌───────────────────┐   │
│  │SocialAuthRepository│ │PhoneAuthRepository│ │EmailAuthRepository│   │
│  │ signInWithGoogle() │ │ sendOtp()         │ │ signInWithEmail() │   │
│  │ signInWithApple()  │ │ verifyOtp()       │ │ signUpWithEmail() │   │
│  └───────────────────┘ └──────────────────┘ └───────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   AuthRepositoryImpl                          │   │
│  │  implements: AuthRepository + SocialAuth + PhoneAuth + Email  │   │
│  └───────────────────────────────┬───────────────────────────────┘   │
│                                  │                                   │
│  ┌───────────────┐  ┌────────────▼───────────┐  ┌───────────────┐   │
│  │  UserProfile  │  │      Supabase          │  │  AuthResult   │   │
│  │   (Freezed)   │  │    SupabaseClient      │  │   (Freezed)   │   │
│  └───────────────┘  └────────────────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Common Issues

### Issue: "authNotifierProvider is not found"

Ensure you ran `dart run build_runner build` after copying the provider file.

### Issue: State not updating after sign-in

Check that:
1. You're using `ref.watch(authNotifierProvider)` not `ref.read`
2. The repository is properly emitting auth state changes
3. The disposal flag `_disposed` isn't preventing updates

### Issue: Import errors

Verify import paths match your project structure. Common fixes:
- `../../../../core/...` for imports from feature to core
- `../../domain/...` for imports from data to domain

---

## Next Steps

After completing auth setup:

1. **Add specific auth methods:**
   - `/social-login` for Google + Apple
   - `/phone-auth` for phone OTP

2. **Add i18n strings:**
   - `/i18n auth`

3. **Write tests:**
   - `/testing auth`

4. **Polish UI:**
   - `/design` to review login screen

5. **Add accessibility:**
   - `/a11y` to audit auth screens
