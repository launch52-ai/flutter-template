// Template: Base offline entity mixin
//
// Location: lib/core/domain/
//
// Usage:
// 1. Copy to target location
// 2. Mix into domain entities that need offline support

import 'sync_status.dart';

/// Mixin for entities that support offline-first operations.
///
/// Provides required fields for sync tracking between local
/// storage and remote server.
mixin OfflineEntity {
  /// Client-generated unique ID (UUID).
  ///
  /// Generated locally before any server interaction.
  /// Used as primary key in local storage.
  String get localId;

  /// Server-assigned ID after successful sync.
  ///
  /// Null until the entity is synced to the server.
  String? get serverId;

  /// Current synchronization status.
  SyncStatus get syncStatus;

  /// When the entity was last modified locally.
  DateTime get localUpdatedAt;

  /// When the entity was last modified on server.
  ///
  /// Used for conflict detection.
  DateTime? get serverUpdatedAt;
}

// -----------------------------------------------------
// Example domain entity using the mixin:
// -----------------------------------------------------
//
// import 'package:freezed_annotation/freezed_annotation.dart';
// import '../../../core/domain/offline_entity.dart';
// import '../../../core/data/sync/sync_status.dart';
//
// part 'task.freezed.dart';
//
// @freezed
// abstract class Task with _$Task, OfflineEntity {
//   const Task._();
//
//   const factory Task({
//     // Offline fields
//     required String localId,
//     String? serverId,
//     @Default(SyncStatus.synced) SyncStatus syncStatus,
//     required DateTime localUpdatedAt,
//     DateTime? serverUpdatedAt,
//
//     // Business fields
//     required String title,
//     String? description,
//     @Default(false) bool isCompleted,
//     required DateTime createdAt,
//   }) = _Task;
//
//   /// Effective ID for use in the app.
//   ///
//   /// Returns serverId if synced, otherwise localId.
//   String get effectiveId => serverId ?? localId;
//
//   /// Whether the entity has been synced to server at least once.
//   bool get hasBeenSynced => serverId != null;
//
//   /// Whether the entity has local changes pending sync.
//   bool get hasPendingChanges => syncStatus.isPending;
// }

// -----------------------------------------------------
// Example DTO mapping with offline fields:
// -----------------------------------------------------
//
// @freezed
// abstract class TaskModel with _$TaskModel {
//   const TaskModel._();
//
//   const factory TaskModel({
//     // Offline tracking (local only, not serialized to JSON)
//     @JsonKey(includeFromJson: false, includeToJson: false)
//     required String localId,
//
//     @JsonKey(name: 'id')
//     String? serverId,
//
//     @JsonKey(includeFromJson: false, includeToJson: false)
//     @Default(SyncStatus.synced) SyncStatus syncStatus,
//
//     @JsonKey(includeFromJson: false, includeToJson: false)
//     required DateTime localUpdatedAt,
//
//     @JsonKey(name: 'updated_at')
//     DateTime? serverUpdatedAt,
//
//     // Business fields
//     required String title,
//     String? description,
//     @JsonKey(name: 'is_completed')
//     @Default(false) bool isCompleted,
//     @JsonKey(name: 'created_at')
//     required DateTime createdAt,
//   }) = _TaskModel;
//
//   factory TaskModel.fromJson(Map<String, dynamic> json) =>
//       _$TaskModelFromJson(json);
//
//   /// Convert to domain entity.
//   Task toEntity() => Task(
//     localId: localId,
//     serverId: serverId,
//     syncStatus: syncStatus,
//     localUpdatedAt: localUpdatedAt,
//     serverUpdatedAt: serverUpdatedAt,
//     title: title,
//     description: description,
//     isCompleted: isCompleted,
//     createdAt: createdAt,
//   );
//
//   /// Create from domain entity.
//   factory TaskModel.fromEntity(Task entity) => TaskModel(
//     localId: entity.localId,
//     serverId: entity.serverId,
//     syncStatus: entity.syncStatus,
//     localUpdatedAt: entity.localUpdatedAt,
//     serverUpdatedAt: entity.serverUpdatedAt,
//     title: entity.title,
//     description: entity.description,
//     isCompleted: entity.isCompleted,
//     createdAt: entity.createdAt,
//   );
//
//   /// Create JSON for API (excludes local-only fields).
//   Map<String, dynamic> toApiJson() => {
//     if (serverId != null) 'id': serverId,
//     'title': title,
//     if (description != null) 'description': description,
//     'is_completed': isCompleted,
//     'created_at': createdAt.toIso8601String(),
//     'updated_at': localUpdatedAt.toIso8601String(),
//   };
// }
