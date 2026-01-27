// Template: Domain entity with Freezed
//
// Location: lib/features/{feature}/domain/entities/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Entity with Computed Properties
// Derived values from stored fields.

import '../enums/sync_status.dart';

/// A photo memory with optional caption and location.
final class Memory {
  final String id;
  final String? localPath;
  final String? remoteUrl;
  final String? caption;
  final SyncStatus syncStatus;
  final DateTime createdAt;

  const Memory({
    required this.id,
    this.localPath,
    this.remoteUrl,
    this.caption,
    required this.syncStatus,
    required this.createdAt,
  });

  /// Returns the path to display (prefers remote, falls back to local).
  String? get displayPath => remoteUrl ?? localPath;

  /// Whether this memory has been synced to cloud.
  bool get isSynced => syncStatus == SyncStatus.synced;

  /// Whether this memory needs to be synced.
  bool get needsSync =>
      syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed;

  /// Whether this memory has a caption.
  bool get hasCaption => caption != null && caption!.isNotEmpty;

  /// Whether this memory has a valid photo path.
  bool get hasPhoto => localPath != null || remoteUrl != null;
}
