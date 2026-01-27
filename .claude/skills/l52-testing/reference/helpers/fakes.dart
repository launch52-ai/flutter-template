/// Spy/Fake implementations for testing.
///
/// Use these when you need to:
/// - Track the sequence of method calls
/// - Verify exact parameters passed
/// - Control completion timing in async flows
///
/// Pattern from Essential Feed: Spy classes with `receivedMessages` list.
library;

import '../../lib/features/auth/data/models/auth_result.dart';
import '../../lib/features/auth/data/models/user_profile.dart';
import '../../lib/features/auth/domain/repositories/auth_repository.dart';
import '../../lib/features/auth/domain/repositories/email_auth_repository.dart';
import '../../lib/features/auth/domain/repositories/phone_auth_repository.dart';

// =============================================================================
// AUTH REPOSITORY SPY
// =============================================================================

/// Spy implementation of auth repositories that tracks all method calls.
///
/// Usage:
/// ```dart
/// final spy = AuthRepositorySpy();
/// spy.completeSignIn(anyAuthResult()); // Set up success
/// await sut.signInWithEmail('a@b.com', 'pass');
/// expect(spy.receivedMessages, [
///   AuthMessage.signInWithEmail('a@b.com', 'pass'),
/// ]);
/// ```
final class AuthRepositorySpy
    implements AuthRepository, EmailAuthRepository, PhoneAuthRepository {
  /// All messages received by this spy, in order.
  final List<AuthMessage> receivedMessages = [];

  // ---------------------------------------------------------------------------
  // Result control
  // ---------------------------------------------------------------------------

  AuthResult? _signInResult;
  AuthResult? _signUpResult;
  AuthResult? _verifyOtpResult;
  Exception? _signInError;
  Exception? _signUpError;
  Exception? _sendOtpError;
  Exception? _verifyOtpError;
  bool _isAuthenticatedResult = false;
  UserProfile? _currentUserResult;

  /// Sets the result for signInWithEmail.
  void completeSignIn(AuthResult result) => _signInResult = result;

  /// Sets signInWithEmail to throw an error.
  void failSignIn(Exception error) => _signInError = error;

  /// Sets the result for signUpWithEmail.
  void completeSignUp(AuthResult result) => _signUpResult = result;

  /// Sets signUpWithEmail to throw an error.
  void failSignUp(Exception error) => _signUpError = error;

  /// Sets the result for isAuthenticated.
  void completeIsAuthenticated(bool value) => _isAuthenticatedResult = value;

  /// Sets the result for getCurrentUser.
  void completeGetCurrentUser(UserProfile? user) => _currentUserResult = user;

  /// Sets sendOtp to throw an error.
  void failSendOtp(Exception error) => _sendOtpError = error;

  /// Sets the result for verifyOtp.
  void completeVerifyOtp(AuthResult result) => _verifyOtpResult = result;

  /// Sets verifyOtp to throw an error.
  void failVerifyOtp(Exception error) => _verifyOtpError = error;

  // ---------------------------------------------------------------------------
  // AuthRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    receivedMessages.add(const AuthMessage.signOut());
  }

  @override
  Future<bool> isAuthenticated() async {
    receivedMessages.add(const AuthMessage.isAuthenticated());
    return _isAuthenticatedResult;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    receivedMessages.add(const AuthMessage.getCurrentUser());
    return _currentUserResult;
  }

  // ---------------------------------------------------------------------------
  // EmailAuthRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    receivedMessages.add(AuthMessage.signInWithEmail(email, password));
    if (_signInError != null) throw _signInError!;
    return _signInResult!;
  }

  @override
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    receivedMessages.add(AuthMessage.signUpWithEmail(email, password));
    if (_signUpError != null) throw _signUpError!;
    return _signUpResult!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    receivedMessages.add(AuthMessage.sendPasswordResetEmail(email));
  }

  // ---------------------------------------------------------------------------
  // PhoneAuthRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendOtp(String phoneNumber) async {
    receivedMessages.add(AuthMessage.sendOtp(phoneNumber));
    if (_sendOtpError != null) throw _sendOtpError!;
  }

  @override
  Future<AuthResult> verifyOtp(String phoneNumber, String otp) async {
    receivedMessages.add(AuthMessage.verifyOtp(phoneNumber, otp));
    if (_verifyOtpError != null) throw _verifyOtpError!;
    return _verifyOtpResult!;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Clears all received messages.
  void reset() {
    receivedMessages.clear();
    _signInResult = null;
    _signUpResult = null;
    _verifyOtpResult = null;
    _signInError = null;
    _signUpError = null;
    _sendOtpError = null;
    _verifyOtpError = null;
    _isAuthenticatedResult = false;
    _currentUserResult = null;
  }
}

// =============================================================================
// AUTH MESSAGES
// =============================================================================

/// Messages tracked by [AuthRepositorySpy].
///
/// Sealed class allows exhaustive pattern matching in assertions.
sealed class AuthMessage {
  const AuthMessage();

