// Template: Riverpod providers for in-app purchases
//
// Location: lib/features/purchases/presentation/providers/purchases_providers.dart
//
// Dependencies:
//   riverpod_annotation: ^2.3.0
//   purchases_flutter: ^8.0.0
//
// Usage:
// 1. Copy to target location
// 2. Adjust imports to match your project structure
// 3. Run: dart run build_runner build

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/purchases_service.dart';
import '../../domain/failures/purchases_failures.dart';
import '../../domain/models/subscription_status.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../../data/repositories/purchases_repository_impl.dart';

part 'purchases_providers.g.dart';

/// Provider for PurchasesService singleton.
@riverpod
PurchasesService purchasesService(PurchasesServiceRef ref) {
  return PurchasesService.instance;
}

/// Provider for PurchasesRepository.
///
/// Override in tests with MockPurchasesRepository:
/// ```dart
/// ProviderScope(
///   overrides: [
///     purchasesRepositoryProvider.overrideWithValue(MockPurchasesRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
@riverpod
PurchasesRepository purchasesRepository(PurchasesRepositoryRef ref) {
  return PurchasesRepositoryImpl(
    purchasesService: ref.watch(purchasesServiceProvider),
    entitlementId: 'premium', // Configure your entitlement ID
  );
}

/// Provider for current subscription status.
///
/// Automatically refreshes when purchases change.
@riverpod
class SubscriptionStatus extends _$SubscriptionStatus {
  @override
  Future<SubscriptionStatus> build() async {
    final repository = ref.watch(purchasesRepositoryProvider);

    // Listen to subscription changes
    final subscription = repository.subscriptionStatusStream.listen((status) {
      state = AsyncData(status);
    });

    ref.onDispose(subscription.cancel);

    // Get initial status
    final result = await repository.getSubscriptionStatus();
    return result.fold(
      (failure) => SubscriptionStatus.free(),
      (status) => status,
    );
  }

  /// Force refresh subscription status.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(purchasesRepositoryProvider);
    final result = await repository.getSubscriptionStatus();
    state = result.fold(
      (failure) => AsyncData(SubscriptionStatus.free()),
      (status) => AsyncData(status),
    );
  }
}

/// Simple boolean provider for quick entitlement checks.
///
/// Usage:
/// ```dart
/// final isPremium = ref.watch(isPremiumProvider);
/// if (!isPremium) {
///   context.push('/paywall');
/// }
/// ```
@riverpod
bool isPremium(IsPremiumRef ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.valueOrNull?.isActive ?? false;
}

/// Provider for available offerings (products to display).
@riverpod
Future<Offering?> offerings(OfferingsRef ref) async {
  final repository = ref.watch(purchasesRepositoryProvider);
  final result = await repository.getOfferings();
  return result.fold(
    (failure) => null,
    (offering) => offering,
  );
}

/// Provider for all offerings (for A/B testing or promotions).
@riverpod
Future<Map<String, Offering>> allOfferings(AllOfferingsRef ref) async {
  final repository = ref.watch(purchasesRepositoryProvider);
  final result = await repository.getAllOfferings();
  return result.fold(
    (failure) => {},
    (offerings) => offerings,
  );
}

/// Provider for purchase actions.
///
/// Usage:
/// ```dart
/// final result = await ref.read(purchaseActionsProvider).purchase(package);
/// result.fold(
///   (failure) => showError(failure),
///   (status) => onSuccess(),
/// );
/// ```
@riverpod
PurchaseActions purchaseActions(PurchaseActionsRef ref) {
  return PurchaseActions(ref.watch(purchasesRepositoryProvider));
}

/// Helper class for purchase actions.
final class PurchaseActions {
  const PurchaseActions(this._repository);

  final PurchasesRepository _repository;

  /// Purchase a package.
  Future<Either<PurchasesFailure, SubscriptionStatus>> purchase(
    Package package,
  ) =>
      _repository.purchase(package);

  /// Restore previous purchases.
  Future<Either<PurchasesFailure, SubscriptionStatus>> restore() =>
      _repository.restorePurchases();

  /// Get management URL for subscription settings.
  Future<String?> getManagementUrl() async {
    final result = await _repository.getManagementUrl();
    return result.fold((failure) => null, (url) => url);
  }
}

/// Notifier for managing purchase flow state.
///
/// Tracks loading state during purchases.
@riverpod
class PurchaseFlow extends _$PurchaseFlow {
  @override
  PurchaseFlowState build() => const PurchaseFlowState.idle();

  /// Execute a purchase.
  Future<void> purchase(Package package) async {
    state = const PurchaseFlowState.loading();

    final repository = ref.read(purchasesRepositoryProvider);
    final result = await repository.purchase(package);

    state = result.fold(
      (failure) => PurchaseFlowState.error(failure),
      (status) => PurchaseFlowState.success(status),
    );
  }

  /// Restore purchases.
  Future<void> restore() async {
    state = const PurchaseFlowState.loading();

    final repository = ref.read(purchasesRepositoryProvider);
    final result = await repository.restorePurchases();

    state = result.fold(
      (failure) => PurchaseFlowState.error(failure),
      (status) => PurchaseFlowState.success(status),
    );
  }

  /// Reset state to idle.
  void reset() {
    state = const PurchaseFlowState.idle();
  }
}

/// State for purchase flow.
sealed class PurchaseFlowState {
  const PurchaseFlowState();

  const factory PurchaseFlowState.idle() = PurchaseFlowIdle;
  const factory PurchaseFlowState.loading() = PurchaseFlowLoading;
  const factory PurchaseFlowState.success(SubscriptionStatus status) =
      PurchaseFlowSuccess;
  const factory PurchaseFlowState.error(PurchasesFailure failure) =
      PurchaseFlowError;
}

final class PurchaseFlowIdle extends PurchaseFlowState {
  const PurchaseFlowIdle();
}

final class PurchaseFlowLoading extends PurchaseFlowState {
  const PurchaseFlowLoading();
}

final class PurchaseFlowSuccess extends PurchaseFlowState {
  const PurchaseFlowSuccess(this.status);
  final SubscriptionStatus status;
}

final class PurchaseFlowError extends PurchaseFlowState {
  const PurchaseFlowError(this.failure);
  final PurchasesFailure failure;
}

// Note: fpdart Either import needed for PurchaseActions return type
import 'package:fpdart/fpdart.dart';
