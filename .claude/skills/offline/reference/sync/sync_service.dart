// Template: Sync orchestration service
//
// Location: lib/core/data/sync/
//
// Usage:
// 1. Copy to target location
// 2. Implement entity-specific sync handlers
// 3. Wire up with connectivity monitoring

import 'dart:async';

import '../models/sync_operation.dart';
import '../models/sync_status.dart';
import 'sync_queue.dart';
import 'conflict_resolver.dart';

/// Result of a sync operation.
final class SyncResult {
  final int succeeded;
  final int failed;
  final int skipped;
  final List<SyncError> errors;

  const SyncResult({
    required this.succeeded,
    required this.failed,
    required this.skipped,
    this.errors = const [],
  });

  bool get hasErrors => failed > 0;
  int get total => succeeded + failed + skipped;
}

/// Error information from a failed sync.
final class SyncError {
  final String operationId;
  final String entityId;
  final String message;
  final bool isRetryable;

  const SyncError({
    required this.operationId,
    required this.entityId,
    required this.message,
    required this.isRetryable,
  });
}

/// Current sync state.
enum SyncState {
  idle,
  syncing,
  error,
}

/// Orchestrates data synchronization between local and remote storage.
///
/// Processes queued operations in order, handles conflicts, and
/// reports sync status.
final class SyncService {
  SyncService({
    required SyncQueue queue,
    required RemoteDataSource remote,
    required LocalDataSource local,
    required ConflictResolver conflictResolver,
  })  : _queue = queue,
        _remote = remote,
        _local = local,
        _conflictResolver = conflictResolver;

  final SyncQueue _queue;
  final RemoteDataSource _remote;
  final LocalDataSource _local;
  final ConflictResolver _conflictResolver;

  final _stateController = StreamController<SyncState>.broadcast();

  /// Stream of sync state changes.
  Stream<SyncState> get stateStream => _stateController.stream;

  SyncState _currentState = SyncState.idle;

  /// Current sync state.
  SyncState get currentState => _currentState;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _currentState == SyncState.syncing;

