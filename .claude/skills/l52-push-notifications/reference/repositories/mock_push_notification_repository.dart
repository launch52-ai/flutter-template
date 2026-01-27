// Template: Mock push notification repository for testing
//
// Location: lib/features/notifications/data/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Use in tests and development

import '../../domain/repositories/push_notification_repository.dart';

/// Mock implementation of [PushNotificationRepository] for testing.
///
/// Usage:
/// ```dart
/// final mockRepo = MockPushNotificationRepository();
/// container = ProviderContainer(overrides: [
///   pushNotificationRepositoryProvider.overrideWithValue(mockRepo),
/// ]);
///
/// // Verify interactions
/// await notifier.registerToken('test_token');
/// expect(mockRepo.registerTokenCallCount, 1);
/// expect(mockRepo.lastRegisteredToken, 'test_token');
/// ```
final class MockPushNotificationRepository implements PushNotificationRepository {
  /// Registered tokens (for verification).
  final List<String> registeredTokens = [];

  /// Subscribed topics.
  final Set<String> subscribedTopics = {};

  /// Notification preferences.
  Map<String, bool> preferences = {
    'marketing': true,
    'orders': true,
    'chat': true,
  };

  /// Call count for verification.
  int registerTokenCallCount = 0;
  int unregisterTokenCallCount = 0;

  /// Last registered token.
  String? lastRegisteredToken;

  /// Simulate failures.
  bool shouldFailRegister = false;
  bool shouldFailTopicSubscription = false;

  /// Delay for simulating network latency.
  Duration delay = Duration.zero;

  @override
  Future<void> registerToken(String token) async {
    await Future<void>.delayed(delay);
    registerTokenCallCount++;
    lastRegisteredToken = token;

    if (shouldFailRegister) {
      throw Exception('Mock register failure');
    }

    registeredTokens.add(token);
  }

  @override
  Future<void> unregisterToken() async {
    await Future<void>.delayed(delay);
    unregisterTokenCallCount++;

    if (lastRegisteredToken != null) {
      registeredTokens.remove(lastRegisteredToken);
    }
    lastRegisteredToken = null;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await Future<void>.delayed(delay);

    if (shouldFailTopicSubscription) {
      throw Exception('Mock topic subscription failure');
    }

    subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await Future<void>.delayed(delay);
    subscribedTopics.remove(topic);
  }

  @override
  Future<List<String>> getSubscribedTopics() async {
    await Future<void>.delayed(delay);
    return subscribedTopics.toList();
  }

  @override
  Future<void> updatePreferences(Map<String, bool> newPreferences) async {
    await Future<void>.delayed(delay);
    preferences = {...preferences, ...newPreferences};
  }

  @override
  Future<Map<String, bool>> getPreferences() async {
    await Future<void>.delayed(delay);
    return Map.from(preferences);
  }

  /// Reset mock state for new test.
  void reset() {
    registeredTokens.clear();
    subscribedTopics.clear();
    preferences = {
      'marketing': true,
      'orders': true,
      'chat': true,
    };
    registerTokenCallCount = 0;
    unregisterTokenCallCount = 0;
    lastRegisteredToken = null;
    shouldFailRegister = false;
    shouldFailTopicSubscription = false;
    delay = Duration.zero;
  }
}
