# Phone Formats Reference

Reference for E.164 format and phone number validation.

---

## E.164 Format

International standard for phone numbers:

```
+[country code][subscriber number]
```

| Property | Value |
|----------|-------|
| Prefix | Always `+` |
| Length | 7-15 digits after `+` |
| Characters | Digits only (no spaces, dashes) |

**Examples:**
```
+14155551234      (USA)
+447911123456     (UK)
+994501234567     (Azerbaijan)
+905551234567     (Turkey)
```

---

## Countries Data

Complete data for 195 countries is in:
```
data/countries.json
```

Each country has:
```json
{
  "name": "Azerbaijan",
  "code": "AZ",
  "dialCode": "+994",
  "flag": "🇦🇿",
  "format": "## ### ## ##"
}
```

### Format Pattern

`#` = digit placeholder

| Pattern | Example Input | Formatted |
|---------|---------------|-----------|
| `### ### ####` | 5551234567 | 555 123 4567 |
| `## ### ## ##` | 501234567 | 50 123 45 67 |
| `# ## ## ## ##` | 612345678 | 6 12 34 56 78 |

---

## Validation

### E.164 Regex

```dart
bool isValidE164(String phone) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone);
}
```

### Country-Specific Length

Phone lengths vary by country. Use `country.phoneLength`:

```dart
bool isValid(String digits, Country country) {
  return digits.length == country.phoneLength;
}
```

---

## Common Dial Codes

| Region | Countries |
|--------|-----------|
| +1 | USA, Canada |
| +7 | Russia, Kazakhstan |
| +44 | United Kingdom |
| +49 | Germany |
| +33 | France |
| +39 | Italy |
| +34 | Spain |
| +90 | Turkey |
| +994 | Azerbaijan |
| +995 | Georgia |
| +374 | Armenia |
| +971 | UAE |
| +966 | Saudi Arabia |
| +86 | China |
| +81 | Japan |
| +82 | South Korea |
| +91 | India |
| +61 | Australia |
| +55 | Brazil |

For complete list, see `data/countries.json`.

---

## Related

- [SKILL.md](SKILL.md) - Overview
- [implementation-guide.md](implementation-guide.md) - How to use
- [best-practices-guide.md](best-practices-guide.md) - Backend expectations
