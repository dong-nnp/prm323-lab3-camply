import '../../services/ai_filter_service.dart';
import '../../services/firebase_ai_filter_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/demo_authentication_service.dart';

import '../../firebase/firebase_configuration.dart';
import '../../services/analytics_service.dart';
import '../../services/report_export_service.dart';
import '../../services/firebase_analytics_service.dart';
import '../../services/authentication_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/firebase_crash_reporting_service.dart';
import '../../services/firebase_initialization_service.dart';
import '../../services/firebase_initializer.dart';
import '../../services/messaging_service.dart';
import '../../services/pending_firebase_services.dart';
import '../../services/remote_config_service.dart';
import '../../services/firebase_remote_config_service.dart';
import '../../services/storage_service.dart';
import '../../services/campus_service.dart';
import '../../services/backend_service.dart';
import '../../services/firebase_backend_service.dart';
import '../../services/firebase_authentication_service.dart';
import '../../services/firebase_messaging_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/unavailable_backend_service.dart';

final firebaseEnabledProvider = Provider<bool>(
  (ref) => FirebaseConfiguration.enabled,
);

final firebaseInitializerProvider = Provider<FirebaseInitializer>(
  (ref) => FirebaseInitializationService(
    enabled: ref.watch(firebaseEnabledProvider),
    onReady: ref.watch(_androidCrashReportingProvider)?.start,
  ),
);

// Replace each adapter independently after implementing its real service.
// Tests can override individual interface providers with deterministic fakes.
final _pendingServicesProvider = Provider(
  (ref) => const PendingFirebaseServices(),
);

final demoAuthEnabledProvider = Provider<bool>(
  (ref) => FirebaseConfiguration.demoAuthEnabled,
);
final realBackendEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(firebaseEnabledProvider) && !ref.watch(demoAuthEnabledProvider),
);
final _firebaseReadyProvider = Provider<Future<void> Function()>((ref) {
  Future<void>? ready;
  return () => ready ??= ref
      .read(firebaseInitializerProvider)
      .initialize()
      .then<void>((_) {})
      .catchError((Object error, StackTrace stack) {
        ready = null;
        Error.throwWithStackTrace(error, stack);
      });
});
final backendServiceProvider = Provider<BackendService>(
  (ref) => ref.watch(realBackendEnabledProvider)
      ? FirebaseBackendService(ref.watch(_firebaseReadyProvider))
      : const UnavailableBackendService(),
);

final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  if (!ref.watch(demoAuthEnabledProvider)) {
    if (ref.watch(realBackendEnabledProvider)) {
      return FirebaseAuthenticationService(
        ref.watch(_firebaseReadyProvider),
        ref.watch(backendServiceProvider),
      );
    }
    return ref.watch(_pendingServicesProvider);
  }
  final service = DemoAuthenticationService();
  ref.onDispose(service.dispose);
  return service;
});
final storageServiceProvider = Provider<StorageService>(
  (ref) => ref.watch(realBackendEnabledProvider)
      ? FirebaseStorageService(ref.watch(_firebaseReadyProvider))
      : ref.watch(_pendingServicesProvider),
);
final messagingServiceProvider = Provider<MessagingService>(
  (ref) => ref.watch(realBackendEnabledProvider)
      ? FirebaseMessagingService(ref.watch(_firebaseReadyProvider))
      : ref.watch(_pendingServicesProvider),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => ref.watch(analyticsEnabledProvider)
      ? FirebaseAnalyticsService(ref.watch(_firebaseReadyProvider))
      : ref.watch(_pendingServicesProvider),
);
final analyticsEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(realBackendEnabledProvider) &&
      FirebaseConfiguration.analyticsEnabled,
);
final reportExportServiceProvider = Provider<ReportExportService>(
  (ref) => AndroidReportExportService(),
);
final _androidCrashReportingProvider = Provider<FirebaseCrashReportingService?>(
  (ref) {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !ref.watch(realBackendEnabledProvider)) {
      return null;
    }
    final service = FirebaseCrashReportingService();
    ref.onDispose(service.dispose);
    return service;
  },
);

final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) =>
      ref.watch(_androidCrashReportingProvider) ??
      ref.watch(_pendingServicesProvider),
);
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => ref.watch(realBackendEnabledProvider)
      ? FirebaseRemoteConfigService(ref.watch(_firebaseReadyProvider))
      : ref.watch(_pendingServicesProvider),
);
final campusServiceProvider = Provider<CampusService>(
  (ref) => ref.watch(_pendingServicesProvider),
);

final aiFilterServiceProvider = Provider<AiFilterService>(
  (ref) => FirebaseAiFilterService(
    ref.watch(_firebaseReadyProvider),
    ref.watch(remoteConfigServiceProvider),
  ),
);
