# Test Patterns Guide

Detailed patterns and helpers for writing maintainable Flutter tests.

> **Reference:** Patterns adapted from [Essential Feed Case Study](https://github.com/essentialdevelopercom/essential-feed-case-study).

---

## 1. Test File Structure

Every test file should follow this structure:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import the class under test
import 'package:your_app/features/auth/data/repositories/auth_repository_impl.dart';

// Import helpers
import '../../../../../helpers/test_helpers.dart';
import '../../../../../helpers/mocks.dart';

void main() {
  // 1. Declare SUT and dependencies
  late AuthRepositoryImpl sut;
  late MockGoTrueClient mockAuth;
  late MockSecureStorageService mockStorage;

  // 2. Factory function for SUT
  AuthRepositoryImpl makeSUT() {
    return AuthRepositoryImpl(mockAuth, mockStorage);
  }

  // 3. Setup fresh instances before each test
  setUp(() {
    mockAuth = MockGoTrueClient();
    mockStorage = MockSecureStorageService();
    sut = makeSUT();
  });

  // 4. Register fallback values once
  setUpAll(() {
    registerFallbackValues();
  });

  // 5. Group related tests
  group('signIn', () {
    test('withValidCredentials_returnsAuthResult', () async {
      // Test implementation
    });

    test('withInvalidCredentials_throwsAuthFailure', () async {
      // Test implementation
    });
  });

  group('signOut', () {
    test('whenAuthenticated_clearsStorage', () async {
      // Test implementation
    });
  });
}
```

---

## 2. The makeSUT() Pattern

**Purpose:** Centralize SUT creation for consistency and easy refactoring.

### Basic makeSUT

```dart
AuthRepositoryImpl makeSUT({
  MockGoTrueClient? auth,
  MockSecureStorageService? storage,
}) {
  return AuthRepositoryImpl(
    auth ?? mockAuth,
    storage ?? mockStorage,
  );
}
```

### With Automatic Cleanup

```dart
AuthRepositoryImpl makeSUT({
  GoTrueClient? auth,
  SecureStorageService? storage,
}) {
  final sut = AuthRepositoryImpl(
    auth ?? mockAuth,
    storage ?? mockStorage,
  );

  // Ensure cleanup after test
  addTearDown(() {
    // Dispose resources if needed (streams, controllers)
  });

  return sut;
}
```

### Usage

```dart
test('signIn_withValidCredentials_succeeds', () async {
  final sut = makeSUT();
  // ... test
});

test('signIn_withCustomStorage_succeeds', () async {
  final customStorage = FailingStorageStub();
  final sut = makeSUT(storage: customStorage);
  // ... test
});
```

---

## 3. Test Data Factories (any*())

**Purpose:** Provide consistent, meaningful test data without hardcoding values.

### test_helpers.dart

```dart
/// Test data factory functions.
/// Reduces boilerplate and ensures consistent test data.

// ============================================================
// PRIMITIVES
// ============================================================

// URLs
Uri anyUri() => Uri.parse('https://example.com');
String anyUrl() => 'https://example.com';

// Errors
Exception anyException() => Exception('any error');
String anyErrorMessage() => 'any error message';

// IDs
String anyId() => 'any-id-123';
String anyUserId() => 'user-123';
String anyEmail() => 'test@example.com';
String anyPassword() => 'password123';
String anyToken() => 'token-abc-123';
String anyRefreshToken() => 'refresh-token-xyz-789';

// Timestamps
DateTime anyTimestamp() => DateTime(2024, 1, 1, 12, 0, 0);
DateTime futureTimestamp() => DateTime.now().add(const Duration(days: 1));
DateTime pastTimestamp() => DateTime.now().subtract(const Duration(days: 1));

// ============================================================
// DOMAIN MODELS
// ============================================================

UserProfile anyUserProfile({
  String? id,
  String? email,
  String? name,
  DateTime? createdAt,
}) => UserProfile(
  id: id ?? anyUserId(),
  email: email ?? anyEmail(),
  name: name ?? 'Test User',
  createdAt: createdAt ?? anyTimestamp(),
);

AuthResult anyAuthResult({
  UserProfile? user,
  bool isNewUser = false,
}) => AuthResult(
  user: user ?? anyUserProfile(),
  isNewUser: isNewUser,
);

// ============================================================
// SUPABASE RESPONSES
// ============================================================

AuthResponse anyAuthResponse({
  User? user,
  Session? session,
}) => AuthResponse(
  session: session ?? anySession(),
  user: user ?? anySupabaseUser(),
);

Session anySession({
  String? accessToken,
  String? refreshToken,
}) => Session(
  accessToken: accessToken ?? anyToken(),
  refreshToken: refreshToken ?? anyRefreshToken(),
  tokenType: 'bearer',
  expiresIn: 3600,
  expiresAt: futureTimestamp().millisecondsSinceEpoch ~/ 1000,
  user: anySupabaseUser(),
);

User anySupabaseUser({
  String? id,
  String? email,
}) => User(
  id: id ?? anyUserId(),
  email: email ?? anyEmail(),
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: anyTimestamp().toIso8601String(),
);

// ============================================================
// JSON HELPERS
// ============================================================

Map<String, dynamic> makeUserJson({
  String? id,
  String? email,
  String? name,
}) => {
  'id': id ?? anyUserId(),
  'email': email ?? anyEmail(),
  'name': name ?? 'Test User',
  'created_at': anyTimestamp().toIso8601String(),
};

// ============================================================
// UNIQUE VALUES
// ============================================================

/// For tests that need unique values each call
String uniqueId() => 'id-${DateTime.now().microsecondsSinceEpoch}';
String uniqueEmail() => 'test-${DateTime.now().microsecondsSinceEpoch}@example.com';
```

---

## 4. Mock Classes

**Purpose:** Control return values and stub behavior.

### mocks.dart

```dart
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// REPOSITORY MOCKS
// ============================================================

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockSettingsRepository extends Mock implements SettingsRepository {}

// ============================================================
// SERVICE MOCKS
// ============================================================

class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockSharedPrefsService extends Mock implements SharedPrefsService {}
class MockSupabaseService extends Mock implements SupabaseService {}

// ============================================================
// SUPABASE MOCKS
// ============================================================

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockPostgrestClient extends Mock implements PostgrestClient {}

// ============================================================
// NETWORK MOCKS
// ============================================================

class MockDio extends Mock implements Dio {}
class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

// ============================================================
// FLUTTER MOCKS
// ============================================================

class MockBuildContext extends Mock implements BuildContext {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// ============================================================
// FALLBACK VALUES
// ============================================================

/// Call in setUpAll() to register fallback values for mocktail.
void registerFallbackValues() {
  registerFallbackValue(Uri());
  registerFallbackValue(anyUserProfile());
  registerFallbackValue(const AuthState.initial());
  registerFallbackValue(Options());
  registerFallbackValue(RequestOptions(path: ''));
}
```

---

## 5. Spy Pattern

**Purpose:** Verify HOW methods were called, with what arguments, in what order.

### spy_implementations.dart

```dart
/// Spy implementation that tracks method calls.
/// Use when you need to verify method calls and their arguments.

// ============================================================
// AUTH REPOSITORY SPY
// ============================================================

final class AuthRepositorySpy implements AuthRepository {
  final List<AuthRepositoryMessage> receivedMessages = [];

  // Control results
  AuthResult? signInResult;
  Exception? signInError;
  bool isAuthenticatedResult = false;
  UserProfile? currentUserResult;

  // ============================================================
  // INTERFACE IMPLEMENTATIONS
  // ============================================================

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    receivedMessages.add(AuthRepositoryMessage.signInWithEmail(email, password));
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    receivedMessages.add(const AuthRepositoryMessage.signInWithGoogle());
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<AuthResult> signInWithApple() async {
    receivedMessages.add(const AuthRepositoryMessage.signInWithApple());
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<bool> isAuthenticated() async {
    receivedMessages.add(const AuthRepositoryMessage.isAuthenticated());
    return isAuthenticatedResult;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    receivedMessages.add(const AuthRepositoryMessage.getCurrentUser());
    return currentUserResult;
  }

  @override
  Future<void> signOut() async {
    receivedMessages.add(const AuthRepositoryMessage.signOut());
  }

  // ============================================================
  // COMPLETION HELPERS
  // ============================================================

  void completeSignIn(AuthResult result) {
    signInResult = result;
    signInError = null;
  }

  void failSignIn(Exception error) {
    signInError = error;
    signInResult = null;
  }

  void completeIsAuthenticated(bool value) {
    isAuthenticatedResult = value;
  }

  void completeGetCurrentUser(UserProfile? user) {
    currentUserResult = user;
  }

  // ============================================================
  // VERIFICATION HELPERS
  // ============================================================

  int get signInCallCount => receivedMessages
      .whereType<SignInWithEmailMessage>()
      .length;

  bool get didCallSignOut => receivedMessages
      .any((m) => m is SignOutMessage);

  void reset() => receivedMessages.clear();
}

// ============================================================
// MESSAGE TYPES
// ============================================================

sealed class AuthRepositoryMessage {
  const AuthRepositoryMessage();

  const factory AuthRepositoryMessage.signInWithEmail(
    String email,
    String password,
  ) = SignInWithEmailMessage;

  const factory AuthRepositoryMessage.signInWithGoogle() = SignInWithGoogleMessage;
  const factory AuthRepositoryMessage.signInWithApple() = SignInWithAppleMessage;
  const factory AuthRepositoryMessage.isAuthenticated() = IsAuthenticatedMessage;
  const factory AuthRepositoryMessage.getCurrentUser() = GetCurrentUserMessage;
  const factory AuthRepositoryMessage.signOut() = SignOutMessage;
}

final class SignInWithEmailMessage extends AuthRepositoryMessage {
  final String email;
  final String password;
  const SignInWithEmailMessage(this.email, this.password);

  @override
  bool operator ==(Object other) =>
      other is SignInWithEmailMessage &&
      other.email == email &&
      other.password == password;

  @override
  int get hashCode => Object.hash(email, password);

  @override
  String toString() => 'signInWithEmail(email: $email, password: $password)';
}

final class SignInWithGoogleMessage extends AuthRepositoryMessage {
  const SignInWithGoogleMessage();
}

final class SignInWithAppleMessage extends AuthRepositoryMessage {
  const SignInWithAppleMessage();
}

final class IsAuthenticatedMessage extends AuthRepositoryMessage {
  const IsAuthenticatedMessage();
}

final class GetCurrentUserMessage extends AuthRepositoryMessage {
  const GetCurrentUserMessage();
}

final class SignOutMessage extends AuthRepositoryMessage {
  const SignOutMessage();
}
```

### Using Spies

```dart
test('signIn_withValidCredentials_callsRepositoryOnce', () async {
  // Arrange
  final authSpy = AuthRepositorySpy();
  authSpy.completeSignIn(anyAuthResult());

  final container = makeProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(authSpy)],
  );

  // Act
  await container.read(authNotifierProvider.notifier).signInWithEmail(
    anyEmail(),
    anyPassword(),
  );

  // Assert
  expect(authSpy.receivedMessages, [
    AuthRepositoryMessage.signInWithEmail(anyEmail(), anyPassword()),
  ]);
});

test('signOut_callsRepositorySignOut', () async {
  // Arrange
  final authSpy = AuthRepositorySpy();

  // Act
  await sut.signOut();

  // Assert
  expect(authSpy.didCallSignOut, isTrue);
});
```

---

## 6. Riverpod Testing Helpers

### riverpod_helpers.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// PROVIDER CONTAINER
// ============================================================

/// Creates a ProviderContainer with overrides for testing.
/// Automatically disposes after test.
ProviderContainer makeProviderContainer({
  List<Override> overrides = const [],
  ProviderContainer? parent,
}) {
  final container = ProviderContainer(
    overrides: overrides,
    parent: parent,
  );
  addTearDown(container.dispose);
  return container;
}

// ============================================================
// STATE LISTENER
// ============================================================

/// Tracks provider state changes for assertions.
class ProviderListener<T> {
  final List<T> states = [];

  void call(T? previous, T next) {
    states.add(next);
  }

  void reset() => states.clear();

  /// Get the last emitted state
  T get last => states.last;

  /// Check if a specific state was emitted
  bool hasState(T state) => states.contains(state);

  /// Get states of a specific type
  List<S> statesOfType<S extends T>() =>
      states.whereType<S>().toList();
}

// ============================================================
// ASYNC VALUE MATCHERS
// ============================================================

/// Extension for testing async providers.
extension AsyncValueMatchers<T> on AsyncValue<T> {
  void expectData(T expected) {
    expect(this, isA<AsyncData<T>>());
    expect((this as AsyncData<T>).value, expected);
  }

  void expectLoading() {
    expect(isLoading, isTrue);
  }

  void expectError([Object? error]) {
    expect(this, isA<AsyncError<T>>());
    if (error != null) {
      expect((this as AsyncError<T>).error, error);
    }
  }

  T? get valueOrNull {
    return whenData((data) => data).value;
  }
}

// ============================================================
// NOTIFIER TESTING
// ============================================================

/// Creates an override for a Notifier provider.
/// Useful when you need to control the notifier directly.
Override overrideNotifier<N extends Notifier<S>, S>(
  NotifierProvider<N, S> provider,
  N Function() create,
) {
  return provider.overrideWith(create);
}

/// Creates an override for an AsyncNotifier provider.
Override overrideAsyncNotifier<N extends AsyncNotifier<S>, S>(
  AsyncNotifierProvider<N, S> provider,
  N Function() create,
) {
  return provider.overrideWith(create);
}

// ============================================================
// COMMON PROVIDER PATTERNS
// ============================================================

/// Helper to test provider state after action
Future<S> readStateAfterAction<N extends Notifier<S>, S>({
  required ProviderContainer container,
  required NotifierProvider<N, S> provider,
  required Future<void> Function(N notifier) action,
}) async {
  final notifier = container.read(provider.notifier);
  await action(notifier);
  return container.read(provider);
}
```

### Example: Testing AsyncNotifier

```dart
void main() {
  late ProviderContainer container;
  late AuthRepositorySpy authSpy;

  setUp(() {
    authSpy = AuthRepositorySpy();
    container = makeProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authSpy),
      ],
    );
  });

  test('authNotifier_signIn_emitsCorrectStateTransitions', () async {
    // Arrange
    final listener = ProviderListener<AuthState>();
    container.listen(authNotifierProvider, listener.call, fireImmediately: true);
    authSpy.completeSignIn(anyAuthResult());

    // Act
    await container.read(authNotifierProvider.notifier).signInWithEmail(
      anyEmail(),
      anyPassword(),
    );

    // Assert
    expect(listener.states, [
      const AuthState.initial(),
      const AuthState.loading(),
      isA<AuthStateAuthenticated>(),
    ]);
  });

  test('authNotifier_signIn_onError_emitsErrorState', () async {
    // Arrange
    authSpy.failSignIn(Exception('Invalid credentials'));

    // Act
    await container.read(authNotifierProvider.notifier).signInWithEmail(
      anyEmail(),
      anyPassword(),
    );

    // Assert
    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthStateError>());
  });
}
```

---

## 7. Widget Testing Helpers

### pump_app.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/theme/app_theme.dart';

// ============================================================
// PUMP EXTENSIONS
// ============================================================

extension WidgetTesterPump on WidgetTester {
  /// Pumps a widget wrapped in necessary providers and MaterialApp.
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
    Locale? locale,
    NavigatorObserver? observer,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: locale,
          navigatorObservers: observer != null ? [observer] : [],
          home: widget,
        ),
      ),
    );
  }

  /// Pumps app and settles all animations/futures.
  Future<void> pumpAppAndSettle(
    Widget widget, {
    List<Override> overrides = const [],
    Duration duration = const Duration(seconds: 10),
  }) async {
    await pumpApp(widget, overrides: overrides);
    await pumpAndSettle(duration);
  }

  /// Pumps with router for navigation testing
  Future<void> pumpRouter({
    required GoRouter router,
    List<Override> overrides = const [],
    ThemeData? theme,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: theme ?? AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
  }
}

