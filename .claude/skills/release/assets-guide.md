# App Assets Guide

Complete guide for creating app icons and splash screens for iOS and Android.

---

## Overview

| Asset | Source Size | Purpose |
|-------|-------------|---------|
| **App Icon** | 1024x1024 px | Home screen, app stores |
| **Splash Screen** | Varies | Launch screen |
| **Store Assets** | Various | App Store / Play Store listing |

---

## 1. App Icon

### 1.1 Design Requirements

| Platform | Requirements |
|----------|-------------|
| **iOS** | No transparency, no alpha channel |
| **Android** | Can have transparency for adaptive icons |
| **Both** | Square, no rounded corners (system applies) |

### 1.2 Source Icon

Create a single **1024x1024 PNG** file:
- No transparency for iOS compatibility
- Keep important content in center (adaptive icon safe zone)
- Use simple, recognizable design
- Avoid text (hard to read at small sizes)

Save to: `assets/icons/app_icon.png`

### 1.3 iOS Icon Setup

**Option A: Using Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** > **Assets.xcassets** > **AppIcon**
3. In Attributes Inspector, set iOS to **Single Size (iOS 18)**
4. Drag your 1024x1024 icon to the AppIcon set

**Note:** As of iOS 18, Apple requires only a single 1024x1024 icon and generates all sizes automatically.

**Option B: Manual (Legacy)**

If supporting older Xcode or needing specific sizes:

| Size | Scale | Dimensions | Usage |
|------|-------|------------|-------|
| 20pt | @2x | 40x40 | Notification |
| 20pt | @3x | 60x60 | Notification |
| 29pt | @2x | 58x58 | Settings |
| 29pt | @3x | 87x87 | Settings |
| 40pt | @2x | 80x80 | Spotlight |
| 40pt | @3x | 120x120 | Spotlight |
| 60pt | @2x | 120x120 | App |
| 60pt | @3x | 180x180 | App |
| 1024pt | @1x | 1024x1024 | App Store |

### 1.4 Android Icon Setup

**Using Android Studio (Recommended)**

