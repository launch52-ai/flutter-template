// Template: Authentication related
//
// Location: lib/features/{feature}/
//
// Usage:
// 1. Copy to target location
// 2. Rename {Feature} placeholders to your feature name
// 3. Update imports as needed

// Template: OAuth Pending Exception
//
// Location: lib/core/errors/exceptions.dart
//
// Add this exception class to your existing exceptions file.
// This is thrown when Apple Sign-In on Android opens a browser
// and the app needs to wait for the deep link callback.

/// Thrown when OAuth flow opens external browser (Apple Sign-In on Android).
///
/// This is not an error - it signals the app should wait for the
/// deep link callback to complete authentication.
///
/// Usage in AuthNotifier:
/// ```dart
/// try {
///   await repository.signInWithApple();
/// } on OAuthPendingException {
///   // Keep loading state, OAuthCallbackScreen handles completion
/// }
/// ```
final class OAuthPendingException extends AppException {
  const OAuthPendingException(super.message);
}
