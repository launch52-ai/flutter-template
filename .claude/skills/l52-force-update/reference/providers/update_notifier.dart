// Template: UpdateNotifier state management with Riverpod
//
// Location: lib/features/force_update/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run build_runner to generate riverpod code

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/app_version_service.dart';
import '../../domain/entities/version_info.dart';
import '../../domain/enums/update_status.dart';

part 'update_notifier.g.dart';

/// State for the update notifier.
sealed class UpdateState {
  const UpdateState();
}

final class UpdateStateInitial extends UpdateState {
  const UpdateStateInitial();
}

final class UpdateStateLoading extends UpdateState {
  const UpdateStateLoading();
}

final class UpdateStateLoaded extends UpdateState {
  const UpdateStateLoaded(this.versionInfo);

  final VersionInfo versionInfo;
}

final class UpdateStateError extends UpdateState {
  const UpdateStateError(this.message);

  final String message;
}

@riverpod
class UpdateNotifier extends _$UpdateNotifier {
  @override
  UpdateState build() => const UpdateStateInitial();

  /// Check for updates and update state accordingly.
  Future<void> checkForUpdates() async {
    state = const UpdateStateLoading();

    try {
      final versionService = ref.read(appVersionServiceProvider);
      final versionInfo = await versionService.checkVersionSafely();

      state = UpdateStateLoaded(versionInfo);
    } catch (e) {
      state = UpdateStateError(e.toString());
    }
  }

  /// Manually set version info (useful for testing).
  void setVersionInfo(VersionInfo versionInfo) {
    state = UpdateStateLoaded(versionInfo);
  }

  /// Reset to initial state.
  void reset() {
    state = const UpdateStateInitial();
  }
}

/// Convenience provider for checking if force update is required.
@riverpod
bool isForceUpdateRequired(IsForceUpdateRequiredRef ref) {
  final state = ref.watch(updateNotifierProvider);

  return switch (state) {
    UpdateStateLoaded(:final versionInfo) =>
      versionInfo.status == UpdateStatus.forceUpdateRequired,
    _ => false,
  };
}

/// Convenience provider for checking if soft update is available.
@riverpod
bool isSoftUpdateAvailable(IsSoftUpdateAvailableRef ref) {
  final state = ref.watch(updateNotifierProvider);

  return switch (state) {
    UpdateStateLoaded(:final versionInfo) =>
      versionInfo.status == UpdateStatus.softUpdateAvailable,
    _ => false,
  };
}

/// Convenience provider for checking if maintenance mode is active.
@riverpod
bool isMaintenanceMode(IsMaintenanceModeRef ref) {
  final state = ref.watch(updateNotifierProvider);

  return switch (state) {
    UpdateStateLoaded(:final versionInfo) =>
      versionInfo.status == UpdateStatus.maintenanceMode,
    _ => false,
  };
}

/// Convenience provider to get version info when loaded.
@riverpod
VersionInfo? versionInfo(VersionInfoRef ref) {
  final state = ref.watch(updateNotifierProvider);

  return switch (state) {
    UpdateStateLoaded(:final versionInfo) => versionInfo,
    _ => null,
  };
}
