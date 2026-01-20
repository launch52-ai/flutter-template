// Template: VersionInfo entity for force update feature
//
// Location: lib/features/force_update/domain/entities/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run build_runner to generate freezed code

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/update_status.dart';

part 'version_info.freezed.dart';

/// Domain entity representing version information from the backend.
@freezed
class VersionInfo with _$VersionInfo {
  const factory VersionInfo({
    /// The latest available app version.
    required String currentVersion,

    /// Minimum version for soft update prompt.
    required String minimumVersion,

    /// Minimum version that forces update (blocks app).
    required String forceMinimumVersion,

    /// URL to the app store for this platform.
    required String storeUrl,

    /// Whether maintenance mode is enabled.
    required bool maintenanceMode,

    /// Optional maintenance message to display.
    String? maintenanceMessage,

    /// Optional release notes for the new version.
    String? releaseNotes,

    /// The determined update status based on version comparison.
    required UpdateStatus status,
  }) = _VersionInfo;

  const VersionInfo._();

  /// Factory for creating an "up to date" instance (used as fallback).
  factory VersionInfo.upToDate() => const VersionInfo(
        currentVersion: '0.0.0',
        minimumVersion: '0.0.0',
        forceMinimumVersion: '0.0.0',
        storeUrl: '',
        maintenanceMode: false,
        status: UpdateStatus.upToDate,
      );
}
