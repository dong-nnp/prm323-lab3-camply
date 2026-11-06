import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporting_service.dart';

final class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashlytics? _sdk;
  Future<void>? _startup;
  StreamSubscription<void>? _authSubscription;

  Future<void> start() => _startup ??= _ignoreReportingFailure(_start);

  Future<void> _start() async {
    final sdk = FirebaseCrashlytics.instance;
    if (!sdk.isCrashlyticsCollectionEnabled) return;
    final auth = FirebaseAuth.instance;
    await sdk.setCustomKey('app_surface', 'mobile_android');
    await sdk.setUserIdentifier(auth.currentUser?.uid ?? '');
    _authSubscription = auth
        .authStateChanges()
        .asyncMap((user) async {
          await _ignoreReportingFailure(
            () => sdk.setUserIdentifier(user?.uid ?? ''),
          );
        })
        .listen((_) {}, onError: (Object _, StackTrace _) {});

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      unawaited(
        _ignoreReportingFailure(() => sdk.recordFlutterFatalError(details)),
      );
    };
    final dispatcher = PlatformDispatcher.instance;
    final previousPlatformHandler = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      unawaited(
        _ignoreReportingFailure(
          () => sdk.recordError(error, stack, fatal: true),
        ),
      );
      return previousPlatformHandler?.call(error, stack) ?? false;
    };
    _sdk = sdk;
  }

  Future<void> _ignoreReportingFailure(Future<void> Function() report) async {
    try {
      await report();
    } catch (_) {
      // Telemetry must not replace the original error or block recovery.
    }
  }

  @override
  Future<void> recordError(Object error, StackTrace stackTrace) async {
    final sdk = _sdk;
    if (sdk == null) return;
    await sdk.recordError(error, stackTrace);
  }

  void dispose() {
    unawaited(_authSubscription?.cancel());
  }
}
