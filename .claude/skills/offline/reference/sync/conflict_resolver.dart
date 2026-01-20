// Template: Conflict resolution strategies
//
// Location: lib/core/data/sync/
//
// Usage:
// 1. Copy to target location
// 2. Choose or implement strategy for your use case
// 3. Wire up with SyncService

import '../models/sync_status.dart';

/// Strategy for resolving conflicts between local and remote versions.
enum ConflictStrategy {
  /// Most recent timestamp wins.
  lastWriteWins,

  /// Server version always wins.
  serverWins,

  /// Local version always wins.
  clientWins,

  /// Attempt automatic merge of non-conflicting fields.
  autoMerge,

  /// Always prompt user to resolve.
  userPrompt,
}

/// Result of conflict resolution.
final class ConflictResolution<T> {
  final T resolved;
  final ConflictStrategy strategyUsed;
  final bool needsUserReview;
  final String? message;

  const ConflictResolution({
    required this.resolved,
    required this.strategyUsed,
    this.needsUserReview = false,
    this.message,
  });
}

/// Resolves conflicts between local and remote entity versions.
final class ConflictResolver {
  ConflictResolver({
    this.defaultStrategy = ConflictStrategy.lastWriteWins,
    Map<String, ConflictStrategy>? entityStrategies,
  }) : _entityStrategies = entityStrategies ?? {};

  final ConflictStrategy defaultStrategy;
  final Map<String, ConflictStrategy> _entityStrategies;

  /// Resolve conflict between local and remote versions.
  ///
  /// Returns the resolved entity that should be saved locally.
  Future<dynamic> resolve({
    required dynamic local,
    required dynamic remote,
    String? entityType,
  }) async {
    final strategy = _entityStrategies[entityType] ?? defaultStrategy;

    return switch (strategy) {
      ConflictStrategy.lastWriteWins => _resolveLastWriteWins(local, remote),
      ConflictStrategy.serverWins => _resolveServerWins(remote),
      ConflictStrategy.clientWins => _resolveClientWins(local),
      ConflictStrategy.autoMerge => _resolveAutoMerge(local, remote),
      ConflictStrategy.userPrompt => _resolveUserPrompt(local, remote),
    };
  }

  dynamic _resolveLastWriteWins(dynamic local, dynamic remote) {
    final localTime = local.localUpdatedAt as DateTime;
    final remoteTime = remote.serverUpdatedAt as DateTime? ?? DateTime(1970);

    if (localTime.isAfter(remoteTime)) {
      // Local wins - keep local, mark for push
      return local.copyWith(syncStatus: SyncStatus.pendingUpdate);
    } else {
      // Remote wins - accept server version
      return remote.copyWith(
        localId: local.localId,
        syncStatus: SyncStatus.synced,
        localUpdatedAt: DateTime.now(),
      );
    }
  }

  dynamic _resolveServerWins(dynamic remote) {
    return remote.copyWith(syncStatus: SyncStatus.synced);
  }

  dynamic _resolveClientWins(dynamic local) {
    return local.copyWith(syncStatus: SyncStatus.pendingUpdate);
  }

  dynamic _resolveAutoMerge(dynamic local, dynamic remote) {
    // Override in subclass for entity-specific merge logic
    // Default falls back to LWW
    return _resolveLastWriteWins(local, remote);
  }

  dynamic _resolveUserPrompt(dynamic local, dynamic remote) {
    // Mark as conflict - UI will handle
    return local.copyWith(
      syncStatus: SyncStatus.conflict,
      conflictData: remote.toJson(),
    );
  }
}

// -----------------------------------------------------
// Example: Field-level merge for a Task entity
// -----------------------------------------------------
//
// final class TaskConflictResolver extends ConflictResolver {
//   TaskConflictResolver() : super(defaultStrategy: ConflictStrategy.autoMerge);
//
//   @override
//   Task _resolveAutoMerge(dynamic local, dynamic remote) {
//     final localTask = local as Task;
//     final remoteTask = remote as Task;
//
//     return Task(
//       localId: localTask.localId,
//       serverId: remoteTask.serverId ?? localTask.serverId,
//
//       // Take most recent title
//       title: localTask.titleUpdatedAt.isAfter(remoteTask.titleUpdatedAt)
//           ? localTask.title
//           : remoteTask.title,
//
//       // Take most recent description
//       description: localTask.descriptionUpdatedAt.isAfter(remoteTask.descriptionUpdatedAt)
//           ? localTask.description
//           : remoteTask.description,
//
//       // Server controls completion status
//       isCompleted: remoteTask.isCompleted,
//
//       // Merge tags (union of both)
//       tags: {...localTask.tags, ...remoteTask.tags}.toList(),
//
//       // Use latest timestamps
//       localUpdatedAt: DateTime.now(),
//       serverUpdatedAt: remoteTask.serverUpdatedAt,
//
//       // Mark as synced since we're creating merged version
//       syncStatus: SyncStatus.pendingUpdate,
//     );
//   }
// }

// -----------------------------------------------------
// Example: User-prompted resolution in UI
// -----------------------------------------------------
//
// class ConflictResolutionDialog extends StatelessWidget {
//   final Task localVersion;
//   final Task remoteVersion;
//   final void Function(Task) onResolved;
//
//   const ConflictResolutionDialog({
//     required this.localVersion,
//     required this.remoteVersion,
//     required this.onResolved,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Sync Conflict'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('This item was modified on another device.'),
//           const SizedBox(height: 16),
//           _buildVersionCard('Your version', localVersion),
//           const SizedBox(height: 8),
//           _buildVersionCard('Server version', remoteVersion),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             onResolved(localVersion.copyWith(
//               syncStatus: SyncStatus.pendingUpdate,
//             ));
//             Navigator.pop(context);
//           },
//           child: const Text('Keep Mine'),
//         ),
//         TextButton(
//           onPressed: () {
//             onResolved(remoteVersion.copyWith(
//               localId: localVersion.localId,
//               syncStatus: SyncStatus.synced,
//             ));
//             Navigator.pop(context);
//           },
//           child: const Text('Use Server'),
//         ),
//         ElevatedButton(
//           onPressed: () => _showMergeDialog(context),
//           child: const Text('Merge'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildVersionCard(String label, Task task) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//             Text('Title: ${task.title}'),
//             Text('Modified: ${task.localUpdatedAt}'),
//           ],
//         ),
//       ),
//     );
//   }
// }

// -----------------------------------------------------
// Conflict tracking in entity:
// -----------------------------------------------------
//
// Add to entity for user-prompted resolution:
//
// @freezed
// abstract class Task with _$Task {
//   const factory Task({
//     // ... other fields
//     SyncStatus syncStatus,
//     // Store remote version when conflict detected
//     @JsonKey(includeFromJson: false, includeToJson: false)
//     Map<String, dynamic>? conflictData,
//   }) = _Task;
//
//   /// Get remote version if in conflict state.
//   Task? get conflictVersion {
//     if (conflictData == null) return null;
//     return Task.fromJson(conflictData!);
//   }
// }
