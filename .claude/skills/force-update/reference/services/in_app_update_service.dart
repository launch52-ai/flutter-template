// Template: InAppUpdateService for Android In-App Updates
//
// Location: lib/core/services/
//
// Usage:
// 1. Copy to target location (Android only)
// 2. Add in_app_update package to pubspec.yaml
// 3. Run build_runner to generate riverpod code

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_update_service.g.dart';

/// Update type for Android In-App Updates.
enum InAppUpdateType {
  /// Downloads in background, user continues using app.
  flexible,

  /// Full-screen blocking UI until update completes.
  immediate,
}

/// Service wrapper for Android Play Store In-App Updates.
/// Returns null/false on iOS as it's not supported.
final class InAppUpdateService {
  /// Check if an update is available via Play Store.
  /// Returns null on iOS or if check fails.
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;

    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      debugPrint('In-app update check failed: $e');
      return null;
    }
  }

  /// Returns true if in-app update is available.
  Future<bool> isUpdateAvailable() async {
    final info = await checkForUpdate();
    return info?.updateAvailability == UpdateAvailability.updateAvailable;
  }

  /// Start a flexible (background) update.
  /// User can continue using app while downloading.
  /// Returns true if update started successfully.
  Future<bool> startFlexibleUpdate() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      debugPrint('Flexible update failed: $e');
      return false;
    }
  }

  /// Complete a flexible update after download finishes.
  /// This will restart the app.
  Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Complete flexible update failed: $e');
    }
  }

  /// Start an immediate (blocking) update.
  /// Shows full-screen UI, user cannot use app until done.
  /// Returns true if update completed successfully.
  Future<bool> startImmediateUpdate() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      debugPrint('Immediate update failed: $e');
      return false;
    }
  }

  /// Perform update based on type.
  /// Convenience method to choose between flexible and immediate.
  Future<bool> performUpdate(InAppUpdateType type) async {
    return switch (type) {
      InAppUpdateType.flexible => startFlexibleUpdate(),
      InAppUpdateType.immediate => startImmediateUpdate(),
    };
  }
}

@riverpod
InAppUpdateService inAppUpdateService(InAppUpdateServiceRef ref) {
  return InAppUpdateService();
}
