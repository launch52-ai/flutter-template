// Template: Drift (SQLite) database setup with offline support
//
// Location: lib/core/database/
//
// Usage:
// 1. Copy to target location
// 2. Add your tables
// 3. Run: dart run build_runner build --delete-conflicting-outputs
// 4. Initialize in main.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────
// Sync Status Enum
// ─────────────────────────────────────────────────────────────────

enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  syncFailed,
  conflict,
}

// ─────────────────────────────────────────────────────────────────
// Tables
// ─────────────────────────────────────────────────────────────────

/// Example offline-capable entity table.
class Tasks extends Table {
  /// Client-generated UUID (primary key).
  TextColumn get localId => text()();

  /// Server-assigned ID (null until synced).
  TextColumn get serverId => text().nullable()();

  /// Task title.
  TextColumn get title => text().withLength(min: 1, max: 500)();

  /// Task description.
  TextColumn get description => text().nullable()();

  /// Completion status.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Sync status (stored as int index).
  IntColumn get syncStatus => intEnum<SyncStatus>()
      .withDefault(Constant(SyncStatus.synced.index))();

  /// When created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// When last modified locally.
  DateTimeColumn get localUpdatedAt => dateTime()();

  /// When last modified on server (for conflict detection).
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};

  @override
  List<String> get customConstraints => [
        // Index for efficient sync queries
        'CREATE INDEX IF NOT EXISTS idx_tasks_sync_status ON tasks(sync_status)',
        // Index for server ID lookups
        'CREATE INDEX IF NOT EXISTS idx_tasks_server_id ON tasks(server_id)',
      ];
}

/// Queue of pending sync operations.
class SyncOperations extends Table {
  /// Operation ID (UUID).
  TextColumn get id => text()();

  /// Operation type (create/update/delete).
  IntColumn get type => integer()();

  /// Entity type name (e.g., 'task', 'note').
  TextColumn get entityType => text()();

  /// Local ID of entity being synced.
  TextColumn get entityId => text()();

  /// JSON payload for create/update operations.
  TextColumn get payload => text()();

  /// When operation was queued.
  DateTimeColumn get createdAt => dateTime()();

  /// Number of sync attempts.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Time of last sync attempt.
  DateTimeColumn get lastAttempt => dateTime().nullable()();

  /// Error message from last failed attempt.
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        // Index for FIFO processing
        'CREATE INDEX IF NOT EXISTS idx_sync_ops_created ON sync_operations(created_at)',
        // Index for entity-specific queries
        'CREATE INDEX IF NOT EXISTS idx_sync_ops_entity ON sync_operations(entity_id)',
      ];
}

/// Sync metadata for tracking last sync time.
class SyncMetadata extends Table {
  /// Entity type or 'global'.
  TextColumn get key => text()();

  /// Last successful sync timestamp.
  DateTimeColumn get lastSyncAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─────────────────────────────────────────────────────────────────
// Database Class
// ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Tasks, SyncOperations, SyncMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Example: Add column in version 2
          // if (from < 2) {
          //   await m.addColumn(tasks, tasks.priority);
          // }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ─────────────────────────────────────────────────────────────────
  // Singleton Access
  // ─────────────────────────────────────────────────────────────────

  static AppDatabase? _instance;

  static AppDatabase get instance => _instance ??= AppDatabase();

  static Future<void> initialize() async {
    _instance = AppDatabase();
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  // ─────────────────────────────────────────────────────────────────
  // Task Queries
  // ─────────────────────────────────────────────────────────────────

  /// Get all tasks.
  Future<List<Task>> getAllTasks() => select(tasks).get();

  /// Watch all tasks (reactive stream).
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  /// Get task by local ID.
  Future<Task?> getTaskById(String localId) {
    return (select(tasks)..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Get task by server ID.
  Future<Task?> getTaskByServerId(String serverId) {
    return (select(tasks)..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  /// Get tasks pending sync.
  Future<List<Task>> getTasksPendingSync() {
    return (select(tasks)
          ..where((t) => t.syncStatus.isNotIn([SyncStatus.synced.index])))
        .get();
  }

  /// Insert or update task.
  Future<void> upsertTask(TasksCompanion task) {
    return into(tasks).insertOnConflictUpdate(task);
  }

  /// Delete task.
  Future<int> deleteTask(String localId) {
    return (delete(tasks)..where((t) => t.localId.equals(localId))).go();
  }

  /// Update sync status for task.
  Future<void> updateTaskSyncStatus(String localId, SyncStatus status,
      {String? serverId}) {
    return (update(tasks)..where((t) => t.localId.equals(localId))).write(
      TasksCompanion(
        syncStatus: Value(status.index),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Sync Operation Queries
  // ─────────────────────────────────────────────────────────────────

  /// Get pending sync operations in FIFO order.
  Future<List<SyncOperation>> getPendingSyncOps() {
    return (select(syncOperations)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get sync operations for an entity.
  Future<List<SyncOperation>> getSyncOpsForEntity(String entityId) {
    return (select(syncOperations)
          ..where((t) => t.entityId.equals(entityId)))
        .get();
  }

  /// Add sync operation.
  Future<void> addSyncOp(SyncOperationsCompanion op) {
    return into(syncOperations).insert(op);
  }

  /// Remove completed sync operation.
  Future<int> removeSyncOp(String id) {
    return (delete(syncOperations)..where((t) => t.id.equals(id))).go();
  }

  /// Update sync operation after failure.
  Future<void> markSyncOpFailed(String id, String error) async {
    final existing = await (select(syncOperations)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(syncOperations)..where((t) => t.id.equals(id))).write(
        SyncOperationsCompanion(
          retryCount: Value(existing.retryCount + 1),
          lastAttempt: Value(DateTime.now()),
          errorMessage: Value(error),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Sync Metadata Queries
  // ─────────────────────────────────────────────────────────────────

  /// Get last sync time for entity type.
  Future<DateTime?> getLastSyncTime(String entityType) async {
    final result = await (select(syncMetadata)
          ..where((t) => t.key.equals(entityType)))
        .getSingleOrNull();
    return result?.lastSyncAt;
  }

  /// Update last sync time.
  Future<void> setLastSyncTime(String entityType, DateTime time) {
    return into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion(
        key: Value(entityType),
        lastSyncAt: Value(time),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Database Connection
// ─────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.db'));

    return NativeDatabase.createInBackground(file);
  });
}

// ─────────────────────────────────────────────────────────────────
// Encrypted Database (Optional - use sqlcipher_flutter_libs)
// ─────────────────────────────────────────────────────────────────
//
// For encrypted database, replace _openConnection with:
//
// import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
// import 'package:sqlite3/open.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// LazyDatabase _openEncryptedConnection() {
//   return LazyDatabase(() async {
//     // Get or generate encryption key
//     const secureStorage = FlutterSecureStorage();
//     var key = await secureStorage.read(key: 'db_encryption_key');
//     if (key == null) {
//       final random = Random.secure();
//       final bytes = List<int>.generate(32, (_) => random.nextInt(256));
//       key = base64Encode(bytes);
//       await secureStorage.write(key: 'db_encryption_key', value: key);
//     }
//
//     final dbFolder = await getApplicationDocumentsDirectory();
//     final file = File(p.join(dbFolder.path, 'app_encrypted.db'));
//
//     // Configure SQLCipher
//     open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
//
//     return NativeDatabase.createInBackground(
//       file,
//       setup: (db) {
//         db.execute("PRAGMA key = '$key'");
//       },
//     );
//   });
// }
