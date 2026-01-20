// Template: Subscription status model
//
// Location: lib/features/purchases/domain/models/subscription_status.dart
//
// Dependencies:
//   freezed_annotation: ^2.4.0
//   purchases_flutter: ^8.0.0
//
// Usage:
// 1. Copy to target location
// 2. Run: dart run build_runner build

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'subscription_status.freezed.dart';

/// Represents the user's current subscription status.
///
/// Derived from RevenueCat's [CustomerInfo].
@freezed
class SubscriptionStatus with _$SubscriptionStatus {
  const factory SubscriptionStatus({
    /// Whether user has an active subscription or entitlement.
    required bool isActive,

    /// The active entitlement identifier (e.g., "premium", "pro").
    String? activeEntitlement,

    /// Product identifier of the active subscription.
    String? activeProductId,

    /// When the subscription will expire (null for lifetime).
    DateTime? expirationDate,

    /// Whether this is the first subscription (for onboarding).
    @Default(false) bool isFirstSubscription,

    /// Whether the subscription will auto-renew.
    @Default(false) bool willRenew,

    /// Management URL for subscription settings.
    String? managementUrl,

    /// All active entitlements (for multi-tier apps).
    @Default({}) Set<String> activeEntitlements,
  }) = _SubscriptionStatus;

  const SubscriptionStatus._();

  /// Create from RevenueCat CustomerInfo.
  factory SubscriptionStatus.fromCustomerInfo(
    CustomerInfo customerInfo, {
    String entitlementId = 'premium',
  }) {
    final entitlement = customerInfo.entitlements.active[entitlementId];
    final isActive = entitlement != null;

    return SubscriptionStatus(
      isActive: isActive,
      activeEntitlement: isActive ? entitlementId : null,
      activeProductId: entitlement?.productIdentifier,
      expirationDate: entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null,
      willRenew: entitlement?.willRenew ?? false,
      managementUrl: customerInfo.managementURL,
      activeEntitlements: customerInfo.entitlements.active.keys.toSet(),
    );
  }

  /// Create an inactive/free status.
  factory SubscriptionStatus.free() => const SubscriptionStatus(isActive: false);

  /// Whether this is a lifetime (non-expiring) subscription.
  bool get isLifetime => isActive && expirationDate == null;

  /// Whether the subscription is expiring soon (within 7 days).
  bool get isExpiringSoon {
    if (!isActive || expirationDate == null) return false;
    final daysUntilExpiration =
        expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration > 0;
  }

  /// Whether the subscription has expired.
  bool get isExpired {
    if (!isActive) return false;
    if (expirationDate == null) return false; // Lifetime
    return expirationDate!.isBefore(DateTime.now());
  }

  /// Days until expiration (null if lifetime or not active).
  int? get daysUntilExpiration {
    if (!isActive || expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  /// Check if user has a specific entitlement.
  bool hasEntitlement(String entitlementId) =>
      activeEntitlements.contains(entitlementId);
}

/// Represents details about a purchasable product.
@freezed
class ProductDetails with _$ProductDetails {
  const factory ProductDetails({
    /// Unique product identifier.
    required String id,

    /// Display title from store.
    required String title,

    /// Description from store.
    required String description,

    /// Formatted price string (e.g., "$4.99").
    required String priceString,

    /// Price as number (for calculations).
    required double price,

    /// Currency code (e.g., "USD").
    required String currencyCode,

    /// Subscription period (null for one-time).
    SubscriptionPeriod? subscriptionPeriod,

    /// Free trial period (if available).
    SubscriptionPeriod? freeTrialPeriod,

    /// Introductory price info (if available).
    IntroductoryPrice? introductoryPrice,
  }) = _ProductDetails;

  const ProductDetails._();

  /// Create from RevenueCat StoreProduct.
  factory ProductDetails.fromStoreProduct(StoreProduct product) {
    return ProductDetails(
      id: product.identifier,
      title: product.title,
      description: product.description,
      priceString: product.priceString,
      price: product.price,
      currencyCode: product.currencyCode,
      subscriptionPeriod: product.subscriptionPeriod != null
          ? SubscriptionPeriod.fromRc(product.subscriptionPeriod!)
          : null,
      freeTrialPeriod: product.introductoryPrice?.subscriptionPeriod != null
          ? SubscriptionPeriod.fromRc(
              product.introductoryPrice!.subscriptionPeriod!)
          : null,
      introductoryPrice: product.introductoryPrice != null
          ? IntroductoryPrice.fromRc(product.introductoryPrice!)
          : null,
    );
  }

  /// Whether this is a subscription product.
  bool get isSubscription => subscriptionPeriod != null;

  /// Whether this product has a free trial.
  bool get hasFreeTrial => freeTrialPeriod != null;

  /// Whether this product has an introductory price.
  bool get hasIntroductoryPrice => introductoryPrice != null;

  /// Get price per month for comparison (null for non-subscriptions).
  double? get monthlyPrice {
    if (subscriptionPeriod == null) return null;
    return subscriptionPeriod!.toMonthlyPrice(price);
  }
}

/// Subscription billing period.
@freezed
class SubscriptionPeriod with _$SubscriptionPeriod {
  const factory SubscriptionPeriod({
    required int value,
    required PeriodUnit unit,
  }) = _SubscriptionPeriod;

  const SubscriptionPeriod._();

  factory SubscriptionPeriod.fromRc(
      purchases_flutter.SubscriptionPeriod period) {
    return SubscriptionPeriod(
      value: period.value,
      unit: PeriodUnit.fromRc(period.unit),
    );
  }

  /// Convert price to monthly equivalent for comparison.
  double toMonthlyPrice(double price) {
    final totalMonths = switch (unit) {
      PeriodUnit.day => value / 30,
      PeriodUnit.week => value / 4,
      PeriodUnit.month => value.toDouble(),
      PeriodUnit.year => value * 12,
    };
    return price / totalMonths;
  }

  /// Human-readable period string.
  String get displayString {
    final unitStr = switch (unit) {
      PeriodUnit.day => value == 1 ? 'day' : 'days',
      PeriodUnit.week => value == 1 ? 'week' : 'weeks',
      PeriodUnit.month => value == 1 ? 'month' : 'months',
      PeriodUnit.year => value == 1 ? 'year' : 'years',
    };
    return value == 1 ? unitStr : '$value $unitStr';
  }
}

/// Period unit for subscriptions.
enum PeriodUnit {
  day,
  week,
  month,
  year;

  factory PeriodUnit.fromRc(purchases_flutter.PeriodUnit unit) {
    return switch (unit) {
      purchases_flutter.PeriodUnit.day => PeriodUnit.day,
      purchases_flutter.PeriodUnit.week => PeriodUnit.week,
      purchases_flutter.PeriodUnit.month => PeriodUnit.month,
      purchases_flutter.PeriodUnit.year => PeriodUnit.year,
      _ => PeriodUnit.month, // Default fallback
    };
  }
}

/// Introductory price information.
@freezed
class IntroductoryPrice with _$IntroductoryPrice {
  const factory IntroductoryPrice({
    required String priceString,
    required double price,
    required int cycles,
    required SubscriptionPeriod period,
  }) = _IntroductoryPrice;

  factory IntroductoryPrice.fromRc(
      purchases_flutter.IntroductoryPrice introPrice) {
    return IntroductoryPrice(
      priceString: introPrice.priceString,
      price: introPrice.price,
      cycles: introPrice.cycles,
      period: SubscriptionPeriod.fromRc(introPrice.subscriptionPeriod),
    );
  }
}
