# Android Release Guide

Complete guide for Android app signing and Google Play Store deployment.

---

## Overview

| Step | Purpose | Time |
|------|---------|------|
| 1. Create Keystore | Generate signing key | 5 min |
| 2. Configure Signing | Connect keystore to build | 10 min |
| 3. Add ProGuard | Code obfuscation & shrinking | 5 min |
| 4. Play Console Setup | Store listing | 30 min |
| 5. Build & Upload | Create release AAB | 10 min |

> **Using CI/CD?** This guide covers manual signing with a local keystore. For automated CI/CD releases, the keystore is stored as Base64 in GitHub Secrets and `key.properties` is generated at build time. See `/ci-cd` skill for that approach.

---

## 1. Create Keystore

### 1.1 Generate Keystore File

Generate the command with your project name filled in:

```bash
dart run .claude/skills/release/scripts/check.dart --keytool-command
```

Or run manually (replace `{project_name}`):

```bash
keytool -genkey -v \
  -keystore ~/{project_name}.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias {project_name}
```

**You'll be prompted for:**
- Keystore password (remember this!)
- Key password (can match keystore password)
- Name, Organization, etc. (enter your details)

### 1.2 Secure Backup

**CRITICAL:** Back up your keystore immediately. If lost, you cannot update your app!

Recommended backup locations:
- Password manager (1Password, Bitwarden)
- Encrypted cloud storage (separate from code repo)
- Secure USB drive in safe location

Store alongside:
- Keystore password
- Key alias
- Key password

---

## 2. Configure Signing

### 2.1 Create key.properties

Create `android/key.properties` (DO NOT COMMIT):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias={project_name}
storeFile=/absolute/path/to/{project_name}.jks
```

**Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=my_app
storeFile=/Users/developer/keystores/my_app.jks
```

### 2.2 Update .gitignore

Ensure `android/.gitignore` or root `.gitignore` contains:

```gitignore
# Android signing
android/key.properties
*.jks
*.keystore
```

### 2.3 Update build.gradle.kts

Edit `android/app/build.gradle.kts`:

**Add imports at the top:**

```kotlin
import java.util.Properties
import java.io.FileInputStream
```

**Add after plugins block:**

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**Add inside `android {}` block:**

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

### 2.4 Complete build.gradle.kts Example

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.my_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

---

## 3. ProGuard Configuration

### 3.1 Create proguard-rules.pro

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Supabase/GoTrue classes (if using Supabase)
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

# Keep Dio/HTTP classes (if using Dio)
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Google Play Core (common warning source)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep model classes (JSON serialization)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Preserve line numbers for debugging crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# If using Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# If using Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
```

### 3.2 Troubleshooting ProGuard

If build fails with missing class errors, add keep rules:

```proguard
# Example: Keep all classes in a package
-keep class your.package.name.** { *; }

# Example: Keep specific class
-keep class com.example.SomeClass { *; }
```

Run build with verbose output to identify issues:
```bash
flutter build appbundle --release -v
```

---

## 4. Google Play Console Setup

### 4.1 Create Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay $25 one-time registration fee
3. Complete account details

### 4.2 Create App

1. Click **Create app**
2. Enter app details:
   - App name
   - Default language
   - App or Game
   - Free or Paid
3. Accept policies

### 4.3 Configure App Signing

Google Play App Signing is recommended (default):

1. Go to **Setup** > **App signing**
2. Choose **Use Google Play App Signing** (recommended)
3. Upload your app bundle (Google manages release signing)

**Or** opt out to manage your own key (not recommended).

### 4.4 Store Listing Requirements

| Requirement | Specification |
|-------------|---------------|
| **Short description** | Max 80 characters |
| **Full description** | Max 4000 characters |
| **Screenshots** | Min 2 per form factor |
| **Feature graphic** | 1024 x 500 px |
| **App icon** | 512 x 512 px (separate from app) |
| **Privacy policy** | Required URL |
| **App category** | Select appropriate |

### 4.5 Content Rating

1. Go to **Policy** > **App content**
2. Complete content rating questionnaire
3. Answer questions about app content
4. Receive IARC rating

### 4.6 Release Track Selection

| Track | Purpose | Review Time |
|-------|---------|-------------|
| **Internal** | Team testing | Instant |
| **Closed** | Selected testers | Instant |
| **Open** | Public beta | ~Hours |
| **Production** | Public release | 1-7 days |

---

## 5. Build & Upload

### 5.1 Build Release Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 5.2 Verify Build

```bash
# Check bundle size
ls -lh build/app/outputs/bundle/release/app-release.aab

