import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/constants/app_strings.dart';
import '../screens/foundation_screen.dart';
import '../screens/evia/login_screen.dart';
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
import '../widgets/responsive_body.dart';
import '../widgets/status_widgets.dart';
import 'authentication_guard.dart';

final initialLocationProvider = Provider<String>((ref) => AppRoutes.home);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authenticationViewModelProvider, (_, next) {
    refresh.value++;
  });

  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) => AuthenticationGuard.redirect(
      requiresAuthentication: AppRoutes.protectedPaths.contains(state.uri.path),
      session: ref.read(authenticationViewModelProvider).asData?.value,
    ),
    routes: [
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
        builder: (_, _) => const RewardVoucherScreen(),
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
        builder: (context, state) => const EviaLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.foundation,
        builder: (_, _) => const FoundationScreen(),
      ),
      GoRoute(
        path: AppRoutes.interests,
        builder: (_, _) => const EviaInterestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.discover,
        builder: (_, _) => const EviaDiscoverScreen(),
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
