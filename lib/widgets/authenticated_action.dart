import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/authentication_guard.dart';
import '../core/constants/app_routes.dart';
import '../viewmodels/authentication_view_model.dart';

/// Public event/organizer pages stay browsable; account actions open Login.
bool ensureAuthenticated(BuildContext context, WidgetRef ref) {
  final redirect = AuthenticationGuard.redirect(
    requiresAuthentication: true,
    session: ref.read(authenticationViewModelProvider).asData?.value,
  );
  if (redirect == null && ref.read(hasAuthenticatedSessionProvider)) {
    return true;
  }
  context.push(
    Uri(
      path: redirect ?? AppRoutes.login,
      queryParameters: {'from': GoRouterState.of(context).uri.toString()},
    ).toString(),
  );
  return false;
}
