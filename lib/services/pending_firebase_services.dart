import 'dart:typed_data';

import '../core/constants/app_strings.dart';
import '../core/errors/app_exception.dart';
import '../models/auth_session.dart';
import '../models/account_creation_result.dart';
import 'analytics_service.dart';
import 'authentication_service.dart';
import 'crash_reporting_service.dart';
import 'messaging_service.dart';
import 'remote_config_service.dart';
import 'storage_service.dart';
import 'campus_service.dart';
import '../models/activity_models.dart';

/// Explicitly unavailable adapters until each real integration is implemented.
/// This is neither a mock backend nor a successful no-op implementation.
final class PendingFirebaseServices
    implements
        AuthenticationService,
        StorageService,
        MessagingService,
        AnalyticsService,
        CrashReportingService,
        RemoteConfigService,
        CampusService {
  const PendingFirebaseServices();

  AppException get _pending => const AppException(
    code: 'firebase_service_pending',
    message: AppStrings.servicePending,
  );

  @override
  int? get minimumPasswordLength => null;

  @override
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async => throw _pending;

  @override
  Stream<AuthSession> watchSession() =>
      Stream.value(const AuthSession.unavailable());

  @override
  Future<void> signInWithEmailPassword(String email, String password) async =>
      throw _pending;

  @override
  Future<void> signInWithGoogle() async => throw _pending;

  @override
  Future<void> resetPassword(String email) async => throw _pending;

  @override
  Future<void> signOut() async => throw _pending;

  @override
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async => throw _pending;

  @override
  Future<bool> requestPermission() async => throw _pending;

  @override
  Future<String?> getToken() async => throw _pending;
  @override
  Stream<String> get tokenChanges => Stream.error(_pending);
  @override
  Stream<Map<String, String>> get foregroundMessages => Stream.error(_pending);
  @override
  Stream<Map<String, String>> get openedMessages => Stream.error(_pending);
  @override
  Future<Map<String, String>?> initialMessage() async => throw _pending;
  @override
  Future<void> disable() async => throw _pending;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async =>
      throw _pending;

  @override
  Future<void> recordError(Object error, StackTrace stackTrace) async =>
      throw _pending;

  @override
  Future<bool> fetchAndActivate() async => throw _pending;

  @override
  String getString(String key) => throw _pending;

  @override
  Future<void> saveInterests(Set<String> interestIds) async => throw _pending;

  @override
  Future<MilestoneClaimResult> claimEventMilestone({
    required String milestoneId,
    required int expectedVersion,
  }) async => throw _pending;
}
