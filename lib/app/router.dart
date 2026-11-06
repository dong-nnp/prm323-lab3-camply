import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../theme/splash_tokens.dart';
import '../theme/app_motion.dart';
import '../screens/foundation_screen.dart';
import '../screens/evia/login_screen.dart';
import '../screens/evia/demo_screens_screen.dart';
import '../core/providers/service_providers.dart';
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
import '../widgets/rewards_backend_gate.dart';
import '../widgets/status_widgets.dart';
import '../widgets/evia_skeleton.dart';
import '../widgets/evia_widgets.dart';
import '../core/utils/exception_mapper.dart';
import '../viewmodels/flow1_view_model.dart';
import 'authentication_guard.dart';
import '../viewmodels/push_notifications_view_model.dart';

final initialLocationProvider = Provider<String>((ref) => AppRoutes.splash);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  late final GoRouter router;
  ref.listen(authenticationViewModelProvider, (_, next) {
    // A pushed Login retains the previous URI during refresh in go_router.
    final matches = router.routerDelegate.currentConfiguration;
    if (next.asData?.value.status == AuthStatus.signedIn &&
        matches.isNotEmpty) {
      final top = matches.last;
      if (top is ImperativeRouteMatch &&
          [AppRoutes.login, AppRoutes.signUp].contains(top.matches.uri.path)) {
        router.go(top.matches.uri.toString());
        return;
      }
    }
    refresh.value++;
  });
  final real = ref.watch(realBackendEnabledProvider);
  if (real) {
    ref.listen(pushNotificationsViewModelProvider, (_, next) {
      if (next.destination != null) {
        final destination = next.destination!;
        ref
            .read(pushNotificationsViewModelProvider.notifier)
            .clearDestination();
        Future.microtask(() => router.push(destination));
      }
    });
  }
  if (real) ref.listen(flow1ViewModelProvider, (_, _) => refresh.value++);

  router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authenticationViewModelProvider);
      final session = auth.isLoading ? null : auth.asData?.value;
      if (real &&
          session?.status == AuthStatus.signedIn &&
          AppRoutes.requiresAuthentication(state.uri.path) &&
          state.uri.path != AppRoutes.interests &&
          state.uri.path != '/profile/interests') {
        final profile = ref.read(flow1ViewModelProvider).asData?.value.profile;
        if (profile != null &&
            profile.isNotEmpty &&
            profile['onboardingCompleted'] != true) {
          return Uri(
            path: AppRoutes.interests,
            queryParameters: {'from': state.uri.toString()},
          ).toString();
        }
      }
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
            (real &&
                ref
                        .read(flow1ViewModelProvider)
                        .asData
                        ?.value
                        .profile['onboardingCompleted'] ==
                    true) ||
            ref
                .read(eviaViewModelProvider)
                .personalizedUsers
                .contains(session.userId);
        if (!handled) {
          return Uri(
            path: AppRoutes.interests,
            queryParameters: {
              if (state.uri.queryParameters['from'] != null)
                'from': state.uri.queryParameters['from']!,
            },
          ).toString();
        }
        final from = state.uri.queryParameters['from'];
        final target = from == null ? null : Uri.tryParse(from);
        if (target != null &&
            !target.hasAuthority &&
            !target.hasScheme &&
            target.path.startsWith('/') &&
            (AppRoutes.requiresAuthentication(target.path) ||
                real &&
                    (target.path.startsWith('/event/') ||
                        target.path == '/organizer'))) {
          return from;
        }
        return AppRoutes.discover;
      }
      final redirect = AuthenticationGuard.redirect(
        requiresAuthentication:
            AppRoutes.requiresAuthentication(state.uri.path) ||
            real && state.uri.path == AppRoutes.interests,
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
      if (ref.read(demoAuthEnabledProvider))
        GoRoute(
          path: '/profile/demo',
          builder: (_, _) => const DemoScreensScreen(),
        ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const EviaSplashScreen(),
      ),
      for (final tab in ['about', 'schedule', 'location'])
        GoRoute(
          path: '/event/$tab',
          builder: (_, state) => _catalogReady(
            EventDetailsScreen(
              tab: tab,
              eventId:
                  state.uri.queryParameters['event'] ??
                  (real ? '' : 'music-live'),
            ),
          ),
        ),
      GoRoute(
        path: '/registration',
        builder: (_, state) => _catalogReady(
          RegistrationFormScreen(
            eventId:
                state.uri.queryParameters['event'] ??
                (real ? '' : 'music-live'),
            resume: state.uri.queryParameters['resume'] == 'true',
          ),
        ),
      ),
      for (final view in ['legacy', 'legacy-error', 'error', 'loading'])
        GoRoute(
          path: '/registration/$view',
          builder: (_, state) => _catalogReady(
            RegistrationFormScreen(
              view: view,
              eventId:
                  state.uri.queryParameters['event'] ??
                  (real ? '' : 'music-live'),
            ),
          ),
        ),
      for (final view in ['success', 'going', 'full', 'failed'])
        GoRoute(
          path: '/registration/$view',
          builder: (_, state) => _catalogReady(
            RegistrationResultScreen(
              view: view,
              eventId: state.uri.queryParameters['event'],
            ),
          ),
        ),
      GoRoute(
        path: '/organizer',
        builder: (_, state) => _catalogReady(
          OrganizerProfileScreen(organizerId: state.uri.queryParameters['id']),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => _catalogReady(const ProfileScreen()),
      ),
      GoRoute(
        path: '/profile/interests',
        builder: (_, _) => _catalogReady(const ProfileInterestsScreen()),
      ),
      GoRoute(
        path: '/profile/saved',
        builder: (_, _) => _catalogReady(const SavedEventsScreen()),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/my-events',
        builder: (_, _) =>
            _catalogReady(const MyEventsScreen(view: 'upcoming')),
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
          builder: (_, _) => _catalogReady(MyEventsScreen(view: view)),
        ),
      GoRoute(
        path: '/my-events/cancel',
        builder: (_, state) => _catalogReady(
          MyEventsScreen(
            view: 'cancel',
            cancelId:
                state.uri.queryParameters['event'] ?? (real ? '' : 'music'),
          ),
        ),
      ),
      GoRoute(
        path: '/my-events/ticket',
        builder: (_, state) => _catalogReady(
          TicketScreen(
            eventId:
                state.uri.queryParameters['event'] ?? (real ? '' : 'music'),
          ),
        ),
      ),
      GoRoute(
        path: '/my-events/check-in',
        builder: (_, state) => _catalogReady(
          EventCheckInScreen(eventId: state.uri.queryParameters['event'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rewards',
        builder: (_, _) => const RewardsBackendGate(
          loadingFooter: EviaBottomBar(selected: 2),
          child: RewardsScreen(),
        ),
      ),
      GoRoute(
        path: '/rewards/catalog',
        builder: (_, _) => const RewardsBackendGate(
          loadingFooter: EviaBottomBar(selected: 2),
          child: RewardsScreen(catalog: true),
        ),
      ),
      GoRoute(
        path: '/rewards/locker',
        builder: (_, _) =>
            const RewardsBackendGate(child: RewardsLockerScreen()),
      ),
      GoRoute(
        path: '/rewards/detail',
        builder: (_, state) => RewardsBackendGate(
          child: RewardDetailsScreen(
            rewardId: state.uri.queryParameters['id'] ?? 'cafe',
          ),
        ),
      ),
      GoRoute(
        path: '/rewards/confirm',
        builder: (_, state) => RewardsBackendGate(
          child: RewardDetailsScreen(
            confirm: true,
            rewardId: state.uri.queryParameters['id'] ?? 'cafe',
          ),
        ),
      ),
      GoRoute(
        path: '/rewards/success',
        builder: (_, _) =>
            const RewardsBackendGate(child: RedemptionSuccessScreen()),
      ),
      GoRoute(
        path: '/rewards/voucher',
        builder: (_, state) => RewardsBackendGate(
          child: RewardVoucherScreen(code: state.uri.queryParameters['code']),
        ),
      ),
      GoRoute(
        path: '/rewards/milestones',
        builder: (_, _) =>
            const RewardsBackendGate(child: EventMilestonesScreen()),
      ),
      GoRoute(
        path: '/rewards/history',
        builder: (_, _) => const RewardsBackendGate(child: CoinHistoryScreen()),
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
        pageBuilder: (context, state) => _startupPage(
          context,
          state,
          _catalogReady(const EviaInterestsScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.discover,
        pageBuilder: (context, state) => _startupPage(
          context,
          state,
          _catalogReady(const EviaDiscoverScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.guestDiscover,
        builder: (_, _) => _catalogReady(const EviaDiscoverScreen(guest: true)),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (_, _) => _catalogReady(const EviaExploreScreen()),
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (_, _) =>
            _catalogReady(const EviaExploreScreen(referenceResults: true)),
      ),
      GoRoute(
        path: AppRoutes.filters,
        builder: (_, _) => _catalogReady(const EviaFiltersScreen()),
      ),
      GoRoute(
        path: AppRoutes.followingEvents,
        builder: (_, _) => _catalogReady(const EviaFollowingScreen()),
      ),
      GoRoute(
        path: AppRoutes.followingOrganizers,
        builder: (_, _) =>
            _catalogReady(const EviaFollowingScreen(organizers: true)),
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

// Gate API reads without replacing already loaded content during refresh.
Widget _catalogReady(Widget child) => Consumer(
  builder: (context, ref, _) {
    if (!ref.watch(realBackendEnabledProvider)) return child;
    ref.listen(flow1ViewModelProvider, (previous, next) {
      final error = next.asData?.value.actionError;
      if (error != null && error != previous?.asData?.value.actionError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            ScaffoldMessenger.maybeOf(context)
                ?.showSnackBar(SnackBar(content: Text(error)));
          }
        });
      }
    });
    return ref
        .watch(flow1ViewModelProvider)
        .when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: false,
          loading: () => switch (child) {
            EviaDiscoverScreen(:final guest) => EviaLoadingPage(
              title: 'Discover',
              layout: SkeletonLayout.discover,
              footer: EviaBottomBar(guest: guest),
            ),
            EventDetailsScreen() => const EviaLoadingPage(
              title: 'Event Details',
              layout: SkeletonLayout.detail,
            ),
            MyEventsScreen() => const EviaLoadingPage(
              title: 'My Events',
              footer: EviaBottomBar(selected: 1),
            ),
            ProfileScreen() => const EviaLoadingPage(
              title: 'Profile',
              footer: EviaBottomBar(selected: 3),
            ),
            _ => const EviaLoadingPage(title: 'Loading content…'),
          },
          error: (error, _) => EviaPage(
            child: Center(
              child: AppErrorWidget(
                message: ExceptionMapper.map(error).message,
                onRetry: () =>
                    ref.read(flow1ViewModelProvider.notifier).refresh(),
              ),
            ),
          ),
          data: (_) => child,
        );
  },
);

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