1. Open `android/` folder in Android Studio
2. **Wait for Gradle sync** (important - project structure won't load correctly without it)
3. Right-click `app/src/main/res` > **New** > **Image Asset**
4. Configure:
   - **Icon Type:** Launcher Icons (Adaptive and Legacy)
   - **Source Asset:** Select your 1024x1024 icon
   - **Background:** Color or image for adaptive icon
   - **Scaling:** Resize as needed to fit safe zone
5. Click **Next** > **Finish**

**Generated Files:**

```
android/app/src/main/res/
├── mipmap-hdpi/
│   ├── ic_launcher.webp
│   └── ic_launcher_round.webp
├── mipmap-mdpi/
│   ├── ic_launcher.webp
│   └── ic_launcher_round.webp
├── mipmap-xhdpi/
│   ├── ic_launcher.webp
│   └── ic_launcher_round.webp
├── mipmap-xxhdpi/
│   ├── ic_launcher.webp
│   └── ic_launcher_round.webp
├── mipmap-xxxhdpi/
│   ├── ic_launcher.webp
│   └── ic_launcher_round.webp
└── mipmap-anydpi-v26/
    ├── ic_launcher.xml        # Adaptive icon
    └── ic_launcher_round.xml  # Round adaptive icon
```

### 1.5 Adaptive Icons (Android)

Android 8.0+ uses adaptive icons with foreground/background layers:

```xml
<!-- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

**Safe Zone:** Keep important content within inner 66% circle to avoid clipping.

### 1.6 Monochrome Icons (Android 13+)

Android 13 introduced themed icons that match the user's wallpaper colors.

**Requirements:**
- Single-color icon (vector or PNG)
- Transparent background
- White/light foreground (system applies color)

**Using Android Studio:**

1. Right-click `res` > **New** > **Image Asset**
2. Select **Launcher Icons (Adaptive and Legacy)**
3. In **Foreground Layer**, choose your icon
4. Check **Enable monochrome icon**
5. Provide monochrome version of your icon

**Generated file:**
```
android/app/src/main/res/
└── mipmap-anydpi-v26/
    └── ic_launcher.xml    # Contains monochrome reference
```

**Adaptive icon with monochrome:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
```

### 1.7 Tintable Icons (iOS 18+)

iOS 18 introduced icon tinting to match user preferences.

**Automatic:** If your icon is a simple shape on solid background, iOS automatically creates tinted version.

**For complex icons:** Provide a separate template image:

1. Open `ios/Runner.xcworkspace`
2. Select **Assets.xcassets** > **AppIcon**
3. Add alternate appearances in **Attributes Inspector**
4. Provide dark mode and tinted variants

### 1.8 Using flutter_launcher_icons (Alternative)

Instead of Android Studio, use `flutter_launcher_icons` package:

**Add to pubspec.yaml:**

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"

  # Android adaptive icon
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  adaptive_icon_monochrome: "assets/icons/app_icon_monochrome.png"

  # iOS settings
  remove_alpha_ios: true

  # Web (if using Flutter web)
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
```

**Generate icons:**
```bash
dart run flutter_launcher_icons
```

**Advantages:**
- Single command generates all sizes
- Consistent across platforms
- Easy to update
- Version controlled configuration

**Disadvantages:**
- Less control over individual icon variants
- May need manual adjustment for complex icons
- Android Studio preview more accurate

---

## 2. Splash Screen

### 2.1 Using flutter_native_splash (Recommended)

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.5

flutter_native_splash:
  color: "#ffffff"                    # Background color
  image: assets/splash/splash_logo.png # Center image

  # Android 12+ specific
  android_12:
    color: "#ffffff"
    image: assets/splash/splash_logo.png

  # iOS specific (optional)
  ios: true

  # Dark mode (optional)
  color_dark: "#1a1a1a"
  image_dark: assets/splash/splash_logo_dark.png
  android_12:
    color_dark: "#1a1a1a"
    image_dark: assets/splash/splash_logo_dark.png
```

### 2.2 Create Splash Assets

Save splash image to `assets/splash/splash_logo.png`:

| Recommendation | Value |
|----------------|-------|
| **Format** | PNG with transparency |
| **Size** | 384x384 px (center logo) |
| **Background** | Transparent (color set in pubspec) |

### 2.3 Generate Splash Screen

```bash
dart run flutter_native_splash:create
```

This updates:
- `android/app/src/main/res/drawable/` - Android splash
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` - iOS splash
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` - iOS storyboard

### 2.4 Remove Splash Screen (Optional)

To revert to default:

```bash
dart run flutter_native_splash:remove
```

### 2.5 Android 12+ Considerations

Android 12 introduced new splash screen API with specific requirements:

| Element | Specification |
|---------|---------------|
| **Icon** | Must be 288dp circle (may clip to circle) |
| **Background** | Single color only |
| **Duration** | System controlled |

The `android_12` section in pubspec handles this automatically.

---

## 3. Store Assets

### 3.1 App Store (iOS) - Updated 2025

| Asset | Size | Required |
|-------|------|----------|
| **App Icon** | 1024x1024 | Yes |
| **iPhone 6.9"** | 1290x2796 | **Yes** |
| iPhone 6.5" | 1284x2778 | Only if no 6.9" |
| iPhone 5.5", 6.1", etc. | Various | No - auto-scaled |
| **iPad 13"** | 2064x2752 | If iPad |
| iPad 12.9", 11" | Various | No - auto-scaled |
| **App Preview** | 1920x1080 | No |

> **Simplified:** Provide **one iPhone screenshot** (6.9") and **one iPad screenshot** (13" if supporting iPad). Apple auto-scales for other device sizes.

### 3.2 Play Store (Android)

| Asset | Size | Required |
|-------|------|----------|
| **App Icon** | 512x512 | Yes |
| **Feature Graphic** | 1024x500 | Yes |
| **Phone Screenshots** | Min 2, 320-3840px wide | Yes |
| **Tablet Screenshots** | 7" and 10" | If tablet |
| **Promo Video** | YouTube URL | No |

### 3.3 Screenshot Recommendations

**Content:**
- Show key features
- Include real (not placeholder) content
- Add device frames (optional)
- Include text overlays explaining features

**Workflow:**
1. Run app on simulator/emulator
2. Take screenshots of key screens
3. Add to marketing materials (Figma, Sketch)
4. Export at required sizes

**Tools:**
- **Screenshots.pro** - Device frames
- **AppMockUp** - Marketing templates
- **LaunchKit** - Automated screenshots

---

## 4. Favicon and Web Icons (If Using Flutter Web)

Add to `web/manifest.json`:

```json
{
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

---

## 5. Asset Organization

Recommended folder structure:

```
assets/
├── icons/
│   └── app_icon.png           # 1024x1024 source icon
│
├── splash/
│   ├── splash_logo.png        # Light mode splash
│   └── splash_logo_dark.png   # Dark mode splash (optional)
│
└── store/
    ├── feature_graphic.png    # 1024x500 Play Store
    ├── screenshots/
    │   ├── phone/
    │   │   ├── screen_1.png
    │   │   └── screen_2.png
    │   └── tablet/
    │       └── screen_1.png
    └── promo/
        └── app_preview.mp4    # Optional video
```

---

## Checklist

**App Icon:**
- [ ] 1024x1024 PNG created
- [ ] No transparency (for iOS)
- [ ] Important content in center 66% (for adaptive icons)
- [ ] iOS AppIcon configured in Xcode
- [ ] Android launcher icons generated

**Splash Screen:**
- [ ] Splash logo image created
- [ ] flutter_native_splash configured in pubspec.yaml
- [ ] Generated: `dart run flutter_native_splash:create`
- [ ] Tested on both platforms

**Store Assets:**
- [ ] 512x512 icon for Play Store
- [ ] 1024x500 feature graphic for Play Store
- [ ] Screenshots for all required sizes
- [ ] (Optional) App preview video

---

## Troubleshooting

### Icons not updating

```bash
flutter clean
flutter pub get
flutter run
```

For iOS, also:
1. Delete app from simulator/device
2. Clean build folder in Xcode (Shift+Cmd+K)

### Splash screen not appearing

1. Verify assets path in pubspec.yaml is correct
2. Re-run: `dart run flutter_native_splash:create`
3. For Android 12+, check `android_12` section

### Android adaptive icon clipping

- Keep logo within inner 66% circle
- Use Android Studio's Image Asset tool preview
- Test on multiple launchers

### iOS icon shows white corners

- Ensure image has no transparency
- Remove alpha channel from PNG
- Re-add to Xcode Assets

### Store rejects icon

Common issues:
- Alpha channel present (iOS)
- Wrong dimensions
- Corrupt file

Solution: Re-export from design tool with correct settings.
