# Testing Examples

Comprehensive before/after examples for every common test scenario.

---

## 1. Unit Tests - Repository

### Basic Repository Test

```dart
// ❌ BAD - Vague test name, no structure
test('test sign in', () async {
  final result = await repo.signIn('test@email.com', 'password');
  expect(result, isNotNull);
});

// ✅ GOOD - Clear name, AAA structure
test('signIn_withValidCredentials_returnsAuthResult', () async {
  // Arrange
  final sut = makeSUT();
  when(() => mockAuth.signInWithPassword(
    email: any(named: 'email'),
    password: any(named: 'password'),
  )).thenAnswer((_) async => anyAuthResponse());

  // Act
  final result = await sut.signInWithEmail(anyEmail(), anyPassword());

  // Assert
  expect(result.user, isNotNull);
  expect(result.user.email, anyEmail());
});
```

### Testing Error Paths

```dart
// ❌ BAD - Missing error path testing
test('signIn_works', () async {
  when(() => mockAuth.signInWithPassword(...)).thenAnswer(...);
  final result = await sut.signIn(...);
  expect(result, isNotNull);
});

// ✅ GOOD - Tests both success and error paths
group('signIn', () {
  test('withValidCredentials_returnsAuthResult', () async {
    // Arrange
    when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => anyAuthResponse());

    // Act
    final result = await sut.signInWithEmail(anyEmail(), anyPassword());

    // Assert
    expect(result.user, isNotNull);
  });

  test('withInvalidCredentials_throwsAuthFailure', () async {
    // Arrange
    when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenThrow(AuthException('invalid_credentials'));

    // Act & Assert
    expect(
      () => sut.signInWithEmail(anyEmail(), anyPassword()),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('withNetworkError_throwsNetworkFailure', () async {
    // Arrange
    when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenThrow(SocketException('No internet'));

    // Act & Assert
    expect(
      () => sut.signInWithEmail(anyEmail(), anyPassword()),
      throwsA(isA<NetworkFailure>()),
    );
  });
});
```

### Testing Side Effects

```dart
// ❌ BAD - Doesn't verify side effects
test('signOut_works', () async {
  await sut.signOut();
  // No verification!
});

// ✅ GOOD - Verifies all side effects
test('signOut_clearsAllStoredData', () async {
  // Arrange
  when(() => mockAuth.signOut()).thenAnswer((_) async {});
  when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
  when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

  // Act
  await sut.signOut();

  // Assert - verify all cleanup happened
  verify(() => mockAuth.signOut()).called(1);
  verify(() => mockStorage.deleteAll()).called(1);
  verify(() => mockPrefs.remove(StorageKeys.hasUser)).called(1);
});

test('signIn_onError_doesNotStoreTokens', () async {
  // Arrange
  when(() => mockAuth.signInWithPassword(
    email: any(named: 'email'),
    password: any(named: 'password'),
  )).thenThrow(AuthException('error'));

  // Act
  try {
    await sut.signInWithEmail(anyEmail(), anyPassword());
  } catch (_) {}

  // Assert - storage should NOT be called on error
  verifyNever(() => mockStorage.write(
    key: any(named: 'key'),
    value: any(named: 'value'),
  ));
});
```

---

## 2. Unit Tests - Services

### Storage Service Test

```dart
// ❌ BAD - Tests implementation, not behavior
test('write stores value', () async {
  await storage.write('key', 'value');
  // Just trusting it worked
});

// ✅ GOOD - Tests round-trip behavior
group('SecureStorageService', () {
  test('write_thenRead_returnsStoredValue', () async {
    // Arrange
    const key = StorageKeys.accessToken;
    final value = anyToken();

    // Act
    await sut.write(key: key, value: value);
    final result = await sut.read(key: key);

    // Assert
    expect(result, value);
  });

  test('read_whenKeyNotExists_returnsNull', () async {
    // Act
    final result = await sut.read(key: 'nonexistent');

    // Assert
    expect(result, isNull);
  });

  test('deleteAll_removesAllStoredValues', () async {
    // Arrange
    await sut.write(key: 'key1', value: 'value1');
    await sut.write(key: 'key2', value: 'value2');

    // Act
    await sut.deleteAll();

    // Assert
    expect(await sut.read(key: 'key1'), isNull);
    expect(await sut.read(key: 'key2'), isNull);
  });
});
```

### Dio Client Test

