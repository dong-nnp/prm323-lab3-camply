import '../models/firebase_status.dart';
import '../services/crash_reporting_service.dart';
import '../services/firebase_initializer.dart';

final class BootstrapRepository {
  const BootstrapRepository(this._initializer, {this._crashReporting});

  final FirebaseInitializer _initializer;
  final CrashReportingService? _crashReporting;

  Future<FirebaseStatus> initialize() => _initializer.initialize();

  Future<void> triggerTestCrash() async {
    await initialize();
    await _crashReporting?.triggerTestCrash();
  }
}
