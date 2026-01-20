# Storage Guide

Setup and configuration for local storage solutions in offline-first Flutter apps.

---

## Storage Comparison

| Feature | Drift (SQLite) | Hive | Isar |
|---------|----------------|------|------|
| **Type** | Relational SQL | Key-value/NoSQL | NoSQL |
| **Query Power** | Full SQL, joins, views | Basic filters | Powerful queries |
| **Performance** | Fast | Very fast | Fastest |
| **Encryption** | AES-256 (SQLCipher) | AES-256 built-in | Limited |
| **Type Safety** | Excellent | Good | Excellent |
| **Migrations** | Built-in | Manual | Automatic |
| **Best For** | Complex relational data | Simple objects, settings | Large datasets |

### When to Use What

**Drift (SQLite):**
- Complex relationships between entities
- Need for SQL joins and aggregations
- Financial/healthcare apps needing encryption
- Migration-heavy schema evolution

**Hive:**
- Simple key-value storage
- User preferences and settings
- Small to medium object collections
- Fast prototyping

**Isar:**
- Very large datasets (100k+ records)
- Full-text search requirements
- Maximum read/write speed
- Complex query patterns

---

## Drift Setup

### Dependencies

```yaml
dependencies:
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0    # Regular SQLite
  # OR for encryption:
  sqlcipher_flutter_libs: ^0.6.0  # Encrypted SQLite
  path_provider: ^2.1.0
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
```

### Database Definition

Create `lib/core/database/app_database.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Define tables
class Tasks extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

class SyncOperations extends Table {
  TextColumn get id => text()();
  IntColumn get type => intEnum<SyncOperationType>()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Tasks, SyncOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Handle migrations
      // if (from < 2) {
      //   await m.addColumn(tasks, tasks.newColumn);
      // }
    },
  );

  // Singleton pattern
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase.createInBackground(file);
  });
}

enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  syncFailed,
  conflict,
}

enum SyncOperationType {
  create,
  update,
  delete,
}
```

### Encrypted Database (SQLCipher)

```dart
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

LazyDatabase _openEncryptedConnection(String encryptionKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_encrypted.db'));

    // Open with encryption
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // Set encryption key
        db.execute("PRAGMA key = '$encryptionKey'");
      },
    );
  });
}

// In app startup
Future<void> initDatabase() async {
  // Get or generate encryption key
  final key = await SecureStorage.read('db_key') ??
      await _generateAndStoreKey();

  _instance = AppDatabase._encrypted(key);
}
```

### DAOs (Data Access Objects)

```dart
part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  /// Get all tasks
  Future<List<Task>> getAll() => select(tasks).get();

  /// Watch all tasks (reactive)
  Stream<List<Task>> watchAll() => select(tasks).watch();

  /// Get pending sync tasks
  Future<List<Task>> getPendingSync() {
    return (select(tasks)
          ..where((t) => t.syncStatus.isNotIn([SyncStatus.synced.index])))
        .get();
  }

  /// Insert or update task
  Future<void> upsert(TasksCompanion task) {
    return into(tasks).insertOnConflictUpdate(task);
  }

  /// Mark as synced
  Future<void> markSynced(String localId, String serverId) {
    return (update(tasks)..where((t) => t.localId.equals(localId))).write(
      TasksCompanion(
        serverId: Value(serverId),
        syncStatus: Value(SyncStatus.synced.index),
      ),
    );
  }

  /// Delete task
  Future<int> deleteById(String localId) {
    return (delete(tasks)..where((t) => t.localId.equals(localId))).go();
  }
}
```

### Run Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

**See:** `reference/local_storage/drift_database.dart`

---

## Hive Setup

### Dependencies

```yaml
dependencies:
  hive_ce: ^2.6.0
  hive_ce_flutter: ^2.1.0
  path_provider: ^2.1.0

dev_dependencies:
  hive_ce_generator: ^1.6.0
  build_runner: ^2.4.0
```

### Initialize Hive

```dart
// In main.dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SyncStatusAdapter());

  // Open boxes
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<SyncOperation>('sync_queue');

  runApp(const MyApp());
}
```

### Model with TypeAdapter

```dart
import 'package:hive_ce/hive_ce.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String localId;

  @HiveField(1)
  String? serverId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  SyncStatus syncStatus;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Task({
    required this.localId,
    this.serverId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return Task(
      localId: localId,
      serverId: serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

@HiveType(typeId: 1)
enum SyncStatus {
  @HiveField(0)
  synced,
  @HiveField(1)
  pendingCreate,
  @HiveField(2)
  pendingUpdate,
  @HiveField(3)
  pendingDelete,
  @HiveField(4)
  syncFailed,
  @HiveField(5)
  conflict,
}
```

### Encrypted Hive Box

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';

