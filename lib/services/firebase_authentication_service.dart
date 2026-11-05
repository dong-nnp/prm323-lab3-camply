import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/fpt_identity.dart';
import '../models/auth_session.dart';
import '../models/account_creation_result.dart';
import 'authentication_service.dart';
import 'backend_service.dart';

class FirebaseAuthenticationService implements AuthenticationService {
  FirebaseAuthenticationService(this.ready, this.backend);
  final Future<void> Function() ready;
  final BackendService backend;
  Future<void>? _googleReady;
  @override
  int? get minimumPasswordLength => null;

  AppException _error(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      final code = error.code.replaceAll('-', '_');
      const messages = {
        'invalid_credential': 'Incorrect email or password.',
        'wrong_password': 'Incorrect email or password.',
        'user_not_found': 'Incorrect email or password.',
        'email_already_in_use': 'An account already uses this email.',
        'weak_password': 'Choose a stronger password.',
        'network_request_failed': 'Check your connection and try again.',
        'too_many_requests':
            'Too many attempts. Wait a moment before retrying.',
        'user_disabled': 'This account is unavailable.',
        'account_exists_with_different_credential':
            'Log in with your original sign-in method.',
      };
      return AppException(
        code: code,
        message: messages[code] ?? 'Authentication failed. Please retry.',
      );
    }
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return const AppException(
        code: 'cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    return const AppException(
      code: 'authentication_failed',
      message: 'Could not sign in. Please retry.',
    );
  }

  void _checkEmail(String? email) {
    if (email == null || !FptIdentity.validEmail(email)) {
      throw const AppException(
        code: 'invalid_email',
        message: 'Enter a valid email address.',
      );
    }
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    await ready();
    try {
      return await action();
    } catch (error) {
      throw _error(error);
    }
  }

  @override
  Stream<AuthSession> watchSession() async* {
    await ready();
    yield* FirebaseAuth.instance.userChanges().asyncMap((user) async {
      if (user == null) return const AuthSession.signedOut();
      try {
        _checkEmail(user.email);
        final initialized = await backend.call('initializeUser');
        if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
          return const AuthSession.signedOut();
        }
        final profile = initialized['profile'] as Map;
        return AuthSession.signedIn(
          user.uid,
          personalizationHandled: profile['onboardingCompleted'] == true,
        );
      } catch (error) {
        throw _error(error);
      }
    });
  }

  @override
  Future<void> signInWithEmailPassword(String email, String password) =>
      _run(() async {
        _checkEmail(email);
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: FptIdentity.email(email),
          password: password,
        );
        await backend.call('initializeUser');
      });
  @override
  Future<AccountCreationResult> createAccount({
    required String fullName,
    required String email,
    required String password,
    required bool acceptedTerms,
  }) => _run(() async {
    _checkEmail(email);
    if (!acceptedTerms) {
      throw const AppException(
        code: 'terms_required',
        message: 'Accept the terms before creating an account.',
      );
    }
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: FptIdentity.email(email),
          password: password,
        );
    await credential.user!.updateDisplayName(fullName.trim());
    await backend.call('initializeUser');
    await backend.call('updateProfile', {'displayName': fullName.trim()});
    return AccountCreationResult.signedIn;
  });
  @override
  Future<void> signInWithGoogle() => _run(() async {
    _googleReady ??= GoogleSignIn.instance.initialize();
    await _googleReady;
    final google = await GoogleSignIn.instance.authenticate();
    try {
      _checkEmail(google.email);
    } catch (_) {
      await GoogleSignIn.instance.signOut();
      rethrow;
    }
    final credential = GoogleAuthProvider.credential(
      idToken: google.authentication.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    await backend.call('initializeUser');
  });
  @override
  Future<void> resetPassword(String email) => _run(() async {
    _checkEmail(email);
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: FptIdentity.email(email),
    );
  });
  @override
  Future<void> signOut() => _run(() async {
    await FirebaseAuth.instance.signOut();
    if (_googleReady != null) await GoogleSignIn.instance.signOut();
  });
}
