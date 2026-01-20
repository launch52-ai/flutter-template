# In-App Purchases Checklist

Complete verification checklist for RevenueCat in-app purchases implementation.

---

## Quick Audit

```bash
dart run .claude/skills/in-app-purchases/scripts/check.dart
```

---

## RevenueCat Dashboard

### Project Setup

- [ ] RevenueCat account created
- [ ] Project created in dashboard
- [ ] iOS app added with correct Bundle ID
- [ ] Android app added with correct Package name

### Store Credentials

**iOS:**
- [ ] App Store Connect shared secret added
- [ ] App Store Connect API key configured (optional)

**Android:**
- [ ] Service account JSON uploaded
- [ ] Service account has correct permissions in Play Console

### Products

- [ ] Products created in App Store Connect
- [ ] Products created in Google Play Console
- [ ] Products added to RevenueCat (matching IDs)
- [ ] Products are "Ready to Submit" (iOS) or "Active" (Android)

### Entitlements

- [ ] Entitlements created (e.g., "premium")
- [ ] Products attached to entitlements
- [ ] Entitlement IDs match code

### Offerings

- [ ] Default offering created
- [ ] Packages added to offering (monthly, annual, etc.)
- [ ] Package identifiers match expected values

### API Keys

- [ ] iOS API key copied
- [ ] Android API key copied
- [ ] Keys stored securely (not in source control)

---

## iOS Setup

### Xcode Configuration

- [ ] In-App Purchase capability enabled
- [ ] StoreKit configuration file created
- [ ] Products added to StoreKit config
- [ ] Scheme configured to use StoreKit config

### App Store Connect

- [ ] Products created with correct IDs
- [ ] Products in "Ready to Submit" status
- [ ] Subscription group created (for subscriptions)
- [ ] Pricing configured
- [ ] Localization added

### Testing

- [ ] Sandbox tester account created
- [ ] Can purchase on Simulator with StoreKit config
- [ ] Can purchase on device with sandbox account
- [ ] Subscription renewal works (accelerated)

---

## Android Setup

### AndroidManifest.xml

- [ ] BILLING permission added:
  ```xml
  <uses-permission android:name="com.android.vending.BILLING" />
  ```

### Google Play Console

- [ ] App uploaded to internal testing track
- [ ] Products created and activated
- [ ] License testers added
- [ ] Service account linked

### Testing

- [ ] Can purchase with license tester account
- [ ] Test cards work (always approves, always declines)
- [ ] Subscription management works

---

## Code Implementation

### Dependencies

- [ ] `purchases_flutter: ^8.0.0` in pubspec.yaml
- [ ] `flutter pub get` run

### Initialization

- [ ] RevenueCat initialized in main.dart
- [ ] API keys configured per platform
- [ ] Debug logging enabled in development
- [ ] Logging disabled in production

### Domain Layer

- [ ] `PurchasesFailure` sealed class created
- [ ] `SubscriptionStatus` model created
- [ ] `PurchasesRepository` interface defined

### Data Layer

- [ ] `PurchasesRepositoryImpl` implemented
- [ ] Error mapping from RevenueCat errors
- [ ] Customer info stream exposed

### Presentation Layer

- [ ] `subscriptionStatusProvider` created
- [ ] `isPremiumProvider` for quick checks
- [ ] `offeringsProvider` for paywall
- [ ] `purchaseFlowProvider` for purchase state

### Paywall

- [ ] Paywall screen implemented
- [ ] Products/packages displayed
- [ ] Prices shown correctly
- [ ] Purchase button functional
- [ ] Loading state during purchase
- [ ] Error handling for failures
- [ ] Restore purchases button present

### Entitlement Checks

- [ ] Premium features gated with `isPremiumProvider`
- [ ] Route guards for premium screens
- [ ] Graceful handling when not premium

### User Identity

- [ ] RevenueCat login on user authentication
- [ ] RevenueCat logout on user sign out
- [ ] Purchases sync across devices

---

## Legal Compliance

### App Store Requirements

- [ ] Restore purchases clearly visible
- [ ] Subscription terms displayed before purchase
- [ ] Auto-renewal terms disclosed
- [ ] Terms of Service link present
- [ ] Privacy Policy link present

### Required Disclosure Text

- [ ] Payment charged at confirmation
- [ ] Auto-renewal unless cancelled 24h before
- [ ] Manage subscriptions in Settings

---

## Testing Checklist

### Basic Flows

- [ ] Products load from RevenueCat
- [ ] Prices display correctly
- [ ] Purchase flow completes
- [ ] Entitlement unlocked after purchase
- [ ] UI updates after purchase
- [ ] Cancel purchase handled gracefully

### Restore Purchases

- [ ] Restore button works
- [ ] Purchases restored on fresh install
- [ ] "No purchases" message when appropriate

### Subscription Lifecycle

- [ ] Initial subscription works
- [ ] Renewal processed (accelerated in sandbox)
- [ ] Expiration removes access
- [ ] Resubscription works

### Edge Cases

- [ ] Network error handling
- [ ] Interrupted purchase (background app)
- [ ] Multiple purchase attempts
- [ ] Cross-device sync

### Regression

- [ ] Existing users not affected
- [ ] Free tier still works
- [ ] App doesn't crash without subscription

---

## Pre-Release

### Final Verification

- [ ] All sandbox tests pass
- [ ] Production API keys configured
- [ ] Debug logging disabled
- [ ] Webhook configured (if using server)
- [ ] Analytics tracking purchase events

### App Store Submission

- [ ] In-App Purchase metadata complete
- [ ] Review notes explain subscription
- [ ] Demo account provided (if needed)
- [ ] Pricing approved

### Google Play Submission

- [ ] Products active and approved
- [ ] Subscription pricing approved
- [ ] Content rating questionnaire updated

---

## Post-Launch

### Monitoring

- [ ] RevenueCat dashboard monitored
- [ ] Purchase events in analytics
- [ ] Error tracking for failures
- [ ] Revenue metrics reviewed

### Support

- [ ] Restore instructions documented
- [ ] FAQ for billing issues
- [ ] Support contact for refund requests

---

## Common Issues Reference

| Issue | Check |
|-------|-------|
| Products not loading | Are products active in store? IDs match? |
| "Cannot connect to store" | Simulator needs StoreKit config |
| Android purchases fail | App uploaded to testing track? |
| Entitlement not unlocking | Product attached to entitlement? |
| Restore not working | Logged in with correct account? |
| Prices showing $0 | Products configured in store? |