// ============================================================
// INTERACTION EXTENSIONS
// ============================================================

extension WidgetTesterInteractions on WidgetTester {
  /// Taps on a widget and pumps
  Future<void> simulateTapOn(Finder finder) async {
    expect(finder, findsOneWidget, reason: 'Widget to tap not found');
    await tap(finder);
    await pump();
  }

  /// Enters text into a field
  Future<void> simulateTextInput(Finder finder, String text) async {
    expect(finder, findsOneWidget, reason: 'Text field not found');
    await enterText(finder, text);
    await pump();
  }

  /// Submits a text field
  Future<void> simulateSubmit(Finder finder) async {
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();
  }

  /// Long press on a widget
  Future<void> simulateLongPress(Finder finder) async {
    expect(finder, findsOneWidget, reason: 'Widget to long press not found');
    await longPress(finder);
    await pump();
  }

  /// Drag from one point to another
  Future<void> simulateDrag(Finder finder, Offset offset) async {
    await drag(finder, offset);
    await pump();
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder,
    Finder scrollable, {
    double delta = 100,
  }) async {
    await dragUntilVisible(
      finder,
      scrollable,
      Offset(0, -delta),
    );
  }
}

// ============================================================
// FINDER EXTENSIONS
// ============================================================

extension FinderExtensions on CommonFinders {
  /// Find by semantic label
  Finder bySemantic(String label) =>
      bySemanticsLabel(label);

