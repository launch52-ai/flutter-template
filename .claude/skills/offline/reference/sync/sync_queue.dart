// Template: Sync operation queue
//
// Location: lib/core/data/sync/
//
// Usage:
// 1. Copy to target location
// 2. Adjust storage backend (Drift/Hive) as needed
// 3. Wire up with SyncService

import 'dart:async';
import 'dart:convert';

import '../models/sync_operation.dart';

/// Persistent queue for sync operations.
///
/// Stores pending operations in local storage and provides
/// ordered retrieval for sync processing.
final class SyncQueue {
  SyncQueue({
    required LocalDatabase db,
  }) : _db = db;

  final LocalDatabase _db;

  /// Stream controller for queue changes.
  final _pendingCountController = StreamController<int>.broadcast();

  /// Stream of pending operation count changes.
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  /// Current count of pending operations.
  Future<int> get pendingCount async {
    return (await getPending()).length;
  }

  /// Add operation to queue.
  Future<void> enqueue(SyncOperation operation) async {
    await _db.syncOperations.insert(
      SyncOperationsCompanion.insert(
        id: operation.id,
        type: operation.type,
        entityType: operation.entityType,
        entityId: operation.entityId,
        payload: jsonEncode(operation.payload),
        createdAt: operation.createdAt,
        retryCount: Value(operation.retryCount),
        lastAttempt: Value(operation.lastAttempt),
        errorMessage: Value(operation.errorMessage),
      ),
    );
    _notifyChange();
  }

  /// Get all pending operations in FIFO order.
  Future<List<SyncOperation>> getPending() async {
    final rows = await (_db.syncOperations.select()
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    return rows.map(_rowToOperation).toList();
  }

  /// Get operations that haven't exceeded retry limit.
  Future<List<SyncOperation>> getRetryable() async {
    final rows = await (_db.syncOperations.select()
          ..where((t) => t.retryCount.isSmallerThan(SyncOperation.maxRetries))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    return rows.map(_rowToOperation).toList();
  }

  /// Get operations for a specific entity.
  Future<List<SyncOperation>> getForEntity(String entityId) async {
    final rows = await (_db.syncOperations.select()
          ..where((t) => t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    return rows.map(_rowToOperation).toList();
  }

  /// Mark operation as completed and remove from queue.
  Future<void> complete(String operationId) async {
    await (_db.syncOperations.delete()
          ..where((t) => t.id.equals(operationId)))
        .go();
    _notifyChange();
  }

  /// Mark operation as failed with error.
  Future<void> markFailed(String operationId, String error) async {
    final existing = await (_db.syncOperations.select()
          ..where((t) => t.id.equals(operationId)))
        .getSingleOrNull();

    if (existing != null) {
      await _db.syncOperations.update().replace(
        SyncOperationsCompanion(
          id: Value(operationId),
          type: Value(existing.type),
          entityType: Value(existing.entityType),
          entityId: Value(existing.entityId),
          payload: Value(existing.payload),
          createdAt: Value(existing.createdAt),
          retryCount: Value(existing.retryCount + 1),
          lastAttempt: Value(DateTime.now()),
          errorMessage: Value(error),
        ),
      );
    }
    _notifyChange();
  }

  /// Remove all operations for a specific entity.
  ///
  /// Useful when entity is deleted before sync completes.
  Future<void> removeForEntity(String entityId) async {
    await (_db.syncOperations.delete()
          ..where((t) => t.entityId.equals(entityId)))
        .go();
    _notifyChange();
  }

  /// Remove operations that exceeded retry limit and are older than [maxAge].
  Future<int> pruneStale({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(maxAge);

    final deleted = await (_db.syncOperations.delete()
          ..where((t) =>
              t.retryCount.isBiggerOrEqualValue(SyncOperation.maxRetries) &
              t.createdAt.isSmallerThanValue(cutoff)))
        .go();

    if (deleted > 0) _notifyChange();
    return deleted;
  }

  /// Clear all pending operations.
  ///
  /// Use with caution - data may be lost.
  Future<void> clear() async {
    await _db.syncOperations.delete().go();
    _notifyChange();
  }

  void _notifyChange() {
    pendingCount.then((count) => _pendingCountController.add(count));
  }

  SyncOperation _rowToOperation(SyncOperationRow row) {
    return SyncOperation(
      id: row.id,
      type: row.type,
      entityType: row.entityType,
      entityId: row.entityId,
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      createdAt: row.createdAt,
      retryCount: row.retryCount,
      lastAttempt: row.lastAttempt,
      errorMessage: row.errorMessage,
    );
  }

  /// Dispose resources.
  void dispose() {
    _pendingCountController.close();
  }
}

// -----------------------------------------------------
// Stub types (replace with actual Drift types):
// -----------------------------------------------------

// These are placeholder types - replace with your actual Drift generated types
typedef LocalDatabase = dynamic;
typedef SyncOperationsCompanion = dynamic;
typedef SyncOperationRow = dynamic;

class Value<T> {
  final T value;
  const Value(this.value);
}

// -----------------------------------------------------
// Hive-based alternative:
// -----------------------------------------------------
//
// final class HiveSyncQueue {
//   Box<SyncOperationHive> get _box => Hive.box('sync_queue');
//
//   final _pendingCountController = StreamController<int>.broadcast();
//
//   Stream<int> get pendingCountStream => _pendingCountController.stream;
//
//   Future<void> enqueue(SyncOperation operation) async {
//     await _box.put(operation.id, SyncOperationHive.fromModel(operation));
//     _notifyChange();
//   }
//
//   List<SyncOperation> getPending() {
//     return _box.values
//         .map((h) => h.toModel())
//         .toList()
//       ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
//   }
//
//   Future<void> complete(String operationId) async {
//     await _box.delete(operationId);
//     _notifyChange();
//   }
//
//   Future<void> markFailed(String operationId, String error) async {
//     final existing = _box.get(operationId);
//     if (existing != null) {
//       existing.retryCount++;
//       existing.lastAttempt = DateTime.now();
//       existing.errorMessage = error;
//       await existing.save();
//     }
//     _notifyChange();
//   }
//
//   void _notifyChange() {
//     _pendingCountController.add(_box.length);
//   }
// }
