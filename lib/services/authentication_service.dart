import '../models/auth_session.dart';
import '../models/account_creation_result.dart';

abstract interface class AuthenticationService {
  /// Null means no backend password policy has been configured, not zero.
  int? get minimumPasswordLength;
  Stream<AuthSession> watchSession();

  /// Real adapters map account conflicts/weak passwords to safe AppExceptions
  /// (email_already_in_use, invalid_email, weak_password). Never emit a usable
  /// signed-in session before required email verification is complete.
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
