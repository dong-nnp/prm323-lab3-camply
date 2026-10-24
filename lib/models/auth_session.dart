enum AuthStatus { unavailable, signedOut, signedIn }

/// Domain model; never exposes a Firebase User to a ViewModel or Widget.
final class AuthSession {
  const AuthSession.unavailable()
    : status = AuthStatus.unavailable,
      userId = null;

  const AuthSession.signedOut() : status = AuthStatus.signedOut, userId = null;

  const AuthSession.signedIn(String uid)
    : assert(uid != ''),
      status = AuthStatus.signedIn,
      userId = uid;

  final AuthStatus status;
  final String? userId;
}
