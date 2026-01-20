// Template: Online-first repository with offline fallback
//
// Location: lib/features/{feature}/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders
// 3. Implement entity-specific methods
// 4. Wire up with providers

import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/data/sync/sync_queue.dart';
import '../../../../core/data/sync/sync_status.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../data_sources/products_local_data_source.dart';
import '../data_sources/products_remote_data_source.dart';
import '../models/product_model.dart';
import '../sync/sync_operation.dart';

/// Online-first repository with offline cache and fallback.
///
/// Tries remote first, falls back to cache when offline.
/// Writes are queued when offline and synced on reconnect.
final class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl({
    required ProductsLocalDataSource localDataSource,
    required ProductsRemoteDataSource remoteDataSource,
    required SyncQueue syncQueue,
    required ConnectivityService connectivity,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _queue = syncQueue,
        _connectivity = connectivity;

  final ProductsLocalDataSource _local;
  final ProductsRemoteDataSource _remote;
  final SyncQueue _queue;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // ─────────────────────────────────────────────────────────────────
  // READ OPERATIONS (Remote-first with cache fallback)
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Product>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try cache first for faster response
      final cached = await _local.getAll();
      if (cached.isNotEmpty && !await _connectivity.isOnline) {
        // Offline - return cache
        return cached.map((m) => m.toEntity()).toList();
      }
    }

    try {
      // Fetch from remote
      final models = await _remote.fetchAll();

      // Update cache
      await _local.replaceAll(models);

      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Fallback to cache on any error
      final cached = await _local.getAll();
      if (cached.isNotEmpty) {
        return cached.map((m) => m.toEntity()).toList();
      }
      rethrow;
    }
  }

  @override
  Stream<List<Product>> watchAll() async* {
    // Emit cached data immediately
    final cached = await _local.getAll();
    if (cached.isNotEmpty) {
      yield cached.map((m) => m.toEntity()).toList();
    }

    // Then try to fetch fresh data
    try {
      final fresh = await getAll(forceRefresh: true);
      yield fresh;
    } catch (e) {
      // Already yielded cache, just log error
    }

    // Continue watching local changes
    yield* _local.watchAll().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Product?> getById(String id) async {
    // Check cache first
    final cached = await _local.getById(id);

    if (await _connectivity.isOnline) {
      try {
        final model = await _remote.fetchById(id);
        if (model != null) {
          await _local.save(model);
          return model.toEntity();
        }
      } catch (e) {
        // Fall through to cached
      }
    }

    return cached?.toEntity();
  }

  // ─────────────────────────────────────────────────────────────────
  // WRITE OPERATIONS (Online-first with offline queue)
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<Product> create(CreateProductRequest request) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    if (await _connectivity.isOnline) {
      try {
        // Try to create on server first
        final serverModel = await _remote.create(request);

        // Save to cache
        final model = serverModel.copyWith(
          localId: localId,
          syncStatus: SyncStatus.synced,
        );
        await _local.save(model);

        return model.toEntity();
      } catch (e) {
        // Fall through to offline creation
      }
    }

    // Offline or failed - save locally and queue
    final model = ProductModel(
      localId: localId,
      serverId: null,
      name: request.name,
      price: request.price,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: now,
      localUpdatedAt: now,
    );

    await _local.save(model);

    await _queue.enqueue(SyncOperation.create(
      entityType: 'product',
      entityId: localId,
      payload: model.toApiJson(),
    ));

    return model.toEntity();
  }

  @override
  Future<Product> update(Product product) async {
    final now = DateTime.now();

    if (await _connectivity.isOnline && product.serverId != null) {
      try {
        // Try to update on server first
        await _remote.update(product.serverId!, UpdateProductRequest(
          name: product.name,
          price: product.price,
        ));

        // Update cache
        final model = ProductModel.fromEntity(product).copyWith(
          syncStatus: SyncStatus.synced,
          localUpdatedAt: now,
        );
        await _local.save(model);

        return model.toEntity();
      } catch (e) {
        // Fall through to offline update
      }
    }

    // Offline or failed - save locally and queue
    final model = ProductModel.fromEntity(product).copyWith(
      syncStatus: SyncStatus.pendingUpdate,
      localUpdatedAt: now,
    );

    await _local.save(model);

    await _queue.enqueue(SyncOperation.update(
      entityType: 'product',
      entityId: product.localId,
      payload: model.toApiJson(),
    ));

    return model.toEntity();
  }

  @override
  Future<void> delete(String id) async {
    final existing = await _local.getById(id);
    if (existing == null) return;

    if (await _connectivity.isOnline && existing.serverId != null) {
      try {
        await _remote.delete(existing.serverId!);
        await _local.delete(id);
        return;
      } catch (e) {
        // Fall through to offline delete
      }
    }

    if (existing.serverId != null) {
      // Mark for deletion
      await _local.save(existing.copyWith(
        syncStatus: SyncStatus.pendingDelete,
      ));

      await _queue.enqueue(SyncOperation.delete(
        entityType: 'product',
        entityId: id,
      ));
    } else {
      // Never synced - just delete
      await _local.delete(id);
      await _queue.removeForEntity(id);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SYNC HELPERS
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<void> syncPending() async {
    if (!await _connectivity.isOnline) return;

    final pending = await _local.getPendingSync();

    for (final model in pending) {
      try {
        switch (model.syncStatus) {
          case SyncStatus.pendingCreate:
            final serverModel = await _remote.create(CreateProductRequest(
              name: model.name,
              price: model.price,
            ));
            await _local.save(model.copyWith(
              serverId: serverModel.serverId,
              syncStatus: SyncStatus.synced,
            ));

          case SyncStatus.pendingUpdate:
            if (model.serverId != null) {
              await _remote.update(model.serverId!, UpdateProductRequest(
                name: model.name,
                price: model.price,
              ));
              await _local.save(model.copyWith(
                syncStatus: SyncStatus.synced,
              ));
            }

          case SyncStatus.pendingDelete:
            if (model.serverId != null) {
              await _remote.delete(model.serverId!);
            }
            await _local.delete(model.localId);

          default:
            break;
        }

        // Clear from queue
        await _queue.removeForEntity(model.localId);
      } catch (e) {
        // Leave in queue for retry
      }
    }
  }

  @override
  Future<int> get pendingSyncCount async {
    return (await _local.getPendingSync()).length;
  }
}

// ─────────────────────────────────────────────────────────────────
// Stub types (replace with actual types):
// ─────────────────────────────────────────────────────────────────

class CreateProductRequest {
  final String name;
  final double price;
  CreateProductRequest({required this.name, required this.price});
}

class UpdateProductRequest {
  final String name;
  final double price;
  UpdateProductRequest({required this.name, required this.price});
}
