import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';

class StartupTestAuth extends AuthenticationViewModel {
  StartupTestAuth(this.sessions);
  final Stream<AuthSession> sessions;
  @override
  Stream<AuthSession> build() => sessions;
}

final signedInTestSession = authenticationViewModelProvider.overrideWith(
  () => StartupTestAuth(
    Stream.value(
      const AuthSession.signedIn('test-user', personalizationHandled: true),
    ),
  ),
);
