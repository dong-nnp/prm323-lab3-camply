import 'package:flutter/foundation.dart';

/// Opt in only after FlutterFire has generated real Android configuration.
/// No credentials or fabricated FirebaseOptions are stored in this foundation.
abstract final class FirebaseConfiguration {
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static const crashTestEnabled = bool.fromEnvironment(
    'ENABLE_CRASH_TEST',
    defaultValue: kDebugMode,
  );
}
