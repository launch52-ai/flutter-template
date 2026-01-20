// Template: App Widget
//
// Location: lib/app.dart
//
// Usage:
// 1. Copy to target location
// 2. Import theme and router
// 3. Update main.dart to use App()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root application widget.
/// Configures theme, router, and global settings.
final class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '{APP_NAME}', // TODO: Replace with actual app name

      // Theme configuration
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // or ThemeMode.light / ThemeMode.dark

      // Router configuration
      routerConfig: router,

      // Disable debug banner
      debugShowCheckedModeBanner: false,

      // Localization (uncomment after running /i18n)
      // locale: TranslationProvider.of(context).flutterLocale,
      // supportedLocales: AppLocaleUtils.supportedLocales,
      // localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
