// Template: Offline-first repository implementation
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders
// 3. Implement entity-specific methods
// 4. Wire up with providers

import 'package:uuid/uuid.dart';

import '../../../../core/data/sync/sync_queue.dart';
import '../../../../core/data/sync/sync_status.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../data_sources/tasks_local_data_source.dart';
import '../data_sources/tasks_remote_data_source.dart';
import '../models/task_model.dart';
import '../sync/sync_operation.dart';

/// Offline-first repository implementation.
///
/// Reads from local storage first, writes to local immediately,
/// and queues sync operations for background processing.
final class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl({
    required TasksLocalDataSource localDataSource,
    required TasksRemoteDataSource remoteDataSource,
    required SyncQueue syncQueue,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _queue = syncQueue;

  final TasksLocalDataSource _local;
  final TasksRemoteDataSource _remote;
  final SyncQueue _queue;

  static const _uuid = Uuid();

  // ─────────────────────────────────────────────────────────────────
  // READ OPERATIONS (Local-first)
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Task>> getAll() async {
    // Always return local data (instant)
    final models = await _local.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Task>> watchAll() {
    // Stream from local database for reactive UI
    return _local.watchAll().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Task?> getById(String id) async {
    final model = await _local.getById(id);
    return model?.toEntity();
  }

  // ─────────────────────────────────────────────────────────────────
  // WRITE OPERATIONS (Local + Queue Sync)
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<Task> create(CreateTaskRequest request) async {
    // Generate local ID
    final localId = _uuid.v4();
    final now = DateTime.now();

    // Create model with pending status
    final model = TaskModel(
      localId: localId,
      serverId: null,
      title: request.title,
      description: request.description,
      isCompleted: false,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: now,
      localUpdatedAt: now,
      serverUpdatedAt: null,
    );

    // Save to local storage immediately
    await _local.save(model);

    // Queue sync operation
    await _queue.enqueue(SyncOperation.create(
      entityType: 'task',
      entityId: localId,
      payload: model.toApiJson(),
    ));

    return model.toEntity();
  }

  @override
  Future<Task> update(Task task) async {
    final now = DateTime.now();

    // Update local with pending status
    final model = TaskModel.fromEntity(task).copyWith(
      syncStatus: SyncStatus.pendingUpdate,
      localUpdatedAt: now,
    );

    await _local.save(model);

    // Queue sync operation
    await _queue.enqueue(SyncOperation.update(
      entityType: 'task',
      entityId: task.localId,
      payload: model.toApiJson(),
    ));

    return model.toEntity();
  }

  @override
  Future<void> delete(String id) async {
    final existing = await _local.getById(id);
    if (existing == null) return;

    if (existing.serverId != null) {
      // Has been synced - mark for deletion
      final model = existing.copyWith(
        syncStatus: SyncStatus.pendingDelete,
        localUpdatedAt: DateTime.now(),
      );
      await _local.save(model);

      // Queue delete operation
      await _queue.enqueue(SyncOperation.delete(
        entityType: 'task',
        entityId: id,
      ));
    } else {
      // Never synced - just delete locally
      await _local.delete(id);
      // Remove any pending create operations
      await _queue.removeForEntity(id);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SYNC HELPERS
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<void> markSynced(String localId, String serverId) async {
    final existing = await _local.getById(localId);
    if (existing == null) return;

    await _local.save(existing.copyWith(
      serverId: serverId,
      syncStatus: SyncStatus.synced,
    ));
  }

  @override
  Future<void> updateFromServer(TaskModel serverModel) async {
    final local = await _local.getById(serverModel.localId);

    if (local == null) {
      // New from server
      await _local.save(serverModel.copyWith(
        syncStatus: SyncStatus.synced,
      ));
    } else if (local.syncStatus == SyncStatus.synced) {
      // No local changes - accept server version
      await _local.save(serverModel.copyWith(
        localId: local.localId,
        syncStatus: SyncStatus.synced,
      ));
    }
    // If local has pending changes, SyncService handles conflict
  }

  @override
  Future<List<Task>> getPendingSync() async {
    final models = await _local.getPendingSync();
    return models.map((m) => m.toEntity()).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // OPTIONAL: Full refresh from server
  // ─────────────────────────────────────────────────────────────────

  /// Fetch all data from server and merge with local.
  ///
  /// Use for initial sync or manual refresh.
  Future<void> fullRefresh() async {
    try {
      final serverModels = await _remote.fetchAll();

      for (final serverModel in serverModels) {
        final localModel = await _local.getByServerId(serverModel.serverId!);

        if (localModel == null) {
          // New from server
          await _local.save(serverModel.copyWith(
            localId: _uuid.v4(),
            syncStatus: SyncStatus.synced,
          ));
        } else if (localModel.syncStatus == SyncStatus.synced) {
          // No local changes - update
          await _local.save(serverModel.copyWith(
            localId: localModel.localId,
            syncStatus: SyncStatus.synced,
          ));
        }
        // Skip if local has pending changes
      }
    } catch (e) {
      // Ignore errors - local data still available
      // Log for debugging
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Stub types (replace with actual types):
// ─────────────────────────────────────────────────────────────────

class CreateTaskRequest {
  final String title;
  final String? description;
  CreateTaskRequest({required this.title, this.description});
}
