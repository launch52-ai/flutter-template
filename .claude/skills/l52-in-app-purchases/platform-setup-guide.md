# Platform Setup Guide

Configure iOS and Android platforms for in-app purchases with RevenueCat.

---

## iOS Setup

### 1. Enable In-App Purchase Capability

1. Open your project in Xcode
2. Select your app target
3. Go to **Signing & Capabilities**
4. Click **"+ Capability"**
5. Search and add **"In-App Purchase"**

### 2. Create StoreKit Configuration (For Testing)

StoreKit Configuration allows testing purchases on the iOS Simulator without a sandbox account.

1. In Xcode, go to **File → New → File**
2. Search for **"StoreKit Configuration File"**
3. Name it `StoreKit.storekit`
4. Save in your project root

### 3. Add Products to StoreKit Configuration

1. Open `StoreKit.storekit`
2. Click **"+"** at bottom left
3. Select product type:
   - **Add Auto-Renewable Subscription** for subscriptions
   - **Add Non-Consumable In-App Purchase** for one-time
4. Configure:
   - **Reference Name:** Display name
   - **Product ID:** Must match App Store Connect (e.g., `premium_monthly`)
   - **Price:** $4.99
   - For subscriptions: Set **Subscription Group** and **Duration**
5. Repeat for all products

### 4. Enable StoreKit Testing in Scheme

1. Go to **Product → Scheme → Edit Scheme**
2. Select **Run** in the sidebar
3. Go to **Options** tab
4. Set **StoreKit Configuration** to your `.storekit` file

### 5. App Store Connect Sandbox Testing

For real device testing:

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access → Sandbox → Testers**
3. Click **"+"** to create sandbox tester
4. Enter email (can be fake, e.g., `test@example.com`)
5. On device: **Settings → App Store → Sandbox Account** → sign in

---

## Android Setup

### 1. Add Billing Permission

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add this permission -->
    <uses-permission android:name="com.android.vending.BILLING" />

    <application ...>
        ...
    </application>
</manifest>
```

### 2. Upload to Play Console

Google Play billing requires a signed app uploaded to at least internal testing track.

1. Build a signed release:
   ```bash
   flutter build appbundle --release
   ```

2. In [Play Console](https://play.google.com/console):
   - Go to **Release → Testing → Internal testing**
   - Click **"Create new release"**
   - Upload the `.aab` file
   - Add release notes
   - Click **"Save"** then **"Review release"** then **"Start rollout**

### 3. Add License Testers

1. In Play Console, go to **Settings → License testing**
2. Add tester email addresses
3. These accounts can make test purchases without being charged

### 4. Create Products

1. Go to **Monetize → Products → Subscriptions** or **In-app products**
2. Create products matching your RevenueCat configuration
3. Set pricing
4. Click **"Activate"**

**Important:** Products must be "Active" for testing. This requires the app to be published to at least internal testing.

---

## Environment Configuration

### Store API Keys Securely

Create `.env` files for different environments:

**`.env.dev`:**
```
REVENUECAT_IOS_KEY=appl_xxxxxxxxx
REVENUECAT_ANDROID_KEY=goog_xxxxxxxxx
```

**`.env.prod`:**
```
REVENUECAT_IOS_KEY=appl_yyyyyyyyy
REVENUECAT_ANDROID_KEY=goog_yyyyyyyyy
```

### Load in Code

Using `flutter_dotenv`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

String get revenueCatApiKey {
  if (Platform.isIOS) {
    return dotenv.env['REVENUECAT_IOS_KEY'] ?? '';
  }
  return dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
}
```

Or using `--dart-define`:

```bash
flutter run --dart-define=REVENUECAT_IOS_KEY=appl_xxx --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
```

```dart
const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
const revenueCatAndroidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
```

---

## Testing Checklist

### iOS Simulator (StoreKit Config)

- [ ] StoreKit configuration file created
- [ ] Products added to StoreKit config
- [ ] Scheme configured to use StoreKit config
- [ ] Can complete purchase flow
- [ ] Can restore purchases

### iOS Real Device (Sandbox)

- [ ] Sandbox tester account created
- [ ] Signed in to sandbox account on device
- [ ] Products created in App Store Connect
- [ ] Can complete purchase flow
- [ ] Can restore purchases
- [ ] Subscription renewal works (accelerated)

### Android Emulator/Device

- [ ] Billing permission added
- [ ] App uploaded to internal testing track
- [ ] License tester email added
- [ ] Products active in Play Console
- [ ] Signed in to tester account on device
- [ ] Can complete purchase flow
- [ ] Can restore purchases

---

## Sandbox Testing Notes

### iOS Sandbox

- Subscription renewals are accelerated:
  - 1 week → 3 minutes
  - 1 month → 5 minutes
  - 1 year → 1 hour
- Subscriptions auto-renew 6 times then expire
- Clear purchase history: **Settings → App Store → Sandbox Account → Manage → Clear Purchase History**

### Android Testing

- Test purchases don't charge the account
- Use "test card, always approves" for consistent testing
- Subscriptions can be managed in Play Store app

---

## Troubleshooting

### iOS: "Cannot connect to App Store"

**On Simulator:** Enable StoreKit configuration in scheme.

**On Device:** Sign in to sandbox account in Settings → App Store.

### iOS: Products not loading

- Verify product IDs match App Store Connect exactly
- Ensure products are "Ready to Submit" status
- Wait 15+ minutes after creating products
- Check agreements in App Store Connect are signed

### Android: "Item not available"

- Ensure app is uploaded to testing track
- Products must be "Active" in Play Console
- Tester email must be in license testers list
- Sign out and back into Play Store app

### Android: "Your transaction cannot be completed"

- Clear Play Store cache and data
- Ensure using a license tester account
- Try on a different network

---

**Next:** [implementation-guide.md](implementation-guide.md) - Add code to your app
