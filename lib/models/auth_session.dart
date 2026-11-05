enum AuthStatus { unavailable, signedOut, signedIn }

/// Domain model; never exposes a Firebase User to a ViewModel or Widget.
final class AuthSession {
  const AuthSession.unavailable()
    : status = AuthStatus.unavailable,
      personalizationHandled = false,
      userId = null;

  const AuthSession.signedOut()
    : status = AuthStatus.signedOut,
      personalizationHandled = false,
      userId = null;

  const AuthSession.signedIn(String uid, {this.personalizationHandled = false})
    : assert(uid != ''),
      status = AuthStatus.signedIn,
      userId = uid;

  final AuthStatus status;
  final String? userId;

  /// Populate from the real account profile when its adapter is integrated.
  /// Never infer completion from the demo interest selections.
  final bool personalizationHandled;
}
