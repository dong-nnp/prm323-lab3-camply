import '../models/auth_session.dart';

abstract interface class AuthenticationService {
  Stream<AuthSession> watchSession();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