  /// Find button with text
  Finder buttonWithText(String text) =>
      find.widgetWithText(ElevatedButton, text);

  /// Find text field with hint
  Finder textFieldWithHint(String hint) =>
      find.widgetWithText(TextField, hint);
}
```

---

## 8. Golden Testing Helpers

### golden_helpers.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

// ============================================================
// DEVICE CONFIGURATIONS
// ============================================================

final class GoldenDevices {
  GoldenDevices._();

  static const Device iPhoneSE = Device(
    name: 'iPhone_SE',
    size: Size(375, 667),
    devicePixelRatio: 2.0,
  );

  static const Device iPhone14 = Device(
    name: 'iPhone_14',
    size: Size(390, 844),
    devicePixelRatio: 3.0,
  );

  static const Device iPhone14ProMax = Device(
    name: 'iPhone_14_Pro_Max',
    size: Size(430, 932),
    devicePixelRatio: 3.0,
  );

  static const Device pixel5 = Device(
    name: 'Pixel_5',
    size: Size(393, 851),
    devicePixelRatio: 2.75,
  );

  static const List<Device> all = [iPhoneSE, iPhone14, iPhone14ProMax, pixel5];
}

// ============================================================
// THEME CONFIGURATIONS
// ============================================================

enum GoldenTheme {
  light('light'),
  dark('dark');

  const GoldenTheme(this.suffix);
  final String suffix;

  ThemeData get theme => switch (this) {
    GoldenTheme.light => AppTheme.light,
    GoldenTheme.dark => AppTheme.dark,
  };
}

// ============================================================
// WIDGET BUILDERS
// ============================================================

/// Builds a widget wrapped in necessary providers for golden tests.
Widget buildGoldenWidget({
  required Widget child,
  GoldenTheme theme = GoldenTheme.light,
  List<Override> overrides = const [],
  Locale? locale,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.theme,
      locale: locale,
      home: child,
    ),
  );
}

/// Builds a widget for multi-device golden tests
Widget buildMultiDeviceGolden({
  required Widget child,
  required Device device,
  GoldenTheme theme = GoldenTheme.light,
  List<Override> overrides = const [],
}) {
  return buildGoldenWidget(
    child: child,
    theme: theme,
    overrides: overrides,
  );
}

// ============================================================
// GOLDEN TEST HELPERS
// ============================================================

/// Run golden test for multiple devices
Future<void> multiDeviceGolden(
  WidgetTester tester, {
  required String name,
  required Widget widget,
  List<Device> devices = const [GoldenDevices.iPhone14],
  List<GoldenTheme> themes = const [GoldenTheme.light],
  List<Override> overrides = const [],
}) async {
  for (final device in devices) {
    for (final theme in themes) {
      final goldenName = '${name}_${device.name}_${theme.suffix}';

      await tester.pumpWidgetBuilder(
        buildGoldenWidget(
          child: widget,
          theme: theme,
          overrides: overrides,
        ),
        surfaceSize: device.size,
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, goldenName);
    }
  }
}

// ============================================================
// TOLERANT COMPARATOR (for CI)
// ============================================================

/// Use when golden tests fail due to minor rendering differences
class TolerantGoldenComparator extends LocalFileComparator {
  final double tolerance;

  TolerantGoldenComparator(
    super.testFile, {
    this.tolerance = 0.005, // 0.5% tolerance
  });

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    return result.passed || result.diffPercent <= tolerance;
  }
}
```