```dart
// ❌ BAD - No interceptor testing
test('get works', () async {
  final response = await client.get('/users');
  expect(response.statusCode, 200);
});

// ✅ GOOD - Tests interceptor behavior
group('DioClient', () {
  test('request_addsAuthorizationHeader', () async {
    // Arrange
    when(() => mockStorage.read(key: StorageKeys.accessToken))
        .thenAnswer((_) async => anyToken());

    // Act
    await sut.get('/users');

    // Assert
    final captured = verify(() => mockDio.get(
      any(),
      options: captureAny(named: 'options'),
    )).captured.single as Options;

    expect(
      captured.headers?['Authorization'],
      'Bearer ${anyToken()}',
    );
  });

  test('request_on401_refreshesTokenAndRetries', () async {
    // Arrange
    var callCount = 0;
    when(() => mockDio.get(any())).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        throw DioException(
          requestOptions: RequestOptions(path: '/users'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/users'),
          ),
        );
      }
      return Response(
        data: {'user': 'data'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/users'),
      );
    });

    when(() => mockAuth.refreshSession())
        .thenAnswer((_) async => anySession());

    // Act
    final response = await sut.get('/users');

    // Assert
    expect(response.statusCode, 200);
    verify(() => mockAuth.refreshSession()).called(1);
    expect(callCount, 2);
  });
});
```

---

## 3. Provider Tests

### Basic Notifier Test

```dart
// ❌ BAD - No provider testing utilities
test('auth provider works', () async {
  final provider = AuthNotifier();
  await provider.signIn('email', 'password');
  expect(provider.state.isAuthenticated, true);
});

// ✅ GOOD - Uses proper Riverpod testing patterns
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

  group('AuthNotifier', () {
    test('initialState_isInitial', () {
      // Act
      final state = container.read(authNotifierProvider);

      // Assert
      expect(state, const AuthState.initial());
    });

    test('signIn_withValidCredentials_becomesAuthenticated', () async {
      // Arrange
      final expectedUser = anyUserProfile();
      authSpy.completeSignIn(AuthResult(user: expectedUser, isNewUser: false));

      // Act
      await container.read(authNotifierProvider.notifier).signInWithEmail(
        anyEmail(),
        anyPassword(),
      );

      // Assert
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthStateAuthenticated>());
      expect((state as AuthStateAuthenticated).user, expectedUser);
    });

    test('signIn_withError_becomesError', () async {
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
  });
}
```

### Testing State Transitions

```dart
// ❌ BAD - Only tests final state
test('signIn changes state', () async {
  await notifier.signIn(...);
  expect(state.isAuthenticated, true);
});

// ✅ GOOD - Tests all state transitions
test('signIn_emitsCorrectStateTransitions', () async {
  // Arrange
  final listener = ProviderListener<AuthState>();
  container.listen(
    authNotifierProvider,
    listener.call,
    fireImmediately: true,
  );
  authSpy.completeSignIn(anyAuthResult());

  // Act
  await container.read(authNotifierProvider.notifier).signInWithEmail(
    anyEmail(),
    anyPassword(),
  );

  // Assert - verify state transitions in order
  expect(listener.states, [
    const AuthState.initial(),      // 1. Initial state
    const AuthState.loading(),      // 2. Loading state
    isA<AuthStateAuthenticated>(),  // 3. Authenticated state
  ]);
});

test('signIn_onError_emitsLoadingThenError', () async {
  // Arrange
  final listener = ProviderListener<AuthState>();
  container.listen(
    authNotifierProvider,
    listener.call,
    fireImmediately: true,
  );
  authSpy.failSignIn(Exception('Error'));

  // Act
  await container.read(authNotifierProvider.notifier).signInWithEmail(
    anyEmail(),
    anyPassword(),
  );

  // Assert
  expect(listener.states, [
    const AuthState.initial(),
    const AuthState.loading(),
    isA<AuthStateError>(),
  ]);
});
```

### Testing Provider Dependencies

```dart
// ❌ BAD - Tests providers in isolation
test('user provider works', () async {
  final user = container.read(userProvider);
  expect(user, isNotNull);
});

// ✅ GOOD - Tests provider dependency chain
group('UserProvider', () {
  test('whenAuthenticated_returnsCurrentUser', () async {
    // Arrange - set up auth state first
    authSpy.completeSignIn(anyAuthResult());
    await container.read(authNotifierProvider.notifier).signInWithEmail(
      anyEmail(),
      anyPassword(),
    );

    // Act
    final user = container.read(currentUserProvider);

    // Assert
    expect(user, isNotNull);
    expect(user?.email, anyEmail());
  });

  test('whenNotAuthenticated_returnsNull', () {
    // Act - no sign in performed
    final user = container.read(currentUserProvider);

    // Assert
    expect(user, isNull);
  });
});
```

