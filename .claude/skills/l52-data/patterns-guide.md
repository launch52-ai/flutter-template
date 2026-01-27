# Data Layer Patterns

Basic data layer patterns. See `reference/` directory for actual code.

> **Note:** For advanced patterns (pagination, retry, caching, file uploads, auth interceptors), see [advanced-patterns.md](advanced-patterns.md).

---

## DTO Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Simple DTO** | Basic entity with flat fields | `reference/models/simple_model.dart` |
| **Nested DTO** | Entity contains other objects | `reference/models/nested_model.dart` |
| **Custom Converters** | API uses non-standard formats (UPPERCASE enums, Unix timestamps) | `reference/models/custom_converter_model.dart` |
| **Request DTOs** | POST/PUT request bodies (subset of fields) | `reference/models/request_models.dart` |
| **Paginated Response** | API returns paginated data | `reference/models/paginated_response.dart` |

### DTO Requirements

All DTOs must have:
- `@freezed` annotation
- `part '{name}.freezed.dart'`
- `part '{name}.g.dart'`
- `toEntity()` method
- `fromEntity()` factory

### JSON Field Mapping

```dart
// API: { "created_at": "2024-01-01T00:00:00Z" }
@JsonKey(name: 'created_at') required DateTime createdAt,

// API: { "status": "PENDING" } → Dart enum
@JsonKey(name: 'status') @OrderStatusConverter() required OrderStatus status,

// Omit null fields in request
@JsonKey(includeIfNull: false) String? description,
```

---

## Repository Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Basic CRUD** | Simple remote-only operations | `reference/repositories/basic_repository_impl.dart` |
| **Cached** | Need offline support or reduce API calls | `reference/repositories/cached_repository_impl.dart` |

### Repository Requirements

- `final class` that `implements` domain interface
- Constructor injection of data sources
- All methods return domain entities (not DTOs)
- Map errors to typed Failures

---

## Data Source Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Remote (Dio)** | REST API calls | `reference/data_sources/remote_data_source.dart` |
| **Local (SharedPreferences)** | Simple key-value, non-sensitive | `reference/data_sources/local_data_source_prefs.dart` |
| **Local (SecureStorage)** | Tokens, credentials, PII | `reference/data_sources/local_data_source_secure.dart` |

### Data Source Requirements

- `final class`
- Constructor injection of client (Dio, SharedPreferences, etc.)
- Return DTOs (not entities)
- Do NOT call `toEntity()` - that's repository's job

---

## Error Handling Patterns

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| **Typed Failures** | Define failure types (no strings) | `reference/failures/failures.dart` |
| **Dio Error Handler** | Map DioException to Failure | `reference/failures/dio_error_handler.dart` |
| **Failure Mapper** | Map Failure to i18n string (presentation) | `reference/failures/failure_mapper.dart` |

### Error Handling Rules

1. **Data layer**: Catch exceptions, throw typed Failures
2. **Domain layer**: Pass through Failures (no handling)
3. **Presentation layer**: Map Failures to localized strings via i18n

```
DioException → mapDioError() → NetworkFailure.timeout()
                                       ↓
                              Presentation layer
                                       ↓
                              t.errors.timeout → "Connection timed out"
```

---

## Folder Structure

```
lib/features/{feature}/data/
├── models/
│   ├── {entity}_model.dart
│   ├── create_{entity}_request.dart
│   └── update_{entity}_request.dart
├── repositories/
│   └── {feature}_repository_impl.dart
└── data_sources/
    ├── {feature}_remote_data_source.dart
    └── {feature}_local_data_source.dart   # Optional
```

---

## Import Rules

Data layer can import:
- ✅ Domain entities and interfaces
- ✅ `package:freezed_annotation`
- ✅ `package:json_annotation`
- ✅ `package:dio` (in data sources)
- ✅ Storage packages (in data sources)

Data layer must NOT import:
- ❌ Presentation layer
- ❌ `package:flutter/material.dart`
- ❌ UI packages
