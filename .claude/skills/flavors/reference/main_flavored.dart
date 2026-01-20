// Template: main_flavored.dart
// Location: lib/main.dart
//
// Example main.dart with flavor configuration.
// This replaces flutter_dotenv with compile-time variables.
//
// Usage:
//   flutter run --flavor dev --dart-define-from-file=.env.dev
//   flutter run --flavor prod --dart-define-from-file=.env.prod

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Uncomment if using Supabase:
// import 'package:supabase_flutter/supabase_flutter.dart';
// Uncomment if using Firebase:
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app.dart';
import 'core/config/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print config in non-production builds
  if (kDebugMode) {
    FlavorConfig.printConfig();
  }

  // Initialize services based on flavor configuration
  await _initializeServices();

  // Run the app
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _initializeServices() async {
  // ===========================================================================
  // SUPABASE INITIALIZATION
  // ===========================================================================

  if (FlavorConfig.hasSupabase) {
    // Uncomment when using Supabase:
    // await Supabase.initialize(
    //   url: FlavorConfig.supabaseUrl,
    //   anonKey: FlavorConfig.supabaseAnonKey,
    //   debug: FlavorConfig.enableLogging,
    // );
    //
    // if (kDebugMode) {
    //   debugPrint('Supabase initialized for ${FlavorConfig.flavorName}');
    // }
  }

  // ===========================================================================
  // FIREBASE INITIALIZATION
  // ===========================================================================

  // Uncomment when using Firebase:
  // await Firebase.initializeApp();
  //
  // // Configure Crashlytics
  // if (FlavorConfig.enableAnalytics) {
  //   // Pass all uncaught "fatal" errors to Crashlytics
  //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //
  //   // Pass all uncaught asynchronous errors to Crashlytics
  //   PlatformDispatcher.instance.onError = (error, stack) {
  //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //     return true;
  //   };
  // } else {
  //   // Disable Crashlytics in dev/staging
  //   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  // }
  //
  // if (kDebugMode) {
  //   final app = Firebase.app();
  //   debugPrint('Firebase project: ${app.options.projectId}');
  // }

  // ===========================================================================
  // ANALYTICS INITIALIZATION
  // ===========================================================================

  // Uncomment when using Firebase Analytics:
  // if (!FlavorConfig.enableAnalytics) {
  //   await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  // }

  // ===========================================================================
  // OTHER SERVICE INITIALIZATION
  // ===========================================================================

  // Add other service initialization here...
}