# Analyze bundle (optional)
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=temp.apks --mode=universal
```

### 5.3 Upload to Play Console

1. Go to **Release** > **Production** (or chosen track)
2. Click **Create new release**
3. Upload `.aab` file
4. Add release notes
5. **Review and roll out**

---

## 6. SHA-1 Fingerprints (for Google Services)

### 6.1 Get Debug SHA-1

```bash
cd android && ./gradlew signingReport
```

Look for:
```
Variant: debug
Config: debug
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### 6.2 Get Release SHA-1

```bash
keytool -list -v -keystore /path/to/{project_name}.jks -alias {project_name}
```

### 6.3 Get Play Store SHA-1

1. Go to Play Console > **Setup** > **App signing**
2. Copy **SHA-1 certificate fingerprint** under "App signing key certificate"

---

## 7. Data Safety Declaration

Google Play requires all apps to declare what data they collect and how it's used. **This is mandatory and must be completed before publishing.**

### 7.1 Access Data Safety Form

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to **Policy** > **App content** > **Data safety**
4. Click **Start** or **Manage**

### 7.2 Common Data Types for Flutter Apps

| Data Type | Collected If Using | Shared With |
|-----------|-------------------|-------------|
| **Email address** | Supabase Auth, Firebase Auth | No (first-party only) |
| **Name** | User profiles | No |
| **User IDs** | Any authentication | No |
| **Crash logs** | Firebase Crashlytics, Sentry | Yes (crash service) |
| **Performance diagnostics** | Firebase Performance | Yes (analytics service) |
| **App interactions** | Firebase Analytics | Yes (analytics service) |
| **Device identifiers** | Push notifications, analytics | Depends on SDK |

### 7.3 Data Collection Questions

The form asks for each data type:

1. **Is this data collected?** - Does your app receive this data?
2. **Is this data shared?** - Sent to third parties?
3. **Is this data processed ephemerally?** - Only in memory, never stored?
4. **Is this data required?** - Can user opt out?
5. **Purpose** - Why do you collect this?

### 7.4 Common Flutter App Declaration

**Typical setup for an app with auth + analytics:**

```
Data Collected:
├── Personal info
│   ├── Email address
│   │   ├── Purpose: Account management
│   │   ├── Shared: No
│   │   └── Required: Yes (for account)
│   └── Name (if profile exists)
│       ├── Purpose: App functionality
│       ├── Shared: No
│       └── Required: No
│
├── App activity
│   └── App interactions (Firebase Analytics)
│       ├── Purpose: Analytics
│       ├── Shared: Yes (with Google)
│       └── Required: Yes
│
└── App info and performance
    └── Crash logs (Crashlytics)
        ├── Purpose: App functionality
        ├── Shared: Yes (with Google)
        └── Required: Yes
```

### 7.5 Security Practices

You must also declare:

| Question | Typical Answer |
|----------|----------------|
| **Data encrypted in transit?** | Yes (HTTPS) |
| **Data deletion request?** | Yes (if you support account deletion) |
| **Committed to Play Families Policy?** | Only if targeting children |

### 7.6 Third-Party SDK Data

Check SDK documentation for their data practices:

| SDK | Data Collected | Documentation |
|-----|----------------|---------------|
| **Firebase Analytics** | Device ID, app interactions | [Firebase Data](https://firebase.google.com/support/privacy) |
| **Firebase Crashlytics** | Crash logs, device info | Same as above |
| **Google Sign-In** | Email, name, profile photo | [Google Identity](https://developers.google.com/identity) |
| **Supabase** | Depends on your schema | Your responsibility |
| **Sentry** | Crash logs, device info | [Sentry Privacy](https://sentry.io/privacy/) |

### 7.7 Tips

1. **Be accurate** - Google may reject apps with inaccurate declarations
2. **Review SDKs** - Each SDK may collect data you're not aware of
3. **Update when adding features** - New data collection requires form update
4. **Account deletion** - If you collect user data, provide deletion option

### 7.8 Preview and Submit

1. Review the preview of your Data Safety section
2. Ensure it matches your Privacy Policy
3. Click **Submit**

> **Note:** Data Safety appears on your Play Store listing. Users see this before installing.

---

## 8. Release Tracks

### 8.1 Track Overview

| Track | Purpose | Review | Users |
|-------|---------|--------|-------|
| **Internal** | Team testing | Instant | Up to 100 |
| **Closed** | Selected testers | Instant | Invite-only |
| **Open** | Public beta | Hours | Anyone can join |
| **Production** | Public release | 1-7 days | Everyone |

### 8.2 Recommended Progression

```
Internal → Closed → Open → Production
```

1. **Internal:** Quick sanity checks by team
2. **Closed:** External testers, feedback collection
3. **Open:** Wider beta, performance testing
4. **Production:** Staged rollout (start at 10%)

### 8.3 Staged Rollout

For production releases, use staged rollout:

1. Start at **10%** of users
2. Monitor crash rates and reviews
3. If stable, increase to **50%**
4. Full rollout to **100%**

```
Day 1: 10% → Day 3: 50% → Day 5: 100%
```

### 8.4 Rollback

If issues discovered:
1. **Halt rollout** - Stop expansion
2. **Fix bug** - Prepare hotfix
3. **New release** - Higher version code
4. **Resume rollout** - With fixed version

---

## 9. Deep Links (App Links)

If your app handles deep links, verify Android App Links are configured correctly.

### 9.1 When Needed

Configure App Links if:
- App opens from web links (https://yourapp.com/path)
- Using OAuth redirects back to app
- Marketing campaigns with deep links
- Sharing content links

### 9.2 AndroidManifest Configuration

Add intent-filter to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity android:name=".MainActivity" ...>
    <!-- Deep Links -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="yourapp"/>
    </intent-filter>

    <!-- App Links (verified HTTPS links) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https" android:host="yourapp.com"/>
    </intent-filter>
</activity>
```

### 9.3 Digital Asset Links

For App Links verification, host `assetlinks.json` on your domain:

**Location:** `https://yourapp.com/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.yourcompany.yourapp",
    "sha256_cert_fingerprints": [
      "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
    ]
  }
}]
```

### 9.4 Get SHA-256 Fingerprint

**For debug builds:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

**For release builds:**
```bash
keytool -list -v -keystore /path/to/your.jks -alias your_alias
```

**For Play Store signed builds:**
Play Console > Setup > App signing > SHA-256 certificate fingerprint

### 9.5 Verify Configuration

```bash
# Test deep link opens app
adb shell am start -a android.intent.action.VIEW \
  -d "https://yourapp.com/path" com.yourcompany.yourapp

# Verify assetlinks.json
curl https://yourapp.com/.well-known/assetlinks.json

# Google's verification tool
# https://developers.google.com/digital-asset-links/tools/generator
```

### 9.6 Troubleshooting

**Links open browser instead of app:**
- Check `android:autoVerify="true"` on intent-filter
- Verify `assetlinks.json` is accessible
- Fingerprint must match signing key

**Verification failed:**
- File must be at exact path: `/.well-known/assetlinks.json`
- Content-Type must be `application/json`
- No redirects allowed
- Include all fingerprints (debug, release, Play Store)

---

## Checklist

**Keystore:**
- [ ] Keystore generated with secure password
- [ ] Keystore backed up to secure location
- [ ] key.properties created with correct paths

**Configuration:**
- [ ] key.properties in .gitignore
- [ ] build.gradle.kts updated with signing config
- [ ] proguard-rules.pro created

**Build:**
- [ ] `flutter build appbundle --release` succeeds
- [ ] No ProGuard errors
- [ ] App size reasonable (< 50MB recommended)

**Play Console:**
- [ ] Developer account created
- [ ] App created
- [ ] Store listing complete
- [ ] Content rating completed
- [ ] Privacy policy URL added
- [ ] Bundle uploaded to track

---

## Troubleshooting

### "Keystore was tampered with, or password was incorrect"

- Verify password matches what you set during keystore creation
- Check storeFile path is absolute and correct
- Ensure keystore file wasn't corrupted

### "No key with alias found in keystore"

- Check keyAlias matches alias used during creation
- List aliases: `keytool -list -keystore your.jks`

### Build succeeds but app crashes on release

Usually ProGuard removing needed classes:
1. Build debug to verify app works
2. Check crash logs for class names
3. Add keep rules for affected classes

### "Version code has already been used"

Increment `versionCode` in pubspec.yaml:
```yaml
version: 1.0.1+2  # versionCode is the number after +
```

### Upload rejected: "App signing certificate mismatch"

You're using a different key than previously uploaded. Options:
1. Use original keystore
2. Request key upgrade from Google (limited)
3. Create new app (last resort)
