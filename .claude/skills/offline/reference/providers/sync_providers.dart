// Template: Sync status providers
//
// Location: lib/core/providers/ or lib/features/{feature}/presentation/providers/
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports
// 3. Register in provider scope

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/sync/sync_queue.dart';
import '../../data/sync/sync_service.dart';
import '../../data/sync/sync_status.dart';

part 'sync_providers.g.dart';

// ─────────────────────────────────────────────────────────────────
// Sync Queue Provider
// ─────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SyncQueue syncQueue(SyncQueueRef ref) {
  final db = ref.watch(appDatabaseProvider);
  final queue = SyncQueue(db: db);

  ref.onDispose(queue.dispose);

  return queue;
}

// ─────────────────────────────────────────────────────────────────
// Sync Service Provider
// ─────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SyncService syncService(SyncServiceRef ref) {
  final queue = ref.watch(syncQueueProvider);
  final remote = ref.watch(remoteDataSourceProvider);
  final local = ref.watch(localDataSourceProvider);
  final conflictResolver = ref.watch(conflictResolverProvider);

  final service = SyncService(
    queue: queue,
    remote: remote,
    local: local,
    conflictResolver: conflictResolver,
  );

  ref.onDispose(service.dispose);

  return service;
}

// ─────────────────────────────────────────────────────────────────
// Sync State Stream
// ─────────────────────────────────────────────────────────────────

@riverpod
Stream<SyncState> syncState(SyncStateRef ref) {
  return ref.watch(syncServiceProvider).stateStream;
}

/// Current sync state (for synchronous access).
@riverpod
SyncState currentSyncState(CurrentSyncStateRef ref) {
  final asyncState = ref.watch(syncStateProvider);
  return asyncState.valueOrNull ?? SyncState.idle;
}

// ─────────────────────────────────────────────────────────────────
// Pending Operations Count
// ─────────────────────────────────────────────────────────────────

@riverpod
Stream<int> pendingOperationCount(PendingOperationCountRef ref) {
  return ref.watch(syncQueueProvider).pendingCountStream;
}

/// Whether there are pending sync operations.
@riverpod
bool hasPendingSync(HasPendingSyncRef ref) {
  final count = ref.watch(pendingOperationCountProvider);
  return count.valueOrNull != null && count.valueOrNull! > 0;
}

// ─────────────────────────────────────────────────────────────────
// Combined Offline Status
// ─────────────────────────────────────────────────────────────────

/// Overall sync/offline status for UI.
@riverpod
OfflineStatus offlineStatus(OfflineStatusRef ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final syncState = ref.watch(currentSyncStateProvider);
  final hasPending = ref.watch(hasPendingSyncProvider);

  if (!isOnline) {
    return hasPending ? OfflineStatus.offlineWithPending : OfflineStatus.offline;
  }

  return switch (syncState) {
    SyncState.syncing => OfflineStatus.syncing,
    SyncState.error => OfflineStatus.syncError,
    SyncState.idle when hasPending => OfflineStatus.pendingSync,
    SyncState.idle => OfflineStatus.synced,
  };
}

enum OfflineStatus {
  /// Online and fully synced.
  synced,

  /// Online with sync in progress.
  syncing,

  /// Online but sync failed.
  syncError,

  /// Online with pending operations waiting to sync.
  pendingSync,

  /// Offline, no pending operations.
  offline,

  /// Offline with pending operations.
  offlineWithPending,
}

extension OfflineStatusX on OfflineStatus {
  bool get isOnline => switch (this) {
        OfflineStatus.synced => true,
        OfflineStatus.syncing => true,
        OfflineStatus.syncError => true,
        OfflineStatus.pendingSync => true,
        OfflineStatus.offline => false,
        OfflineStatus.offlineWithPending => false,
      };

  bool get hasPending => switch (this) {
        OfflineStatus.pendingSync => true,
        OfflineStatus.offlineWithPending => true,
        _ => false,
      };

  String get displayText => switch (this) {
        OfflineStatus.synced => 'Synced',
        OfflineStatus.syncing => 'Syncing...',
        OfflineStatus.syncError => 'Sync failed',
        OfflineStatus.pendingSync => 'Pending sync',
        OfflineStatus.offline => 'Offline',
        OfflineStatus.offlineWithPending => 'Offline (changes pending)',
      };
}

// ─────────────────────────────────────────────────────────────────
// Sync Actions
// ─────────────────────────────────────────────────────────────────

/// Trigger manual sync.
@riverpod
Future<SyncResult> triggerSync(TriggerSyncRef ref) async {
  final syncService = ref.read(syncServiceProvider);
  return syncService.sync();
}

// ─────────────────────────────────────────────────────────────────
// Auto-sync on connectivity change
// ─────────────────────────────────────────────────────────────────

/// Call this at app startup to enable auto-sync.
void setupAutoSync(ProviderContainer container) {
  container.listen(isOnlineProvider, (previous, next) {
    if (previous == false && next == true) {
      // Just came online - trigger sync
      container.read(syncServiceProvider).sync();
    }
  });
}

// ─────────────────────────────────────────────────────────────────
// Entity-level sync status
// ─────────────────────────────────────────────────────────────────

/// Watch sync status for a specific entity.
@riverpod
SyncStatus entitySyncStatus(EntitySyncStatusRef ref, String entityId) {
  // This would typically come from watching the entity itself
  // Implementation depends on your entity provider structure
  final entity = ref.watch(entityProvider(entityId));
  return entity.valueOrNull?.syncStatus ?? SyncStatus.synced;
}

// ─────────────────────────────────────────────────────────────────
// Stub providers (replace with actual implementations):
// ─────────────────────────────────────────────────────────────────

// @Riverpod(keepAlive: true)
// AppDatabase appDatabase(AppDatabaseRef ref) => AppDatabase.instance;
//
// @riverpod
// bool isOnline(IsOnlineRef ref) {
//   return ref.watch(actualConnectivityProvider);
// }
//
// @Riverpod(keepAlive: true)
// RemoteDataSource remoteDataSource(RemoteDataSourceRef ref) => ...;
//
// @Riverpod(keepAlive: true)
// LocalDataSource localDataSource(LocalDataSourceRef ref) => ...;
//
// @Riverpod(keepAlive: true)
// ConflictResolver conflictResolver(ConflictResolverRef ref) => ConflictResolver();

// Placeholder for stub references
dynamic appDatabaseProvider;
dynamic remoteDataSourceProvider;
dynamic localDataSourceProvider;
dynamic conflictResolverProvider;
dynamic isOnlineProvider;
dynamic entityProvider;
