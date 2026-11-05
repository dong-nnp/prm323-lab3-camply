import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../theme/splash_tokens.dart';
import '../theme/app_motion.dart';
import '../screens/foundation_screen.dart';
import '../screens/evia/login_screen.dart';
import '../screens/evia/welcome_screen.dart';
import '../screens/evia/sign_up_screen.dart';
import '../screens/evia/splash_screen.dart';
import '../screens/evia/interests_screen.dart';
import '../screens/evia/discover_screen.dart';
import '../screens/evia/explore_screen.dart';
import '../screens/evia/filters_screen.dart';
import '../screens/evia/following_screen.dart';
import '../screens/evia/my_events_screen.dart';
import '../screens/evia/ticket_screen.dart';
import '../screens/evia/check_in_screen.dart';
import '../screens/evia/rewards_screen.dart';
import '../screens/evia/reward_details_screen.dart';
import '../screens/evia/reward_voucher_screen.dart';
import '../screens/evia/milestones_screen.dart';
import '../screens/evia/coin_history_screen.dart';
import '../screens/evia/event_details_screen.dart';
import '../screens/evia/registration_form_screen.dart';
import '../screens/evia/registration_result_screen.dart';
import '../screens/evia/organizer_profile_screen.dart';
import '../screens/evia/profile_screens.dart';
import '../viewmodels/authentication_view_model.dart';
import '../viewmodels/evia_view_model.dart';
import '../models/auth_session.dart';
import '../widgets/responsive_body.dart';
import '../widgets/status_widgets.dart';
import 'authentication_guard.dart';

