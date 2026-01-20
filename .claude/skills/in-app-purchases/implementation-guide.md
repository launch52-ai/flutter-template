# Implementation Guide

Step-by-step code implementation for RevenueCat in-app purchases.

---

## 1. Add Dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  purchases_flutter: ^8.0.0
```

Run:
```bash
flutter pub get
```

---

## 2. Initialize RevenueCat

In `lib/main.dart`:

```dart
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat
  await _initializePurchases();

  runApp(
    ProviderScope(child: const MyApp()),
  );
}

Future<void> _initializePurchases() async {
  await Purchases.setLogLevel(LogLevel.debug); // Remove in production

  final configuration = PurchasesConfiguration(
    Platform.isIOS
        ? const String.fromEnvironment('REVENUECAT_IOS_KEY')
        : const String.fromEnvironment('REVENUECAT_ANDROID_KEY'),
  );

  await Purchases.configure(configuration);
}
```

### With User Identification

To sync purchases across devices/platforms:

```dart
Future<void> _initializePurchases({String? userId}) async {
  await Purchases.setLogLevel(LogLevel.debug);

  final configuration = PurchasesConfiguration(
    Platform.isIOS
        ? const String.fromEnvironment('REVENUECAT_IOS_KEY')
        : const String.fromEnvironment('REVENUECAT_ANDROID_KEY'),
  )..appUserID = userId; // Optional: your user ID

  await Purchases.configure(configuration);
}
```

---

## 3. Copy Reference Files

Copy the reference files to your project:

```
lib/
├── core/
│   └── services/
│       └── purchases_service.dart          # From reference/services/
└── features/
    └── purchases/
        ├── domain/
        │   ├── failures/
        │   │   └── purchases_failures.dart  # From reference/failures/
        │   ├── models/
        │   │   └── subscription_status.dart # From reference/models/
        │   └── repositories/
        │       └── purchases_repository.dart # From reference/repositories/
        ├── data/
        │   └── repositories/
        │       └── purchases_repository_impl.dart
        └── presentation/
            └── providers/
                └── purchases_providers.dart  # From reference/providers/
```

**See:** `reference/` folder for complete implementations.

---

## 4. Implement Entitlement Checks

### Simple Check

```dart
// In any widget
class PremiumFeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return subscriptionStatus.when(
      data: (status) {
        if (!status.isActive) {
          return const PaywallScreen();
        }
        return const ActualPremiumContent();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const PaywallScreen(),
    );
  }
}
```

### Using isPremiumProvider

```dart
// Simple boolean check
final isPremium = ref.watch(isPremiumProvider);

