// Template: Nonce/security helpers
//
// Location: lib/features/{feature}/data/utils/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: Nonce Generation Helpers
//
// Location: Add these methods to your AuthRepositoryImpl class
//
// These helpers generate and hash nonces for PKCE security in OAuth flows.
// The raw nonce goes to Supabase, the hashed nonce goes to the provider.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a cryptographically secure random nonce.
///
/// Used for PKCE security in OAuth flows:
/// 1. Generate raw nonce
/// 2. Hash it with SHA-256 for the provider (Google/Apple)
/// 3. Send raw nonce to Supabase for validation
///
/// [length] - Nonce length (default: 32 characters)
String _generateRawNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// SHA-256 hash of the input string.
///
/// The hashed nonce is sent to OAuth providers (Google/Apple).
/// They include it in the ID token, which Supabase validates
/// against the raw nonce.
String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// Usage example:
//
// final rawNonce = _generateRawNonce();
// final hashedNonce = _sha256ofString(rawNonce);
//
// // Send hashedNonce to provider
// await GoogleSignIn.instance.initialize(nonce: hashedNonce);
//
// // Send rawNonce to Supabase
// await supabase.auth.signInWithIdToken(nonce: rawNonce);