  /// Sync all pending operations.
  ///
  /// Returns a [SyncResult] with counts of succeeded, failed, and skipped operations.
  Future<SyncResult> sync() async {
    if (isSyncing) {
      return const SyncResult(succeeded: 0, failed: 0, skipped: 0);
    }

    _setState(SyncState.syncing);

    final operations = await _queue.getRetryable();

    if (operations.isEmpty) {
      _setState(SyncState.idle);
      return const SyncResult(succeeded: 0, failed: 0, skipped: 0);
    }

    var succeeded = 0;
    var failed = 0;
    var skipped = 0;
    final errors = <SyncError>[];

    for (final op in operations) {
      // Skip if exceeded retries
      if (op.hasExceededRetries) {
        skipped++;
        continue;
      }

      try {
        await _executeOperation(op);
        await _queue.complete(op.id);
        succeeded++;
      } on ConflictException catch (e) {
        await _handleConflict(op, e.serverVersion);
        // Don't count as failed - conflict handler will requeue if needed
      } on RetryableException catch (e) {
        await _queue.markFailed(op.id, e.message);
        failed++;
        errors.add(SyncError(
          operationId: op.id,
          entityId: op.entityId,
          message: e.message,
          isRetryable: true,
        ));
      } catch (e) {
        await _queue.markFailed(op.id, e.toString());
        failed++;
        errors.add(SyncError(
          operationId: op.id,
          entityId: op.entityId,
          message: e.toString(),
          isRetryable: false,
        ));
      }
    }

    _setState(failed > 0 ? SyncState.error : SyncState.idle);

    return SyncResult(
      succeeded: succeeded,
      failed: failed,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Sync a specific entity immediately.
  Future<bool> syncEntity(String entityType, String entityId) async {
    final operations = await _queue.getForEntity(entityId);

    if (operations.isEmpty) return true;

    for (final op in operations) {
      try {
        await _executeOperation(op);
        await _queue.complete(op.id);
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  /// Pull latest changes from server.
  ///
  /// For delta sync, pass [since] timestamp to only get changes after that time.
  Future<void> pull({DateTime? since}) async {
    _setState(SyncState.syncing);

    try {
      // Get changes from server
      final changes = await _remote.getChangesSince(since);

      for (final serverEntity in changes) {
        final localEntity = await _local.getById(serverEntity.id);

        if (localEntity == null) {
          // New from server - insert locally
          await _local.save(serverEntity);
        } else if (localEntity.syncStatus == SyncStatus.synced) {
          // No local changes - accept server version
          await _local.save(serverEntity);
        } else {
          // Local changes exist - resolve conflict
          final resolved = await _conflictResolver.resolve(
            local: localEntity,
            remote: serverEntity,
          );
          await _local.save(resolved);

          // If local version won, we need to push it
          if (resolved.localUpdatedAt == localEntity.localUpdatedAt) {
            await _queue.enqueue(SyncOperation.update(
              entityType: serverEntity.entityType,
              entityId: serverEntity.id,
              payload: resolved.toJson(),
            ));
          }
        }
      }

      // Handle deletions
      final deletions = await _remote.getDeletedSince(since);
      for (final id in deletions) {
        await _local.delete(id);
        await _queue.removeForEntity(id);
      }

      _setState(SyncState.idle);
    } catch (e) {
      _setState(SyncState.error);
      rethrow;
    }
  }

  Future<void> _executeOperation(SyncOperation op) async {
    switch (op.type) {
      case SyncOperationType.create:
        final serverId = await _remote.create(op.entityType, op.payload);
        await _local.updateServerId(op.entityId, serverId);
        await _local.updateSyncStatus(op.entityId, SyncStatus.synced);

      case SyncOperationType.update:
        await _remote.update(op.entityType, op.entityId, op.payload);
        await _local.updateSyncStatus(op.entityId, SyncStatus.synced);

      case SyncOperationType.delete:
        await _remote.delete(op.entityType, op.entityId);
        // Entity already deleted locally
    }
  }

  Future<void> _handleConflict(
    SyncOperation op,
    Map<String, dynamic> serverVersion,
  ) async {
    final local = await _local.getById(op.entityId);
    if (local == null) return;

    try {
      final resolved = await _conflictResolver.resolve(
        local: local,
        remote: serverVersion,
      );

      await _local.save(resolved);

      // If local changes need to be pushed
      if (resolved.syncStatus == SyncStatus.pendingUpdate) {
        // Existing operation will be retried
        await _queue.markFailed(op.id, 'Conflict resolved, retrying');
      } else {
        // Server version accepted
        await _queue.complete(op.id);
      }
    } catch (e) {
      // Mark for user resolution
      await _local.updateSyncStatus(op.entityId, SyncStatus.conflict);
      await _queue.markFailed(op.id, 'Conflict requires manual resolution');
    }
  }

  void _setState(SyncState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Dispose resources.
  void dispose() {
    _stateController.close();
  }
}

// -----------------------------------------------------
// Exception types:
// -----------------------------------------------------

class ConflictException implements Exception {
  final Map<String, dynamic> serverVersion;
  ConflictException(this.serverVersion);
}

class RetryableException implements Exception {
  final String message;
  RetryableException(this.message);
}

// -----------------------------------------------------
// Stub interfaces (implement based on your app):
// -----------------------------------------------------

abstract interface class RemoteDataSource {
  Future<String> create(String entityType, Map<String, dynamic> data);
  Future<void> update(String entityType, String id, Map<String, dynamic> data);
  Future<void> delete(String entityType, String id);
  Future<List<dynamic>> getChangesSince(DateTime? since);
  Future<List<String>> getDeletedSince(DateTime? since);
}

abstract interface class LocalDataSource {
  Future<dynamic> getById(String id);
  Future<void> save(dynamic entity);
  Future<void> delete(String id);
  Future<void> updateServerId(String localId, String serverId);
  Future<void> updateSyncStatus(String id, SyncStatus status);
}
