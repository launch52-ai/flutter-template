# Phone Auth Implementation Checklist

Complete verification checklist for phone authentication implementation.

---

## Backend Setup

### Supabase

- [ ] Phone auth enabled in Authentication → Providers → Phone
- [ ] SMS provider configured (Twilio, MessageBird, Vonage)
- [ ] Rate limiting configured (default: 30s between requests)
- [ ] OTP expiration set (recommended: 10 minutes)
- [ ] Test phone numbers added for development (if supported)

### Custom Backend

- [ ] `/auth/phone/send-otp` endpoint implemented
- [ ] `/auth/phone/verify-otp` endpoint implemented
- [ ] E.164 format validation on server
- [ ] Rate limiting implemented (IP + phone number)
- [ ] OTP storage with expiration
- [ ] Secure OTP generation (6 digits, cryptographically random)
- [ ] Brute force protection (max 3-5 attempts per OTP)

---

## Flutter Implementation

### Dependencies

- [ ] `supabase_flutter` added (if using Supabase)
- [ ] `dio` added (if using custom API)
- [ ] `freezed` and `freezed_annotation` added
- [ ] `json_serializable` and `json_annotation` added
- [ ] `flutter_riverpod` and `riverpod_annotation` added

### Data Layer

- [ ] `Country` model created with Freezed
- [ ] `countries.json` asset created
- [ ] `CountriesData` loader implemented
- [ ] `PhoneFormatUtils` created
- [ ] `PhoneNumberFormatter` created
- [ ] `PhoneAuthRepository` interface created
- [ ] `PhoneAuthRepositoryImpl` implemented
- [ ] `MockPhoneAuthRepository` implemented

### Domain Layer

- [ ] `PhoneAuthFailure` types defined (follows Failure pattern)
- [ ] Error → Failure mapping implemented

### Presentation Layer

- [ ] `PhoneAuthState` sealed class created
- [ ] `PhoneAuthNotifier` with disposal safety created
- [ ] `phoneAuthRepositoryProvider` registered
- [ ] Failure → i18n mapping helper created

### UI Components

- [ ] Country picker implemented
- [ ] Phone number input with formatting
- [ ] OTP input field (6 digits, auto-advance)
- [ ] Countdown timer for resend
- [ ] Loading states shown
- [ ] Error messages displayed

---

## UX Verification

### Phone Input Screen

- [ ] Auto-focus on phone input
- [ ] Keyboard type is `TextInputType.phone`
- [ ] Country flag + dial code visible
- [ ] Phone number formats as user types
- [ ] Hint shows expected format (e.g., "XXX XXX XXXX")
- [ ] Validation prevents invalid length
- [ ] Submit button disabled until valid
- [ ] Clear error on input change

### OTP Verification Screen

- [ ] Auto-focus on OTP input
- [ ] Keyboard type is `TextInputType.number`
- [ ] Auto-advance between OTP boxes (if using separate fields)
- [ ] Auto-submit when 6 digits entered
- [ ] Paste support for OTP codes
- [ ] Countdown shows time until resend available
- [ ] Resend button disabled during countdown
- [ ] Remaining attempts shown after failed verification
- [ ] Clear error on input change

### Error Handling

- [ ] Invalid phone number shows specific error
- [ ] Rate limit shows countdown
- [ ] Invalid OTP shows attempts remaining
- [ ] Expired OTP shows "request new code" option
- [ ] Max attempts shows "request new code" option
- [ ] Network error shows retry button
- [ ] Server error shows generic message

---

## Retry Pattern Verification

Verify escalating retry intervals:

| Attempt | Wait Time | Cumulative |
|---------|-----------|------------|
| 1st resend | 30 seconds | 30s |
| 2nd resend | 40 seconds | 1m 10s |
| 3rd resend | 60 seconds | 2m 10s |
| 4th resend | 90 seconds | 3m 40s |
| 5th resend | 120 seconds | 5m 40s |

- [ ] Countdown timer accurately reflects wait time
- [ ] Wait time persists across app restart (optional)
- [ ] Maximum resend attempts enforced

---

## Security Verification

- [ ] Phone numbers stored in E.164 format
- [ ] OTP not logged in debug output
- [ ] OTP not stored locally on device
- [ ] No OTP hints in error messages
- [ ] Rate limiting cannot be bypassed client-side
- [ ] Session token stored in secure storage
- [ ] Session token cleared on logout

---

## Testing Checklist

### Unit Tests

- [ ] `PhoneFormatUtils.toE164()` tested
- [ ] `PhoneFormatUtils.format()` tested
- [ ] `PhoneFormatUtils.isValidE164()` tested
- [ ] `Country.phoneLength` computed correctly
- [ ] Repository sends correct E.164 format
- [ ] Failure types mapped correctly

### Widget Tests

- [ ] Phone input accepts valid numbers
- [ ] Phone input rejects invalid characters
- [ ] OTP input advances correctly
- [ ] Countdown timer displays correctly
- [ ] Error messages appear on failure

### Integration Tests (Optional)

- [ ] Full flow: phone → OTP → authenticated
- [ ] Rate limiting triggers correctly
- [ ] Session persists across restart

---

## i18n Strings Required

Add these strings to your localization files:

```yaml
phone_auth:
  # Phone input screen
  phone_input:
    title: "Enter your phone number"
    subtitle: "We'll send you a verification code"
    phone_hint: "Phone number"
    continue: "Continue"

  # OTP verification screen
  otp_verification:
    title: "Verify your number"
    subtitle: "Enter the code sent to {phone}"
    code_hint: "Verification code"
    verify: "Verify"
    resend: "Resend code"
    resend_countdown: "Resend in {seconds}s"
    resend_available: "Didn't receive a code? Resend"
    different_number: "Use a different number"

  # Errors
  errors:
    invalid_phone: "Please enter a valid phone number"
    rate_limited: "Too many requests. Please wait {seconds} seconds."
    invalid_otp: "Incorrect code. {attempts} attempts remaining."
    otp_expired: "Code expired. Please request a new one."
    max_attempts: "Too many failed attempts. Please request a new code."

  # Accessibility labels
  accessibility:
    phone_input: "Phone number input field"
    country_picker: "Select country"
    otp_digit: "Verification code digit {position}"
    resend_button: "Resend verification code"
```

---

## Verification Commands

```bash
# Run build_runner for code generation
dart run build_runner build --delete-conflicting-outputs

# Run unit tests
flutter test test/unit/features/auth/

# Run widget tests
flutter test test/widget/features/auth/

# Run all tests
flutter test

# Check for linting issues
flutter analyze
```

---

## Common Issues & Solutions

### Issue: OTP auto-fetch not working on Android

**Solution:** Add SMS permission and use `sms_autofill` package.

### Issue: Country picker slow with 200+ countries

**Solution:** Use `ListView.builder` with search, lazy load countries.

### Issue: Countdown resets on screen rotation

**Solution:** Store countdown end time in provider, calculate remaining on rebuild.

### Issue: User can spam resend button

**Solution:** Disable button + server-side rate limiting. Trust server, show UI feedback.
