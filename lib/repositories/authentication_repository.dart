import '../models/auth_session.dart';
import '../services/authentication_service.dart';

final class AuthenticationRepository {
  const AuthenticationRepository(this._service);

  final AuthenticationService _service;

  Stream<AuthSession> watchSession() => _service.watchSession();
  Future<void> signInWithGoogle() => _service.signInWithGoogle();
  Future<void> signOut() => _service.signOut();
}
