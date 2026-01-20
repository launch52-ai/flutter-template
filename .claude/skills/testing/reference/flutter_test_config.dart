/// Global test configuration.
///
/// This file is automatically loaded by Flutter test runner.
/// It configures golden tests to load fonts properly.
import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Load fonts for golden tests
  await loadAppFonts();

  return testMain();
}