---

## 9. Arrange-Act-Assert Pattern

Every test should have clear sections:

```dart
test('signIn_withValidCredentials_returnsAuthResult', () async {
  // ============================================================
  // ARRANGE - Set up test conditions
  // ============================================================
  final sut = makeSUT();
  final expectedUser = anyUserProfile();

  when(() => mockAuth.signInWithPassword(
    email: any(named: 'email'),
    password: any(named: 'password'),
  )).thenAnswer((_) async => anyAuthResponse());

  // ============================================================
  // ACT - Execute the behavior being tested
  // ============================================================
  final result = await sut.signInWithEmail(anyEmail(), anyPassword());

  // ============================================================
  // ASSERT - Verify the expected outcome
  // ============================================================
  expect(result.user.email, expectedUser.email);
  verify(() => mockAuth.signInWithPassword(
    email: anyEmail(),
    password: anyPassword(),
  )).called(1);
});
```

---

## 10. Testing Async Operations

### With Completer

```dart
test('loadUser_whileLoading_emitsLoadingState', () async {
  // Arrange
  final completer = Completer<UserProfile>();
  when(() => mockRepo.getUser()).thenAnswer((_) => completer.future);

  // Act - start loading
  final future = sut.loadUser();

  // Assert loading state
  expect(sut.state.isLoading, isTrue);

  // Complete and verify final state
  completer.complete(anyUserProfile());
  await future;
  expect(sut.state.user, isNotNull);
});
```

