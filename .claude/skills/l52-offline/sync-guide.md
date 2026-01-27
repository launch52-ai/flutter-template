# Sync Guide

Comprehensive guide for implementing data synchronization and conflict resolution in offline-first Flutter apps.

---

## Sync Strategies Overview

### When to Sync

| Trigger | How | Best For |
|---------|-----|----------|
| **Periodic** | WorkManager/Timer | Background data freshness |
| **On-Demand** | Pull-to-refresh | User-controlled sync |
| **On-Reconnect** | Connectivity listener | Queue flush |
| **Push-Based** | FCM notification | Real-time updates |
| **On-Write** | After local save | Immediate consistency |

### Sync Direction

| Direction | Pattern | Use Case |
|-----------|---------|----------|
| **Upload** | Local → Remote | User-generated content |
| **Download** | Remote → Local | Server-authoritative data |
| **Bidirectional** | Both directions | Collaborative apps |

---

## Sync Queue Implementation

The sync queue persists pending operations for reliable sync even after app restarts.

### Operation Model

```dart
@freezed
abstract class SyncOperation with _$SyncOperation {
  const factory SyncOperation({
    required String id,
    required SyncOperationType type,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    @Default(0) int retryCount,
    DateTime? lastAttempt,
    String? errorMessage,
  }) = _SyncOperation;
}

enum SyncOperationType {
  create,
  update,
  delete,
}
```

**See:** `reference/sync/sync_operation.dart`

### Queue Operations

```dart
final class SyncQueue {
  final LocalDatabase _db;

  /// Add operation to queue
  Future<void> enqueue(SyncOperation op) async {
    await _db.syncOperations.insert(op.toCompanion());
  }

  /// Get pending operations in order
  Future<List<SyncOperation>> getPending() async {
    return _db.syncOperations
        .select()
        .orderBy([(t) => OrderingTerm.asc(t.createdAt)])
        .get();
  }

  /// Mark operation as completed
  Future<void> complete(String operationId) async {
    await _db.syncOperations.deleteWhere((t) => t.id.equals(operationId));
  }

  /// Mark operation as failed
  Future<void> markFailed(String operationId, String error) async {
    await _db.syncOperations.update().replace(
      SyncOperationsCompanion(
        id: Value(operationId),
        retryCount: Value((await _getOperation(operationId)).retryCount + 1),
        lastAttempt: Value(DateTime.now()),
        errorMessage: Value(error),
      ),
    );
  }
}
```

**See:** `reference/sync/sync_queue.dart`

---

## Sync Service

Orchestrates the sync process, handling operations in order with proper error handling.

### Basic Sync Service

```dart
final class SyncService {
  final SyncQueue _queue;
  final RemoteDataSource _remote;
  final LocalDataSource _local;

  static const maxRetries = 3;

  Future<SyncResult> sync() async {
    final operations = await _queue.getPending();
    var succeeded = 0;
    var failed = 0;

    for (final op in operations) {
      if (op.retryCount >= maxRetries) {
        failed++;
        continue;
      }

      try {
        await _executeOperation(op);
        await _queue.complete(op.id);
        succeeded++;
      } catch (e) {
        await _queue.markFailed(op.id, e.toString());
        failed++;
      }
    }

    return SyncResult(succeeded: succeeded, failed: failed);
  }

  Future<void> _executeOperation(SyncOperation op) async {
    switch (op.type) {
      case SyncOperationType.create:
        final serverId = await _remote.create(op.entityType, op.payload);
        await _local.updateServerId(op.entityId, serverId);
      case SyncOperationType.update:
        await _remote.update(op.entityType, op.entityId, op.payload);
      case SyncOperationType.delete:
        await _remote.delete(op.entityType, op.entityId);
    }

    await _local.markSynced(op.entityId);
  }
}
```

**See:** `reference/sync/sync_service.dart`

---

## Conflict Resolution Strategies

### Last-Write-Wins (LWW)

Simplest strategy: the most recent change wins based on timestamp.

```dart
Future<Entity> resolveConflict(Entity local, Entity remote) async {
  if (local.updatedAt.isAfter(remote.updatedAt)) {
    // Local wins - push to server
    await _remote.update(local);
    return local;
  } else {
    // Remote wins - update local
    await _local.save(remote);
    return remote;
  }
}
```

**Pros:** Simple, deterministic
**Cons:** Can lose data if clocks are wrong

### Server-Wins

Server is always authoritative. Good for multi-user shared data.

```dart
Future<Entity> resolveConflict(Entity local, Entity remote) async {
  // Always accept server version
  await _local.save(remote.copyWith(syncStatus: SyncStatus.synced));

  // Re-queue local changes if significantly different
  if (_hasSignificantChanges(local, remote)) {
    await _notifyUserOfOverwrite(local, remote);
  }

  return remote;
}
```

**Pros:** Consistent shared state
**Cons:** User may lose local work

### Client-Wins

Local changes always preserved. Good for single-user offline apps.

```dart
Future<Entity> resolveConflict(Entity local, Entity remote) async {
  // Force push local version
  await _remote.update(local);
  await _local.markSynced(local.id);
  return local;
}
```

