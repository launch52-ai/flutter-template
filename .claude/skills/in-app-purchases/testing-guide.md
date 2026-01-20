# Testing Guide

Test in-app purchases in development and staging environments.

---

## Testing Environments

| Environment | Platform | Real Money | Notes |
|-------------|----------|------------|-------|
| StoreKit Config | iOS Simulator | No | Fast, local testing |
| iOS Sandbox | iOS Device | No | Real App Store flow |
| License Testing | Android | No | Real Play Store flow |
| Production | Both | Yes | Live users |

---

## iOS: StoreKit Configuration Testing

Best for rapid development iteration on Simulator.

### Setup

1. Create StoreKit Configuration file in Xcode
2. Add products matching RevenueCat configuration
3. Enable in scheme → Run → Options → StoreKit Configuration

### Testing Features

| Feature | How to Test |
|---------|-------------|
| Purchase | Normal purchase flow |
| Restore | Purchases persist in StoreKit config |
| Subscription renewal | Automatic (accelerated) |
| Expiration | Edit subscription in StoreKit debug menu |
| Failed payment | Enable "Fail Transactions" in debug menu |

### Access Debug Menu

In Simulator: **Debug → StoreKit → Manage Transactions**

### Accelerated Renewals

StoreKit Config uses accelerated time:

| Real Duration | Test Duration |
|---------------|---------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 1 year | 1 hour |

---

## iOS: Sandbox Testing

For real device testing with App Store flow.

### Create Sandbox Tester

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access → Sandbox → Testers**
3. Click **+** to add tester
4. Enter details (email can be fake)
5. Save

### Sign In on Device

1. **Settings → App Store → Sandbox Account**
2. Sign in with sandbox credentials
3. Keep production account signed in for other apps

### Testing Flow

1. Build and run app on device
2. Trigger purchase
3. Sign in with sandbox account when prompted
4. Complete purchase (no charge)

### Sandbox Subscription Behavior

- Renewals happen automatically (accelerated)
- Subscriptions renew 6 times then expire
- Clear purchase history: **Settings → App Store → Sandbox Account → Manage**

---

## Android: License Testing

### Add License Testers

1. Open [Play Console](https://play.google.com/console)
2. Go to **Settings → License testing**
3. Add email addresses
4. Save

### Upload Test Build

Google Play billing requires an uploaded app:

1. Build signed release: `flutter build appbundle --release`
2. Upload to Internal Testing track
3. Products must be "Active"

### Testing Flow

1. Install from Play Store (internal track) or sideload signed APK
2. Sign in to device with license tester account
3. Trigger purchase
4. Use test card options:
   - "Test card, always approves"
   - "Test card, always declines"

### Test Card Options

When testing, Play Store shows special test cards:

| Card | Behavior |
|------|----------|
| Always approves | Purchase succeeds |
| Always declines | Purchase fails |
| Slow | Delayed response |

---

## Testing Checklist

### Basic Purchase Flow

- [ ] Products load correctly
- [ ] Prices display in correct currency
- [ ] Purchase button triggers store sheet
- [ ] Successful purchase unlocks entitlement
- [ ] UI updates after purchase
- [ ] Error handling for cancelled purchase

### Restore Purchases

- [ ] Restore button visible
- [ ] Restore on fresh install recovers purchases
- [ ] Appropriate message when no purchases to restore

### Subscription Lifecycle

- [ ] Initial purchase works
- [ ] Subscription renews (wait for accelerated renewal)
- [ ] Expired subscription removes access
- [ ] Cancelled subscription shows correct expiration

### Edge Cases

- [ ] Network error during purchase
- [ ] Background/foreground during purchase
- [ ] Multiple rapid purchase attempts
- [ ] Purchase on one device, check on another

### Cross-Platform (if applicable)

- [ ] iOS purchase visible on Android (same user)
- [ ] Android purchase visible on iOS (same user)
- [ ] User login syncs purchases

---

## RevenueCat Dashboard Verification

After testing purchases, verify in RevenueCat:

1. Go to **Customers** tab
2. Search for test user (app user ID or email)
3. Verify:
   - Transactions appear
   - Entitlements are active
   - Subscription status is correct

### Useful Dashboard Features

- **Event History**: See all purchase events
- **Customer Timeline**: Debug individual users
- **Sandbox Filter**: Toggle sandbox/production data

---

## Debugging Tips

### Enable Debug Logs

```dart
await Purchases.setLogLevel(LogLevel.debug);
```

### Check CustomerInfo

```dart
final customerInfo = await Purchases.getCustomerInfo();
print('Active entitlements: ${customerInfo.entitlements.active.keys}');
print('All purchases: ${customerInfo.allPurchasedProductIdentifiers}');
```

### Verify Product Configuration

```dart
final offerings = await Purchases.getOfferings();
for (final package in offerings.current?.availablePackages ?? []) {
  print('Package: ${package.identifier}');
  print('Product: ${package.storeProduct.identifier}');
  print('Price: ${package.storeProduct.priceString}');
}
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Products not loading | Not configured in store | Create in App Store Connect / Play Console |
| "Cannot connect" on Simulator | No StoreKit config | Add StoreKit Configuration file |
| Android purchase fails | App not uploaded | Upload to internal testing track |
| Entitlement not unlocking | Product not attached | Attach product to entitlement in RevenueCat |

---

## Automated Testing

### Mock Repository

Use `MockPurchasesRepository` for unit/widget tests:

```dart
void main() {
  testWidgets('paywall shows when not premium', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchasesRepositoryProvider.overrideWithValue(
            MockPurchasesRepository(isSubscribed: false),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Navigate to premium feature
    await tester.tap(find.text('Premium Feature'));
    await tester.pumpAndSettle();

    // Should show paywall
    expect(find.text('Unlock Premium'), findsOneWidget);
  });

  testWidgets('premium content shows when subscribed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchasesRepositoryProvider.overrideWithValue(
            MockPurchasesRepository(isSubscribed: true),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Navigate to premium feature
    await tester.tap(find.text('Premium Feature'));
    await tester.pumpAndSettle();

    // Should show content, not paywall
    expect(find.text('Premium Content'), findsOneWidget);
  });
}
```

### Integration Tests

For real store testing in CI, use:
- iOS: Xcode Cloud with StoreKit Configuration
- Android: Firebase Test Lab with license testing

---

**See also:** [implementation-guide.md](implementation-guide.md)
