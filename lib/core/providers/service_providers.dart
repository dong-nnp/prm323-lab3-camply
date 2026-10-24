import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase/firebase_configuration.dart';
import '../../services/analytics_service.dart';
import '../../services/authentication_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/firebase_initialization_service.dart';
import '../../services/firebase_initializer.dart';
import '../../services/messaging_service.dart';
import '../../services/pending_firebase_services.dart';
import '../../services/remote_config_service.dart';
import '../../services/storage_service.dart';

final firebaseInitializerProvider = Provider<FirebaseInitializer>(
  (ref) => const FirebaseInitializationService(
    enabled: FirebaseConfiguration.enabled,
  ),
);

// Replace each adapter independently after implementing its real service.
// Tests can override individual interface providers with deterministic fakes.
final _pendingServicesProvider = Provider(
  (ref) => const PendingFirebaseServices(),
);

final authenticationServiceProvider = Provider<AuthenticationService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
final messagingServiceProvider = Provider<MessagingService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => ref.watch(_pendingServicesProvider),
);
