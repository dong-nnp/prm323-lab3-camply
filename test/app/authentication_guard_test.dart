import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/authentication_guard.dart';
import 'package:prm393_lab03/core/constants/app_routes.dart';
import 'package:prm393_lab03/models/auth_session.dart';

void main() {
  test('public foundation remains accessible before authentication', () {
    expect(
      AuthenticationGuard.redirect(
        requiresAuthentication: false,
        session: null,
      ),
      isNull,
    );
  });

  test(
    'unknown, unavailable and signed-out sessions cannot enter private UI',
    () {
      for (final session in <AuthSession?>[
        null,
        const AuthSession.unavailable(),
        const AuthSession.signedOut(),
      ]) {
        expect(
          AuthenticationGuard.redirect(
            requiresAuthentication: true,
            session: session,
          ),
          AppRoutes.login,
        );
      }
    },
  );

  test('authenticated session can enter a protected route', () {
    expect(
      AuthenticationGuard.redirect(
        requiresAuthentication: true,
        session: const AuthSession.signedIn('test-user'),
      ),
      isNull,
    );
  });
}
