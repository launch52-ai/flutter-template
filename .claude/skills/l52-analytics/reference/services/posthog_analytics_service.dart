// Template: PostHog analytics implementation
//
// Location: lib/core/services/posthog_analytics_service.dart
//
// Dependencies:
//   posthog_flutter: ^4.0.0
//
// Usage:
// 1. Copy to target location
// 2. Configure PostHog in main.dart
// 3. Use this service for analytics

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'error_tracking_service.dart';

/// PostHog implementation of [ProductAnalyticsService].
///
/// PostHog advantages over Firebase Analytics:
/// - Self-hostable (data ownership)
/// - Better product analytics (funnels, retention)
/// - Session recordings
/// - Feature flags built-in
/// - No sampling on free tier
final class PostHogAnalyticsService implements ProductAnalyticsService {
  PostHogAnalyticsService._();

  static final instance = PostHogAnalyticsService._();

  bool _enabled = true;

  @override
  Future<void> initialize() async {
    // PostHog initialization happens via PostHogConfig in main.dart
    _enabled = !kDebugMode;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_enabled) return;

    await Posthog().capture(
      eventName: name,
      properties: parameters,
    );
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;

    await Posthog().screen(
      screenName: screenName,
      properties: screenClass != null ? {'screen_class': screenClass} : null,
    );
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (value == null) return;

    // PostHog uses $set for user properties
    await Posthog().capture(
      eventName: r'$set',
      properties: {name: value},
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (userId != null) {
      await Posthog().identify(userId: userId);
    } else {
      await Posthog().reset();
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      await Posthog().disable();
    } else {
      await Posthog().enable();
    }
  }

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> reset() async {
    await Posthog().reset();
  }

  // PostHog-specific methods

  /// Check if a feature flag is enabled.
  Future<bool> isFeatureEnabled(String flagKey) async {
    return await Posthog().isFeatureEnabled(flagKey);
  }

  /// Get feature flag value.
  Future<dynamic> getFeatureFlagValue(String flagKey) async {
    return await Posthog().getFeatureFlag(flagKey);
  }

  /// Reload feature flags.
  Future<void> reloadFeatureFlags() async {
    await Posthog().reloadFeatureFlags();
  }

  /// Identify user with additional properties.
  Future<void> identifyWithProperties(
    String userId,
    Map<String, Object> properties,
  ) async {
    await Posthog().identify(
      userId: userId,
      userProperties: properties,
    );
  }

  /// Create an alias (link anonymous ID to user ID).
  Future<void> alias(String alias) async {
    await Posthog().alias(alias: alias);
  }

  /// Track a group.
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, Object>? groupProperties,
  }) async {
    await Posthog().group(
      groupType: groupType,
      groupKey: groupKey,
      groupProperties: groupProperties,
    );
  }
}
