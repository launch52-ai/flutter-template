# Advanced API Patterns

Advanced patterns for robust API integration. Code is in `reference/` directory.

---

## Quick Reference

| Pattern | Use Case | Reference File |
|---------|----------|----------------|
| **Offset Pagination** | Simple lists, admin panels | `reference/pagination/paginated_result.dart` |
| **Cursor Pagination** | Real-time data, social feeds | `reference/pagination/cursor_result.dart` |
| **Infinite Scroll** | Load more with Riverpod | `reference/pagination/infinite_scroll_provider.dart` |
| **Retry Config** | Configure retry behavior | `reference/retry/retry_config.dart` |
| **Retry Helper** | Wrap operations with retry | `reference/retry/with_retry.dart` |
| **Retry Interceptor** | Auto-retry for Dio | `reference/retry/retry_interceptor.dart` |
| **Request Cancellation** | Search, navigation | `reference/cancellation/cancellable_repository.dart` |
| **Memory Cache** | In-memory with TTL | `reference/caching/memory_cache.dart` |
| **Optimistic Updates** | Instant UI feedback | `reference/optimistic/optimistic_updates.dart` |
| **File Upload** | Upload with progress | `reference/upload/upload_with_progress.dart` |
| **Upload Provider** | Riverpod upload state | `reference/upload/upload_notifier.dart` |
| **Auth Interceptor** | Token refresh | `reference/auth/auth_interceptor.dart` |
| **Mock Dio** | Testing helpers | `reference/testing/mock_dio.dart` |
| **Repository Tests** | Test example | `reference/testing/repository_test_example.dart` |
| **Widget Tests** | Provider overrides | `reference/testing/widget_test_example.dart` |

---

## 1. Pagination Patterns

### When to Use

| Pattern | Best For |
|---------|----------|
| **Offset-based** | Admin panels, known page counts, traditional pagination UI |
| **Cursor-based** | Real-time feeds, infinite scroll, data that changes frequently |

### Files

```
reference/pagination/
├── paginated_result.dart       # PaginatedResult<T> entity
├── cursor_result.dart          # CursorResult<T> entity
└── infinite_scroll_provider.dart  # Riverpod provider with load more
```

**Key points:**
- Domain entities (`PaginatedResult`, `CursorResult`) go in domain layer
- Repository returns these entities
- Provider manages pagination state and load more

---

## 2. Retry Patterns

### When to Use

Use retry for transient failures: timeouts, connection errors, 5xx server errors.

**Don't retry:** 4xx client errors (400, 401, 403, 404).

### Files

```
reference/retry/
├── retry_config.dart           # RetryConfig with backoff settings
├── with_retry.dart             # withRetry<T> helper function
└── retry_interceptor.dart      # Dio interceptor for automatic retry
```

**Key points:**
- Use `withRetry()` wrapper for specific operations
- Use `RetryInterceptor` for global retry on all requests
- Exponential backoff: 1s → 2s → 4s → 8s (capped at maxDelay)

---

## 3. Request Cancellation

### When to Use

- Search-as-you-type (cancel previous search)
- Navigation away from screen
- User explicitly cancels operation

### Files

```
reference/cancellation/
└── cancellable_repository.dart  # Repository with CancelToken
```

**Key points:**
- Store `CancelToken` as instance variable
- Cancel previous token before starting new request
- Handle `DioExceptionType.cancel` gracefully (return empty, not error)
- Cancel on provider dispose

---

## 4. Caching Patterns

### When to Use

- Reduce API calls for frequently accessed data
- Support offline/poor connectivity
- Stale-while-revalidate for instant UI

### Files

```
reference/caching/
└── memory_cache.dart           # MemoryCache<T> with TTL
```

**Key points:**
- Check cache before API call
- Set cache after successful fetch
- Invalidate cache after mutations (create/update/delete)
- Return stale cache on error (fallback)

---

## 5. Optimistic Updates

### When to Use

- Like/favorite buttons (instant feedback)
- Delete with undo
- Any action where lag feels bad

### Files

```
reference/optimistic/
└── optimistic_updates.dart     # Examples with revert logic
```

**Key points:**
1. Save original state
2. Update UI immediately
3. Send to server
4. Revert on error + show message
5. For deletes: show undo snackbar before actual deletion

---

## 6. File Upload Patterns

### When to Use

- Image uploads
- Document uploads
- Any file with progress indicator

### Files

```
reference/upload/
├── upload_with_progress.dart   # Repository method with progress
└── upload_notifier.dart        # Riverpod provider with upload state
```

**Key points:**
- Use `MultipartFile.fromFile()` with `FormData`
- Pass `onSendProgress` callback for progress
- Support `CancelToken` for user cancellation
- Track state: idle → uploading(progress) → success/error

---

## 7. Authentication Interceptor

### When to Use

- JWT authentication with refresh tokens
- Automatic token refresh on 401
- Request queuing during refresh

### Files

```
reference/auth/
└── auth_interceptor.dart       # QueuedInterceptor with refresh
```

**Key points:**
- Extend `QueuedInterceptor` (not `Interceptor`) to queue requests during refresh
- Skip auth for public endpoints (`options.extra['skipAuth'] = true`)
- Only attempt refresh once (`_isRefreshing` flag)
- Call `onAuthFailure` callback to navigate to login

---

## 8. Testing API Code

### Files

```
reference/testing/
├── mock_dio.dart                   # MockDio + helper functions
├── repository_test_example.dart    # Complete repository test
└── widget_test_example.dart        # Widget test with provider overrides
```

**Key points:**
- Use `mocktail` for mocking
- `mockResponse<T>()` helper for success responses
- `mockDioError()` helper for error scenarios
- Override providers in widget tests with `ProviderScope`

---

## 9. Error Handling

See `reference/failures/` for basic error handling patterns.

For comprehensive error mapping, the pattern is:

```dart
Failure _mapDioError(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkFailure('Timeout'),
    DioExceptionType.connectionError => const NetworkFailure('No connection'),
    DioExceptionType.badResponse => _mapStatusCode(e.response),
    DioExceptionType.cancel => const NetworkFailure('Cancelled'),
    _ => UnknownFailure(e.message ?? 'Unknown error'),
  };
}

Failure _mapStatusCode(Response? response) {
  final statusCode = response?.statusCode ?? 0;
  final message = response?.data?['message'] as String? ?? 'Server error';

  return switch (statusCode) {
    400 => ValidationFailure(message),
    401 => const AuthFailure('Session expired'),
    403 => const AuthFailure('Permission denied'),
    404 => NotFoundFailure(message),
    409 => ConflictFailure(message),
    422 => ValidationFailure(message),
    429 => const RateLimitFailure('Too many requests'),
    >= 500 => const ServerFailure('Server error'),
    _ => ServerFailure(message),
  };
}
```

---

## Pattern Selection Guide

| Scenario | Patterns to Use |
|----------|-----------------|
| **List screen** | Pagination + Caching |
| **Search screen** | Cancellation + Debounce |
| **Like button** | Optimistic update |
| **Delete action** | Optimistic + Undo |
| **Image picker** | Upload with progress |
| **Auth API calls** | Auth interceptor |
| **Flaky network** | Retry interceptor |
| **Tests** | Mock Dio + Provider overrides |
