import '../models/auth_session.dart';
import '../models/account_creation_result.dart';
import '../services/authentication_service.dart';

final class AuthenticationRepository {
  const AuthenticationRepository(this._service);

  final AuthenticationService _service;

  int? get minimumPasswordLength => _service.minimumPasswordLength;
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) => _service.createAccount(
    fullName: fullName,
    email: email,
    password: password,
    acceptedTerms: acceptedTerms,
  );

  Stream<AuthSession> watchSession() => _service.watchSession();
  Future<void> signInWithGoogle() => _service.signInWithGoogle();
  Future<void> signOut() => _service.signOut();
}
