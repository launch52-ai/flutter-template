// Template: AsyncNotifier for state management
//
// Location: lib/core/data/upload/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Provider with Upload State
// Riverpod provider for file uploads with progress tracking.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'upload_notifier.freezed.dart';
part 'upload_notifier.g.dart';

@freezed
sealed class UploadState with _$UploadState {
  const factory UploadState.idle() = UploadStateIdle;
  const factory UploadState.uploading({
    required double progress,
  }) = UploadStateUploading;
  const factory UploadState.success(String url) = UploadStateSuccess;
  const factory UploadState.error(String message) = UploadStateError;
}

@riverpod
final class UploadNotifier extends _$UploadNotifier {
  CancelToken? _cancelToken;
  bool _disposed = false;

  @override
  UploadState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _cancelToken?.cancel();
    });
    return const UploadState.idle();
  }

  Future<void> upload(File file) async {
    _cancelToken = CancelToken();
    state = const UploadState.uploading(progress: 0);

    try {
      final url = await ref.read(uploadRepositoryProvider).uploadImage(
        file,
        cancelToken: _cancelToken,
        onProgress: (sent, total) {
          if (_disposed) return;
          state = UploadState.uploading(progress: sent / total);
        },
      );

      if (_disposed) return;
      state = UploadState.success(url);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        state = const UploadState.idle();
        return;
      }
      if (_disposed) return;
      state = UploadState.error(e.message ?? 'Upload failed');
    }
  }

  void cancel() {
    _cancelToken?.cancel();
    state = const UploadState.idle();
  }
}

// Placeholder - replace with actual repository provider
final uploadRepositoryProvider =
    Provider<dynamic>((ref) => throw UnimplementedError());
