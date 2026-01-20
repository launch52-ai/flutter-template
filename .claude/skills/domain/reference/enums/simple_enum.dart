// Template: Enum definition
//
// Location: lib/features/{feature}/domain/enums/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Simple Enum
// Basic enum with documented values.

/// Status of sync operation.
enum SyncStatus {
  /// Waiting to be synced.
  pending,

  /// Currently uploading.
  uploading,

  /// Successfully synced.
  synced,

  /// Sync failed, can retry.
  failed,
}