**Pros:** Never loses local work
**Cons:** Can overwrite others' changes

### Field-Level Merge

Merge individual fields based on rules.

```dart
Future<Entity> resolveConflict(Entity local, Entity remote) async {
  final merged = Entity(
    id: local.id,
    // Take most recent title
    title: local.titleUpdatedAt.isAfter(remote.titleUpdatedAt)
        ? local.title
        : remote.title,
    // Always take larger quantity (additive)
    quantity: max(local.quantity, remote.quantity),
    // Merge tags (union)
    tags: {...local.tags, ...remote.tags}.toList(),
    // Server controls status
    status: remote.status,
    updatedAt: DateTime.now(),
  );

  await _remote.update(merged);
  await _local.save(merged.copyWith(syncStatus: SyncStatus.synced));

  return merged;
}
```

**Pros:** Preserves intent from both sides
**Cons:** Complex, field-specific logic needed

### User Prompt

Ask user to resolve conflicts for important data.

```dart
Future<Entity> resolveConflict(Entity local, Entity remote) async {
  // Mark as conflict
  await _local.save(local.copyWith(
    syncStatus: SyncStatus.conflict,
    conflictData: remote.toJson(),
  ));

  // Notify UI
  ref.read(conflictNotifierProvider.notifier).addConflict(
    ConflictInfo(localEntity: local, remoteEntity: remote),
  );

  // User will resolve via UI
  throw ConflictException('User resolution required');
}
```

**UI for conflict resolution:**
```dart
// In presentation layer
Widget buildConflictResolver(ConflictInfo conflict) {
  return AlertDialog(
    title: Text('Sync Conflict'),
    content: Column(
      children: [
        Text('Your version: ${conflict.local.title}'),
        Text('Server version: ${conflict.remote.title}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => _resolveWith(conflict.local),
        child: Text('Keep Mine'),
      ),
      TextButton(
        onPressed: () => _resolveWith(conflict.remote),
        child: Text('Use Server'),
      ),
    ],
  );
}
```

---

## Conflict Detection

### Version-Based (Optimistic Locking)

```dart
@freezed
abstract class Entity with _$Entity {
  const factory Entity({
    required String id,
    required int version, // Incremented on each update
    // ...
  }) = _Entity;
}

Future<void> update(Entity entity) async {
  try {
    await _remote.update(
      entity.copyWith(version: entity.version + 1),
      expectedVersion: entity.version, // Server checks this
    );
  } on VersionConflictException catch (e) {
    final serverEntity = await _remote.getById(entity.id);
    await _resolveConflict(entity, serverEntity);
  }
}
```

### Timestamp-Based

```dart
Future<void> sync() async {
  final localItems = await _local.getModifiedSince(lastSyncTime);
  final remoteItems = await _remote.getModifiedSince(lastSyncTime);

  // Find conflicts (same item modified on both sides)
  for (final local in localItems) {
    final remote = remoteItems.firstWhereOrNull((r) => r.id == local.id);
    if (remote != null) {
      await _resolveConflict(local, remote);
    } else {
      await _pushToServer(local);
    }
  }

  // Pull remote-only changes
  for (final remote in remoteItems) {
    if (!localItems.any((l) => l.id == remote.id)) {
      await _local.save(remote);
    }
  }
}
```

---

## Delta Sync

For large datasets, only sync changes since last sync.

### Server Requirements

Server must support:
- `GET /items?since=2024-01-01T00:00:00Z` - Return items modified after timestamp
- `GET /items/deleted?since=...` - Return IDs of deleted items

### Implementation

```dart
Future<void> deltaSync() async {
  final lastSync = await _local.getLastSyncTimestamp();

  // Get changes from server
  final changes = await _remote.getChangesSince(lastSync);
  final deletions = await _remote.getDeletedSince(lastSync);

  // Apply changes
  for (final item in changes) {
    final local = await _local.getById(item.id);

    if (local == null) {
      // New item from server
      await _local.insert(item);
    } else if (local.syncStatus == SyncStatus.synced) {
      // No local changes, accept server version
      await _local.update(item);
    } else {
      // Local changes exist, resolve conflict
      await _resolveConflict(local, item);
    }
  }

  // Apply deletions
  for (final id in deletions) {
    await _local.delete(id);
  }

  // Push local changes
  final pendingOps = await _queue.getPending();
  for (final op in pendingOps) {
    await _executeOperation(op);
  }

  // Update sync timestamp
  await _local.setLastSyncTimestamp(DateTime.now());
}
```

---

## Background Sync with WorkManager

### Setup

```dart
// In main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Register periodic sync
  await Workmanager().registerPeriodicTask(
    'periodic-sync',
    'syncTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(const MyApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'syncTask':
        // Initialize dependencies in isolate
        final db = await AppDatabase.open();
        final dio = Dio()..options.baseUrl = Environment.apiUrl;

        final syncService = SyncService(
          queue: SyncQueue(db),
          remote: RemoteDataSource(dio),
          local: LocalDataSource(db),
        );

        final result = await syncService.sync();
        print('Sync completed: ${result.succeeded} succeeded, ${result.failed} failed');
        return true;

      default:
        return false;
    }
  });
}
```

