# Network Connectivity Setup Guide

Step-by-step guide to integrate network connectivity monitoring with a global offline banner.

## Smart Detection

This implementation uses **smart detection** that combines:
1. `connectivity_plus` library status
2. Actual API request success

**Why?** The `connectivity_plus` library only checks network interface status. It can report false negatives when:
- Government blocks the connectivity check endpoints
- Captive portals intercept requests
- DNS issues affect only certain domains

**Solution:** If any real API request succeeds, we override the "offline" status from the library.

---

## Prerequisites

- Flutter project with Riverpod 3.x
- Dio for HTTP requests
- `build_runner` for code generation

---

## Step 1: Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^6.0.0
```

Run:

```bash
flutter pub get
```

---

## Step 2: Create ConnectivityService

Copy `reference/connectivity_service.dart` to `lib/core/services/connectivity_service.dart`.

This service wraps `connectivity_plus` and provides:
- `onConnectivityChanged` - Stream of connectivity changes
- `checkConnectivity()` - One-shot connectivity check
- `isOnline()` - Convenience method returning bool

---

## Step 3: Create Providers

Copy `reference/connectivity_provider.dart` to `lib/core/providers/connectivity_provider.dart`.

Update the import:

```dart
// Change this:
import '../services/connectivity_service.dart';

// To your actual path:
import 'package:your_app/core/services/connectivity_service.dart';
```

Run build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Step 4: Create Banner Widget

Copy `reference/connectivity_banner.dart` to `lib/core/widgets/connectivity_banner.dart`.

---

## Step 5: Create Dio Interceptor

Copy `reference/connectivity_interceptor.dart` to `lib/core/network/connectivity_interceptor.dart`.

Add to your Dio client:

```dart
// In dio_client.dart or wherever you create Dio
Dio createDio(Ref ref) {
  final dio = Dio(BaseOptions(...));

  dio.interceptors.addAll([
    ConnectivityInterceptor(ref),  // Add this
    // ... other interceptors
  ]);

  return dio;
}
```

This interceptor reports successful/failed requests to the connectivity notifier, enabling smart detection.

---

## Step 6: Create Wrapper Widget

Copy `reference/connectivity_wrapper.dart` to `lib/core/widgets/connectivity_wrapper.dart`.

Update imports:

```dart
import 'package:your_app/core/providers/connectivity_provider.dart';
import 'package:your_app/core/widgets/connectivity_banner.dart';
```

---

## Step 7: Integrate in main.dart

Wrap your `MaterialApp` with `ConnectivityWrapper`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: ConnectivityWrapper(
        child: MaterialApp(
          // Your app configuration...
        ),
      ),
    ),
  );
}
```

**Important:** `ConnectivityWrapper` must be **inside** `ProviderScope` but **outside** `MaterialApp`.

---

## Step 8: Test

1. **Enable airplane mode** on device/simulator
   - Banner should slide down from top
2. **Disable airplane mode**
   - Banner should slide back up
3. **Launch app in airplane mode**
   - Banner should be visible immediately

---

## Customization

### Different Banner Position

To show banner at bottom instead of top, modify `_BannerAnimator`:

```dart
// In connectivity_wrapper.dart, change Stack alignment:
Stack(
  alignment: Alignment.bottomCenter,
  children: [
    child,
    // ... banner
  ],
)

// And update slide direction:
_slideAnimation = Tween<Offset>(
  begin: const Offset(0, 1),  // Slide from bottom
  end: Offset.zero,
).animate(...);

// In connectivity_banner.dart, update SafeArea:
SafeArea(
  top: false,  // Changed from bottom: false
  child: ...
)
```

---

## Using Connectivity in Features

### Reactive UI Updates

```dart
final isOnline = ref.watch(isOnlineProvider);

ElevatedButton(
  onPressed: isOnline ? () => _submitForm() : null,
  child: Text(isOnline ? 'Submit' : 'No connection'),
)
```

### Listen for Changes

```dart
ref.listen(isOnlineProvider, (prev, next) {
  if (!next) {
    // Pause background sync, show message, etc.
  }
});
```

### Manual Reporting (outside Dio)

If you have network operations outside Dio:

```dart
// After successful request
ref.read(actualConnectivityProvider.notifier).reportRequestSuccess();

// After network failure
ref.read(actualConnectivityProvider.notifier).reportRequestFailure();
```

---

## Troubleshooting

### Banner not appearing

1. Verify `ConnectivityWrapper` is above `MaterialApp`
2. Check that `ProviderScope` wraps everything
3. Run `build_runner` to generate provider code

### Banner stuck visible

Check that `connectivity_plus` is correctly detecting network changes. On iOS simulator, network changes may not be detected properly. Test on real device.

### Multiple banners

Ensure only one `ConnectivityWrapper` exists in widget tree. It should be at the root level only.

### False offline despite working API

If banner shows "offline" but API requests succeed:

1. Verify `ConnectivityInterceptor` is added to Dio
2. Check that the interceptor receives a valid `Ref`
3. Confirm `reportRequestSuccess()` is being called (add logging)

---

## File Checklist

After setup, verify these files exist:

```
lib/
├── core/
│   ├── services/
│   │   └── connectivity_service.dart
│   ├── providers/
│   │   ├── connectivity_provider.dart
│   │   └── connectivity_provider.g.dart  # Generated
│   ├── network/
│   │   └── connectivity_interceptor.dart
│   └── widgets/
│       ├── connectivity_banner.dart
│       └── connectivity_wrapper.dart
└── main.dart  # Updated
```

---

## Platform Notes

### iOS

No additional configuration required. Works out of the box.

### Android

No additional permissions required for basic connectivity monitoring. If you need to check actual internet access (not just network connection), consider using `internet_connection_checker` package.

### Web

`connectivity_plus` has limited support on web. The `onConnectivityChanged` stream may not work reliably. Consider using `Navigator.onLine` for web-specific handling.
