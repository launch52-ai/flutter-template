# Offline Architecture Guide

Comprehensive guide for choosing and implementing offline architecture patterns in Flutter apps.

---

## Offline Architecture Patterns

### Pattern 1: Fully Offline-First

**Best for:** Notes, journals, todo apps, field data collection

The local database is the **primary source of truth**. Remote sync is optional/secondary.

```
User Action → Local DB → UI Update → Background Sync → Remote
                ↓
           Immediate feedback
```

**Characteristics:**
- App works 100% without internet
- Local changes are immediately visible
- Sync happens in background
- Remote is backup/sharing mechanism

**Trade-offs:**
- Requires robust conflict resolution
- More complex data model (sync metadata)
- User may see stale data from other devices

**See:** `reference/repositories/offline_repository.dart`

---

### Pattern 2: Offline-First with Sync

**Best for:** Travel apps, field service, inventory management

Local database is primary, but sync is expected and important.

```
User Action → Local DB → UI Update → Sync Queue → Remote (when online)
                ↓                         ↓
           Immediate feedback      Conflict resolution
```

**Characteristics:**
- Full offline functionality
- Sync queue persists operations
- Automatic sync on reconnect
- Conflict detection and resolution

**Trade-offs:**
- Need to handle sync failures
- Queue management complexity
- Potential data conflicts

---

### Pattern 3: Online-First with Offline Fallback

**Best for:** E-commerce, social apps, news readers

Remote is primary; local cache provides fallback when offline.

```
User Action → Remote API → Local Cache → UI Update
                ↓ (offline?)
            Local Cache → UI Update → Queue for Sync
```

**Characteristics:**
- Fresh data when online
- Cached data when offline
- Write operations queued
- Sync on reconnect

**Trade-offs:**
- Limited offline write capability
- Need to show "offline mode" state
- Stale data indicators needed

**See:** `reference/repositories/cache_first_repository.dart`

---

### Pattern 4: Cache-Only (Read-Heavy)

**Best for:** News feeds, product catalogs, reference data

Local cache for fast reads; server is always authoritative.

```
Read Request → Check Cache → Cache Hit? → Return cached
                   ↓ (miss/stale)
              Fetch Remote → Update Cache → Return fresh
```

**Characteristics:**
- Fast reads from cache
- No offline writes
- TTL-based invalidation
- Pull-to-refresh updates

**Trade-offs:**
- No offline write support
- May show stale data
- Simpler implementation

---

## Decision Matrix

| Factor | Fully Offline | Offline + Sync | Online + Fallback | Cache-Only |
|--------|---------------|----------------|-------------------|------------|
| Internet required | Never | Rarely | Usually | For fresh data |
| Write offline | Yes | Yes | Limited | No |
| Sync complexity | High | High | Medium | Low |
| Conflict handling | Required | Required | Rare | None |
| Data freshness | User syncs | Background | Always fresh | TTL-based |
| Implementation | Complex | Complex | Medium | Simple |

---

## Hybrid Approaches

### Read Offline, Write Online

Common for apps where reads are frequent but writes need validation:

```dart
// Read: local-first
Future<List<Product>> getProducts() async {
  final local = await _localSource.getAll();
  if (local.isNotEmpty) return local;
  return _fetchAndCache();
}

// Write: online-only with queue
Future<void> placeOrder(Order order) async {
  if (await _isOnline()) {
    await _remoteSource.createOrder(order);
  } else {
    await _syncQueue.enqueue(SyncOperation.create(order));
    throw const OfflineException('Order queued for sync');
  }
}
```

### Critical vs. Non-Critical Data

Different strategies for different data types:

```dart
// Critical data (orders, payments): Online-first
Future<void> submitPayment(Payment payment) async {
  // Must be online for payments
  await _remoteSource.processPayment(payment);
  await _localSource.savePayment(payment);
}

// Non-critical data (favorites, notes): Offline-first
Future<void> addFavorite(String productId) async {
  await _localSource.addFavorite(productId);
  _syncQueue.enqueue(SyncOperation.addFavorite(productId));
}
```

---

## Data Model Considerations

### Sync Metadata Fields

Every offline-capable entity needs:

```dart
@freezed
abstract class OfflineEntity {
  // Client-generated UUID (created before server knows about it)
  String get localId;

  // Server ID (null until synced)
  String? get serverId;

  // Sync tracking
  SyncStatus get syncStatus;
  DateTime get localUpdatedAt;
  DateTime? get serverUpdatedAt;

  // Conflict detection
  int get version; // Optimistic locking
}
```

**See:** `reference/models/offline_entity.dart`

### Client-Generated IDs

Always generate IDs locally for offline support:

```dart
import 'package:uuid/uuid.dart';

final class IdGenerator {
  static const _uuid = Uuid();

  static String generate() => _uuid.v4();
}

// Usage
final newItem = Item(
  localId: IdGenerator.generate(),
  // ... other fields
);
```

### Sync Status Enum

