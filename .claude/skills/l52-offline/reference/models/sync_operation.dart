// Template: Sync operation model for queue
//
// Location: lib/core/data/sync/
//
// Usage:
// 1. Copy to target location
// 2. Adjust payload serialization as needed
// 3. Register Hive adapter if using Hive

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_operation.freezed.dart';
part 'sync_operation.g.dart';

/// Type of sync operation.
enum SyncOperationType {
  /// Create new entity on server.
  create,

  /// Update existing entity on server.
  update,

  /// Delete entity from server.
  delete,
}

/// A queued operation pending synchronization with the server.
///
/// Operations are persisted locally and executed in order when online.
@freezed
abstract class SyncOperation with _$SyncOperation {
  const SyncOperation._();

  const factory SyncOperation({
    /// Unique operation ID (UUID).
    required String id,

    /// Type of operation (create/update/delete).
    required SyncOperationType type,

    /// Entity type (e.g., 'task', 'note').
    required String entityType,

    /// Local ID of the entity being synced.
    required String entityId,

    /// Serialized entity data for create/update.
    required Map<String, dynamic> payload,

    /// When operation was created.
    required DateTime createdAt,

    /// Number of sync attempts.
    @Default(0) int retryCount,

    /// Time of last sync attempt.
    DateTime? lastAttempt,

    /// Error message from last failed attempt.
    String? errorMessage,
  }) = _SyncOperation;

  factory SyncOperation.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationFromJson(json);

  /// Maximum number of retries before giving up.
  static const maxRetries = 3;

  /// Whether operation has exceeded retry limit.
  bool get hasExceededRetries => retryCount >= maxRetries;

  /// Whether operation should be retried.
  bool get shouldRetry => !hasExceededRetries && errorMessage != null;

  /// Create a "create" operation.
  factory SyncOperation.create({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      id: _generateId(),
      type: SyncOperationType.create,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  /// Create an "update" operation.
  factory SyncOperation.update({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) {
    return SyncOperation(
      id: _generateId(),
      type: SyncOperationType.update,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  /// Create a "delete" operation.
  factory SyncOperation.delete({
    required String entityType,
    required String entityId,
  }) {
    return SyncOperation(
      id: _generateId(),
      type: SyncOperationType.delete,
      entityType: entityType,
      entityId: entityId,
      payload: const {},
      createdAt: DateTime.now(),
    );
  }

  /// Mark as failed with error message.
  SyncOperation markFailed(String error) {
    return copyWith(
      retryCount: retryCount + 1,
      lastAttempt: DateTime.now(),
      errorMessage: error,
    );
  }

  static String _generateId() {
    // Use UUID package in actual implementation
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}

// -----------------------------------------------------
// Drift table definition:
// -----------------------------------------------------
//
// class SyncOperations extends Table {
//   TextColumn get id => text()();
//   IntColumn get type => intEnum<SyncOperationType>()();
//   TextColumn get entityType => text()();
//   TextColumn get entityId => text()();
//   TextColumn get payload => text()(); // JSON string
//   DateTimeColumn get createdAt => dateTime()();
//   IntColumn get retryCount => integer().withDefault(const Constant(0))();
//   DateTimeColumn get lastAttempt => dateTime().nullable()();
//   TextColumn get errorMessage => text().nullable()();
//
//   @override
//   Set<Column> get primaryKey => {id};
// }

// -----------------------------------------------------
// Hive adapter:
// -----------------------------------------------------
//
// @HiveType(typeId: 10)
// class SyncOperationHive extends HiveObject {
//   @HiveField(0)
//   final String id;
//
//   @HiveField(1)
//   final int typeIndex;
//
//   @HiveField(2)
//   final String entityType;
//
//   @HiveField(3)
//   final String entityId;
//
//   @HiveField(4)
//   final String payloadJson;
//
//   @HiveField(5)
//   final DateTime createdAt;
//
//   @HiveField(6)
//   int retryCount;
//
//   @HiveField(7)
//   DateTime? lastAttempt;
//
//   @HiveField(8)
//   String? errorMessage;
//
//   SyncOperationHive({...});
//
//   SyncOperation toModel() => SyncOperation(
//     id: id,
//     type: SyncOperationType.values[typeIndex],
//     entityType: entityType,
//     entityId: entityId,
//     payload: jsonDecode(payloadJson),
//     createdAt: createdAt,
//     retryCount: retryCount,
//     lastAttempt: lastAttempt,
//     errorMessage: errorMessage,
//   );
//
//   factory SyncOperationHive.fromModel(SyncOperation op) => SyncOperationHive(
//     id: op.id,
//     typeIndex: op.type.index,
//     entityType: op.entityType,
//     entityId: op.entityId,
//     payloadJson: jsonEncode(op.payload),
//     createdAt: op.createdAt,
//     retryCount: op.retryCount,
//     lastAttempt: op.lastAttempt,
//     errorMessage: op.errorMessage,
//   );
// }