---

## 4. Widget Tests

### Basic Widget Test

```dart
// ❌ BAD - No assertions, unclear intent
testWidgets('login screen test', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  await tester.pump();
});

// ✅ GOOD - Clear intent, specific assertions
testWidgets('LoginScreen_displaysEmailAndPasswordFields', (tester) async {
  // Arrange & Act
  await tester.pumpApp(const LoginScreen());

  // Assert
  expect(find.byType(TextField), findsNWidgets(2));
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Password'), findsOneWidget);
  expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
});
```

### Testing User Interactions

```dart
// ❌ BAD - Uses sleep, unclear verification
testWidgets('tap button works', (tester) async {
  await tester.pumpWidget(LoginScreen());
  await tester.tap(find.byType(ElevatedButton));
  await Future.delayed(Duration(seconds: 1));
  // No verification!
});

// ✅ GOOD - Uses spy, verifies behavior
testWidgets('LoginScreen_tapSignIn_callsProviderWithEnteredValues', (tester) async {
  // Arrange
  final authSpy = AuthNotifierSpy();
  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      authNotifierProvider.overrideWith(() => authSpy),
    ],
  );

  // Act - enter credentials
  await tester.simulateTextInput(
    find.byKey(const Key('email_field')),
    'test@example.com',
  );
  await tester.simulateTextInput(
    find.byKey(const Key('password_field')),
    'password123',
  );
  await tester.simulateTapOn(find.byKey(const Key('sign_in_button')));
  await tester.pump();

  // Assert
  expect(authSpy.receivedMessages, [
    AuthNotifierMessage.signInWithEmail('test@example.com', 'password123'),
  ]);
});
```

### Testing Loading States

```dart
// ❌ BAD - Doesn't test loading state
testWidgets('shows content', (tester) async {
  await tester.pumpWidget(LoginScreen());
  expect(find.byType(TextField), findsWidgets);
});

// ✅ GOOD - Tests loading state properly
testWidgets('LoginScreen_whileLoading_showsProgressIndicator', (tester) async {
  // Arrange - override with always-loading notifier
  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      authNotifierProvider.overrideWith(() => AlwaysLoadingAuthNotifier()),
    ],
  );

  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byKey(const Key('sign_in_button')), findsNothing);
});

testWidgets('LoginScreen_whileLoading_disablesInputs', (tester) async {
  // Arrange
  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      authNotifierProvider.overrideWith(() => AlwaysLoadingAuthNotifier()),
    ],
  );

  // Assert - text fields should be disabled
  final textFields = tester.widgetList<TextField>(find.byType(TextField));
  for (final field in textFields) {
    expect(field.enabled, isFalse);
  }
});
```

### Testing Error Display

```dart
// ❌ BAD - Doesn't test error states
testWidgets('login works', (tester) async {
  // Only happy path
});

// ✅ GOOD - Tests error display
testWidgets('LoginScreen_onError_showsErrorMessage', (tester) async {
  // Arrange
  const errorMessage = 'Invalid credentials';
  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      authNotifierProvider.overrideWith(
        () => ErrorAuthNotifier(errorMessage),
      ),
    ],
  );

  // Assert
  expect(find.text(errorMessage), findsOneWidget);
  expect(find.byIcon(Icons.error), findsOneWidget);
});

testWidgets('LoginScreen_onError_showsRetryButton', (tester) async {
  // Arrange
  await tester.pumpApp(
    const LoginScreen(),
    overrides: [
      authNotifierProvider.overrideWith(
        () => ErrorAuthNotifier('Error'),
      ),
    ],
  );

  // Assert
  expect(find.text('Try again'), findsOneWidget);
});
```

### Testing Form Validation