### With FakeAsync

```dart
test('refreshToken_afterDelay_refreshesAutomatically', () {
  fakeAsync((async) {
    // Arrange
    sut.startAutoRefresh(interval: const Duration(minutes: 5));

    // Act - advance time
    async.elapse(const Duration(minutes: 5));

    // Assert
    verify(() => mockAuth.refreshSession()).called(1);

    // Advance more time
    async.elapse(const Duration(minutes: 5));
    verify(() => mockAuth.refreshSession()).called(2);
  });
});
```

---

## 11. Disposal Testing Patterns

**Purpose:** Test proper resource cleanup to prevent callbacks firing after disposal, setState on unmounted widgets, and wasted CPU cycles.

> **Note:** Dart uses garbage collection, not reference counting like Swift. The real concern in Flutter isn't memory leaks but **improper disposal** causing runtime errors.

### Common Disposal Issues in Flutter

| Issue | Symptom | Cause |
|-------|---------|-------|
| `setState() called after dispose()` | Crash/warning | Stream listener not cancelled |
| State set on disposed notifier | Silent bug or crash | Async completes after disposal |
| Wasted resources | Battery/CPU drain | Timers/animations not stopped |
| Stale callbacks | Wrong data displayed | Old subscriptions still active |

### Testing Stream Subscription Disposal

```dart
// Component under test
final class DataService {
  StreamSubscription<Data>? _subscription;
  final StreamController<Data> _controller = StreamController.broadcast();

  void startListening(Stream<Data> source) {
    _subscription = source.listen(_controller.add);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

// Test
test('dispose_cancelsSubscription', () {
  // Arrange
  final sourceController = StreamController<Data>();
  final sut = DataService();
  sut.startListening(sourceController.stream);

  // Verify subscription is active
  expect(sourceController.hasListener, isTrue);

  // Act
  sut.dispose();

  // Assert - subscription should be cancelled
  expect(sourceController.hasListener, isFalse);

  // Cleanup
  sourceController.close();
});
```

### Testing Controller Disposal

```dart
// Component under test
final class FormController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}

// Test using a spy controller
final class TextEditingControllerSpy extends TextEditingController {
  bool disposeCalled = false;

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }
}

test('dispose_disposesAllControllers', () {
  // Arrange
  final emailSpy = TextEditingControllerSpy();
  final passwordSpy = TextEditingControllerSpy();
  final sut = FormController.withControllers(
    email: emailSpy,
    password: passwordSpy,
  );

  // Act
  sut.dispose();

  // Assert
  expect(emailSpy.disposeCalled, isTrue);
  expect(passwordSpy.disposeCalled, isTrue);
});
```

### Testing AsyncNotifier Disposal Safety

The `_disposed` flag pattern prevents state changes after disposal:

```dart
// Component under test
@riverpod
final class UserNotifier extends _$UserNotifier {
  bool _disposed = false;

  @override
  UserState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const UserState.initial();
  }

  Future<void> loadUser() async {
    state = const UserState.loading();

    final result = await ref.read(userRepositoryProvider).getUser();

    // Safety check - don't set state if disposed
    if (_disposed) return;

    state = result.fold(
      (failure) => UserState.error(failure.message),
      (user) => UserState.loaded(user),
    );
  }
}

// Test
test('loadUser_afterDisposal_doesNotSetState', () async {
  // Arrange
  final completer = Completer<Either<Failure, User>>();
  final mockRepo = MockUserRepository();
  when(() => mockRepo.getUser()).thenAnswer((_) => completer.future);

  final container = makeProviderContainer(
    overrides: [userRepositoryProvider.overrideWithValue(mockRepo)],
  );

  // Start loading
  final future = container.read(userNotifierProvider.notifier).loadUser();

  // Verify loading state
  expect(
    container.read(userNotifierProvider),
    const UserState.loading(),
  );

  // Dispose container BEFORE async completes
  container.dispose();

  // Complete the future after disposal
  completer.complete(Right(anyUser()));

  // Wait for async to finish
  await future;

  // No assertion needed - test passes if no exception thrown
  // (setState on disposed notifier would throw)
});
```

