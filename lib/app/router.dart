import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../screens/foundation_screen.dart';
import '../viewmodels/authentication_view_model.dart';
import '../widgets/responsive_body.dart';
import '../widgets/status_widgets.dart';
import 'authentication_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authenticationViewModelProvider, (_, next) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => AuthenticationGuard.redirect(
      requiresAuthentication: AppRoutes.protectedPaths.contains(state.uri.path),
      session: ref.read(authenticationViewModelProvider).asData?.value,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: ResponsiveBody(
        child: AppErrorWidget(message: AppStrings.routeNotFound),
      ),
    ),
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