```dart
// ❌ BAD - No validation testing
testWidgets('form submits', (tester) async {
  await tester.tap(find.byType(ElevatedButton));
});

// ✅ GOOD - Tests form validation
group('LoginScreen validation', () {
  testWidgets('withEmptyEmail_showsValidationError', (tester) async {
    // Arrange
    await tester.pumpApp(const LoginScreen());

    // Act - submit without entering email
    await tester.simulateTapOn(find.byKey(const Key('sign_in_button')));
    await tester.pump();

    // Assert
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('withInvalidEmail_showsValidationError', (tester) async {
    // Arrange
    await tester.pumpApp(const LoginScreen());

    // Act
    await tester.simulateTextInput(
      find.byKey(const Key('email_field')),
      'invalid-email',
    );
    await tester.simulateTapOn(find.byKey(const Key('sign_in_button')));
    await tester.pump();

    // Assert
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('withShortPassword_showsValidationError', (tester) async {
    // Arrange
    await tester.pumpApp(const LoginScreen());

    // Act
    await tester.simulateTextInput(
      find.byKey(const Key('email_field')),
      anyEmail(),
    );
    await tester.simulateTextInput(
      find.byKey(const Key('password_field')),
      '123', // Too short
    );
    await tester.simulateTapOn(find.byKey(const Key('sign_in_button')));
    await tester.pump();

    // Assert
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });
});
```

---

## 5. Golden Tests

### Basic Golden Test

```dart
// ❌ BAD - No golden testing
testWidgets('screen looks correct', (tester) async {
  await tester.pumpWidget(LoginScreen());
  // Visual inspection only
});

// ✅ GOOD - Golden test for visual regression
testGoldens('login_screen_initial_light', (tester) async {
  // Arrange
  final widget = buildGoldenWidget(
    child: const LoginScreen(),
    theme: GoldenTheme.light,
    overrides: [
      authNotifierProvider.overrideWith(() => InitialAuthNotifier()),
    ],
  );

  // Act
  await tester.pumpWidgetBuilder(
    widget,
    surfaceSize: GoldenDevices.iPhone14.size,
  );
  await tester.pumpAndSettle();

  // Assert
  await screenMatchesGolden(tester, 'login_screen_initial_light');
});
```

### Testing Multiple States

```dart
// ✅ GOOD - Tests multiple visual states
group('LoginScreen golden tests', () {
  testGoldens('initial_state_light', (tester) async {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(
        child: const LoginScreen(),
        theme: GoldenTheme.light,
      ),
      surfaceSize: GoldenDevices.iPhone14.size,
    );
    await screenMatchesGolden(tester, 'login_initial_light');
  });

  testGoldens('initial_state_dark', (tester) async {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(
        child: const LoginScreen(),
        theme: GoldenTheme.dark,
      ),
      surfaceSize: GoldenDevices.iPhone14.size,
    );
    await screenMatchesGolden(tester, 'login_initial_dark');
  });

  testGoldens('loading_state', (tester) async {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(
        child: const LoginScreen(),
        overrides: [
          authNotifierProvider.overrideWith(() => AlwaysLoadingAuthNotifier()),
        ],
      ),
      surfaceSize: GoldenDevices.iPhone14.size,
    );
    await tester.pump(); // Don't settle - want to see loading state
    await screenMatchesGolden(tester, 'login_loading');
  });

  testGoldens('error_state', (tester) async {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(
        child: const LoginScreen(),
        overrides: [
          authNotifierProvider.overrideWith(
            () => ErrorAuthNotifier('Wrong password'),
          ),
        ],
      ),
      surfaceSize: GoldenDevices.iPhone14.size,
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'login_error');
  });

  testGoldens('filled_form', (tester) async {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(child: const LoginScreen()),
      surfaceSize: GoldenDevices.iPhone14.size,
    );
    await tester.pumpAndSettle();

    // Fill in form
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'login_filled');
  });
});
```

### Testing Multiple Devices

```dart
// ✅ GOOD - Tests responsive design
testGoldens('login_screen_responsive', (tester) async {
  for (final device in [
    GoldenDevices.iPhoneSE,
    GoldenDevices.iPhone14,
    GoldenDevices.iPhone14ProMax,
  ]) {
    await tester.pumpWidgetBuilder(
      buildGoldenWidget(child: const LoginScreen()),
      surfaceSize: device.size,
    );
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'login_${device.name}');
  }
});
```

---

## 6. Integration Tests

### Storage Integration Test