### Testing Timer Disposal

```dart
// Component under test
final class PollingService {
  Timer? _timer;
  final void Function() onPoll;

  PollingService({required this.onPoll});

  void startPolling(Duration interval) {
    _timer = Timer.periodic(interval, (_) => onPoll());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

// Test
test('dispose_cancelsTimer', () {
  fakeAsync((async) {
    // Arrange
    var pollCount = 0;
    final sut = PollingService(onPoll: () => pollCount++);
    sut.startPolling(const Duration(seconds: 1));

    // Verify timer is working
    async.elapse(const Duration(seconds: 3));
    expect(pollCount, 3);

    // Act
    sut.dispose();

    // Assert - no more polls after disposal
    async.elapse(const Duration(seconds: 3));
    expect(pollCount, 3); // Still 3, not 6
  });
});
```

### Disposal Test Helpers

```dart
// disposal_helpers.dart

/// Verifies a StreamController has no listeners after action.
void expectNoListeners(StreamController controller, {String? reason}) {
  expect(
    controller.hasListener,
    isFalse,
    reason: reason ?? 'Expected no listeners after disposal',
  );
}

/// Creates a Completer that can verify if it was used after disposal.
final class DisposalTestCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  bool _completedAfterDisposal = false;
  bool _disposed = false;

  Future<T> get future => _completer.future;

  void markDisposed() => _disposed = true;

  void complete(T value) {
    if (_disposed) _completedAfterDisposal = true;
    if (!_completer.isCompleted) _completer.complete(value);
  }

  bool get wasCompletedAfterDisposal => _completedAfterDisposal;
}

/// Extension to verify disposal was called on a notifier.
extension NotifierDisposalTest<T> on ProviderContainer {
  /// Reads a notifier, then disposes container, returning the notifier for assertions.
  N readAndDispose<N>(ProviderListenable<N> provider) {
    final notifier = read(provider);
    dispose();
    return notifier;
  }
}
```

### Widget Disposal Testing

```dart
testWidgets('widget_onDispose_cancelsSubscription', (tester) async {
  // Arrange
  final streamController = StreamController<int>.broadcast();

  await tester.pumpWidget(
    MaterialApp(
      home: MyStreamWidget(stream: streamController.stream),
    ),
  );

  // Verify listening
  expect(streamController.hasListener, isTrue);

  // Act - remove widget from tree (triggers dispose)
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));

  // Assert
  expect(streamController.hasListener, isFalse);

  // Cleanup
  await streamController.close();
});
```

### Checklist for Disposal Tests

For any component with resources, test:

- [ ] **Subscriptions cancelled** - `StreamSubscription.cancel()` called
- [ ] **Controllers disposed** - `TextEditingController`, `AnimationController`, etc.
- [ ] **Timers cancelled** - `Timer.cancel()` called
- [ ] **Async safety** - State not set after disposal
- [ ] **Streams closed** - `StreamController.close()` called
- [ ] **Focus nodes disposed** - `FocusNode.dispose()` called

---

## 12. Stubbing vs Spying (Capturing)

**Purpose:** Understand when to use stubs vs spies for clearer, more maintainable tests.

> **Reference:** Essential Developer pattern distinguishing behavior control from interaction verification.

### When to Use Stubs (Mocks with `when`)

Use **stubs** when you need to **control behavior** - making collaborators return specific values:

```dart
// STUB: Control what the dependency returns
test('signIn_withValidCredentials_returnsUser', () async {
  // Arrange - STUB the dependency to return expected value
  when(() => mockAuth.signInWithPassword(
    email: any(named: 'email'),
    password: any(named: 'password'),
  )).thenAnswer((_) async => anyAuthResponse());

  // Act
  final result = await sut.signInWithEmail(anyEmail(), anyPassword());

  // Assert - verify the result, not how we got there
  expect(result.user, isNotNull);
});
```

### When to Use Spies (Capturing)

Use **spies** when you need to **verify interactions** - checking what was called and with what arguments:

```dart
// SPY: Verify how collaborators were called
test('signIn_callsAuthWithCorrectCredentials', () async {
  // Arrange - use spy to capture calls
  final authSpy = AuthClientSpy();
  authSpy.completeSignIn(anyAuthResponse());
  final sut = makeSUT(auth: authSpy);

  // Act
  await sut.signInWithEmail('user@test.com', 'password123');

  // Assert - verify the interaction
  expect(authSpy.receivedMessages, [
    SignInMessage(email: 'user@test.com', password: 'password123'),
  ]);
});
```

### Key Principle: Single Responsibility for Spies

Spies should only **capture** - they should not also **stub** behavior inline:

