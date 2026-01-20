// Template: Biometric state tracker for banking-grade security
//
// Location: lib/core/services/biometric_state_tracker.dart
//
// Usage:
// 1. Copy to target location
// 2. Update imports
// 3. For iOS: Add platform channel for evaluatedPolicyDomainState
// 4. For Android: Implement Keystore-backed key generation
//
// PURPOSE: Detect when biometrics change (new fingerprint/face added)
// and require full re-authentication for banking-grade security.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks biometric enrollment state for banking-grade security.
///
/// Detects when:
/// - New fingerprint/face is added
/// - Existing fingerprint/face is removed
///
/// On iOS: Uses LAContext.evaluatedPolicyDomainState
/// On Android: Uses Keystore key invalidation
///
/// SECURITY: When biometrics change, the app should require full
/// re-authentication (username/password or social login) to prevent
/// unauthorized access by someone who adds their fingerprint to the device.
final class BiometricStateTracker {
  final FlutterSecureStorage _storage;
  final MethodChannel _channel;

  static const _stateHashKey = 'biometric_state_hash';
  static const _channelName = 'com.yourapp/biometric_state';

  BiometricStateTracker({
    FlutterSecureStorage? storage,
    MethodChannel? channel,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _channel = channel ?? const MethodChannel(_channelName);

  /// Check if biometrics have changed since last save.
  ///
  /// Returns true if:
  /// - New fingerprint/face was added
  /// - Existing fingerprint/face was removed
  /// - First time checking (no stored state)
  ///
  /// Returns false if:
  /// - Biometrics unchanged
  /// - Unable to check (device doesn't support)
  Future<bool> didBiometricsChange() async {
    try {
      if (Platform.isIOS) {
        return _checkiOSBiometricState();
      } else if (Platform.isAndroid) {
        return _checkAndroidBiometricState();
      }
      return false;
    } catch (e) {
      // If we can't check, assume no change
      return false;
    }
  }

  /// Save current biometric state.
  ///
  /// Call this after successful authentication to establish baseline.
  Future<void> saveCurrentState() async {
    try {
      if (Platform.isIOS) {
        await _saveiOSBiometricState();
      } else if (Platform.isAndroid) {
        await _createAndroidAuthBoundKey();
      }
    } catch (e) {
      // Ignore errors - best effort
    }
  }

  /// Clear stored biometric state.
  ///
  /// Call this on logout to reset tracking.
  Future<void> clearState() async {
    await _storage.delete(key: _stateHashKey);
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('deleteAuthBoundKey');
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // iOS Implementation
  // ---------------------------------------------------------------------------

  Future<bool> _checkiOSBiometricState() async {
    final currentState = await _getiOSBiometricDomainState();

    if (currentState == null) {
      // No biometrics enrolled
      return false;
    }

    final storedHash = await _storage.read(key: _stateHashKey);

    if (storedHash == null) {
      // First time - treat as "changed" to force initial save
      return true;
    }

    final currentHash = _hashState(currentState);
    return currentHash != storedHash;
  }

  Future<void> _saveiOSBiometricState() async {
    final currentState = await _getiOSBiometricDomainState();
    if (currentState != null) {
      final hash = _hashState(currentState);
      await _storage.write(key: _stateHashKey, value: hash);
    }
  }

  /// Get iOS LAContext.evaluatedPolicyDomainState via platform channel.
  ///
  /// Returns base64-encoded opaque data that changes when biometrics change.
  Future<String?> _getiOSBiometricDomainState() async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getBiometricDomainState',
      );
      return result;
    } on PlatformException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Android Implementation
  // ---------------------------------------------------------------------------

  Future<bool> _checkAndroidBiometricState() async {
    try {
      // Try to use the auth-bound key
      // If biometrics changed, key is permanently invalidated
      final isValid = await _channel.invokeMethod<bool>('checkAuthBoundKey');
      return isValid == false; // Changed if key is invalid
    } on PlatformException catch (e) {
      if (e.code == 'KEY_PERMANENTLY_INVALIDATED') {
        return true; // Biometrics changed
      }
      return false;
    }
  }

  Future<void> _createAndroidAuthBoundKey() async {
    try {
      await _channel.invokeMethod('createAuthBoundKey');
    } catch (_) {
      // Ignore errors
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _hashState(String state) {
    final bytes = utf8.encode(state);
    return sha256.convert(bytes).toString();
  }
}

// =============================================================================
// PLATFORM CHANNEL SETUP
// =============================================================================

// iOS (Swift) - AppDelegate.swift or separate file:
//
// import LocalAuthentication
//
// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     let controller = window?.rootViewController as! FlutterViewController
//     let channel = FlutterMethodChannel(
//       name: "com.yourapp/biometric_state",
//       binaryMessenger: controller.binaryMessenger
//     )
//
//     channel.setMethodCallHandler { (call, result) in
//       if call.method == "getBiometricDomainState" {
//         let context = LAContext()
//         var error: NSError?
//
//         if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
//           if let domainState = context.evaluatedPolicyDomainState {
//             result(domainState.base64EncodedString())
//           } else {
//             result(nil)
//           }
//         } else {
//           result(nil)
//         }
//       } else {
//         result(FlutterMethodNotImplemented)
//       }
//     }
//
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

// Android (Kotlin) - MainActivity.kt:
//
// import android.security.keystore.KeyGenParameterSpec
// import android.security.keystore.KeyProperties
// import android.security.keystore.KeyPermanentlyInvalidatedException
// import io.flutter.embedding.android.FlutterFragmentActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import java.security.KeyStore
// import javax.crypto.KeyGenerator
// import javax.crypto.SecretKey
//
// class MainActivity: FlutterFragmentActivity() {
//   private val CHANNEL = "com.yourapp/biometric_state"
//   private val KEY_NAME = "biometric_auth_key"
//
//   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//     super.configureFlutterEngine(flutterEngine)
//
//     MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
//       .setMethodCallHandler { call, result ->
//         when (call.method) {
//           "createAuthBoundKey" -> {
//             createKey()
//             result.success(true)
//           }
//           "checkAuthBoundKey" -> {
//             try {
//               getKey()
//               result.success(true) // Key valid
//             } catch (e: KeyPermanentlyInvalidatedException) {
//               result.error("KEY_PERMANENTLY_INVALIDATED", "Biometrics changed", null)
//             }
//           }
//           "deleteAuthBoundKey" -> {
//             deleteKey()
//             result.success(true)
//           }
//           else -> result.notImplemented()
//         }
//       }
//   }
//
//   private fun createKey() {
//     val keyGenerator = KeyGenerator.getInstance(
//       KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
//     )
//     keyGenerator.init(
//       KeyGenParameterSpec.Builder(
//         KEY_NAME,
//         KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
//       )
//       .setBlockModes(KeyProperties.BLOCK_MODE_CBC)
//       .setUserAuthenticationRequired(true)
//       .setInvalidatedByBiometricEnrollment(true) // Key point!
//       .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7)
//       .build()
//     )
//     keyGenerator.generateKey()
//   }
//
//   private fun getKey(): SecretKey {
//     val keyStore = KeyStore.getInstance("AndroidKeyStore")
//     keyStore.load(null)
//     return keyStore.getKey(KEY_NAME, null) as SecretKey
//   }
//
//   private fun deleteKey() {
//     val keyStore = KeyStore.getInstance("AndroidKeyStore")
//     keyStore.load(null)
//     keyStore.deleteEntry(KEY_NAME)
//   }
// }