if (!isPremium) {
  context.push('/paywall');
  return;
}
```

### Route Guard

```dart
GoRoute(
  path: '/premium-feature',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final isPremium = container.read(isPremiumProvider);
    return isPremium ? null : '/paywall';
  },
  builder: (context, state) => const PremiumFeatureScreen(),
),
```

---

## 5. Implement Paywall

### Get Offerings

```dart
class PaywallScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(offeringsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: offerings.when(
        data: (offering) {
          if (offering == null) {
            return const Center(child: Text('No packages available'));
          }
          return _buildPackageList(context, ref, offering);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPackageList(
    BuildContext context,
    WidgetRef ref,
    Offering offering,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        const Text(
          'Unlock Premium Features',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // Package cards
        ...offering.availablePackages.map(
          (package) => PackageCard(
            package: package,
            onTap: () => _purchase(context, ref, package),
          ),
        ),

        const SizedBox(height: 16),

        // Restore button
        TextButton(
          onPressed: () => _restore(context, ref),
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    Package package,
  ) async {
    final result = await ref.read(purchasesRepositoryProvider).purchase(package);

    result.fold(
      (failure) => _handleFailure(context, failure),
      (_) {
        // Purchase successful - UI will update via subscriptionStatusProvider
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(purchasesRepositoryProvider).restorePurchases();

    result.fold(
      (failure) => _handleFailure(context, failure),
      (status) {
        if (status.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No purchases to restore')),
          );
        }
      },
    );
  }

  void _handleFailure(BuildContext context, PurchasesFailure failure) {
    final message = switch (failure) {
      PurchaseCancelled() => null, // User cancelled, no message needed
      PurchasePending() => 'Purchase pending approval',
      NetworkError() => 'Network error. Please try again.',
      StoreError(:final message) => message ?? 'Store error occurred',
      ProductNotFound() => 'Product not available',
      NotAllowed() => 'Purchases not allowed on this device',
      UnknownError(:final message) => message ?? 'An error occurred',
    };

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
```

### Package Card Widget

```dart
class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    required this.onTap,
  });

  final Package package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.priceString,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getPeriodText(package),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPeriodText(Package package) {
    return switch (package.packageType) {
      PackageType.monthly => 'per month',
      PackageType.annual => 'per year',
      PackageType.weekly => 'per week',
      PackageType.lifetime => 'one-time',
      _ => '',
    };
  }
}
```

---

## 6. Handle Login/Logout

Sync RevenueCat user with your auth:

```dart
// On login
Future<void> onUserLogin(String userId) async {
  final result = await Purchases.logIn(userId);
  // CustomerInfo now reflects this user's purchases
}

// On logout
Future<void> onUserLogout() async {
  await Purchases.logOut();
  // Reverts to anonymous user
}
```

### With Auth Provider Integration

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<UserProfile?> build() async {
    // ... existing auth logic
  }

  Future<void> signIn(/* ... */) async {
    // ... sign in logic

    // Sync with RevenueCat
    if (user != null) {
      await Purchases.logIn(user.id);
    }
  }

  Future<void> signOut() async {
    await Purchases.logOut();
    // ... sign out logic
  }
}
```

---

## 7. Listen to Subscription Changes

React to subscription changes (e.g., from outside the app):

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to subscription changes
    ref.listen(subscriptionStatusProvider, (previous, next) {
      next.whenData((status) {
        if (previous?.valueOrNull?.isActive == true && !status.isActive) {
          // Subscription expired - handle appropriately
          // e.g., navigate to paywall, show message
        }
      });
    });

    return MaterialApp.router(/* ... */);
  }
}
```

---

## 8. Track Purchase Events (Analytics)

```dart
Future<void> _purchase(Package package) async {
  final result = await ref.read(purchasesRepositoryProvider).purchase(package);

  result.fold(
    (failure) {
      // Track failure
      ref.read(analyticsLoggerProvider).logEvent(
        name: 'purchase_failed',
        parameters: {
          'product_id': package.storeProduct.identifier,
          'error': failure.toString(),
        },
      );
    },
    (_) {
      // Track success
      ref.read(analyticsLoggerProvider).logEvent(
        name: 'purchase_completed',
        parameters: {
          'product_id': package.storeProduct.identifier,
          'price': package.storeProduct.price,
        },
      );
    },
  );
}
```

---

## Code Structure Summary

```
lib/
├── main.dart                              # Initialize RevenueCat
├── core/
│   └── services/
│       └── purchases_service.dart         # RevenueCat wrapper
└── features/
    └── purchases/
        ├── domain/
        │   ├── failures/
        │   │   └── purchases_failures.dart
        │   ├── models/
        │   │   └── subscription_status.dart
        │   └── repositories/
        │       └── purchases_repository.dart
        ├── data/
        │   └── repositories/
        │       └── purchases_repository_impl.dart
        └── presentation/
            ├── providers/
            │   └── purchases_providers.dart
            ├── screens/
            │   └── paywall_screen.dart
            └── widgets/
                ├── package_card.dart
                └── restore_button.dart
```

---

**Next:** [paywall-guide.md](paywall-guide.md) - Paywall UI patterns