```dart
// ❌ BAD: Spy doing too much
final class BadAuthSpy implements AuthClient {
  final List<String> capturedEmails = [];

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    capturedEmails.add(email);
    // ❌ Stubbing behavior inside spy
    return AuthResponse(user: User(id: '123', email: email));
  }
}

// ✅ GOOD: Spy only captures, behavior controlled separately
final class GoodAuthSpy implements AuthClient {
  final List<SignInMessage> receivedMessages = [];

  // Control behavior through these
  AuthResponse? signInResult;
  Exception? signInError;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Only capture
    receivedMessages.add(SignInMessage(email: email, password: password));

    // Return controlled result
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  // Completion helpers separate from capture
  void completeSignIn(AuthResponse response) => signInResult = response;
  void failSignIn(Exception error) => signInError = error;
}
```

### Decision Guide

| Need | Use | Example |
|------|-----|---------|
| Control return value | Stub (Mock + `when`) | "Return this user when called" |
| Verify method was called | Spy | "Was signIn called?" |
| Verify call arguments | Spy with messages | "Was signIn called with this email?" |
| Verify call order | Spy with message list | "Was signIn called before signOut?" |
| Verify call count | Either | Both support `.called(n)` or `.length` |

---

## 13. Inbox Checklist Pattern

**Purpose:** Systematically test infrastructure components (storage, cache, API) with a proven checklist.

> **Reference:** Essential Developer "Inbox" pattern for comprehensive infrastructure testing.

### The Checklist

For any storage/cache/repository that implements **Insert**, **Retrieve**, and **Delete**:

```
INSERT
├── Delivers no error on empty cache
├── Delivers no error on non-empty cache (overwrites)
└── Has no side effects on empty cache (insert-only)

RETRIEVE
├── Delivers empty on empty cache
├── Delivers found data on non-empty cache
├── Has no side effects on non-empty cache (retrieve doesn't modify)
└── Delivers empty on expired data (if applicable)

DELETE
├── Delivers no error on empty cache
├── Empties previously inserted cache
└── Has no side effects on empty cache (delete-only)

SIDE EFFECTS (General)
├── Operations are isolated (one doesn't affect unrelated data)
├── Operations are thread-safe (if applicable)
└── Operations handle corruption gracefully
```

### Implementation Example

```dart
void main() {
  late Directory tempDir;
  late CacheStore sut;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_test_');
    sut = CacheStore(directory: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ============================================================
  // INSERT
  // ============================================================

  group('insert', () {
    test('deliversNoErrorOnEmptyCache', () async {
      await expectLater(
        sut.insert(anyFeedItem()),
        completes,
      );
    });

    test('deliversNoErrorOnNonEmptyCache_overwrites', () async {
      // First insert
      await sut.insert(anyFeedItem(id: 'item-1'));

      // Second insert with same ID should overwrite
      await expectLater(
        sut.insert(anyFeedItem(id: 'item-1', title: 'Updated')),
        completes,
      );

      final retrieved = await sut.retrieve('item-1');
      expect(retrieved?.title, 'Updated');
    });

    test('hasNoSideEffectsOnEmptyCache', () async {
      await sut.insert(anyFeedItem(id: 'item-1'));

      // Verify only the inserted item exists
      final all = await sut.retrieveAll();
      expect(all, hasLength(1));
    });
  });

  // ============================================================
  // RETRIEVE
  // ============================================================

  group('retrieve', () {
    test('deliversEmptyOnEmptyCache', () async {
      final result = await sut.retrieve('non-existent');
      expect(result, isNull);
    });

    test('deliversFoundDataOnNonEmptyCache', () async {
      final item = anyFeedItem(id: 'item-1');
      await sut.insert(item);

      final retrieved = await sut.retrieve('item-1');

      expect(retrieved, isNotNull);
      expect(retrieved?.id, item.id);
      expect(retrieved?.title, item.title);
    });

    test('hasNoSideEffectsOnNonEmptyCache', () async {
      await sut.insert(anyFeedItem(id: 'item-1'));

      // Multiple retrieves shouldn't affect data
      await sut.retrieve('item-1');
      await sut.retrieve('item-1');
      await sut.retrieve('item-1');

      final all = await sut.retrieveAll();
      expect(all, hasLength(1));
    });

    test('deliversEmptyOnExpiredData', () async {
      await sut.insert(
        anyFeedItem(id: 'item-1'),
        expiration: pastTimestamp(),
      );

      final result = await sut.retrieve('item-1');
      expect(result, isNull);
    });
  });

  // ============================================================
  // DELETE
  // ============================================================

  group('delete', () {
    test('deliversNoErrorOnEmptyCache', () async {
      await expectLater(
        sut.delete('non-existent'),
        completes,
      );
    });

    test('emptiesPreviouslyInsertedCache', () async {
      await sut.insert(anyFeedItem(id: 'item-1'));

      await sut.delete('item-1');

      final result = await sut.retrieve('item-1');
      expect(result, isNull);
    });

    test('hasNoSideEffectsOnEmptyCache', () async {
      await sut.delete('non-existent');

      final all = await sut.retrieveAll();
      expect(all, isEmpty);
    });
  });
}
```

### Applying to Different Infrastructure

