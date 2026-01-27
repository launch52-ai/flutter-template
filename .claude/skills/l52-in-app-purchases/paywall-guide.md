# Paywall UI Guide

Best practices and patterns for designing effective paywall screens.

---

## Paywall Types

### 1. Hard Paywall

Blocks access to content until purchase.

**When to use:**
- Premium-only features
- Content apps (news, magazines)
- Productivity tools with clear premium tiers

```dart
class PremiumFeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return const PaywallScreen();
    }

    return const ActualPremiumContent();
  }
}
```

### 2. Soft Paywall

Allows limited access with upgrade prompts.

**When to use:**
- Freemium apps
- Usage-limited features
- Trial experiences

```dart
class LimitedFeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final usageCount = ref.watch(featureUsageCountProvider);

    if (!isPremium && usageCount >= 3) {
      return const PaywallScreen(
        title: 'Unlock Unlimited Access',
        subtitle: 'You\'ve used your 3 free tries today',
      );
    }

    return ActualFeatureContent(
      showUpgradeHint: !isPremium,
    );
  }
}
```

### 3. Onboarding Paywall

Shown during first-run experience.

**When to use:**
- Apps with free trials
- High-value premium features
- Clear value proposition

```dart
// In onboarding flow
GoRoute(
  path: '/onboarding/paywall',
  builder: (context, state) => const OnboardingPaywallScreen(),
),
```

---

## Paywall Layout Patterns

### Pattern 1: Feature Showcase

Highlight what premium unlocks.

```dart
class PaywallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Hero image or animation
            const Expanded(
              flex: 2,
              child: PremiumHeroImage(),
            ),

            // Features list
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unlock Premium',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem('Unlimited access'),
                    _buildFeatureItem('No ads'),
                    _buildFeatureItem('Offline mode'),
                    _buildFeatureItem('Priority support'),
                  ],
                ),
              ),
            ),

            // Packages
            const PackageSelector(),

            // CTA and restore
            const PurchaseButton(),
            const RestoreButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
```

### Pattern 2: Package Comparison

Show value of annual vs monthly.

```dart
class PackageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(offeringsProvider);

    return offerings.when(
      data: (offering) {
        if (offering == null) return const SizedBox.shrink();

        final packages = offering.availablePackages;
        final annual = packages.firstWhereOrNull(
          (p) => p.packageType == PackageType.annual,
        );
        final monthly = packages.firstWhereOrNull(
          (p) => p.packageType == PackageType.monthly,
        );

        return Column(
          children: [
            if (annual != null)
              _PackageOption(
                package: annual,
                isRecommended: true,
                savings: _calculateSavings(annual, monthly),
              ),
            if (monthly != null)
              _PackageOption(
                package: monthly,
                isRecommended: false,
              ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Unable to load packages'),
    );
  }

  String? _calculateSavings(Package annual, Package? monthly) {
    if (monthly == null) return null;
    final annualMonthly = annual.storeProduct.price / 12;
    final monthlyPrice = monthly.storeProduct.price;
    final savings = ((monthlyPrice - annualMonthly) / monthlyPrice * 100).round();
    return 'Save $savings%';
  }
}

class _PackageOption extends StatelessWidget {
  const _PackageOption({
    required this.package,
    required this.isRecommended,
    this.savings,
  });

  final Package package;
  final bool isRecommended;
  final String? savings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? Theme.of(context).primaryColor : Colors.grey,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  package.storeProduct.priceString,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (savings != null)
            Positioned(
              top: -1,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  savings!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTitle() {
    return switch (package.packageType) {
      PackageType.annual => 'Annual',
      PackageType.monthly => 'Monthly',
      PackageType.weekly => 'Weekly',
      PackageType.lifetime => 'Lifetime',
      _ => package.storeProduct.title,
    };
  }

  String _getSubtitle() {
    return switch (package.packageType) {
      PackageType.annual => 'Billed annually',
      PackageType.monthly => 'Billed monthly',
      PackageType.weekly => 'Billed weekly',
      PackageType.lifetime => 'One-time purchase',
      _ => '',
    };
  }
}
```

---

## Best Practices

### 1. Clear Value Proposition

- Show what users get, not what they're missing
- Use concrete examples, not vague benefits
- Include social proof if available

### 2. Reduce Friction

- Don't require account creation before paywall
- Show prices immediately (no "See pricing" buttons)
- Make closing the paywall easy (accessibility)

### 3. Free Trial Messaging

```dart
// Clearly communicate trial terms
Text(
  '7-day free trial, then ${package.storeProduct.priceString}/month',
  style: TextStyle(color: Colors.grey[600]),
),
Text(
  'Cancel anytime before trial ends',
  style: TextStyle(color: Colors.grey[600], fontSize: 12),
),
```

### 4. Price Anchoring

- Show annual first (higher price, better value)
- Calculate and display monthly equivalent
- Highlight savings percentage

### 5. Restore Purchases

Always include restore option (App Store requirement):

```dart
TextButton(
  onPressed: _restorePurchases,
  child: const Text('Restore Purchases'),
),
```

---

## Legal Requirements

### App Store Guidelines

- [ ] Restore purchases button visible
- [ ] Clear pricing information
- [ ] Subscription terms visible before purchase
- [ ] Links to Terms of Service and Privacy Policy
- [ ] Clear auto-renewal disclosure

### Required Text

```dart
// Subscription terms (required)
Text(
  'Payment will be charged to your ${Platform.isIOS ? 'iTunes' : 'Google Play'} '
  'account at confirmation of purchase. Subscription automatically renews unless '
  'auto-renew is turned off at least 24-hours before the end of the current period.',
  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
),

// Links
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    TextButton(
      onPressed: () => launchUrl(Uri.parse('https://yourapp.com/terms')),
      child: const Text('Terms of Service'),
    ),
    const Text(' | '),
    TextButton(
      onPressed: () => launchUrl(Uri.parse('https://yourapp.com/privacy')),
      child: const Text('Privacy Policy'),
    ),
  ],
),
```

---

## Loading States

### During Purchase

```dart
class PurchaseButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(purchaseFlowProvider);
    final selectedPackage = ref.watch(selectedPackageProvider);

    final isLoading = flowState is PurchaseFlowLoading;

    return ElevatedButton(
      onPressed: isLoading || selectedPackage == null
          ? null
          : () => ref.read(purchaseFlowProvider.notifier).purchase(selectedPackage),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Continue'),
    );
  }
}
```

### Error Handling

```dart
ref.listen(purchaseFlowProvider, (previous, next) {
  if (next is PurchaseFlowError) {
    final message = next.failure.userMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    ref.read(purchaseFlowProvider.notifier).reset();
  }

  if (next is PurchaseFlowSuccess) {
    Navigator.of(context).pop(true); // Return success
  }
});
```

---

## A/B Testing Paywalls

RevenueCat supports multiple offerings for A/B testing:

```dart
// Get specific offering for experiment
final offerings = ref.watch(allOfferingsProvider);
final experimentOffering = offerings.valueOrNull?['experiment_v2'];

// Or use current offering (configurable in dashboard)
final currentOffering = ref.watch(offeringsProvider);
```

Configure different offerings in RevenueCat dashboard and remotely switch which is "current".

---

**Next:** [testing-guide.md](testing-guide.md) - Test purchases in sandbox
