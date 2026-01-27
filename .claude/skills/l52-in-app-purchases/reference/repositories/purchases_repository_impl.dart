// Template: RevenueCat implementation of PurchasesRepository
//
// Location: lib/features/purchases/data/repositories/purchases_repository_impl.dart
//
// Dependencies:
//   fpdart: ^1.1.0
//   purchases_flutter: ^8.0.0
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports to match your project structure
// 3. Provide via Riverpod

import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../domain/failures/purchases_failures.dart';
import '../../domain/models/subscription_status.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../../../core/services/purchases_service.dart';

/// RevenueCat implementation of [PurchasesRepository].
final class PurchasesRepositoryImpl implements PurchasesRepository {
  PurchasesRepositoryImpl({
    required PurchasesService purchasesService,
    this.entitlementId = 'premium',
  }) : _service = purchasesService;

  final PurchasesService _service;
  final String entitlementId;

  @override
  Stream<SubscriptionStatus> get subscriptionStatusStream {
    return _service.customerInfoStream.map(
      (info) => SubscriptionStatus.fromCustomerInfo(
        info,
        entitlementId: entitlementId,
      ),
    );
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>>
      getSubscriptionStatus() async {
    try {
      final customerInfo = await _service.getCustomerInfo();
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, Offering?>> getOfferings() async {
    try {
      final offerings = await _service.getOfferings();
      return Right(offerings.current);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, Map<String, Offering>>>
      getAllOfferings() async {
    try {
      final offerings = await _service.getOfferings();
      return Right(offerings.all);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchase(
    Package package,
  ) async {
    try {
      final customerInfo = await _service.purchasePackage(package);
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchaseProduct(
    String productId,
  ) async {
    try {
      final customerInfo = await _service.purchaseProduct(productId);
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>>
      restorePurchases() async {
    try {
      final customerInfo = await _service.restorePurchases();
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      return _service.hasActiveEntitlement(entitlementId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> logIn(
    String userId,
  ) async {
    try {
      final result = await _service.logIn(userId);
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          result.customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, void>> logOut() async {
    try {
      await _service.logOut();
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, String?>> getManagementUrl() async {
    try {
      final url = await _service.getManagementUrl();
      return Right(url);
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  @override
  Future<Either<PurchasesFailure, SubscriptionStatus>> syncPurchases() async {
    try {
      final customerInfo = await _service.syncPurchases();
      return Right(
        SubscriptionStatus.fromCustomerInfo(
          customerInfo,
          entitlementId: entitlementId,
        ),
      );
    } on PlatformException catch (e) {
      return Left(_mapPlatformException(e));
    } catch (e) {
      return Left(UnknownError(e.toString(), e));
    }
  }

  /// Map RevenueCat errors to domain failures.
  PurchasesFailure _mapPlatformException(PlatformException e) {
    final errorCode = PurchasesErrorHelper.getErrorCode(e);

    return switch (errorCode) {
      PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
      PurchasesErrorCode.paymentPendingError => const PurchasePending(),
      PurchasesErrorCode.networkError => NetworkError(e.message),
      PurchasesErrorCode.productNotAvailableForPurchaseError ||
      PurchasesErrorCode.productAlreadyPurchasedError =>
        ProductNotFound(e.message),
      PurchasesErrorCode.purchaseNotAllowedError =>
        NotAllowed(e.message),
      PurchasesErrorCode.storeProblemError ||
      PurchasesErrorCode.receiptAlreadyInUseError ||
      PurchasesErrorCode.invalidReceiptError ||
      PurchasesErrorCode.missingReceiptFileError =>
        StoreError(e.message, errorCode.index),
      _ => UnknownError(e.message, e),
    };
  }
}
