// Template: iOS Network Permission Service
//
// Location: lib/core/services/ios_network_permission_service.dart
//
// Purpose:
// On iOS, the first network request triggers a system permission dialog
// asking for data/WiFi access. This causes the initial request to fail
// or be cancelled. This service makes a fire-and-forget request early
// in the app lifecycle so real requests don't get blocked.
//
// Usage:
// 1. Copy to target location
// 2. Call `triggerIOSNetworkPermission()` in main.dart before runApp
// 3. The function is non-blocking and safe to call on any platform

import 'dart:io';

/// Triggers iOS network permission dialog by making a simple HEAD request.
///
/// On iOS, the first network request shows a system permission dialog asking
/// for local network/data access. If ignored, this causes the initial request
/// to fail while the user sees the prompt.
///
/// Call this early in `main()` to trigger the dialog before any real API
/// calls are made. The request is fire-and-forget and errors are ignored.
///
/// On non-iOS platforms, this function returns immediately.
///
/// Example:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Trigger iOS network permission early
///   triggerIOSNetworkPermission();
///
///   await dotenv.load(fileName: '.env');
///   // ... rest of initialization
/// }
/// ```
void triggerIOSNetworkPermission() {
  if (!Platform.isIOS) return;

  // Fire and forget - don't await, don't care about result
  _makePermissionRequest();
}

Future<void> _makePermissionRequest() async {
  try {
    final client = HttpClient();
    // Use Apple's connectivity check URL - lightweight and reliable
    final request = await client.headUrl(
      Uri.parse('https://captive.apple.com/hotspot-detect.html'),
    );
    // Close request immediately, we don't need the response
    final response = await request.close();
    // Drain response to free resources
    await response.drain<void>();
    client.close();
  } catch (_) {
    // Silently ignore all errors - this is a best-effort trigger
  }
}
