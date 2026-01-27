// Template: Mock implementation for testing
//
// Location: test/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Pattern: Mock Dio for Testing
// Test helpers for mocking Dio responses and errors.

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Mock Dio for testing.
final class MockDio extends Mock implements Dio {}

/// Test helper for Dio responses.
Response<T> mockResponse<T>(T data, {int statusCode = 200}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: ''),
  );
}

/// Test helper for Dio errors.
DioException mockDioError({
  required DioExceptionType type,
  int? statusCode,
  dynamic data,
}) {
  return DioException(
    type: type,
    requestOptions: RequestOptions(path: ''),
    response: statusCode != null
        ? Response(
            statusCode: statusCode,
            data: data,
            requestOptions: RequestOptions(path: ''),
          )
        : null,
  );
}

// -----------------------------------------------------
// Common test scenarios:
// -----------------------------------------------------

// Success response:
// when(() => mockDio.get<List<dynamic>>(any()))
//     .thenAnswer((_) async => mockResponse([
//           {'id': '1', 'title': 'Test'},
//         ]));

// Connection error:
// when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
//   mockDioError(type: DioExceptionType.connectionError),
// );

// 401 Unauthorized:
// when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
//   mockDioError(type: DioExceptionType.badResponse, statusCode: 401),
// );

// 500 Server error:
// when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
//   mockDioError(type: DioExceptionType.badResponse, statusCode: 500),
// );