final initialLocationProvider = Provider<String>((ref) => AppRoutes.splash);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authenticationViewModelProvider, (_, next) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authenticationViewModelProvider);
      final session = auth.isLoading ? null : auth.asData?.value;
      if (!auth.isLoading &&
          state.uri.path == AppRoutes.discover &&
          session?.status != AuthStatus.signedIn) {
        return AppRoutes.guestDiscover;
      }
      if (session?.status == AuthStatus.signedIn &&
          [
            AppRoutes.home,
            AppRoutes.login,
            AppRoutes.signUp,
          ].contains(state.uri.path)) {
        final handled =
            session!.personalizationHandled ||
            ref
                .read(eviaViewModelProvider)
                .personalizedUsers
                .contains(session.userId);
        if (!handled) return AppRoutes.interests;
        final from = state.uri.queryParameters['from'];
        final target = from == null ? null : Uri.tryParse(from);
        if (target != null &&
            !target.hasAuthority &&
            !target.hasScheme &&
            target.path.startsWith('/') &&
            AppRoutes.requiresAuthentication(target.path)) {
          return from;
        }
        return AppRoutes.discover;
      }
      final redirect = AuthenticationGuard.redirect(
        requiresAuthentication: AppRoutes.requiresAuthentication(
          state.uri.path,
        ),
        session: session,
      );
      return redirect == null
          ? null
          : Uri(
              path: redirect,
              queryParameters: {'from': state.uri.toString()},
            ).toString();
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const EviaSplashScreen(),
      ),
      for (final tab in ['about', 'schedule', 'location'])
        GoRoute(
          path: '/event/$tab',
          builder: (_, state) => EventDetailsScreen(
            tab: tab,
            eventId: state.uri.queryParameters['event'] ?? 'music-live',
          ),
        ),
      GoRoute(
        path: '/registration',
        builder: (_, state) => RegistrationFormScreen(
          eventId: state.uri.queryParameters['event'] ?? 'music-live',
          resume: state.uri.queryParameters['resume'] == 'true',
        ),
      ),
      for (final view in ['legacy', 'legacy-error', 'error', 'loading'])
        GoRoute(
          path: '/registration/$view',
          builder: (_, state) => RegistrationFormScreen(
            view: view,
            eventId: state.uri.queryParameters['event'] ?? 'music-live',
          ),
        ),
      for (final view in ['success', 'going', 'full', 'failed'])
        GoRoute(
          path: '/registration/$view',
          builder: (_, _) => RegistrationResultScreen(view: view),
        ),
      GoRoute(
        path: '/organizer',
        builder: (_, _) => const OrganizerProfileScreen(),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/profile/interests',
        builder: (_, _) => const ProfileInterestsScreen(),
      ),
      GoRoute(
        path: '/profile/saved',
        builder: (_, _) => const SavedEventsScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/my-events',
        builder: (_, _) => const MyEventsScreen(view: 'upcoming'),
      ),
      for (final view in [
        'past-empty',
        'past-date',
        'past-all',
        'selected',
        'calendar',
      ])
        GoRoute(
          path: '/my-events/$view',
          builder: (_, _) => MyEventsScreen(view: view),
        ),
      GoRoute(
        path: '/my-events/cancel',
        builder: (_, state) => MyEventsScreen(
          view: 'cancel',
          cancelId: state.uri.queryParameters['event'] ?? 'music',
        ),
      ),
      GoRoute(
        path: '/my-events/ticket',
        builder: (_, state) => TicketScreen(
          eventId: state.uri.queryParameters['event'] ?? 'music',
        ),
      ),
      GoRoute(
        path: '/my-events/check-in',
        builder: (_, _) => const EventCheckInScreen(),
      ),
      GoRoute(path: '/rewards', builder: (_, _) => const RewardsScreen()),
      GoRoute(
        path: '/rewards/catalog',
        builder: (_, _) => const RewardsScreen(catalog: true),
      ),
      GoRoute(
        path: '/rewards/locker',
        builder: (_, _) => const RewardsLockerScreen(),
      ),
      GoRoute(
        path: '/rewards/detail',
        builder: (_, state) => RewardDetailsScreen(
          rewardId: state.uri.queryParameters['id'] ?? 'cafe',
        ),
      ),
      GoRoute(
        path: '/rewards/confirm',
        builder: (_, state) => RewardDetailsScreen(
          confirm: true,
          rewardId: state.uri.queryParameters['id'] ?? 'cafe',
        ),
      ),
      GoRoute(
        path: '/rewards/success',
        builder: (_, _) => const RedemptionSuccessScreen(),
      ),
      GoRoute(
        path: '/rewards/voucher',
        builder: (_, state) =>
            RewardVoucherScreen(code: state.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/rewards/milestones',
        builder: (_, _) => const EventMilestonesScreen(),
      ),
      GoRoute(
        path: '/rewards/history',
        builder: (_, _) => const CoinHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeName,
        pageBuilder: (context, state) =>
            _startupPage(context, state, const EviaWelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _loginPage(context, state),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (_, _) => const EviaSignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.foundation,
        builder: (_, _) => const FoundationScreen(),
      ),
      GoRoute(
        path: AppRoutes.interests,
        pageBuilder: (context, state) =>
            _startupPage(context, state, const EviaInterestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.discover,
        pageBuilder: (context, state) =>
            _startupPage(context, state, const EviaDiscoverScreen()),
      ),
      GoRoute(
        path: AppRoutes.guestDiscover,
        builder: (_, _) => const EviaDiscoverScreen(guest: true),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (_, _) => const EviaExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (_, _) => const EviaExploreScreen(referenceResults: true),
      ),
      GoRoute(
        path: AppRoutes.filters,
        builder: (_, _) => const EviaFiltersScreen(),
      ),
      GoRoute(
        path: AppRoutes.followingEvents,
        builder: (_, _) => const EviaFollowingScreen(),
      ),
      GoRoute(
        path: AppRoutes.followingOrganizers,
        builder: (_, _) => const EviaFollowingScreen(organizers: true),
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

CustomTransitionPage<void> _startupPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : SplashTokens.transition,
  reverseTransitionDuration: Duration.zero,
  child: child,
  transitionsBuilder: (_, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

CustomTransitionPage<void> _loginPage(
  BuildContext context,
  GoRouterState state,
) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: reducedMotion ? Duration.zero : AppMotion.loginEnter,
    reverseTransitionDuration: reducedMotion
        ? Duration.zero
        : AppMotion.loginExit,
    child: const EviaLoginScreen(),
    transitionsBuilder: (context, animation, _, child) {
      final eased = animation.drive(CurveTween(curve: AppMotion.loginCurve));
      return FadeTransition(
        opacity: eased,
        child: SlideTransition(
          textDirection: Directionality.of(context),
          position: Tween<Offset>(
            begin: AppMotion.loginOffset,
            end: Offset.zero,
          ).animate(eased),
          child: child,
        ),
      );
    },
  );
}
