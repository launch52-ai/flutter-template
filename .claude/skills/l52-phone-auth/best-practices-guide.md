# OTP Best Practices

Backend handles all security. This guide documents expected backend behavior for mobile integration.

---

## Backend Expectations

### OTP Specifications

| Aspect | Expected | Notes |
|--------|----------|-------|
| **Length** | 6 digits | Industry standard |
| **Expiration** | 5-10 minutes | Backend enforces |
| **Max attempts** | 3-5 per OTP | Backend tracks |
| **Rate limit** | 3-5 OTPs per hour per number | Backend enforces |

### Rate Limiting

| Limit | Expected Value |
|-------|----------------|
| OTPs per phone/hour | 3-5 |
| OTPs per IP/hour | 10-20 |
| Verification attempts per OTP | 3-5 |

---

## Error Types

Backend should return these error types. Mobile maps them to `PhoneAuthErrorType`.

| Error | HTTP | Response Body | Mobile Handling |
|-------|------|---------------|-----------------|
| Invalid phone | 400 | `{"error": "invalid_phone"}` | Show validation error |
| Rate limited | 429 | `{"error": "rate_limited"}` + Retry-After header | Show countdown |
| Invalid OTP | 401 | `{"error": "invalid_otp", "attempts_remaining": 2}` | Clear input, show attempts |
| OTP expired | 401 | `{"error": "otp_expired"}` | Show resend option |
| Max attempts | 401 | `{"error": "max_attempts"}` | Request new OTP |

### Retry-After Header

For rate limiting, backend should include:
```
HTTP/1.1 429 Too Many Requests
Retry-After: 3600
```

---

## API Contract

### Send OTP

```
POST /auth/otp/send
Content-Type: application/json

{
  "phone": "+994501234567"
}
```

**Success:** 200 OK (empty body or `{"success": true}`)

**Errors:** See error types above

### Verify OTP

```
POST /auth/otp/verify
Content-Type: application/json

{
  "phone": "+994501234567",
  "otp": "123456"
}
```

**Success:** 200 OK with auth tokens
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "user": {...}
}
```

**Errors:** See error types above

---

## Mobile Responsibilities

- Format and validate phone input (E.164)
- Call backend APIs
- Handle error responses
- Update UI state
- Manage cooldown timers (based on Retry-After)

**For user-facing error messages:** Use `/i18n` skill

---

## Security Notes

All handled by backend:
- OTP generation (cryptographically secure)
- OTP storage (hashed)
- Rate limiting enforcement
- Expiration checking
- Attempt counting
- Constant-time comparison

Mobile never sees or generates OTPs.
