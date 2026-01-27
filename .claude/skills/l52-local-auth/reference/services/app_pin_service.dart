// Template: App-level PIN service
//
// Location: lib/core/services/app_pin_service.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. Use for devices without biometric/device lock
//
// IMPORTANT: This is for devices that have NO lock screen at all.
// For most apps, device credentials (biometric + PIN) are sufficient.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for app-level PIN authentication.
///
/// Use this for:
/// - Devices without any lock screen
/// - Apps on shared devices (family tablet)
/// - Additional security layer beyond device lock
///
/// SECURITY NOTE: PIN is stored as SHA-256 hash in secure storage.
/// For production banking apps, consider bcrypt or Argon2.
final class AppPinService {
  final FlutterSecureStorage _storage;

  static const _pinHashKey = 'app_pin_hash';
  static const _pinAttemptsKey = 'app_pin_attempts';
  static const _pinLockoutKey = 'app_pin_lockout_until';

  /// Maximum failed attempts before lockout.
  static const maxAttempts = 5;

  /// Lockout duration after max attempts.
  static const lockoutDuration = Duration(minutes: 5);

  AppPinService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Check if app PIN is set up.
  Future<bool> isPinEnabled() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Set up app PIN.
  ///
  /// [pin] should be at least 4 digits.
  /// Returns false if PIN doesn't meet requirements.
  Future<bool> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      return false;
    }

    final hash = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hash);
    await _clearAttempts();
    return true;
  }

  /// Verify app PIN.
  ///
  /// Returns [PinVerifyResult] with success/failure details.
  Future<PinVerifyResult> verifyPin(String pin) async {
    // Check lockout
    final lockoutUntil = await _getLockoutUntil();
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now());
      return PinVerifyResult.lockedOut(remaining);
    }

    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) {
      return PinVerifyResult.notSet();
    }

    final inputHash = _hashPin(pin);

    if (storedHash == inputHash) {
      await _clearAttempts();
      return PinVerifyResult.success();
    }

    // Wrong PIN - track attempt
    final attempts = await _incrementAttempts();
    final remaining = maxAttempts - attempts;

    if (remaining <= 0) {
      // Lock out
      await _setLockout();
      return PinVerifyResult.lockedOut(lockoutDuration);
    }

    return PinVerifyResult.failed(remaining);
  }

  /// Change PIN (requires current PIN verification).
  Future<bool> changePin(String currentPin, String newPin) async {
    final verifyResult = await verifyPin(currentPin);
    if (!verifyResult.success) {
      return false;
    }

    return setPin(newPin);
  }

  /// Clear PIN (call on logout).
  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _clearAttempts();
  }

  /// Check if currently locked out.
  Future<bool> isLockedOut() async {
    final lockoutUntil = await _getLockoutUntil();
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }

  /// Get remaining lockout duration.
  Future<Duration?> getLockoutRemaining() async {
    final lockoutUntil = await _getLockoutUntil();
    if (lockoutUntil == null) return null;

    final now = DateTime.now();
    if (now.isAfter(lockoutUntil)) return null;

    return lockoutUntil.difference(now);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _isValidPin(String pin) {
    // At least 4 digits
    if (pin.length < 4) return false;

    // Only digits
    if (!RegExp(r'^\d+$').hasMatch(pin)) return false;

    // Not all same digit (1111)
    if (pin.split('').toSet().length == 1) return false;

    // Not sequential (1234, 4321)
    if (_isSequential(pin)) return false;

    return true;
  }

  bool _isSequential(String pin) {
    final digits = pin.split('').map(int.parse).toList();

    bool ascending = true;
    bool descending = true;

    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i - 1] + 1) ascending = false;
      if (digits[i] != digits[i - 1] - 1) descending = false;
    }

    return ascending || descending;
  }

  String _hashPin(String pin) {
    // SHA-256 hash
    // For production, consider bcrypt with salt
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<int> _incrementAttempts() async {
    final current = await _getAttempts();
    final next = current + 1;
    await _storage.write(key: _pinAttemptsKey, value: next.toString());
    return next;
  }

  Future<int> _getAttempts() async {
    final value = await _storage.read(key: _pinAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  Future<void> _clearAttempts() async {
    await _storage.delete(key: _pinAttemptsKey);
    await _storage.delete(key: _pinLockoutKey);
  }

  Future<void> _setLockout() async {
    final until = DateTime.now().add(lockoutDuration);
    await _storage.write(key: _pinLockoutKey, value: until.toIso8601String());
  }

  Future<DateTime?> _getLockoutUntil() async {
    final value = await _storage.read(key: _pinLockoutKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}

/// Result of PIN verification.
final class PinVerifyResult {
  final bool success;
  final bool isLockedOut;
  final bool isNotSet;
  final int? attemptsRemaining;
  final Duration? lockoutRemaining;

  const PinVerifyResult._({
    required this.success,
    this.isLockedOut = false,
    this.isNotSet = false,
    this.attemptsRemaining,
    this.lockoutRemaining,
  });

  factory PinVerifyResult.success() => const PinVerifyResult._(success: true);

  factory PinVerifyResult.failed(int remaining) => PinVerifyResult._(
        success: false,
        attemptsRemaining: remaining,
      );

  factory PinVerifyResult.lockedOut(Duration remaining) => PinVerifyResult._(
        success: false,
        isLockedOut: true,
        lockoutRemaining: remaining,
      );

  factory PinVerifyResult.notSet() => const PinVerifyResult._(
        success: false,
        isNotSet: true,
      );
}