```dart
enum SyncStatus {
  /// Synced with server
  synced,

  /// Created locally, not yet synced
  pendingCreate,

  /// Modified locally, pending sync
  pendingUpdate,

  /// Marked for deletion, pending sync
  pendingDelete,

  /// Sync failed, needs retry
  syncFailed,

  /// Conflict detected, needs resolution
  conflict,
}
```

**See:** `reference/models/sync_status.dart`

---

## Storage Layer Architecture

### Repository Pattern with Offline Support

```
┌─────────────────────────────────────────────────────────┐
│                    Repository                            │
│  (Orchestrates local/remote, handles sync logic)        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐     ┌─────────────────┐          │
│  │  Local Source   │     │  Remote Source  │          │
│  │  (Drift/Hive)   │     │     (Dio)       │          │
│  └─────────────────┘     └─────────────────┘          │
│                                                         │
│  ┌─────────────────┐     ┌─────────────────┐          │
│  │   Sync Queue    │     │  Sync Service   │          │
│  │ (Pending ops)   │     │ (Orchestration) │          │
│  └─────────────────┘     └─────────────────┘          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Data Flow: Offline-First Write

```
1. User creates item
   ↓
2. Generate localId (UUID)
   ↓
3. Save to local DB (syncStatus: pendingCreate)
   ↓
4. Return success to UI (optimistic)
   ↓
5. Enqueue sync operation
   ↓
6. When online: Execute sync
   ↓
7. On success: Update syncStatus to synced, save serverId
   ↓
8. On conflict: Resolve per strategy, update local
   ↓
9. On failure: Retry with backoff, mark syncFailed after max retries
```

---

## Background Sync Architecture

### WorkManager Integration

For reliable background sync that survives app restarts:

```dart
// Register background task
await Workmanager().registerPeriodicTask(
  'sync-task',
  'syncData',
  frequency: const Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  ),
);

// Task callback (runs in isolate)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'syncData') {
      final syncService = await SyncService.initialize();
      await syncService.syncAll();
      return true;
    }
    return false;
  });
}
```

**Note:** WorkManager tasks run in a separate isolate. Initialize dependencies carefully.

### Sync on Connectivity Change

```dart
// In app startup
connectivityService.onConnectivityChanged.listen((status) {
  if (status != ConnectivityResult.none) {
    ref.read(syncServiceProvider).syncPendingOperations();
  }
});
```

---

## Performance Considerations

### Large Datasets

For apps with thousands of records:

1. **Pagination:** Load data in pages
2. **Delta sync:** Only fetch changes since last sync
3. **Lazy loading:** Load details on demand
4. **Indexing:** Index frequently queried fields

```dart
// Delta sync with timestamp
Future<List<Item>> syncChanges() async {
  final lastSync = await _localSource.getLastSyncTime();
  final changes = await _remoteSource.getChangesSince(lastSync);

  for (final change in changes) {
    await _localSource.upsert(change);
  }

  await _localSource.setLastSyncTime(DateTime.now());
  return _localSource.getAll();
}
```

### Data Pruning

Prevent unbounded local storage growth:

```dart
// Prune old data periodically
Future<void> pruneOldData() async {
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  await _localSource.deleteWhere(
    (t) => t.syncStatus.equals(SyncStatus.synced) &
           t.createdAt.isSmallerThan(cutoff),
  );
}
```

### Cache Strategies

| Strategy | TTL | Use Case |
|----------|-----|----------|
| **Short TTL** | 1-5 min | Frequently changing data |
| **Medium TTL** | 15-60 min | Semi-static data |
| **Long TTL** | 24h+ | Reference data, catalogs |
| **Stale-while-revalidate** | Serve stale, fetch fresh | UX priority |

---

## Security Considerations

### Encrypted Local Storage

For sensitive data, use encrypted storage:

**Drift with SQLCipher:**
```yaml
dependencies:
  sqlcipher_flutter_libs: ^0.6.0  # Instead of sqlite3_flutter_libs
```

**Hive with encryption:**
```dart
final encryptionKey = await SecureStorage.read('hive_key') ??
    await _generateAndStoreKey();

await Hive.openBox<MyModel>(
  'my_box',
  encryptionCipher: HiveAesCipher(encryptionKey),
);
```

### Data Classification

| Classification | Storage | Example |
|----------------|---------|---------|
| Public | Any | Product catalog |
| Internal | Encrypted DB | User preferences |
| Sensitive | SecureStorage | Auth tokens |
| PII | Encrypted DB | User profile |

---

## Verification Scenarios

Verify offline functionality with these scenarios:

| Scenario | What to Check |
|----------|---------------|
| Offline read | Data available without network |
| Offline write | Operations queued correctly |
| Sync on reconnect | Queue flushed on connectivity |
| Conflict resolution | Correct strategy applied |
| Error recovery | Graceful handling of sync failures |

**See:** Run `/testing` for comprehensive offline test patterns.

---

## Related Documentation

- [storage-guide.md](storage-guide.md) - Drift and Hive setup
- [sync-guide.md](sync-guide.md) - Sync strategies and conflict resolution
- Flutter docs: [Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