| Infrastructure | Insert | Retrieve | Delete |
|----------------|--------|----------|--------|
| **Local Cache** | `save()` | `load()` | `clear()` |
| **Secure Storage** | `write()` | `read()` | `delete()` |
| **SharedPrefs** | `setString()` | `getString()` | `remove()` |
| **Database** | `insert()` | `query()` | `delete()` |
| **API Client** | `POST` | `GET` | `DELETE` |

---

## 14. Testing Framework Assumptions

**Purpose:** Verify assumptions about framework/library behavior to catch breaking changes early.

> **Reference:** Essential Developer pattern for testing third-party behavior.

### Why Test Assumptions?

Frameworks and libraries can change behavior between versions. Test your assumptions to:
- Catch breaking changes during upgrades
- Document expected behavior
- Understand edge cases

### Examples

```dart
group('Supabase Assumptions', () {
  test('signInWithPassword_returnsUserWithEmail', () async {
    // Test that Supabase returns user with email in response
    // If this fails after upgrade, we know behavior changed
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    expect(response.user?.email, isNotNull);
    expect(response.user?.email, testEmail);
  });

  test('signOut_clearsSession', () async {
    // Assumption: signOut clears the current session
    await Supabase.instance.client.auth.signOut();

    expect(Supabase.instance.client.auth.currentSession, isNull);
  });
});

group('SharedPreferences Assumptions', () {
  test('getString_returnsNullForMissingKey', () async {
    final prefs = await SharedPreferences.getInstance();

    // Assumption: missing keys return null, not throw
    final result = prefs.getString('definitely-not-set-key');

    expect(result, isNull);
  });

  test('setString_withEmptyString_storesEmpty', () async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('key', '');
    final result = prefs.getString('key');

    // Assumption: empty string is stored, not removed
    expect(result, '');
    expect(result, isNot(isNull));
  });
});

group('Dio Assumptions', () {
  test('get_on404_throwsDioException', () async {
    final dio = Dio();

    // Assumption: 404 throws, doesn't return response
    await expectLater(
      dio.get('https://httpstat.us/404'),
      throwsA(isA<DioException>()),
    );
  });

  test('get_onTimeout_throwsDioExceptionWithType', () async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 1),
    ));

    // Assumption: timeout throws specific DioException type
    try {
      await dio.get('https://httpstat.us/200?sleep=5000');
      fail('Should have thrown');
    } on DioException catch (e) {
      expect(e.type, DioExceptionType.connectionTimeout);
    }
  });
});
```

### When to Add Assumption Tests

Add assumption tests when you:
- Rely on specific framework behavior
- Use undocumented features
- Have had bugs from framework updates
- Work with edge cases (null, empty, special values)

---

## 15. Making Invalid Paths Non-Representable

**Purpose:** Use types to eliminate invalid states, reducing test burden.

> **Reference:** Essential Developer pattern for compile-time safety.

### Problem: Too Many Invalid States

```dart
// ❌ BAD: Many invalid states possible
final class LoadResult {
  final List<Item>? items;
  final String? error;
  final bool isLoading;

  // Invalid states:
  // - items != null && error != null (both success AND failure?)
  // - isLoading && items != null (loading but already has data?)
  // - isLoading && error != null (loading but already failed?)
}
```

### Solution: Sealed Classes

```dart
// ✅ GOOD: Invalid states are impossible
sealed class LoadResult {
  const LoadResult();
}

final class LoadResultLoading extends LoadResult {
  const LoadResultLoading();
}

final class LoadResultSuccess extends LoadResult {
  final List<Item> items;
  const LoadResultSuccess(this.items);
}

final class LoadResultFailure extends LoadResult {
  final String error;
  const LoadResultFailure(this.error);
}
```

### With Freezed

```dart
@freezed
sealed class LoadResult with _$LoadResult {
  const factory LoadResult.loading() = LoadResultLoading;
  const factory LoadResult.success(List<Item> items) = LoadResultSuccess;
  const factory LoadResult.failure(String error) = LoadResultFailure;
}
```

### Testing Benefits

With sealed classes, you only need to test valid states:

```dart
// Only 3 states to test, not 8+ combinations
test('load_whileLoading_emitsLoadingState', () {
  expect(sut.state, const LoadResult.loading());
});

test('load_onSuccess_emitsSuccessWithItems', () {
  final result = sut.state as LoadResultSuccess;
  expect(result.items, isNotEmpty);
});

test('load_onError_emitsFailureWithMessage', () {
  final result = sut.state as LoadResultFailure;
  expect(result.error, isNotEmpty);
});
```

---

## Summary

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `makeSUT()` | Centralize SUT creation | Every test file |
| `any*()` | Consistent test data | All test data |
| Mock | Control return values | Dependencies you don't own |
| Spy | Track method calls | Verify interactions |
| `pumpApp()` | Widget test wrapper | Widget tests |
| `ProviderListener` | Track state changes | Provider tests |
| AAA | Clear test structure | Every test |
| Disposal Testing | Verify resource cleanup | Components with subscriptions/timers |
| Inbox Checklist | Test infrastructure | Storage, cache, API |
| Framework Assumptions | Catch breaking changes | Third-party dependencies |
| Sealed Classes | Eliminate invalid states | State modeling |
