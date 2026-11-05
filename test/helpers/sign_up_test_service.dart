import 'dart:async';

import 'package:prm393_lab03/models/account_creation_result.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/services/authentication_service.dart';

/// Test-only outcomes, never used by runtime providers.
class SignUpTestService implements AuthenticationService {
  final _sessions = StreamController<AuthSession>.broadcast();
  AuthSession session = const AuthSession.signedOut();
  Future<AccountCreationResult> Function()? create;
  Future<void> Function()? google;
  int createCalls = 0, googleCalls = 0;
  String? submittedName, submittedEmail;
  bool? submittedTerms;
  @override
  int? minimumPasswordLength;
  @override
  Stream<AuthSession> watchSession() async* {
    yield session;
    yield* _sessions.stream;
  }

  void publish(AuthSession value) {
    session = value;
    _sessions.add(value);
  }

  @override
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) {
    createCalls++;
    submittedName = fullName;
    submittedEmail = email;
    submittedTerms = acceptedTerms;
    return create?.call() ?? Future.value(AccountCreationResult.signedIn);
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    await google?.call();
  }

  @override
  Future<void> signOut() async => publish(const AuthSession.signedOut());
  @override
  Future<void> resetPassword(String email) async => throw UnimplementedError();
  Future<void> close() => _sessions.close();
}
