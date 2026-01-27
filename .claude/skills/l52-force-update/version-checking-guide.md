# Version Checking Guide

Complete guide for implementing version checking with Supabase and Firebase Remote Config backends.

## Backend Options

### Option 1: Supabase (Recommended)

Supabase provides a PostgreSQL database with real-time capabilities and a REST API.

#### Database Schema

Create the `app_versions` table:

```sql
-- Create app_versions table
CREATE TABLE app_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  current_version TEXT NOT NULL,           -- Latest available version
  minimum_version TEXT NOT NULL,           -- Minimum for soft update
  force_minimum_version TEXT NOT NULL,     -- Minimum for force update
  store_url TEXT NOT NULL,
  maintenance_mode BOOLEAN DEFAULT FALSE,
  maintenance_message TEXT,
  release_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(platform)
);

-- Insert initial versions
INSERT INTO app_versions (platform, current_version, minimum_version, force_minimum_version, store_url)
VALUES
  ('ios', '1.0.0', '1.0.0', '1.0.0', 'https://apps.apple.com/app/id{YOUR_APP_ID}'),
  ('android', '1.0.0', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id={YOUR_PACKAGE_NAME}');

-- Enable Row Level Security
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Allow public read access (no auth required)
CREATE POLICY "Allow public read" ON app_versions
  FOR SELECT USING (true);

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER app_versions_updated_at
  BEFORE UPDATE ON app_versions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

#### Supabase Query

```dart
final response = await supabase
    .from('app_versions')
    .select()
    .eq('platform', Platform.isIOS ? 'ios' : 'android')
    .single();
```

### Option 2: Firebase Remote Config

Firebase Remote Config allows changing app behavior without publishing updates.

#### Setup Parameters

In Firebase Console > Remote Config, add these parameters:

| Parameter | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| `current_version_ios` | String | `1.0.0` | Latest iOS version |
| `current_version_android` | String | `1.0.0` | Latest Android version |
| `minimum_version_ios` | String | `1.0.0` | Min iOS for soft update |
| `minimum_version_android` | String | `1.0.0` | Min Android for soft update |
| `force_minimum_version_ios` | String | `1.0.0` | Min iOS for force update |
| `force_minimum_version_android` | String | `1.0.0` | Min Android for force update |
| `maintenance_mode` | Boolean | `false` | Enable maintenance screen |
| `maintenance_message` | String | `` | Maintenance message |
| `store_url_ios` | String | (your URL) | iOS App Store URL |
| `store_url_android` | String | (your URL) | Play Store URL |

#### Remote Config Query

```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),
  minimumFetchInterval: const Duration(hours: 1),
));
await remoteConfig.fetchAndActivate();

final platform = Platform.isIOS ? 'ios' : 'android';
final currentVersion = remoteConfig.getString('current_version_$platform');
final minimumVersion = remoteConfig.getString('minimum_version_$platform');
```

## Version Comparison Logic

### Semantic Versioning

Apps use semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)

- **MAJOR:** Breaking changes, new architecture
- **MINOR:** New features, non-breaking changes
- **PATCH:** Bug fixes, small improvements

### Comparison Algorithm

```dart
/// Compares two semantic versions.
/// Returns:
///   - negative if v1 < v2
///   - zero if v1 == v2
///   - positive if v1 > v2
int compareVersions(String v1, String v2) {
  final parts1 = v1.split('.').map(int.parse).toList();
  final parts2 = v2.split('.').map(int.parse).toList();

  // Pad shorter version with zeros
  while (parts1.length < 3) parts1.add(0);
  while (parts2.length < 3) parts2.add(0);

  for (var i = 0; i < 3; i++) {
    if (parts1[i] != parts2[i]) {
      return parts1[i] - parts2[i];
    }
  }
  return 0;
}