Future<Box<Task>> openEncryptedBox() async {
  const secureStorage = FlutterSecureStorage();

  // Get or generate encryption key
  var keyString = await secureStorage.read(key: 'hive_key');
  if (keyString == null) {
    final key = Hive.generateSecureKey();
    keyString = base64Encode(key);
    await secureStorage.write(key: 'hive_key', value: keyString);
  }

  final encryptionKey = base64Decode(keyString);

  return Hive.openBox<Task>(
    'tasks_encrypted',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}
```

### Local Data Source with Hive

```dart
final class TasksLocalDataSource {
  Box<Task> get _box => Hive.box<Task>('tasks');

  /// Get all tasks
  List<Task> getAll() => _box.values.toList();

  /// Watch all tasks (reactive)
  Stream<List<Task>> watchAll() {
    return _box.watch().map((_) => getAll());
  }

  /// Get task by ID
  Task? getById(String localId) => _box.get(localId);

  /// Save task
  Future<void> save(Task task) async {
    await _box.put(task.localId, task);
  }

  /// Delete task
  Future<void> delete(String localId) async {
    await _box.delete(localId);
  }

  /// Get pending sync tasks
  List<Task> getPendingSync() {
    return _box.values
        .where((t) => t.syncStatus != SyncStatus.synced)
        .toList();
  }

  /// Mark as synced
  Future<void> markSynced(String localId, String serverId) async {
    final task = _box.get(localId);
    if (task != null) {
      task.serverId = serverId;
      task.syncStatus = SyncStatus.synced;
      await task.save();
    }
  }
}
```

**See:** `reference/local_storage/hive_local_source.dart`

---

## Isar Setup (Brief)

### Dependencies

```yaml
dependencies:
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.0

dev_dependencies:
  isar_generator: ^3.1.0
  build_runner: ^2.4.0
```

### Collection Definition

```dart
import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String localId;

  String? serverId;

  late String title;
  String? description;
  late bool isCompleted;

  @enumerated
  late SyncStatus syncStatus;

  late DateTime createdAt;
  late DateTime updatedAt;

  // Full-text search index
  @Index(type: IndexType.value)
  List<String> get titleWords => title.split(' ');
}
```

---

## Choosing Storage for Your Data

### Decision Tree

```
Is data relational with complex queries?
├── Yes → Use Drift (SQLite)
└── No
    ├── Is it sensitive/needs encryption?
    │   ├── Yes → Drift with SQLCipher OR Hive with encryption
    │   └── No
    │       ├── Large dataset (10k+ items)?
    │       │   ├── Yes → Isar
    │       │   └── No → Hive
    │       └── Need full-text search?
    │           ├── Yes → Isar
    │           └── No → Hive
```

### Hybrid Approach

For complex apps, use multiple storage solutions:

```dart
// lib/core/services/storage_service.dart
final class StorageService {
  // Drift for main app data
  final AppDatabase database;

  // Hive for preferences and cache
  final Box<dynamic> prefsBox;
  final Box<CachedItem> cacheBox;

  // SecureStorage for sensitive data
  final FlutterSecureStorage secureStorage;

  StorageService({
    required this.database,
    required this.prefsBox,
    required this.cacheBox,
    required this.secureStorage,
  });
}

// Provider
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService(
    database: AppDatabase.instance,
    prefsBox: Hive.box('prefs'),
    cacheBox: Hive.box<CachedItem>('cache'),
    secureStorage: const FlutterSecureStorage(),
  );
}
```

---

## Data Migration Patterns

### Drift Migrations

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    // Version 1 → 2: Add priority column
    if (from < 2) {
      await m.addColumn(tasks, tasks.priority);
    }

    // Version 2 → 3: Add tags table
    if (from < 3) {
      await m.createTable(tags);
      await m.createTable(taskTags);
    }

    // Version 3 → 4: Rename column
    if (from < 4) {
      await m.alterTable(TableMigration(
        tasks,
        columnTransformer: {
          tasks.dueDate: tasks.deadline,
        },
      ));
    }
  },
  beforeOpen: (details) async {
    // Run after migration, before queries
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

### Hive Migrations

Hive doesn't have built-in migrations. Handle manually:

```dart
Future<void> migrateHive() async {
  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('hive_version') ?? 1;

  if (currentVersion < 2) {
    // Migrate Task model
    final oldBox = await Hive.openBox('tasks_v1');
    final newBox = await Hive.openBox<Task>('tasks');

    for (final key in oldBox.keys) {
      final oldData = oldBox.get(key) as Map;
      final newTask = Task(
        localId: oldData['id'],
        title: oldData['title'],
        // Add new required field
        priority: TaskPriority.medium,
        // ...
      );
      await newBox.put(key, newTask);
    }

    await oldBox.deleteFromDisk();
    await prefs.setInt('hive_version', 2);
  }
}
```

---

## Performance Tips

### Batch Operations

**Drift:**
```dart
Future<void> insertBatch(List<TasksCompanion> tasks) async {
  await batch((batch) {
    batch.insertAll(this.tasks, tasks);
  });
}
```

**Hive:**
```dart
Future<void> saveBatch(List<Task> tasks) async {
  final map = {for (final t in tasks) t.localId: t};
  await _box.putAll(map);
}
```

### Indexing (Drift)

```dart
class Tasks extends Table {
  // ...

  @override
  List<Set<Column>>? get uniqueKeys => [
    {localId},
  ];

  // Add indexes for frequently queried columns
  @override
  List<String> get customConstraints => [
    'CREATE INDEX idx_tasks_sync ON tasks(sync_status)',
    'CREATE INDEX idx_tasks_created ON tasks(created_at DESC)',
  ];
}
```

### Lazy Loading

```dart
// Load only headers initially
Future<List<TaskHeader>> loadHeaders({int limit = 50}) async {
  return (select(tasks)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit))
      .map((t) => TaskHeader(id: t.localId, title: t.title))
      .get();
}

// Load full details on demand
Future<Task?> loadDetails(String id) async {
  return (select(tasks)..where((t) => t.localId.equals(id)))
      .getSingleOrNull();
}
```

---

## Related Documentation

- [architecture-guide.md](architecture-guide.md) - Offline architecture patterns
- [sync-guide.md](sync-guide.md) - Sync strategies and conflict resolution
- [Drift documentation](https://drift.simonbinder.eu/)
- [Hive documentation](https://pub.dev/packages/hive_ce)
