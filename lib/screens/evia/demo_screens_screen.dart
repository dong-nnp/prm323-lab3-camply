import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/authentication_view_model.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../widgets/evia_widgets.dart';

const demoScreenRoutes = [
  ('Discover', '/discover'),
  ('Guest Discover', '/discover/guest'),
  ('Interests', '/interests'),
  ('Explore', '/explore'),
  ('Search Results', '/explore/results'),
  ('Filters', '/filters'),
  ('Following Events', '/following/events'),
  ('Following Organizers', '/following/organizers'),
  ('Event · About', '/event/about'),
  ('Event · Schedule', '/event/schedule'),
  ('Event · Location', '/event/location'),
  ('Walk-in Event', '/event/about?event=club-live'),
  ('Organizer', '/organizer'),
  ('Registration Form', '/registration'),
  ('Legacy Form', '/registration/legacy'),
  ('Legacy Validation Errors', '/registration/legacy-error'),
  ('Validation Errors', '/registration/error'),
  ('Registration Loading', '/registration/loading'),
  ('Registration Success', '/registration/success'),
  ('Walk-in Success', '/registration/going'),
  ('Event Full', '/registration/full'),
  ('Registration Failed', '/registration/failed'),
  ('My Events', '/my-events'),
  ('Past · Empty', '/my-events/past-empty'),
  ('Past · Date', '/my-events/past-date'),
  ('Past · All', '/my-events/past-all'),
  ('Selected Date', '/my-events/selected'),
  ('Calendar', '/my-events/calendar'),
  ('Cancel Registration', '/my-events/cancel?event=ai'),
  ('Ticket', '/my-events/ticket?event=ai'),
  ('Event Check-in', '/my-events/check-in'),
  ('Rewards', '/rewards'),
  ('Reward Catalog', '/rewards/catalog'),
  ('Reward Details', '/rewards/detail'),
  ('Redemption Confirmation', '/rewards/confirm'),
  ('Redemption Success', '/rewards/success'),
  ('Voucher', '/rewards/voucher'),
  ('My Rewards', '/rewards/locker'),
  ('Milestones · legacy UI', '/rewards/milestones'),
  ('Coin History', '/rewards/history'),
  ('Profile', '/profile'),
  ('Profile Interests', '/profile/interests'),
  ('Saved Events', '/profile/saved'),
  ('Notifications', '/profile/notifications'),
];

class DemoScreensScreen extends ConsumerWidget {
  const DemoScreensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => EviaPage(
    header: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BackButton(onPressed: () => context.pop()),
          const Expanded(
            child: Text('Demo screens', style: EviaTheme.cardTitle),
          ),
        ],
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text(
          'Local preview only. No backend changes. Reset to try again with 2,000 demo coins.',
          style: EviaTheme.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () {
            ref.read(activityViewModelProvider.notifier).resetDemo();
            ref.invalidate(registrationViewModelProvider);
            AppFeedback.show(context, 'Demo reset · 2,000 coins.');
          },
          child: const Text('Reset demo'),
        ),
        TextButton(
          onPressed: () async {
            final error = await ref
                .read(authenticationViewModelProvider.notifier)
                .signOut();
            if (!context.mounted) return;
            if (error != null) {
              AppFeedback.show(context, error, isError: true);
              return;
            }
            context.go('/splash');
          },
          child: const Text('View Splash / Welcome / Login / Sign up'),
        ),
        const Text(
          'Event check-in demo code: EVIA-CLUB-2026. QR camera, Google sign-in and password emails are not live services.',
          style: EviaTheme.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in demoScreenRoutes)
          Material(
            color: AppColors.surface,
            child: ListTile(
              title: Text(item.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(item.$2),
            ),
          ),
      ],
    ),
  );
}