/// Check if currentVersion meets minimumVersion requirement.
bool meetsMinimum(String currentVersion, String minimumVersion) {
  return compareVersions(currentVersion, minimumVersion) >= 0;
}
```

### Update Status Logic

```dart
UpdateStatus determineStatus({
  required String currentVersion,
  required String minimumVersion,
  required String forceMinimumVersion,
  required bool maintenanceMode,
}) {
  // Priority 1: Maintenance mode
  if (maintenanceMode) {
    return UpdateStatus.maintenanceMode;
  }

  // Priority 2: Force update check
  if (!meetsMinimum(currentVersion, forceMinimumVersion)) {
    return UpdateStatus.forceUpdateRequired;
  }

  // Priority 3: Soft update check
  if (!meetsMinimum(currentVersion, minimumVersion)) {
    return UpdateStatus.softUpdateAvailable;
  }

  return UpdateStatus.upToDate;
}
```

## Store URLs

### iOS App Store

```dart
// Format: https://apps.apple.com/app/id{APPLE_APP_ID}
const iosStoreUrl = 'https://apps.apple.com/app/id1234567890';

// To find your App ID:
// 1. Go to App Store Connect
// 2. Select your app
// 3. Look for "Apple ID" in App Information
```

### Google Play Store

```dart
// Format: https://play.google.com/store/apps/details?id={PACKAGE_NAME}
const androidStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.app';

// Package name is in android/app/build.gradle:
// namespace = "com.example.app"
```

### Opening Store URLs

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openStore(String storeUrl) async {
  final uri = Uri.parse(storeUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    // Fallback: open in browser
    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  }
}
```

## Error Handling

### Network Failures

Version checks should never block app launch indefinitely:

```dart
Future<VersionInfo> checkVersionSafely() async {
  try {
    return await checkVersion().timeout(
      const Duration(seconds: 5),
      onTimeout: () => VersionInfo.upToDate(),
    );
  } catch (e) {
    // Log error but allow app to continue
    debugPrint('Version check failed: $e');
    return VersionInfo.upToDate();
  }
}
```

### Caching

Cache version info to reduce API calls:

```dart
class VersionCache {
  static const _cacheKey = 'version_info_cache';
  static const _cacheDuration = Duration(hours: 1);

  final SharedPreferences _prefs;

  Future<VersionInfo?> getCached() async {
    final json = _prefs.getString(_cacheKey);
    final timestamp = _prefs.getInt('${_cacheKey}_timestamp');

    if (json == null || timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedAt) > _cacheDuration) {
      return null; // Cache expired
    }

    return VersionInfoDto.fromJson(jsonDecode(json)).toEntity();
  }

  Future<void> cache(VersionInfo info) async {
    await _prefs.setString(_cacheKey, jsonEncode(info.toDto().toJson()));
    await _prefs.setInt('${_cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
}
```

## When to Check Version

### 1. App Startup

Check immediately after splash screen:

```dart
// In your app initialization
Future<void> _initializeApp() async {
  // ... other initialization

  final versionInfo = await ref.read(versionServiceProvider).checkVersionSafely();
  ref.read(updateNotifierProvider.notifier).setVersionInfo(versionInfo);
}
```

### 2. Foreground Resume

Check when app returns from background:

```dart
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(versionServiceProvider).checkVersionSafely().then((info) {
        ref.read(updateNotifierProvider.notifier).setVersionInfo(info);
      });
    }
  }
}
```

### 3. Periodic Check (Long Sessions)

For apps with long sessions (e.g., games):

```dart
// Check every 4 hours while app is open
Timer.periodic(const Duration(hours: 4), (_) {
  ref.read(versionServiceProvider).checkVersionSafely().then((info) {
    ref.read(updateNotifierProvider.notifier).setVersionInfo(info);
  });
});
```

## Testing

### Local Testing

Override version for testing without deploying:

```dart
// In your debug/dev environment config
class MockVersionService implements VersionService {
  @override
  Future<VersionInfo> checkVersion() async {
    // Simulate different scenarios
    return VersionInfo(
      currentVersion: '2.0.0',
      minimumVersion: '1.5.0',
      forceMinimumVersion: '1.0.0',
      storeUrl: 'https://example.com',
      maintenanceMode: false,
      status: UpdateStatus.softUpdateAvailable,
    );
  }
}
```

### Testing Checklist

- [ ] Test force update with outdated version
- [ ] Test soft update with slightly outdated version
- [ ] Test up-to-date scenario
- [ ] Test maintenance mode
- [ ] Test network failure handling
- [ ] Test store URL opens correctly on both platforms
- [ ] Test timeout behavior
