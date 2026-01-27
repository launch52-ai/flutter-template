// Template: Hive-based local data source
//
// Location: lib/features/{feature}/data/data_sources/
//
// Usage:
// 1. Copy to target location
// 2. Create Hive model with @HiveType annotation
// 3. Register adapter in main.dart
// 4. Open box before using

import 'dart:async';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/task_model.dart';
import '../../domain/entities/sync_status.dart';

/// Local data source using Hive for Task entities.
///
/// Provides fast key-value storage with reactive streams.
final class TasksLocalDataSource {
  TasksLocalDataSource({String? boxName}) : _boxName = boxName ?? 'tasks';

  final String _boxName;

  /// Get the Hive box (must be opened first).
  Box<TaskHiveModel> get _box => Hive.box<TaskHiveModel>(_boxName);

  // ─────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────

  /// Initialize Hive and open boxes.
  ///
  /// Call once at app startup before using data source.
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    // Open boxes
    await Hive.openBox<TaskHiveModel>('tasks');
    await Hive.openBox<SyncOperationHive>('sync_queue');
  }

  /// Initialize with encryption.
  static Future<void> initializeEncrypted(List<int> encryptionKey) async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }

    // Open encrypted boxes
    final cipher = HiveAesCipher(encryptionKey);
    await Hive.openBox<TaskHiveModel>('tasks', encryptionCipher: cipher);
    await Hive.openBox<SyncOperationHive>('sync_queue', encryptionCipher: cipher);
  }

  // ─────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────

  /// Get all tasks.
  List<TaskModel> getAll() {
    return _box.values.map((h) => h.toModel()).toList();
  }

  /// Watch all tasks (reactive stream).
  Stream<List<TaskModel>> watchAll() {
    // Initial value
    final controller = StreamController<List<TaskModel>>();
    controller.add(getAll());

    // Watch for changes
    final subscription = _box.watch().listen((_) {
      controller.add(getAll());
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Get task by local ID.
  TaskModel? getById(String localId) {
    final hiveModel = _box.get(localId);
    return hiveModel?.toModel();
  }

  /// Get task by server ID.
  TaskModel? getByServerId(String serverId) {
    final hiveModel = _box.values.where((t) => t.serverId == serverId).firstOrNull;
    return hiveModel?.toModel();
  }

  /// Get tasks pending sync.
  List<TaskModel> getPendingSync() {
    return _box.values
        .where((t) => t.syncStatus != SyncStatus.synced)
        .map((h) => h.toModel())
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────

  /// Save task (insert or update).
  Future<void> save(TaskModel model) async {
    await _box.put(model.localId, TaskHiveModel.fromModel(model));
  }

  /// Save multiple tasks.
  Future<void> saveAll(List<TaskModel> models) async {
    final map = {
      for (final m in models) m.localId: TaskHiveModel.fromModel(m),
    };
    await _box.putAll(map);
  }

  /// Replace all tasks (for full refresh).
  Future<void> replaceAll(List<TaskModel> models) async {
    await _box.clear();
    await saveAll(models);
  }

  /// Delete task.
  Future<void> delete(String localId) async {
    await _box.delete(localId);
  }

  /// Clear all tasks.
  Future<void> clear() async {
    await _box.clear();
  }

  // ─────────────────────────────────────────────────────────────────
  // Sync Status Updates
  // ─────────────────────────────────────────────────────────────────

  /// Update sync status for a task.
  Future<void> updateSyncStatus(
    String localId,
    SyncStatus status, {
    String? serverId,
  }) async {
    final existing = _box.get(localId);
    if (existing != null) {
      existing.syncStatus = status;
      if (serverId != null) {
        existing.serverId = serverId;
      }
      await existing.save();
    }
  }

  /// Mark task as synced.
  Future<void> markSynced(String localId, String serverId) async {
    await updateSyncStatus(localId, SyncStatus.synced, serverId: serverId);
  }
}

// ─────────────────────────────────────────────────────────────────
// Hive Model
// ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class TaskHiveModel extends HiveObject {
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
  final DateTime createdAt;

  @HiveField(7)
  DateTime localUpdatedAt;

  @HiveField(8)
  DateTime? serverUpdatedAt;

  TaskHiveModel({
    required this.localId,
    this.serverId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.localUpdatedAt,
    this.serverUpdatedAt,
  });

  /// Convert to Freezed model.
  TaskModel toModel() => TaskModel(
        localId: localId,
        serverId: serverId,
        title: title,
        description: description,
        isCompleted: isCompleted,
        syncStatus: syncStatus,
        createdAt: createdAt,
        localUpdatedAt: localUpdatedAt,
        serverUpdatedAt: serverUpdatedAt,
      );

  /// Create from Freezed model.
  factory TaskHiveModel.fromModel(TaskModel model) => TaskHiveModel(
        localId: model.localId,
        serverId: model.serverId,
        title: model.title,
        description: model.description,
        isCompleted: model.isCompleted,
        syncStatus: model.syncStatus,
        createdAt: model.createdAt,
        localUpdatedAt: model.localUpdatedAt,
        serverUpdatedAt: model.serverUpdatedAt,
      );
}

// ─────────────────────────────────────────────────────────────────
// Type Adapters
// ─────────────────────────────────────────────────────────────────

class TaskHiveModelAdapter extends TypeAdapter<TaskHiveModel> {
  @override
  final int typeId = 0;

  @override
  TaskHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskHiveModel(
      localId: fields[0] as String,
      serverId: fields[1] as String?,
      title: fields[2] as String,
      description: fields[3] as String?,
      isCompleted: fields[4] as bool,
      syncStatus: fields[5] as SyncStatus,
      createdAt: fields[6] as DateTime,
      localUpdatedAt: fields[7] as DateTime,
      serverUpdatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.syncStatus)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.localUpdatedAt)
      ..writeByte(8)
      ..write(obj.serverUpdatedAt);
  }
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 1;

  @override
  SyncStatus read(BinaryReader reader) {
    return SyncStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────
// Sync Operation Hive Model
// ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 10)
class SyncOperationHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int typeIndex;

  @HiveField(2)
  final String entityType;

  @HiveField(3)
  final String entityId;

  @HiveField(4)
  final String payloadJson;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  DateTime? lastAttempt;

  @HiveField(8)
  String? errorMessage;

  SyncOperationHive({
    required this.id,
    required this.typeIndex,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttempt,
    this.errorMessage,
  });
}

// ─────────────────────────────────────────────────────────────────
// Stub types (replace with actual)
// ─────────────────────────────────────────────────────────────────

// Replace with your actual TaskModel from Freezed
class TaskModel {
  final String localId;
  final String? serverId;
  final String title;
  final String? description;
  final bool isCompleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  final DateTime? serverUpdatedAt;

  TaskModel({
    required this.localId,
    this.serverId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.syncStatus = SyncStatus.pendingCreate,
    required this.createdAt,
    required this.localUpdatedAt,
    this.serverUpdatedAt,
  });
}