```dart
// ❌ BAD - Uses mocks for integration test
test('storage integration', () async {
  final mockPrefs = MockSharedPreferences();
  // This isn't testing real integration!
});

// ✅ GOOD - Uses real implementation
@Tags(['integration'])
void main() {
  late Directory tempDir;
  late SharedPreferences prefs;
  late SharedPrefsService sut;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sut = SharedPrefsService(prefs);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    await prefs.clear();
  });

  test('savedValue_persistsAcrossInstances', () async {
    // Arrange - save with one instance
    await sut.setBool(StorageKeys.hasUser, true);

    // Act - create new instance and read
    final sut2 = SharedPrefsService(prefs);
    final result = sut2.getBool(StorageKeys.hasUser);

    // Assert
    expect(result, isTrue);
  });

  test('remove_deletesValue', () async {
    // Arrange
    await sut.setString(StorageKeys.userId, anyUserId());

    // Act
    await sut.remove(StorageKeys.userId);

    // Assert
    expect(sut.getString(StorageKeys.userId), isNull);
  });
}
```

### Auth Flow Integration Test

```dart
@Tags(['integration'])
void main() {
  late ProviderContainer container;

  setUp(() {
    // Use real implementations with test doubles for external services
    container = ProviderContainer(
      overrides: [
        // Override only external dependencies
        supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('fullAuthFlow_signInThenOut_clearsState', () async {
    // Arrange
    final authNotifier = container.read(authNotifierProvider.notifier);

    // Act - sign in
    await authNotifier.signInWithEmail(anyEmail(), anyPassword());

    // Assert - authenticated
    var state = container.read(authNotifierProvider);
    expect(state, isA<AuthStateAuthenticated>());

    // Act - sign out
    await authNotifier.signOut();

    // Assert - back to initial
    state = container.read(authNotifierProvider);
    expect(state, const AuthState.initial());

    // Verify storage is cleared
    final hasUser = container.read(sharedPrefsProvider).getBool(StorageKeys.hasUser);
    expect(hasUser, isFalse);
  });
}
```

---

## 7. Async Testing Patterns

### Testing Concurrent Operations

```dart
// ❌ BAD - Race condition, flaky test
test('concurrent calls work', () async {
  await Future.wait([
    sut.operation1(),
    sut.operation2(),
  ]);
  // Results might vary!
});

// ✅ GOOD - Controlled concurrent testing
test('concurrentSignIn_onlyExecutesOnce', () async {
  // Arrange
  var callCount = 0;
  when(() => mockAuth.signInWithPassword(
    email: any(named: 'email'),
    password: any(named: 'password'),
  )).thenAnswer((_) async {
    callCount++;
    await Future.delayed(const Duration(milliseconds: 100));
    return anyAuthResponse();
  });

  // Act - start two sign-ins concurrently
  final results = await Future.wait([
    sut.signInWithEmail(anyEmail(), anyPassword()),
    sut.signInWithEmail(anyEmail(), anyPassword()),
  ]);

  // Assert - should only call once (debounced)
  expect(callCount, 1);
  expect(results[0], results[1]); // Same result
});
```

### Testing Timeouts

```dart
// ❌ BAD - Uses real delay
test('times out', () async {
  await Future.delayed(Duration(seconds: 30));
  // Takes forever!
});

// ✅ GOOD - Uses fake async
test('request_afterTimeout_throwsTimeoutException', () {
  fakeAsync((async) async {
    // Arrange
    when(() => mockDio.get(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 60));
      return Response(data: {}, requestOptions: RequestOptions(path: ''));
    });

    // Act
    final future = sut.fetchData();

    // Advance past timeout
    async.elapse(const Duration(seconds: 31));

    // Assert
    await expectLater(future, throwsA(isA<TimeoutException>()));
  });
});
```

---

## Quick Reference: Test Scenarios

### What to Test for Each Component Type

| Component | Test Scenarios |
|-----------|----------------|
| **Repository** | Success path, error paths, side effects, edge cases |
| **Service** | CRUD operations, error handling, persistence |
| **Provider** | Initial state, state transitions, error handling, disposal |
| **Widget** | Rendering, interactions, loading, errors, validation |
| **Golden** | Initial, loading, error, filled, themes, devices |

### Assertions Checklist

| Test Type | Verify |
|-----------|--------|
| **Unit** | Return values, thrown exceptions, method calls |
| **Provider** | State values, state transitions, side effects |
| **Widget** | Widget presence, text content, interactions work |
| **Golden** | Visual appearance matches snapshot |
| **Integration** | End-to-end flow works with real implementations |
