import '../core/constants/app_routes.dart';
import '../models/auth_session.dart';

/// Fail closed for protected routes while auth is unknown/unavailable/failed.
abstract final class AuthenticationGuard {
  static String? redirect({
    required bool requiresAuthentication,
    required AuthSession? session,
  }) {
    if (!requiresAuthentication) return null;
    if (session?.status == AuthStatus.signedIn) return null;
    // TODO(Lab 3): Replace with a sign-in route once the auth flow exists.
    return AppRoutes.home;
  }
}
