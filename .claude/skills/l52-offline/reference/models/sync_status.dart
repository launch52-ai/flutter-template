// Template: Sync status tracking
//
// Location: lib/core/data/sync/
//
// Usage:
// 1. Copy to target location
// 2. Import in entities and DTOs that need sync tracking

/// Sync status for offline-capable entities.
///
/// Tracks the synchronization state between local storage and remote server.
enum SyncStatus {
  /// Entity is synced with server (no pending changes).
  synced,

  /// Entity was created locally and hasn't been synced yet.
  pendingCreate,

  /// Entity was modified locally and changes need to be synced.
  pendingUpdate,

  /// Entity was deleted locally but deletion not yet synced.
  pendingDelete,

  /// Sync attempt failed (will retry).
  syncFailed,

  /// Conflict detected between local and server versions.
  conflict,
}

/// Extension methods for [SyncStatus].
extension SyncStatusX on SyncStatus {
  /// Whether the entity has pending changes to sync.
  bool get isPending => switch (this) {
        SyncStatus.synced => false,
        SyncStatus.pendingCreate => true,
        SyncStatus.pendingUpdate => true,
        SyncStatus.pendingDelete => true,
        SyncStatus.syncFailed => true,
        SyncStatus.conflict => true,
      };

  /// Whether the entity needs user attention.
  bool get needsAttention => switch (this) {
        SyncStatus.syncFailed => true,
        SyncStatus.conflict => true,
        _ => false,
      };

  /// Human-readable description for UI.
  String get displayName => switch (this) {
        SyncStatus.synced => 'Synced',
        SyncStatus.pendingCreate => 'Pending upload',
        SyncStatus.pendingUpdate => 'Pending sync',
        SyncStatus.pendingDelete => 'Pending deletion',
        SyncStatus.syncFailed => 'Sync failed',
        SyncStatus.conflict => 'Conflict',
      };
}

// -----------------------------------------------------
// Hive TypeAdapter (if using Hive):
// -----------------------------------------------------
//
// import 'package:hive_ce/hive_ce.dart';
//
// class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
//   @override
//   final int typeId = 100; // Choose unique ID
//
//   @override
//   SyncStatus read(BinaryReader reader) {
//     return SyncStatus.values[reader.readByte()];
//   }
//
//   @override
//   void write(BinaryWriter writer, SyncStatus obj) {
//     writer.writeByte(obj.index);
//   }
// }

// -----------------------------------------------------
// Drift enum usage:
// -----------------------------------------------------
//
// In table definition:
// IntColumn get syncStatus => intEnum<SyncStatus>()();
//
// When querying:
// ..where((t) => t.syncStatus.equals(SyncStatus.pendingCreate.index))