### iOS Background Fetch

WorkManager uses BGTaskScheduler on iOS. Add to `Info.plist`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.yourcompany.yourapp.syncTask</string>
</array>
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>processing</string>
</array>
```

---

## Sync Status in UI

### Provider

```dart
@riverpod
Stream<SyncStatus> syncStatus(SyncStatusRef ref) {
  return ref.watch(syncServiceProvider).statusStream;
}

@riverpod
int pendingOperationCount(PendingOperationCountRef ref) {
  return ref.watch(syncQueueProvider).pendingCount;
}
```

### UI Indicators

```dart
Widget buildSyncIndicator(BuildContext context, WidgetRef ref) {
  final status = ref.watch(syncStatusProvider);
  final pendingCount = ref.watch(pendingOperationCountProvider);

  return switch (status) {
    SyncStatus.syncing => Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Syncing...'),
        ],
      ),
    SyncStatus.synced => Icon(Icons.cloud_done, color: Colors.green),
    SyncStatus.offline => Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange),
          if (pendingCount > 0)
            Text(' ($pendingCount pending)'),
        ],
      ),
    SyncStatus.error => Icon(Icons.cloud_off, color: Colors.red),
  };
}
```

### Item-Level Sync Status

```dart
Widget buildItemTile(Item item) {
  return ListTile(
    title: Text(item.title),
    trailing: switch (item.syncStatus) {
      SyncStatus.synced => null, // No indicator needed
      SyncStatus.pendingCreate ||
      SyncStatus.pendingUpdate => Icon(Icons.cloud_upload, size: 16),
      SyncStatus.pendingDelete => Icon(Icons.delete_outline, size: 16),
      SyncStatus.syncFailed => Icon(Icons.error, color: Colors.red, size: 16),
      SyncStatus.conflict => Icon(Icons.warning, color: Colors.orange, size: 16),
    },
  );
}
```

---

## Error Handling and Retry

### Retry with Exponential Backoff

```dart
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  var attempt = 0;
  var delay = initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;

      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
}

// Usage
await withRetry(() => _remote.update(entity));
```

### Handling Specific Errors

```dart
Future<void> _executeOperation(SyncOperation op) async {
  try {
    // ... execute
  } on NetworkException {
    // Network error - retry later
    throw SyncRetryException('Network unavailable');
  } on ConflictException catch (e) {
    // Conflict - needs resolution
    await _handleConflict(op, e.serverVersion);
  } on AuthException {
    // Auth expired - need re-login
    await _handleAuthExpired();
    throw SyncAbortException('Re-authentication required');
  } on NotFoundException {
    // Item deleted on server - remove locally
    await _local.delete(op.entityId);
    await _queue.complete(op.id);
  }
}
```

---

## Verifying Sync Implementation

Run `/testing` for comprehensive sync verification. Example patterns:

### Unit Verification Example

```dart
void main() {
  group('SyncService', () {
    late MockSyncQueue mockQueue;
    late MockRemoteDataSource mockRemote;
    late MockLocalDataSource mockLocal;
    late SyncService syncService;

    setUp(() {
      mockQueue = MockSyncQueue();
      mockRemote = MockRemoteDataSource();
      mockLocal = MockLocalDataSource();
      syncService = SyncService(
        queue: mockQueue,
        remote: mockRemote,
        local: mockLocal,
      );
    });

    test('syncs pending operations', () async {
      final op = SyncOperation(
        id: '1',
        type: SyncOperationType.create,
        entityType: 'task',
        entityId: 'task-1',
        payload: {'title': 'Test'},
        createdAt: DateTime.now(),
      );

      when(mockQueue.getPending()).thenAnswer((_) async => [op]);
      when(mockRemote.create(any, any)).thenAnswer((_) async => 'server-id');

      final result = await syncService.sync();

      expect(result.succeeded, 1);
      verify(mockQueue.complete('1')).called(1);
      verify(mockLocal.updateServerId('task-1', 'server-id')).called(1);
    });

    test('handles conflicts with LWW', () async {
      // Test conflict resolution
    });
  });
}
```

### Integration Verification Example

```dart
testWidgets('syncs when coming back online', (tester) async {
  // Setup
  final mockConnectivity = MockConnectivityService();
  mockConnectivity.setOffline();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWithValue(mockConnectivity),
      ],
      child: const MyApp(),
    ),
  );

  // Create item while offline
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  // Verify pending indicator
  expect(find.byIcon(Icons.cloud_upload), findsOneWidget);

  // Go online
  mockConnectivity.setOnline();
  await tester.pumpAndSettle();

  // Verify synced
  expect(find.byIcon(Icons.cloud_upload), findsNothing);
});
```

---

## Related Documentation

- [architecture-guide.md](architecture-guide.md) - Offline architecture patterns
- [storage-guide.md](storage-guide.md) - Local storage setup
- Flutter docs: [WorkManager](https://pub.dev/packages/workmanager)
