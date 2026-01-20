// Template: Repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Social Auth Methods for AuthRepositoryImpl
//
// Location: lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Add these methods and imports to your existing AuthRepositoryImpl.
// This template shows the social login implementation pattern.

// ===========================================================================
// IMPORTS TO ADD
// ===========================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your project files
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/social_auth_repository.dart';

// ===========================================================================
// CLASS DECLARATION
// ===========================================================================

// Add SocialAuthRepository to your implements clause:
// final class AuthRepositoryImpl implements AuthRepository, SocialAuthRepository

// ===========================================================================
// GOOGLE SIGN-IN
// ===========================================================================

@override
Future<AuthResult?> signInWithGoogle() async {
  final rawNonce = _generateRawNonce();
  final hashedNonce = _sha256ofString(rawNonce);

  // Initialize Google Sign-In
  // - serverClientId: Web Client ID (required for idToken on Android)
  // - clientId: iOS Client ID (required for iOS)
  await GoogleSignIn.instance.initialize(
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    clientId: Platform.isIOS ? dotenv.env['GOOGLE_IOS_CLIENT_ID'] : null,
    nonce: hashedNonce,
  );

  final googleUser = await GoogleSignIn.instance.signIn();
  if (googleUser == null) {
    return null; // User cancelled
  }

  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  if (idToken == null) {
    throw const AuthException('No ID token received from Google');
  }

  // Sign in to Supabase with the Google ID token
  final response = await _auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    nonce: rawNonce, // Raw nonce for Supabase to validate
  );

  await _persistSession(response.session);

  return AuthResult(
    user: _mapUser(response.user!),
    isNewUser: response.user?.createdAt == response.user?.updatedAt,
    accessToken: response.session?.accessToken,
    refreshToken: response.session?.refreshToken,
  );
}

// ===========================================================================
// APPLE SIGN-IN
// ===========================================================================

@override
Future<AuthResult?> signInWithApple() async {
  if (Platform.isIOS) {
    return _signInWithAppleNative();
  } else {
    return _signInWithAppleOAuth();
  }
}

/// Native Apple Sign-In for iOS.
///
/// Uses the native Sign in with Apple SDK for seamless
/// Face ID/Touch ID authentication.
Future<AuthResult?> _signInWithAppleNative() async {
  final rawNonce = _generateRawNonce();
  final hashedNonce = _sha256ofString(rawNonce);

  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: hashedNonce,
  );

  final idToken = credential.identityToken;
  if (idToken == null) {
    throw const AuthException('No identity token received from Apple');
  }

  final response = await _auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: idToken,
    nonce: rawNonce,
  );

  await _persistSession(response.session);

  // Apple only provides name on first sign-in - store it immediately
  final fullName = [
    credential.givenName,
    credential.familyName,
  ].where((n) => n != null && n.isNotEmpty).join(' ');

  if (fullName.isNotEmpty) {
    await _secureStorage.write(
      key: StorageKeys.userFullName,
      value: fullName,
    );
  }

  return AuthResult(
    user: _mapUser(response.user!),
    isNewUser: response.user?.createdAt == response.user?.updatedAt,
    accessToken: response.session?.accessToken,
    refreshToken: response.session?.refreshToken,
  );
}

/// OAuth flow for Apple Sign-In on Android.
///
/// Opens external browser for Apple authentication.
/// Throws [OAuthPendingException] to signal the app should
/// wait for the deep link callback.
Future<AuthResult?> _signInWithAppleOAuth() async {
  await _auth.signInWithOAuth(
    OAuthProvider.apple,
    redirectTo: '${AppConstants.deepLinkScheme}://login-callback',
  );

  // Signal that OAuth flow is pending
  // OAuthCallbackScreen will handle the completion
  throw const OAuthPendingException(
    'Apple Sign-In opened in browser. Waiting for callback...',
  );
}

// ===========================================================================
// NONCE HELPERS (see nonce_helpers.dart for detailed documentation)
// ===========================================================================

String _generateRawNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
