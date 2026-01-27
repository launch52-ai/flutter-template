# RevenueCat Dashboard Setup Guide

Step-by-step guide to configuring RevenueCat for your Flutter app.

---

## 1. Create RevenueCat Account

1. Go to [revenuecat.com](https://www.revenuecat.com)
2. Sign up for a free account
3. Verify your email

---

## 2. Create a New Project

1. Click **"+ New Project"** in the dashboard
2. Enter your app name
3. Click **"Create Project"**

---

## 3. Add Your Apps

### iOS App

1. Go to **Project Settings → Apps**
2. Click **"+ New App"**
3. Select **"App Store"**
4. Enter:
   - **App name:** Your app name
   - **Bundle ID:** e.g., `com.yourcompany.yourapp`
5. Click **"Save"**

### Android App

1. Click **"+ New App"**
2. Select **"Play Store"**
3. Enter:
   - **App name:** Your app name
   - **Package name:** e.g., `com.yourcompany.yourapp`
4. Click **"Save"**

---

## 4. Configure App Store Connect (iOS)

### Get Shared Secret

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app → **App Information**
3. Under **App-Specific Shared Secret**, click **"Manage"**
4. Click **"Generate App-Specific Shared Secret"**
5. Copy the secret

### Add to RevenueCat

1. In RevenueCat, go to your iOS app settings
2. Paste the shared secret in **"App Store Connect App-Specific Shared Secret"**
3. Click **"Save"**

---

## 5. Configure Play Console (Android)

### Create Service Account

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Select your project (or create one)
3. Go to **IAM & Admin → Service Accounts**
4. Click **"+ Create Service Account"**
5. Enter:
   - **Name:** `revenuecat-service-account`
   - **Description:** RevenueCat billing access
6. Click **"Create and Continue"**
7. Skip role assignment (we'll do this in Play Console)
8. Click **"Done"**

### Generate Key

1. Click on your new service account
2. Go to **Keys** tab
3. Click **"Add Key → Create new key"**
4. Select **JSON**
5. Click **"Create"** (downloads the key file)

### Grant Access in Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Go to **Settings → API Access**
3. Click **"Link"** next to your Cloud project
4. Find your service account and click **"Grant access"**
5. Set permissions:
   - **App permissions:** Select your app
   - **Account permissions:** View financial data, Manage orders
6. Click **"Invite user"**

### Add to RevenueCat

1. In RevenueCat, go to your Android app settings
2. Upload the JSON key file to **"Service Account credentials JSON"**
3. Click **"Save"**

---

## 6. Create Products in Store Consoles

### App Store Connect

1. Go to your app → **In-App Purchases**
2. Click **"+"** to create a new product
3. Select type:
   - **Auto-Renewable Subscription** for subscriptions
   - **Non-Consumable** for one-time purchases
4. Enter:
   - **Reference Name:** Internal name (e.g., "Monthly Premium")
   - **Product ID:** Unique identifier (e.g., `premium_monthly`)
   - **Pricing:** Select price tier
   - **Localization:** Display name and description
5. For subscriptions, create a **Subscription Group** first

### Google Play Console

1. Go to your app → **Monetize → Products**
2. For subscriptions: **Subscriptions → Create subscription**
3. For one-time: **In-app products → Create product**
4. Enter:
   - **Product ID:** Same as iOS for consistency (e.g., `premium_monthly`)
   - **Name:** Display name
   - **Description:** Product description
   - **Price:** Set pricing
5. Click **"Activate"**

---

## 7. Configure Products in RevenueCat

1. Go to **Products** in RevenueCat
2. Click **"+ New Product"**
3. Enter the **Product Identifier** (must match store product IDs)
4. Select the app(s) this product applies to
5. Click **"Save"**

**Repeat for each product.**

---

## 8. Create Entitlements

Entitlements represent access levels users can unlock.

1. Go to **Entitlements**
2. Click **"+ New Entitlement"**
3. Enter:
   - **Identifier:** e.g., `premium`
   - **Description:** e.g., "Access to all premium features"
4. Click **"Save"**
5. Click on the entitlement
6. Under **"Products"**, click **"Attach"**
7. Select all products that grant this entitlement
8. Click **"Attach"**

### Common Entitlement Structures

**Single tier:**
```
premium (entitlement)
├── premium_monthly (product)
├── premium_annual (product)
└── premium_lifetime (product)
```

**Multiple tiers:**
```
basic (entitlement)
├── basic_monthly
└── basic_annual

pro (entitlement)
├── pro_monthly
└── pro_annual
```

---

## 9. Create Offerings

Offerings are collections of products to show users.

1. Go to **Offerings**
2. Click **"+ New Offering"**
3. Enter:
   - **Identifier:** e.g., `default`
   - **Description:** Main offering
4. Click **"Save"**
5. Click on the offering
6. Under **"Packages"**, click **"+ New Package"**
7. Enter:
   - **Identifier:** e.g., `monthly` or `$rc_monthly` (use RevenueCat identifier)
   - **Product:** Select the corresponding product
8. Click **"Save"**

### Standard Package Identifiers

Use these for automatic duration detection:

| Identifier | Duration |
|------------|----------|
| `$rc_monthly` | 1 month |
| `$rc_annual` | 1 year |
| `$rc_weekly` | 1 week |
| `$rc_lifetime` | Lifetime |

---

## 10. Get API Keys

1. Go to **Project Settings → API Keys**
2. Copy:
   - **iOS/macOS Public API Key:** `appl_xxxxxxxxx`
   - **Android Public API Key:** `goog_xxxxxxxxx`

Store these securely (environment variables or secure storage).

---

## 11. Configure Webhooks (Optional)

For server-side purchase tracking:

1. Go to **Project Settings → Integrations**
2. Click **"+ New Integration"**
3. Select **"Webhook"**
4. Enter your server endpoint URL
5. Select events to receive
6. Click **"Save"**

---

## Pricing Table Example

| Product ID | Type | iOS Price | Android Price |
|------------|------|-----------|---------------|
| `premium_monthly` | Subscription | $4.99/mo | $4.99/mo |
| `premium_annual` | Subscription | $39.99/yr | $39.99/yr |
| `premium_lifetime` | Non-consumable | $99.99 | $99.99 |

---

## Troubleshooting

### Products not appearing

- Ensure products are "Ready to Submit" (iOS) or "Active" (Android)
- Check product IDs match exactly (case-sensitive)
- Wait 15-30 minutes for changes to propagate

### "Invalid credentials" error

- Verify shared secret (iOS) is correct
- Ensure service account JSON (Android) has proper permissions
- Check the service account is linked in Play Console

### Entitlement not unlocking

- Verify product is attached to entitlement
- Check entitlement identifier matches code
- Verify customer's purchase is in RevenueCat dashboard

---

**Next:** [platform-setup-guide.md](platform-setup-guide.md) - Configure iOS & Android
