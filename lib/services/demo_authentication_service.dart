import 'dart:async';

import '../core/errors/app_exception.dart';
import '../data/mock/registration_mock_data.dart';
import '../models/account_creation_result.dart';
import '../models/auth_session.dart';
import 'authentication_service.dart';
import 'pending_firebase_services.dart';

/// Local UI preview only; never issues Firebase credentials or backend access.
final class DemoAuthenticationService implements AuthenticationService {
  static const email = RegistrationMockData.email;
  static const password = 'EviaDemo123!';
  final _changes = StreamController<void>.broadcast();
  AuthSession _session = const AuthSession.signedOut();

  @override
  int? get minimumPasswordLength => null;

  @override
  Stream<AuthSession> watchSession() => Stream.multi((controller) {
    final subscription = _changes.stream.listen(
      (_) => controller.add(_session),
    );
    controller.add(_session);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    if (email.trim().toLowerCase() != DemoAuthenticationService.email ||
        password != DemoAuthenticationService.password) {
      throw const AppException(
        code: 'invalid_credentials',
        message: 'Incorrect demo email or password.',
      );
    }
    _session = const AuthSession.signedIn(
      'demo-alex-morgan',
      personalizationHandled: true,
    );
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    _session = const AuthSession.signedOut();
    _changes.add(null);
  }

  @override
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) => const PendingFirebaseServices().createAccount(
    fullName: fullName,
    email: email,
    password: password,
    acceptedTerms: acceptedTerms,
  );

  @override
  Future<void> signInWithGoogle() =>
      const PendingFirebaseServices().signInWithGoogle();

  @override
  Future<void> resetPassword(String email) =>
      const PendingFirebaseServices().resetPassword(email);

  Future<void> dispose() => _changes.close();
}
