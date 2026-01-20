// Template: RevenueCat service wrapper
//
// Location: lib/core/services/purchases_service.dart
//
// Dependencies:
//   purchases_flutter: ^8.0.0
//
// Usage:
// 1. Copy to target location
// 2. Initialize in main.dart after WidgetsFlutterBinding.ensureInitialized()
// 3. Access via PurchasesService.instance

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Singleton service wrapping RevenueCat SDK.
///
/// Initialize once in main.dart:
/// ```dart
/// await PurchasesService.instance.initialize(
///   apiKey: Platform.isIOS ? 'appl_xxx' : 'goog_xxx',
/// );
/// ```
final class PurchasesService {
  PurchasesService._();

  static final instance = PurchasesService._();

  bool _initialized = false;
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Stream of customer info updates.
  ///
  /// Listen to this for subscription changes.
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize RevenueCat.
  ///
  /// Call once in main.dart.
  /// [apiKey] - RevenueCat API key (iOS or Android specific)
  /// [appUserId] - Optional user ID for cross-platform sync
  Future<void> initialize({
    required String apiKey,
    String? appUserId,
  }) async {
    if (_initialized) return;

    // Enable debug logs in development
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    // Configure RevenueCat
    final configuration = PurchasesConfiguration(apiKey)
      ..appUserID = appUserId;

    await Purchases.configure(configuration);

    // Listen to customer info updates
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _customerInfoController.add(customerInfo);
    });

    _initialized = true;
  }

  /// Get current customer info.
  Future<CustomerInfo> getCustomerInfo() async {
    _ensureInitialized();
    return Purchases.getCustomerInfo();
  }

  /// Get available offerings (products to display).
  Future<Offerings> getOfferings() async {
    _ensureInitialized();
    return Purchases.getOfferings();
  }

  /// Purchase a package.
  ///
  /// Returns [CustomerInfo] on success.
  /// Throws [PlatformException] on failure.
  Future<CustomerInfo> purchasePackage(Package package) async {
    _ensureInitialized();
    return Purchases.purchasePackage(package);
  }

  /// Purchase a specific product by ID.
  ///
  /// Prefer [purchasePackage] when using Offerings.
  Future<CustomerInfo> purchaseProduct(String productId) async {
    _ensureInitialized();
    final products = await Purchases.getProducts([productId]);
    if (products.isEmpty) {
      throw Exception('Product not found: $productId');
    }
    return Purchases.purchaseStoreProduct(products.first);
  }

  /// Restore previous purchases.
  ///
  /// Call when user taps "Restore Purchases".
  Future<CustomerInfo> restorePurchases() async {
    _ensureInitialized();
    return Purchases.restorePurchases();
  }

  /// Log in a user (for cross-device sync).
  ///
  /// Call after user authentication.
  Future<LogInResult> logIn(String userId) async {
    _ensureInitialized();
    return Purchases.logIn(userId);
  }

  /// Log out current user.
  ///
  /// Call on user sign out.
  Future<CustomerInfo> logOut() async {
    _ensureInitialized();
    return Purchases.logOut();
  }

  /// Check if user has an active entitlement.
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    final customerInfo = await getCustomerInfo();
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  /// Get the management URL for subscription settings.
  ///
  /// Opens App Store / Play Store subscription management.
  Future<String?> getManagementUrl() async {
    final customerInfo = await getCustomerInfo();
    return customerInfo.managementURL;
  }

  /// Sync purchases with RevenueCat (Android only).
  ///
  /// Call if purchases might be out of sync.
  Future<CustomerInfo> syncPurchases() async {
    _ensureInitialized();
    if (Platform.isAndroid) {
      return Purchases.syncPurchases();
    }
    return getCustomerInfo();
  }

  /// Present code redemption sheet (iOS only).
  ///
  /// For promotional/offer codes.
  Future<void> presentCodeRedemptionSheet() async {
    _ensureInitialized();
    if (Platform.isIOS) {
      await Purchases.presentCodeRedemptionSheet();
    }
  }

  /// Set user attributes for targeting.
  Future<void> setAttributes(Map<String, String> attributes) async {
    _ensureInitialized();
    for (final entry in attributes.entries) {
      await Purchases.setAttributes({entry.key: entry.value});
    }
  }

  /// Set email for receipt delivery and customer lookup.
  Future<void> setEmail(String email) async {
    _ensureInitialized();
    await Purchases.setEmail(email);
  }

  /// Dispose resources.
  void dispose() {
    _customerInfoController.close();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'PurchasesService not initialized. '
        'Call PurchasesService.instance.initialize() first.',
      );
    }
  }
}
