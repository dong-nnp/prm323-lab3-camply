import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/authentication_repository.dart';
import '../../repositories/analytics_repository.dart';
import '../../repositories/report_export_repository.dart';
import '../../repositories/bootstrap_repository.dart';
import '../../repositories/campus_repository.dart';
import '../../repositories/flow1_repository.dart';
import '../../repositories/push_notification_repository.dart';
import 'service_providers.dart';

final analyticsRepositoryProvider = Provider(
  (ref) => AnalyticsRepository(
    ref.watch(analyticsServiceProvider),
    enabled: ref.watch(analyticsEnabledProvider),
  ),
);
final reportExportRepositoryProvider = Provider(
  (ref) => ReportExportRepository(ref.watch(reportExportServiceProvider)),
);

final bootstrapRepositoryProvider = Provider(
  (ref) => BootstrapRepository(
    ref.watch(firebaseInitializerProvider),
    crashReporting: ref.watch(crashReportingServiceProvider),
  ),
);

final authenticationRepositoryProvider = Provider(
  (ref) => AuthenticationRepository(
    ref.watch(authenticationServiceProvider),
    beforeSignOut: ref.watch(realBackendEnabledProvider)
        ? ref.watch(pushNotificationRepositoryProvider).detach
        : null,
  ),
);
final pushNotificationRepositoryProvider = Provider(
  (ref) => PushNotificationRepository(
    ref.watch(messagingServiceProvider),
    ref.watch(backendServiceProvider),
  ),
);
final campusRepositoryProvider = Provider(
  (ref) => CampusRepository(ref.watch(campusServiceProvider)),
);
final flow1RepositoryProvider = Provider(
  (ref) => Flow1Repository(
    ref.watch(backendServiceProvider),
    crashReporting: ref.watch(crashReportingServiceProvider),
  ),
);
