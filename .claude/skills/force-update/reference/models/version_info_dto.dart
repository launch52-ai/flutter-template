// Template: VersionInfoDto data transfer object
//
// Location: lib/features/force_update/data/models/
//
// Usage:
// 1. Copy to target location
// 2. Update import paths
// 3. Run build_runner to generate freezed and json_serializable code

import 'package:freezed_annotation/freezed_annotation.dart';

part 'version_info_dto.freezed.dart';
part 'version_info_dto.g.dart';

/// Data transfer object for version info from Supabase or API.
@freezed
class VersionInfoDto with _$VersionInfoDto {
  const factory VersionInfoDto({
    @JsonKey(name: 'current_version') required String currentVersion,
    @JsonKey(name: 'minimum_version') required String minimumVersion,
    @JsonKey(name: 'force_minimum_version') required String forceMinimumVersion,
    @JsonKey(name: 'store_url') required String storeUrl,
    @JsonKey(name: 'maintenance_mode') @Default(false) bool maintenanceMode,
    @JsonKey(name: 'maintenance_message') String? maintenanceMessage,
    @JsonKey(name: 'release_notes') String? releaseNotes,
  }) = _VersionInfoDto;

  factory VersionInfoDto.fromJson(Map<String, dynamic> json) =>
      _$VersionInfoDtoFromJson(json);
}
