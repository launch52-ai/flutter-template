// Template: Push notification repository interface
//
// Location: lib/features/notifications/domain/repositories/
//
// Usage:
// 1. Copy to target location
// 2. Implement in data layer

/// Repository interface for push notification operations.
///
/// Handles token management and backend communication.
/// Implement in data layer with actual backend integration.
abstract interface class PushNotificationRepository {
  /// Register FCM token with backend.
  ///
  /// Called when:
  /// - User logs in
  /// - Token refreshes
  /// - App launches with logged-in user
  ///
  /// Throws [TokenRegistrationFailure] on backend error.
  /// Throws [NotificationNetworkFailure] on network error.
  Future<void> registerToken(String token);

  /// Unregister FCM token from backend.
  ///
  /// Called when user logs out.
  /// Should remove token from backend to stop receiving notifications.
  Future<void> unregisterToken();

  /// Subscribe to a notification topic.
  ///
  /// Topics allow broadcasting to user segments without individual tokens.
  /// Common topics: "promotions", "news", "all_users".
  ///
  /// Throws [TopicSubscriptionFailure] on error.
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a notification topic.
  Future<void> unsubscribeFromTopic(String topic);

  /// Get list of subscribed topics.
  ///
  /// Returns cached list from local storage.
  Future<List<String>> getSubscribedTopics();

  /// Update notification preferences on backend.
  ///
  /// [preferences] is a map of category to enabled state.
  /// Example: {'marketing': true, 'orders': true, 'chat': false}
  Future<void> updatePreferences(Map<String, bool> preferences);

  /// Get notification preferences from backend.
  Future<Map<String, bool>> getPreferences();
}
