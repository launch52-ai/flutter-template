// Template: AppVersionService for version checking
//
// Location: lib/core/services/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Configure Supabase table name if different
// 4. Run build_runner to generate riverpod code

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/force_update/data/models/version_info_dto.dart';
import '../../features/force_update/domain/entities/version_info.dart';
import '../../features/force_update/domain/enums/update_status.dart';

part 'app_version_service.g.dart';

/// Service for checking app version against backend requirements.
final class AppVersionService {
  AppVersionService(this._supabase);

  final SupabaseClient _supabase;

  /// Fetch version info from Supabase and determine update status.
  Future<VersionInfo> checkVersion() async {
    // Get current app version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Determine platform
    final platform = Platform.isIOS ? 'ios' : 'android';

    // Fetch version requirements from Supabase
    final response = await _supabase
        .from('app_versions')
        .select()
        .eq('platform', platform)
        .single();

    final dto = VersionInfoDto.fromJson(response);

    // Determine update status
    final status = _determineStatus(
      currentVersion: currentVersion,
      minimumVersion: dto.minimumVersion,
      forceMinimumVersion: dto.forceMinimumVersion,
      maintenanceMode: dto.maintenanceMode,
    );

    return VersionInfo(
      currentVersion: dto.currentVersion,
      minimumVersion: dto.minimumVersion,
      forceMinimumVersion: dto.forceMinimumVersion,
      storeUrl: dto.storeUrl,
      maintenanceMode: dto.maintenanceMode,
      maintenanceMessage: dto.maintenanceMessage,
      releaseNotes: dto.releaseNotes,
      status: status,
    );
  }

  /// Safe version check with timeout and fallback.
  Future<VersionInfo> checkVersionSafely({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      return await checkVersion().timeout(
        timeout,
        onTimeout: () => VersionInfo.upToDate(),
      );
    } catch (e) {
      debugPrint('Version check failed: $e');
      return VersionInfo.upToDate();
    }
  }

  UpdateStatus _determineStatus({
    required String currentVersion,
    required String minimumVersion,
    required String forceMinimumVersion,
    required bool maintenanceMode,
  }) {
    // Priority 1: Maintenance mode
    if (maintenanceMode) {
      return UpdateStatus.maintenanceMode;
    }

    // Priority 2: Force update check
    if (!_meetsMinimum(currentVersion, forceMinimumVersion)) {
      return UpdateStatus.forceUpdateRequired;
    }

    // Priority 3: Soft update check
    if (!_meetsMinimum(currentVersion, minimumVersion)) {
      return UpdateStatus.softUpdateAvailable;
    }

    return UpdateStatus.upToDate;
  }

  /// Compare semantic versions.
  /// Returns true if current >= minimum.
  bool _meetsMinimum(String current, String minimum) {
    return _compareVersions(current, minimum) >= 0;
  }

  /// Compare two semantic versions.
  /// Returns negative if v1 < v2, zero if equal, positive if v1 > v2.
  int _compareVersions(String v1, String v2) {
    final parts1 = _parseVersion(v1);
    final parts2 = _parseVersion(v2);

    for (var i = 0; i < 3; i++) {
      if (parts1[i] != parts2[i]) {
        return parts1[i] - parts2[i];
      }
    }
    return 0;
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.').map((p) {
      // Handle versions like "1.2.3-beta" by taking only the numeric part
      final numeric = RegExp(r'^\d+').firstMatch(p)?.group(0) ?? '0';
      return int.parse(numeric);
    }).toList();

    // Pad with zeros if needed
    while (parts.length < 3) {
      parts.add(0);
    }

    return parts.take(3).toList();
  }
}

@riverpod
AppVersionService appVersionService(AppVersionServiceRef ref) {
  return AppVersionService(Supabase.instance.client);
}
