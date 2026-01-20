# Android Flavors Guide

Configuring Android product flavors for Flutter apps with Gradle.

## Overview

Android uses Gradle's `productFlavors` to create different app variants. Each flavor can have:

- Different application ID (bundle ID)
- Different app name
- Different resources (icons, colors)
- Different signing configuration
- Different Firebase config

## Gradle Configuration

### Basic Setup

Update `android/app/build.gradle`:

```groovy
android {
    // ... existing config

    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "My App (Dev)"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "My App (Staging)"
        }
        prod {
            dimension "environment"
            // No suffix for production
            resValue "string", "app_name", "My App"
        }
    }
}
```

### Update AndroidManifest.xml

Replace hardcoded app name with resource reference:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:label="@string/app_name"
    ...>
```

### Full build.gradle Example

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.myapp"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.myapp"
        minSdk flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "My App (Dev)"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "My App (Staging)"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "My App"
        }
    }

    signingConfigs {
        release {
            // Configure from environment variables or local.properties
            // See /release skill for signing setup
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

flutter {
    source '../..'
}

dependencies {}
```

## Firebase Per Flavor

When using separate Firebase projects per environment:

### Directory Structure

```
android/app/
├── src/
│   ├── dev/
│   │   └── google-services.json    # Dev Firebase project
│   ├── staging/
│   │   └── google-services.json    # Staging Firebase project
│   ├── prod/
│   │   └── google-services.json    # Production Firebase project
│   └── main/
│       └── AndroidManifest.xml
└── build.gradle
```

### Get Firebase Config Files

1. Go to Firebase Console → Project Settings → Your apps
2. Download `google-services.json` for each project
3. Place in the appropriate `src/{flavor}/` directory

Gradle automatically picks the correct file based on the build flavor.

## Signing Per Flavor

### Key Files Structure

```
android/
├── keystores/
│   ├── dev.keystore       # Dev signing key (can be debug key)
│   ├── staging.keystore   # Staging signing key
│   └── prod.keystore      # Production signing key
└── app/
    └── build.gradle
```

### Configure Signing

```groovy
android {
    signingConfigs {
        dev {
            storeFile file('../keystores/dev.keystore')
            storePassword System.getenv('DEV_KEYSTORE_PASSWORD') ?: 'android'
            keyAlias 'dev'
            keyPassword System.getenv('DEV_KEY_PASSWORD') ?: 'android'
        }
        staging {
            storeFile file('../keystores/staging.keystore')
            storePassword System.getenv('STAGING_KEYSTORE_PASSWORD')
            keyAlias 'staging'
            keyPassword System.getenv('STAGING_KEY_PASSWORD')
        }
        prod {
            storeFile file('../keystores/prod.keystore')
            storePassword System.getenv('PROD_KEYSTORE_PASSWORD')
            keyAlias 'prod'
            keyPassword System.getenv('PROD_KEY_PASSWORD')
        }
    }

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            resValue "string", "app_name", "My App (Dev)"
            signingConfig signingConfigs.dev
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            resValue "string", "app_name", "My App (Staging)"
            signingConfig signingConfigs.staging
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "My App"
            signingConfig signingConfigs.prod
        }
    }

    buildTypes {
        debug {
            // Use flavor-specific signing in debug too
        }
        release {
            // Flavor signing config takes precedence
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

## Flavor-Specific Resources

### Different App Icons

```
android/app/src/
├── dev/res/
│   ├── mipmap-hdpi/ic_launcher.png
│   ├── mipmap-mdpi/ic_launcher.png
│   ├── mipmap-xhdpi/ic_launcher.png
│   ├── mipmap-xxhdpi/ic_launcher.png
│   └── mipmap-xxxhdpi/ic_launcher.png
├── staging/res/
│   └── mipmap-*/ic_launcher.png
├── prod/res/
│   └── mipmap-*/ic_launcher.png
└── main/res/
    └── (shared resources)
```

### Different Colors/Themes

```
android/app/src/dev/res/values/colors.xml
android/app/src/staging/res/values/colors.xml
android/app/src/prod/res/values/colors.xml
```

## Build Commands

### Debug Builds

```bash
# Dev flavor, debug build
flutter run --flavor dev --dart-define-from-file=.env.dev

# Staging flavor, debug build
flutter run --flavor staging --dart-define-from-file=.env.staging

# Prod flavor, debug build
flutter run --flavor prod --dart-define-from-file=.env.prod
```

### Release Builds

```bash
# APK
flutter build apk --flavor prod --dart-define-from-file=.env.prod

# App Bundle (for Play Store)
flutter build appbundle --flavor prod --dart-define-from-file=.env.prod
```

### Build Outputs

Build outputs are in flavor-specific directories:

```
build/app/outputs/
├── flutter-apk/
│   ├── app-dev-debug.apk
│   ├── app-dev-release.apk
│   ├── app-staging-debug.apk
│   ├── app-staging-release.apk
│   ├── app-prod-debug.apk
│   └── app-prod-release.apk
└── bundle/
    ├── devRelease/app-dev-release.aab
    ├── stagingRelease/app-staging-release.aab
    └── prodRelease/app-prod-release.aab
```

## Troubleshooting

### "Flavor not found"

Ensure flavor name in command matches exactly:

```bash
# Correct
flutter run --flavor dev

# Wrong
flutter run --flavor Dev
flutter run --flavor development
```

### Gradle Sync Issues

```bash
cd android
./gradlew clean
./gradlew --stop
cd ..
flutter clean
flutter pub get
```

### Missing google-services.json

Error: `File google-services.json is missing`

Ensure:
1. File exists at `android/app/src/{flavor}/google-services.json`
2. Flavor name matches directory name exactly

### Version Code Conflicts

If deploying multiple flavors to Play Store, use different version codes:

```groovy
productFlavors {
    dev {
        versionCode 10000 + flutterVersionCode.toInteger()
    }
    staging {
        versionCode 20000 + flutterVersionCode.toInteger()
    }
    prod {
        versionCode flutterVersionCode.toInteger()
    }
}
```

## CI/CD Integration

In GitHub Actions:

```yaml
- name: Build Android (Prod)
  run: flutter build appbundle --flavor prod --dart-define-from-file=.env.prod

- name: Build Android (Dev)
  run: flutter build apk --flavor dev --dart-define-from-file=.env.dev
```

See `/ci-cd` skill for complete workflow templates.
