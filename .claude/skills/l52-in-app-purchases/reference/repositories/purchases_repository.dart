// Template: Purchases repository interface
//
// Location: lib/features/purchases/domain/repositories/purchases_repository.dart
//
// Dependencies:
//   fpdart: ^1.1.0
//   purchases_flutter: ^8.0.0
//
// Usage:
// 1. Copy to target location
// 2. Implement in data layer (purchases_repository_impl.dart)
// 3. Inject via Riverpod provider

import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../failures/purchases_failures.dart';
import '../models/subscription_status.dart';

/// Repository interface for in-app purchases.
///
/// Abstracts RevenueCat for testability and clean architecture.
abstract interface class PurchasesRepository {
  /// Get current subscription status.
  ///
  /// Returns [SubscriptionStatus] with active entitlements.
  Future<Either<PurchasesFailure, SubscriptionStatus>> getSubscriptionStatus();

  /// Get available offerings to display.
  ///
  /// Returns the current [Offering] or null if none configured.
  Future<Either<PurchasesFailure, Offering?>> getOfferings();

  /// Get all available offerings (for A/B testing or promotions).
  Future<Either<PurchasesFailure, Map<String, Offering>>> getAllOfferings();

  /// Purchase a package from an offering.
  ///
  /// Returns updated [SubscriptionStatus] on success.
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchase(
    Package package,
  );

  /// Purchase a specific product by ID.
  ///
  /// Prefer [purchase] when using offerings.
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchaseProduct(
    String productId,
  );

  /// Restore previous purchases.
  ///
  /// Returns [SubscriptionStatus] reflecting restored purchases.
  Future<Either<PurchasesFailure, SubscriptionStatus>> restorePurchases();

  /// Check if user has a specific entitlement.
  Future<bool> hasEntitlement(String entitlementId);

  /// Stream of subscription status changes.
  ///
  /// Listen to react to subscription changes from outside the app.
  Stream<SubscriptionStatus> get subscriptionStatusStream;

  /// Log in user for cross-device sync.
  ///
  /// Call after user authentication.
  Future<Either<PurchasesFailure, SubscriptionStatus>> logIn(String userId);

  /// Log out user.
  ///
  /// Call on user sign out.
  Future<Either<PurchasesFailure, void>> logOut();

  /// Get URL to manage subscription (App Store / Play Store).
  Future<Either<PurchasesFailure, String?>> getManagementUrl();

  /// Sync purchases with store (primarily for Android).
  Future<Either<PurchasesFailure, SubscriptionStatus>> syncPurchases();
}
