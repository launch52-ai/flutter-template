# Android In-App Updates Guide

Implement seamless updates using Android's Play Core In-App Updates API.

## Overview

Android In-App Updates allows users to download and install updates without leaving your app. iOS does not have an equivalent API - users must visit the App Store.

### Update Types

| Type | Behavior | UX | When to Use |
|------|----------|----|----|
| **Flexible** | Downloads in background | Non-blocking, user continues using app | Minor updates, new features |
| **Immediate** | Full-screen, blocks app | User must wait for download | Critical fixes, security updates |

## Setup

### 1. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  in_app_update: ^4.2.3  # Check for latest version
```

### 2. Requirements

- Android app must be published on Play Store
- User's device must have Play Store installed
- App must be downloaded from Play Store (not sideloaded)
- Minimum Android API 21 (Android 5.0)

**Important:** In-App Updates will NOT work with:
- Debug builds
- APKs installed via `adb install`
- Apps from other stores (Amazon, Samsung, etc.)

## Implementation

### Service Wrapper

Create a service to abstract the `in_app_update` plugin:

```dart
// lib/core/services/in_app_update_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum InAppUpdateType { flexible, immediate }

enum InAppUpdateStatus {
  updateNotAvailable,
  updateAvailable,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
}

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

  /// Start a flexible (background) update.
  /// User can continue using app while downloading.
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
}
```

### Flexible Update Flow

```dart
// 1. Check for update
final updateInfo = await inAppUpdateService.checkForUpdate();

if (updateInfo == null) {
  // Not on Android or check failed - fallback to store redirect
  return;
}

if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
  // 2. Start download in background
  final started = await inAppUpdateService.startFlexibleUpdate();

  if (started) {
    // 3. Show snackbar when download completes
    // The plugin will notify when ready
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded'),
        action: SnackBarAction(
          label: 'Install',
          onPressed: () async {
            // 4. Install (restarts app)
            await inAppUpdateService.completeFlexibleUpdate();
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}
```

### Immediate Update Flow

```dart
// 1. Check for update
final updateInfo = await inAppUpdateService.checkForUpdate();

if (updateInfo == null) {
  // Fallback to store redirect
  await openStore(storeUrl);
  return;
}

if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
  // 2. Start immediate update (blocks UI)
  final success = await inAppUpdateService.startImmediateUpdate();

  if (!success) {
    // Update was cancelled or failed - show force update screen
    // or redirect to store
  }
  // If success, app will restart automatically
}
```

## Choosing Update Type

### Decision Matrix

| Scenario | Update Type | Reason |
|----------|-------------|--------|
| Security vulnerability | Immediate | User safety is priority |
| Breaking API change | Immediate | App won't function |
| Major version (X.0.0) | Immediate | Significant changes |
| New features | Flexible | Non-urgent |
| Bug fixes | Flexible | Can wait |
| Performance improvements | Flexible | Nice to have |

### Hybrid Strategy

Use your backend to control which type:

```dart
// In your version check response, include update strategy
final class VersionInfo {
  final UpdateStatus status;
  final InAppUpdateType? androidUpdateType; // flexible or immediate
  final String storeUrl;
  // ...
}

// Then use it
if (Platform.isAndroid && versionInfo.androidUpdateType != null) {
  switch (versionInfo.androidUpdateType!) {
    case InAppUpdateType.flexible:
      await inAppUpdateService.startFlexibleUpdate();
    case InAppUpdateType.immediate:
      await inAppUpdateService.startImmediateUpdate();
  }
} else {
  // iOS or Android without in-app update
  await openStore(versionInfo.storeUrl);
}
```

## Download Progress

For flexible updates, show download progress:

```dart
// Using a stream to track download progress
StreamSubscription? _downloadSubscription;

void _startFlexibleUpdate() async {
  // Listen to download progress
  _downloadSubscription = InAppUpdate.flexibleUpdateStream.listen(
    (status) {
      switch (status.status) {
        case InstallStatus.downloading:
          final progress = status.bytesDownloaded / status.totalBytesToDownload;
          ref.read(downloadProgressProvider.notifier).state = progress;
        case InstallStatus.downloaded:
          // Show "Install" prompt
          _showInstallPrompt();
        case InstallStatus.failed:
          // Fallback to store
          _openStore();
        default:
          break;
      }
    },
  );

  await InAppUpdate.startFlexibleUpdate();
}

@override
void dispose() {
  _downloadSubscription?.cancel();
  super.dispose();
}
```

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `ERROR_API_NOT_AVAILABLE` | Play Store too old | Fallback to store redirect |
| `ERROR_INVALID_REQUEST` | Request not properly formed | Check implementation |
| `ERROR_DOWNLOAD_NOT_PRESENT` | Completing update without download | Wait for download |
| `ERROR_INTERNAL_ERROR` | Play Store internal issue | Retry or fallback |
| `ERROR_INSTALL_UNAVAILABLE` | Device incompatible | Fallback to store |

### Graceful Degradation

Always have a fallback:

```dart
Future<void> triggerUpdate({
  required String storeUrl,
  required bool useImmediateUpdate,
}) async {
  // Try in-app update first (Android only)
  if (Platform.isAndroid) {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (useImmediateUpdate) {
          await InAppUpdate.performImmediateUpdate();
          return; // Success - app will restart
        } else {
          await InAppUpdate.startFlexibleUpdate();
          return; // Success - downloading in background
        }
      }
    } catch (e) {
      debugPrint('In-app update failed, falling back to store: $e');
    }
  }

  // Fallback: Open store URL
  await openStore(storeUrl);
}
```

## Testing

### Test on Physical Device

In-app updates only work on physical devices with:
1. App installed from Play Store
2. New version published to Play Store (or internal testing track)

### Internal Testing Track

For testing before production:
1. Upload new version to Internal Testing track
2. Add test devices to Internal Testing
3. Wait ~10 minutes for propagation
4. Test update flow

### Mock for Development

Create a mock for debug builds:

```dart
final class MockInAppUpdateService implements InAppUpdateService {
  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Simulate update available
    return MockAppUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      availableVersionCode: 2,
    );
  }

  @override
  Future<bool> startFlexibleUpdate() async {
    // Simulate download delay
    await Future.delayed(const Duration(seconds: 3));
    return true;
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    // In mock, just print
    debugPrint('Mock: Would restart app for update');
  }

  @override
  Future<bool> startImmediateUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
```

## Checklist

**Setup:**
- [ ] `in_app_update` package added
- [ ] App published to Play Store (any track)
- [ ] Minimum Android SDK 21

**Implementation:**
- [ ] `InAppUpdateService` wrapper created
- [ ] Flexible update flow implemented
- [ ] Immediate update flow implemented
- [ ] Download progress UI (flexible)
- [ ] Install prompt after download

**Error Handling:**
- [ ] Fallback to store URL on failure
- [ ] Handle update cancellation
- [ ] Log errors for debugging

**Testing:**
- [ ] Tested on physical device
- [ ] Tested via Internal Testing track
- [ ] Mock service for development
