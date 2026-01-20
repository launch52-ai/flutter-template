// Template: Repository interface
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Repository with Offline Support
// Local-first with sync operations.

import '../entities/memory.dart';
import '../entities/lat_lng.dart';

/// Repository for memories with offline support.
abstract interface class MemoriesRepository {
  /// Get all memories (local + synced).
  Future<List<Memory>> getAll();

  /// Get a single memory by ID.
  Future<Memory?> getById(String id);

  /// Create a new memory locally.
  /// Returns memory with SyncStatus.pending.
  Future<Memory> create({
    required String localPath,
    String? caption,
    LatLng? location,
  });

  /// Update memory caption.
  Future<Memory> updateCaption({
    required String id,
    required String caption,
  });

  /// Delete memory (local and queues remote delete).
  Future<void> delete(String id);

  // --- Sync Operations ---

  /// Get all memories pending sync.
  Future<List<Memory>> getPendingSync();

  /// Sync a single memory to cloud.
  Future<Memory> syncMemory(String id);

  /// Sync all pending memories.
  /// Returns list of IDs that failed to sync.
  Future<List<String>> syncAll();
}