  // Factory constructors
  const factory AuthMessage.signOut() = SignOutMessage;
  const factory AuthMessage.isAuthenticated() = IsAuthenticatedMessage;
  const factory AuthMessage.getCurrentUser() = GetCurrentUserMessage;
  const factory AuthMessage.signInWithEmail(String email, String password) =
      SignInWithEmailMessage;
  const factory AuthMessage.signUpWithEmail(String email, String password) =
      SignUpWithEmailMessage;
  const factory AuthMessage.sendPasswordResetEmail(String email) =
      SendPasswordResetEmailMessage;
  const factory AuthMessage.sendOtp(String phoneNumber) = SendOtpMessage;
  const factory AuthMessage.verifyOtp(String phoneNumber, String otp) =
      VerifyOtpMessage;
}

final class SignOutMessage extends AuthMessage {
  const SignOutMessage();

  @override
  bool operator ==(Object other) => other is SignOutMessage;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SignOutMessage()';
}

final class IsAuthenticatedMessage extends AuthMessage {
  const IsAuthenticatedMessage();

  @override
  bool operator ==(Object other) => other is IsAuthenticatedMessage;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'IsAuthenticatedMessage()';
}

final class GetCurrentUserMessage extends AuthMessage {
  const GetCurrentUserMessage();

  @override
  bool operator ==(Object other) => other is GetCurrentUserMessage;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'GetCurrentUserMessage()';
}

final class SignInWithEmailMessage extends AuthMessage {
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
  String toString() => 'SignInWithEmailMessage($email, $password)';
}

final class SignUpWithEmailMessage extends AuthMessage {
  final String email;
  final String password;

  const SignUpWithEmailMessage(this.email, this.password);

  @override
  bool operator ==(Object other) =>
      other is SignUpWithEmailMessage &&
      other.email == email &&
      other.password == password;

  @override
  int get hashCode => Object.hash(email, password);

  @override
  String toString() => 'SignUpWithEmailMessage($email, $password)';
}

final class SendPasswordResetEmailMessage extends AuthMessage {
  final String email;

  const SendPasswordResetEmailMessage(this.email);

  @override
  bool operator ==(Object other) =>
      other is SendPasswordResetEmailMessage && other.email == email;

  @override
  int get hashCode => email.hashCode;

  @override
  String toString() => 'SendPasswordResetEmailMessage($email)';
}

final class SendOtpMessage extends AuthMessage {
  final String phoneNumber;

  const SendOtpMessage(this.phoneNumber);

  @override
  bool operator ==(Object other) =>
      other is SendOtpMessage && other.phoneNumber == phoneNumber;

  @override
  int get hashCode => phoneNumber.hashCode;

  @override
  String toString() => 'SendOtpMessage($phoneNumber)';
}

final class VerifyOtpMessage extends AuthMessage {
  final String phoneNumber;
  final String otp;

  const VerifyOtpMessage(this.phoneNumber, this.otp);

  @override
  bool operator ==(Object other) =>
      other is VerifyOtpMessage &&
      other.phoneNumber == phoneNumber &&
      other.otp == otp;

  @override
  int get hashCode => Object.hash(phoneNumber, otp);

  @override
  String toString() => 'VerifyOtpMessage($phoneNumber, $otp)';
}

// =============================================================================
// STORAGE SPY
// =============================================================================

/// Spy implementation for SecureStorageService.
final class SecureStorageSpy {
  final List<StorageMessage> receivedMessages = [];
  final Map<String, String> _storage = {};

  Future<void> write({required String key, required String value}) async {
    receivedMessages.add(StorageMessage.write(key, value));
    _storage[key] = value;
  }

  Future<String?> read({required String key}) async {
    receivedMessages.add(StorageMessage.read(key));
    return _storage[key];
  }

  Future<void> delete({required String key}) async {
    receivedMessages.add(StorageMessage.delete(key));
    _storage.remove(key);
  }

  Future<void> deleteAll() async {
    receivedMessages.add(const StorageMessage.deleteAll());
    _storage.clear();
  }

  /// Pre-populate storage for testing.
  void seed(Map<String, String> data) => _storage.addAll(data);

  void reset() {
    receivedMessages.clear();
    _storage.clear();
  }
}

/// Messages tracked by [SecureStorageSpy].
sealed class StorageMessage {
  const StorageMessage();

  const factory StorageMessage.write(String key, String value) =
      StorageWriteMessage;
  const factory StorageMessage.read(String key) = StorageReadMessage;
  const factory StorageMessage.delete(String key) = StorageDeleteMessage;
  const factory StorageMessage.deleteAll() = StorageDeleteAllMessage;
}

final class StorageWriteMessage extends StorageMessage {
  final String key;
  final String value;

  const StorageWriteMessage(this.key, this.value);

  @override
  bool operator ==(Object other) =>
      other is StorageWriteMessage && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => 'StorageWriteMessage($key, $value)';
}

final class StorageReadMessage extends StorageMessage {
  final String key;

  const StorageReadMessage(this.key);

  @override
  bool operator ==(Object other) =>
      other is StorageReadMessage && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'StorageReadMessage($key)';
}

final class StorageDeleteMessage extends StorageMessage {
  final String key;

  const StorageDeleteMessage(this.key);

  @override
  bool operator ==(Object other) =>
      other is StorageDeleteMessage && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'StorageDeleteMessage($key)';
}

final class StorageDeleteAllMessage extends StorageMessage {
  const StorageDeleteAllMessage();

  @override
  bool operator ==(Object other) => other is StorageDeleteAllMessage;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'StorageDeleteAllMessage()';
}
