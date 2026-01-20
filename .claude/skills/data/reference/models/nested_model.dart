// Template: Freezed DTO model for API serialization
//
// Location: lib/features/{feature}/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: DTO with Nested Objects
// When API returns nested objects, create models for each.

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/memory.dart';
import '../../domain/entities/lat_lng.dart';
import '../../domain/enums/sync_status.dart';

part 'memory_model.freezed.dart';
part 'memory_model.g.dart';

@freezed
abstract class MemoryModel with _$MemoryModel {
  const MemoryModel._();

  const factory MemoryModel({
    required String id,
    @JsonKey(name: 'local_path') String? localPath,
    @JsonKey(name: 'remote_url') String? remoteUrl,
    String? caption,
    LatLngModel? location,
    @JsonKey(name: 'sync_status') required String syncStatus,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MemoryModel;

  factory MemoryModel.fromJson(Map<String, dynamic> json) =>
      _$MemoryModelFromJson(json);

  Memory toEntity() => Memory(
        id: id,
        localPath: localPath,
        remoteUrl: remoteUrl,
        caption: caption,
        location: location?.toEntity(),
        syncStatus: SyncStatus.values.byName(syncStatus),
        createdAt: createdAt,
      );

  factory MemoryModel.fromEntity(Memory entity) => MemoryModel(
        id: entity.id,
        localPath: entity.localPath,
        remoteUrl: entity.remoteUrl,
        caption: entity.caption,
        location: entity.location != null
            ? LatLngModel.fromEntity(entity.location!)
            : null,
        syncStatus: entity.syncStatus.name,
        createdAt: entity.createdAt,
      );
}

/// Nested value object DTO.
@freezed
abstract class LatLngModel with _$LatLngModel {
  const LatLngModel._();

  const factory LatLngModel({
    required double latitude,
    required double longitude,
  }) = _LatLngModel;

  factory LatLngModel.fromJson(Map<String, dynamic> json) =>
      _$LatLngModelFromJson(json);

  LatLng toEntity() => LatLng(
        latitude: latitude,
        longitude: longitude,
      );

  factory LatLngModel.fromEntity(LatLng entity) => LatLngModel(
        latitude: entity.latitude,
        longitude: entity.longitude,
      );
}
