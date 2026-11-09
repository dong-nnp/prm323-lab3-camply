import 'package:flutter/foundation.dart';

/// Debug Android can opt in automatically when native configuration is present.
abstract final class FirebaseConfiguration {
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static const demoAuthEnabled =
      kDebugMode && bool.fromEnvironment('DEMO_AUTH');
  static const analyticsEnabled = bool.fromEnvironment(
    'ANALYTICS_ENABLED',
    defaultValue: kDebugMode,
  );
  static const crashTestEnabled = bool.fromEnvironment(
    'ENABLE_CRASH_TEST',
    defaultValue: kDebugMode,
  );

  static bool get detectAndroidConfig =>
      kDebugMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !demoAuthEnabled &&
      !const bool.hasEnvironment('FIREBASE_ENABLED');
}
