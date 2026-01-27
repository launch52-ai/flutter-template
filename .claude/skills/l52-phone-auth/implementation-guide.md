# Implementation Guide

Step-by-step phone OTP authentication setup.

---

## Project Structure

Copy reference files to your project:

```
lib/features/auth/
├── data/
│   ├── models/
│   │   └── country.dart              ← reference/models/country.dart
│   ├── repositories/
│   │   ├── phone_auth_repository_impl.dart  ← implement (see below)
│   │   └── mock_phone_auth_repository.dart  ← reference/repositories/
│   └── utils/
│       ├── countries_data.dart       ← reference/utils/
│       ├── phone_format_utils.dart   ← reference/utils/
│       └── phone_number_formatter.dart ← reference/utils/
├── domain/
│   ├── failures/
│   │   └── phone_auth_failures.dart  ← reference/failures/
│   └── repositories/
│       └── phone_auth_repository.dart ← reference/repositories/
└── presentation/
    └── providers/
        ├── phone_auth_provider.dart  ← reference/providers/
        ├── phone_auth_state.dart     ← reference/providers/
        └── phone_auth_providers.dart ← reference/providers/

assets/data/
└── countries.json                    ← data/countries.json
```

---

## Setup Steps

### 1. Copy Countries Data

```bash
cp .claude/skills/phone-auth/data/countries.json assets/data/
```

Add to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/data/countries.json
```

### 2. Initialize at App Start

```dart
// main.dart
await CountriesData.loadFromAsset();
runApp(const ProviderScope(child: MyApp()));
```

### 3. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Backend Implementation

### Option 1: Supabase

**Setup:**
1. Enable Phone Auth: Authentication → Providers → Phone
2. Configure SMS provider (Twilio, MessageBird, Vonage)

**Repository:** Create `supabase_phone_auth_repository.dart`:

```dart
final class SupabasePhoneAuthRepository implements PhoneAuthRepository {
  final SupabaseClient _supabase;
  const SupabasePhoneAuthRepository(this._supabase);

  @override
  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    try {
      await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  PhoneAuthFailure _mapAuthException(AuthException e) {
    // Map to PhoneAuthFailure types
    // See reference/failures/phone_auth_failures.dart for types
  }
}
```

### Option 2: Custom API

**API Contract:**

```
POST /auth/phone/send-otp
Request:  { "phone": "+15551234567" }
Success:  200 { "message": "OTP sent" }
Errors:   400 invalid_phone, 429 rate_limited

POST /auth/phone/verify-otp
Request:  { "phone": "+15551234567", "otp": "123456" }
Success:  200 { "access_token": "...", "refresh_token": "..." }
Errors:   401 invalid_otp/otp_expired/max_attempts
```

**Repository:** Create `api_phone_auth_repository.dart`:

```dart
final class ApiPhoneAuthRepository implements PhoneAuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;
  const ApiPhoneAuthRepository(this._dio, this._storage);

  @override
  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _dio.post('/auth/phone/send-otp', data: {'phone': phoneNumber});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/phone/verify-otp',
        data: {'phone': phoneNumber, 'otp': otp},
      );
      // Store tokens from response.data
      await _storage.write(key: StorageKeys.accessToken, value: response.data!['access_token']);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  PhoneAuthFailure _mapDioException(DioException e) {
    // Map status codes to PhoneAuthFailure types
    // See reference/failures/phone_auth_failures.dart
  }
}
```

---

## Provider Registration

In `lib/core/providers.dart`:

```dart
@riverpod
PhoneAuthRepository phoneAuthRepository(Ref ref) {
  if (DebugConstants.useMockAuth) {
    return MockPhoneAuthRepository();
  }
  // Return your implementation
  return SupabasePhoneAuthRepository(Supabase.instance.client);
  // OR: return ApiPhoneAuthRepository(ref.watch(dioProvider), ref.watch(secureStorageProvider));
}
```

---

## Reference Files Overview

### Models

**country.dart** - Freezed Country model with:
- Fields: `name`, `code`, `dialCode`, `flag`, `format`, `isActive`
- Computed: `phoneLength`, `hint`
- Extensions: `findByCode()`, `findByDialCode()`, `search()`

### Utils

**countries_data.dart** - Static country access:
- `loadFromAsset()` / `loadFromList()`
- `all`, `active`, `inactive`
- `findByCode()`, `findByDialCode()`, `search()`

**phone_format_utils.dart** - Formatting utilities:
- `toE164(localNumber, country)` - Convert to E.164
- `format(digits, country)` - Apply format pattern
- `isValidE164(phone)` - Validate E.164
- `extractDigits(input)` - Remove non-digits

**phone_number_formatter.dart** - TextInputFormatter for real-time formatting

### Providers

**phone_auth_state.dart** - Freezed UI states:
- `initial`, `sendingOtp`, `otpSent`, `verifying`, `success`, `error`

**phone_auth_provider.dart** - Riverpod notifier:
- `sendOtp()`, `verifyOtp()`, `resendOtp()`, `reset()`

**phone_auth_providers.dart** - Provider registration + retry config

### Error Handling

**failures/phone_auth_failures.dart** - Sealed Failure types (recommended)
**exceptions/phone_auth_exceptions.dart** - Exception types (alternative)

---

## UI Integration

Use `/design` skill for:
- Country picker bottom sheet
- Phone input field with formatting
- OTP digit boxes with auto-advance
- Countdown timer component

---

## Testing

```dart
// Use mock repository
final mockRepo = MockPhoneAuthRepository(validOtp: '123456');
container = ProviderContainer(overrides: [
  phoneAuthRepositoryProvider.overrideWithValue(mockRepo),
]);

// Verify interactions
await notifier.sendOtp('5551234567', country);
expect(mockRepo.sendOtpCallCount, 1);
```

See `reference/repositories/mock_phone_auth_repository.dart` for test helpers.

---

## Related

- [checklist.md](checklist.md) - Implementation verification
- [best-practices-guide.md](best-practices-guide.md) - Security and UX
- `/design` - UI components
- `/i18n` - Error messages
