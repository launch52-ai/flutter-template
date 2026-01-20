// Template: File upload with progress tracking
//
// Location: lib/core/data/upload/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: File Upload with Progress
// Repository method for uploading files with progress tracking.

import 'dart:io';

import 'package:dio/dio.dart';

/// Upload progress callback.
typedef UploadProgressCallback = void Function(int sent, int total);

// -----------------------------------------------------
// Repository Method Example:
// -----------------------------------------------------

/// Repository method for uploading files.
Future<String> uploadImage(
  Dio dio,
  File file, {
  UploadProgressCallback? onProgress,
  CancelToken? cancelToken,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await dio.post<Map<String, dynamic>>(
      '/upload',
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );

    return response.data!['url'] as String;
  } on DioException catch (e) {
    // Handle error appropriately
    rethrow;
  }
}
