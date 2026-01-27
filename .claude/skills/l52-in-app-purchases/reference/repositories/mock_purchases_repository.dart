// Template: Mock implementation of PurchasesRepository for testing
//
// Location: lib/features/purchases/data/repositories/mock_purchases_repository.dart
//
// Usage:
// 1. Copy to target location (or test/ folder)
// 2. Use in tests or development mode
// 3. Configure behavior via constructor parameters

import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/failures/purchases_failures.dart';
import '../../domain/models/subscription_status.dart';
import '../../domain/repositories/purchases_repository.dart';

/// Mock implementation of [PurchasesRepository] for testing.
///
/// Configure behavior via constructor:
/// ```dart
/// MockPurchasesRepository(
///   isSubscribed: true, // Start with active subscription
///   shouldFailPurchase: false, // Purchases succeed
/// )
/// ```
final class MockPurchasesRepository implements PurchasesRepository {
  MockPurchasesRepository({
    this.isSubscribed = false,
    this.shouldFailPurchase = false,
    this.shouldFailRestore = false,
    this.purchaseDelay = const Duration(seconds: 1),
  });

  bool isSubscribed;
  final bool shouldFailPurchase;
  final bool shouldFailRestore;
  final Duration purchaseDelay;

  final _statusController = StreamController<SubscriptionStatus>.broadcast();

  @override
  Stream<SubscriptionStatus> get subscriptionStatusStream =>
      _statusController.stream;

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>>
      getSubscriptionStatus() async {
    return Right(_currentStatus);
  }

  @override
  Future<Either<PurchasesFailure, Offering?>> getOfferings() async {
    // Return mock offering
    // In real tests, you might want to create mock Offering objects
    return const Right(null);
  }

  @override
  Future<Either<PurchasesFailure, Map<String, Offering>>>
      getAllOfferings() async {
    return const Right({});
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchase(
    Package package,
  ) async {
    await Future.delayed(purchaseDelay);

    if (shouldFailPurchase) {
      return const Left(StoreError('Mock purchase failed'));
    }

    isSubscribed = true;
    final status = _currentStatus;
    _statusController.add(status);
    return Right(status);
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchaseProduct(
    String productId,
  ) async {
    await Future.delayed(purchaseDelay);

    if (shouldFailPurchase) {
      return const Left(StoreError('Mock purchase failed'));
    }

    isSubscribed = true;
    final status = _currentStatus;
    _statusController.add(status);
    return Right(status);
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>>
      restorePurchases() async {
    await Future.delayed(purchaseDelay);

    if (shouldFailRestore) {
      return const Left(NetworkError('Mock restore failed'));
    }

    // Restore doesn't change subscription state in mock
    return Right(_currentStatus);
  }

  @override
  Future<bool> hasEntitlement(String entitlementId) async {
    return isSubscribed;
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> logIn(
    String userId,
  ) async {
    return Right(_currentStatus);
  }

  @override
  Future<Either<PurchasesFailure, void>> logOut() async {
    return const Right(null);
  }

  @override
  Future<Either<PurchasesFailure, String?>> getManagementUrl() async {
    return const Right('https://apps.apple.com/account/subscriptions');
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> syncPurchases() async {
    return Right(_currentStatus);
  }

  SubscriptionStatus get _currentStatus => isSubscribed
      ? SubscriptionStatus(
          isActive: true,
          activeEntitlement: 'premium',
          activeProductId: 'mock_premium_monthly',
          expirationDate: DateTime.now().add(const Duration(days: 30)),
          willRenew: true,
          activeEntitlements: {'premium'},
        )
      : SubscriptionStatus.free();

  /// Simulate subscription expiration.
  void simulateExpiration() {
    isSubscribed = false;
    _statusController.add(_currentStatus);
  }

  /// Simulate subscription renewal.
  void simulateRenewal() {
    isSubscribed = true;
    _statusController.add(_currentStatus);
  }

  void dispose() {
    _statusController.close();
  }
}
