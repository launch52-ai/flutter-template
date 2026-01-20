// Template: Supabase Service
//
// Location: lib/core/services/supabase_service.dart
//
// Usage:
// 1. Copy to target location (only if using Supabase)
// 2. Ensure Supabase is initialized in main.dart
// 3. Register provider in core/providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_service.g.dart';

/// Supabase client provider.
/// Provides access to auth, database, storage, etc.
///
/// Example:
/// ```dart
/// final supabase = ref.watch(supabaseClientProvider);
/// final user = supabase.auth.currentUser;
/// ```
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// Supabase auth provider.
/// Convenience provider for auth operations.
///
/// Example:
/// ```dart
/// final auth = ref.watch(supabaseAuthProvider);
/// await auth.signOut();
/// ```
@riverpod
GoTrueClient supabaseAuth(Ref ref) {
  return Supabase.instance.client.auth;
}

/// Current user provider.
/// Returns null if not authenticated.
///
/// Example:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// if (user != null) { ... }
/// ```
@riverpod
User? currentUser(Ref ref) {
  return Supabase.instance.client.auth.currentUser;
}

/// Auth state changes stream provider.
/// Listens to auth state changes.
///
/// Example:
/// ```dart
/// ref.listen(authStateChangesProvider, (_, state) {
///   state.whenData((event) {
///     if (event.event == AuthChangeEvent.signedOut) {
///       context.go('/login');
///     }
///   });
/// });
/// ```
@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}
