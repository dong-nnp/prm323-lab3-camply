import 'package:firebase_core/firebase_core.dart';

import '../core/constants/app_strings.dart';
import '../core/errors/app_exception.dart';
import '../models/firebase_status.dart';
import 'firebase_initializer.dart';

/// On Android, FlutterFire's google-services Gradle plugin supplies options
/// from the real google-services.json. No generated Dart file is required here.
final class FirebaseInitializationService implements FirebaseInitializer {
  const FirebaseInitializationService({required this.enabled, this.onReady});

  final bool enabled;
  final Future<void> Function()? onReady;

  @override
  Future<FirebaseStatus> initialize() async {
    if (!enabled) return FirebaseStatus.notConfigured;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      }
    } on Exception {
      throw const AppException(
        code: 'firebase_initialization',
        message: AppStrings.initializationError,
      );
    }
    await onReady?.call();
    return FirebaseStatus.ready;
  }
}
