// Template: Sealed Failure types for in-app purchases
//
// Location: lib/features/purchases/domain/failures/purchases_failures.dart
//
// Usage:
// 1. Copy to target location
// 2. Import in repository and presentation layers
// 3. Handle each failure type in UI

/// Sealed class representing all possible purchase failures.
///
/// Use pattern matching to handle each case:
/// ```dart
/// result.fold(
///   (failure) => switch (failure) {
///     PurchaseCancelled() => null, // Dismiss silently
///     PurchasePending() => showPendingMessage(),
///     NetworkError() => showRetryOption(),
///     StoreError(:final message) => showError(message),
///     ProductNotFound() => logError(),
///     NotAllowed() => showRestrictionMessage(),
///     UnknownError(:final message) => showGenericError(message),
///   },
///   (success) => handleSuccess(),
/// );
/// ```
sealed class PurchasesFailure {
  const PurchasesFailure();
}

/// User cancelled the purchase flow.
///
/// This is not an error - user intentionally dismissed.
/// UI should dismiss silently without error message.
final class PurchaseCancelled extends PurchasesFailure {
  const PurchaseCancelled();
}

/// Purchase is pending external action.
///
/// Common scenarios:
/// - Parental approval required (Ask to Buy)
/// - Payment method requires verification
/// - Deferred payment (some regions)
///
/// UI should inform user that purchase is pending.
final class PurchasePending extends PurchasesFailure {
  const PurchasePending();
}

/// Network connectivity issue.
///
/// UI should show retry option.
final class NetworkError extends PurchasesFailure {
  const NetworkError([this.message]);

  final String? message;
}

/// App Store or Play Store error.
///
/// UI should show generic error message.
final class StoreError extends PurchasesFailure {
  const StoreError([this.message, this.code]);

  final String? message;
  final int? code;
}

/// Product not found or not configured.
///
/// This is likely a configuration error.
/// Log the error and hide the product from UI.
final class ProductNotFound extends PurchasesFailure {
  const ProductNotFound([this.productId]);

  final String? productId;
}

/// Purchases not allowed on this device.
///
/// Common scenarios:
/// - Parental controls
/// - MDM restrictions
/// - Sandbox/enterprise restrictions
///
/// UI should explain that purchases are restricted.
final class NotAllowed extends PurchasesFailure {
  const NotAllowed([this.message]);

  final String? message;
}

/// Unknown or unexpected error.
///
/// Log for debugging, show generic error to user.
final class UnknownError extends PurchasesFailure {
  const UnknownError([this.message, this.error]);

  final String? message;
  final Object? error;
}

/// Extension for user-friendly messages.
extension PurchasesFailureMessage on PurchasesFailure {
  /// Get a user-friendly message for this failure.
  ///
  /// Returns null for [PurchaseCancelled] as no message is needed.
  String? get userMessage => switch (this) {
        PurchaseCancelled() => null,
        PurchasePending() => 'Your purchase is pending approval.',
        NetworkError(:final message) =>
          message ?? 'Network error. Please check your connection.',
        StoreError(:final message) => message ?? 'Unable to complete purchase.',
        ProductNotFound() => 'This product is not available.',
        NotAllowed(:final message) =>
          message ?? 'Purchases are not allowed on this device.',
        UnknownError(:final message) =>
          message ?? 'An unexpected error occurred.',
      };

  /// Whether this failure should show an error message.
  bool get shouldShowMessage => this is! PurchaseCancelled;

  /// Whether user should be offered to retry.
  bool get canRetry => this is NetworkError;
}
