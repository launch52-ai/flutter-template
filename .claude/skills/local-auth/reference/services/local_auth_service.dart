// Template: Local authentication service
//
// Location: lib/core/services/local_auth_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports as needed
// 3. Register as provider

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

/// Result of a local authentication attempt.
final class LocalAuthResult {
  final bool success;
  final bool isCancelled;
  final bool isLockout;
  final bool isNotEnrolled;
  final bool isNotAvailable;
  final String? errorMessage;

  const LocalAuthResult._({
    required this.success,
    this.isCancelled = false,
    this.isLockout = false,
    this.isNotEnrolled = false,
    this.isNotAvailable = false,
    this.errorMessage,
  });

  factory LocalAuthResult.success() => const LocalAuthResult._(success: true);

  factory LocalAuthResult.cancelled() => const LocalAuthResult._(
        success: false,
        isCancelled: true,
      );

  factory LocalAuthResult.lockout() => const LocalAuthResult._(
        success: false,
        isLockout: true,
        errorMessage: 'Too many failed attempts. Please try again later.',
      );

  factory LocalAuthResult.notEnrolled() => const LocalAuthResult._(
        success: false,
        isNotEnrolled: true,
        errorMessage: 'No biometrics enrolled on this device.',
      );

  factory LocalAuthResult.notAvailable() => const LocalAuthResult._(
        success: false,
        isNotAvailable: true,
        errorMessage: 'Biometric authentication is not available.',
      );

  factory LocalAuthResult.failed([String? message]) => LocalAuthResult._(
        success: false,
        errorMessage: message ?? 'Authentication failed.',
      );
}

/// Service wrapping local_auth package for device authentication.
///
/// Supports:
/// - Face ID (iOS)
/// - Touch ID (iOS)
/// - Fingerprint (Android)
/// - Face unlock (Android)
/// - Device credentials (PIN/pattern/password) as fallback
final class LocalAuthService {
  final LocalAuthentication _localAuth;

  LocalAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Check if device supports any form of local authentication.
  ///
  /// Returns true if device has biometric hardware OR device credentials set up.
  Future<bool> isDeviceSupported() async {
    return _localAuth.isDeviceSupported();
  }

  /// Check if biometrics can be used.
  ///
  /// Returns true only if:
  /// - Device has biometric hardware
  /// - User has enrolled at least one biometric
  Future<bool> canCheckBiometrics() async {
    return _localAuth.canCheckBiometrics;
  }

  /// Check if any authentication method is available.
  ///
  /// This is the main check to use before showing auth option.
  /// Returns true if either biometrics OR device credentials are available.
  Future<bool> canAuthenticate() async {
    final canBiometric = await canCheckBiometrics();
    final deviceSupported = await isDeviceSupported();
    return canBiometric || deviceSupported;
  }

  /// Get list of available biometric types.
  ///
  /// Returns empty list if no biometrics enrolled.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate user with biometrics and/or device credentials.
  ///
  /// [reason] - Message shown to user explaining why auth is needed.
  /// [biometricOnly] - If false (default), allows PIN/pattern fallback.
  /// [stickyAuth] - If true, auth dialog survives app going to background.
  ///
  /// Returns [LocalAuthResult] with success/failure details.
  /// Cancellation is NOT an error - check [LocalAuthResult.isCancelled].
  Future<LocalAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          useErrorDialogs: true,
        ),
      );

      return authenticated
          ? LocalAuthResult.success()
          : LocalAuthResult.cancelled();
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Stop any ongoing authentication.
  ///
  /// Call this when navigating away or when auth is no longer needed.
  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  LocalAuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notEnrolled:
        return LocalAuthResult.notEnrolled();

      case auth_error.notAvailable:
        return LocalAuthResult.notAvailable();

      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return LocalAuthResult.lockout();

      case auth_error.passcodeNotSet:
        return LocalAuthResult.notAvailable();

      default:
        return LocalAuthResult.failed(e.message);
    }
  }
}

// ===========================================================================
// PROVIDER REGISTRATION
// ===========================================================================

// Add to lib/core/providers.dart:
//
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import '../services/local_auth_service.dart';
//
// @riverpod
// LocalAuthService localAuthService(Ref ref) => LocalAuthService();
