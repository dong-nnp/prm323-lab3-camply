import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/flow_assets.dart';
import '../../data/mock/registration_mock_data.dart';
import '../../models/registration_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/flow_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/event_flow_widgets.dart';

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({
    this.tab = 'about',
    this.eventId = 'music-live',
    super.key,
  });
  final String tab, eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref
        .read(registrationViewModelProvider.notifier)
        .event(eventId);
    final screen = tab == 'schedule'
        ? '2083:4752'
        : tab == 'location'
        ? '2083:5137'
        : '2083:5523';
    final saved = ref.watch(
      profileViewModelProvider.select((s) => s.saved.contains(event.id)),
    );
    final registered = ref.watch(
      activityViewModelProvider.select(
        (s) =>
            s.registrations.any((e) => e.id == event.id) &&
            !s.cancelled.contains(event.id),
      ),
    );
    return EviaPage(
      footer: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.surface,
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FREE ADMISSION', style: FlowTheme.footnote),
                  Text('120 spots remaining', style: EviaTheme.label),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: AppButton(
                label: event.past
                    ? 'Event Ended'
                    : registered
                    ? 'View My Events'
                    : event.walkIn
                    ? "I'm Going"
                    : 'Register Now',
                trailing: ActivityIcon(
                  screen,
                  tab == 'about'
                      ? 'imgContainer11'
                      : tab == 'schedule'
                      ? 'imgContainer7'
                      : 'imgContainer12',
                ),
                onPressed: event.past
                    ? null
                    : () {
                        if (registered) {
                          context.go('/my-events');
                        } else if (event.walkIn) {
                          ref
                              .read(registrationViewModelProvider.notifier)
                              .markGoing();
                          context.push('/registration/going');
                        } else {
                          context.push('/registration?event=${event.id}');
                        }
                      },
              ),
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: FlowTheme.heroHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      event.id == 'music-live'
                          ? FlowAssets.image(screen, 0)
                          : event.image ??
                                RegistrationMockData.saved
                                    .firstWhere(
                                      (e) => e.event.id == event.id,
                                      orElse: () =>
                                          RegistrationMockData.saved.first,
                                    )
                                    .image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: EviaTheme.thumbnail,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: FlowTheme.heroGradient,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: AppColors.surface.withValues(alpha: .8),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Back',
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/discover'),
                            icon: ActivityIcon(screen, 'imgContainer'),
                          ),
                        ),
                        Material(
                          color: AppColors.surface.withValues(alpha: .8),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: saved
                                ? 'Remove from saved events'
                                : 'Save event',
                            isSelected: saved,
                            onPressed: () {
                              ref
                                  .read(profileViewModelProvider.notifier)
                                  .toggleSaved(event.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    saved
                                        ? 'Event removed from saved.'
                                        : 'Event saved.',
                                  ),
                                ),
                              );
                            },
                            icon: ActivityIcon(screen, 'imgContainer1'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -FlowTheme.heroOverlap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EviaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              EventBadge(
                                event.category.toUpperCase(),
                                category: true,
                                color: AppColors.accent,
                                foreground: AppColors.textPrimary,
                              ),
                              const Spacer(),
                              EventBadge('${event.spots} spots left'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            event.title,
                            style: FlowTheme.fieldLabel.copyWith(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .fontSize,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _EventOrganizer(screen: screen),
                          const Divider(height: AppSpacing.xl),
                          FlowMeta(
                            event.id == 'music-live'
                                ? 'Sat, Nov 7, 2026'
                                : event.date,
                            subtitle: 'Fall Semester Showcase',
                            screen: screen,
                            asset: 'imgContainer3',
                          ),
                          FlowMeta(
                            tab == 'about' && event.id == 'music-live'
                                ? 'Sat, Nov 7, 2026'
                                : event.time,
                            subtitle: 'Doors open: 17:30',
                            screen: screen,
                            asset: 'imgContainer4',
                          ),
                          FlowMeta(
                            tab == 'about' && event.id == 'music-live'
                                ? 'Sat, Nov 7, 2026'
                                : event.venue,
                            subtitle: 'West Campus Lawn • Gate 4 Entrance',
                            screen: screen,
                            asset: 'imgContainer5',
                          ),
                          const Divider(height: AppSpacing.xl),
                          if (tab == 'about') ...[
                            const Text(
                              'PARTICIPATION',
                              style: FlowTheme.footnote,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              const EventBadge(
                                'All Students',
                                color: AppColors.surfaceMuted,
                                foreground: AppColors.textSecondary,
                              ),
                              EventBadge(
                                event.walkIn
                                    ? 'Walk-in allowed'
                                    : 'Registration Required',
                                color: AppColors.surfaceMuted,
                                foreground: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          EviaCard(
                            color: AppColors.primarySoft,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: AppSpacing.lg,
                                  backgroundColor: AppColors.warningSurface,
                                  child: const CoinIcon(size: AppSpacing.lg),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.xs,
                                        children: [
                                          Text(
                                            'Earn +${event.coins} coins',
                                            style: EviaTheme.label,
                                          ),
                                          const EventBadge(
                                            'Special Reward',
                                            color: AppColors.warningSurface,
                                            foreground: AppColors.warning,
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'After verified event check-in',
                                        style: EviaTheme.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          EviaCard(
                            color: AppColors.warningSurface,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: AppSpacing.lg,
                                  backgroundColor: FlowTheme.coin,
                                  child: ActivityIcon(
                                    screen,
                                    tab == 'about'
                                        ? 'imgContainer7'
                                        : 'imgContainer6',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.walkIn
                                            ? 'No deposit required'
                                            : '${event.deposit}-coin deposit required',
                                        style: EviaTheme.label,
                                      ),
                                      const Text(
                                        'Held during registration · Refund subject to event policy',
                                        style: EviaTheme.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EviaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              for (final section in [
                                'about',
                                'schedule',
                                'location',
                              ])
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => context.go(
                                      '/event/$section?event=${event.id}',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: tab == section
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${section[0].toUpperCase()}${section.substring(1)}',
                                        ),
                                        if (tab == section)
                                          const Divider(
                                            color: AppColors.primary,
                                            thickness: 2,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (tab == 'about')
                            const _AboutPanel()
                          else if (tab == 'schedule')
                            _SchedulePanel(screen: screen, event: event)
                          else
                            const _LocationPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventOrganizer extends ConsumerWidget {
  const _EventOrganizer({required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(
      eviaViewModelProvider.select((s) => s.followed.contains('union')),
    );
    return Row(
      children: [
        const CircleAvatar(
          radius: AppSpacing.lg,
          backgroundColor: AppColors.primarySoft,
          child: Text('SU', style: TextStyle(color: AppColors.primary)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InkWell(
            onTap: () => context.push('/organizer'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Organized by', style: EviaTheme.caption),
                Row(
                  children: [
                    const Flexible(
                      child: Text('Student Union', style: EviaTheme.label),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ActivityIcon(screen, 'imgContainer2'),
                  ],
                ),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () =>
              ref.read(eviaViewModelProvider.notifier).toggleFollowed('union'),
          child: Text(followed ? 'Following' : '+ Follow'),
        ),
      ],
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('About This Event', style: EviaTheme.cardTitle),
      const SizedBox(height: AppSpacing.md),
      const Text(
        'Kick off the fall semester with the biggest live music showcase on campus! Featuring student bands, guest DJ sets, food trucks, and light installations across the Main Stadium lawn.',
        style: EviaTheme.caption,
      ),
      const SizedBox(height: AppSpacing.xl),
      const Text("What You'll Gain", style: EviaTheme.cardTitle),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < 3; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: AppColors.primarySoft,
              child: ActivityIcon('2083:5523', 'imgContainer${8 + i}'),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      'Live Performances',
                      'Campus Networking',
                      'Free Merch & Snacks',
                    ][i],
                    style: EviaTheme.label,
                  ),
                  Text(
                    [
                      'Experience live sets from top student bands and guest artists.',
                      'Connect with peers across faculties and student club leaders.',
                      'Exclusive festival wristbands, stickers, and local food vouchers.',
                    ][i],
                    style: EviaTheme.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: AppSpacing.xl),
      ],
      const Text('Who Can Join', style: EviaTheme.cardTitle),
      const SizedBox(height: AppSpacing.md),
      const Text(
        '• Open to all currently enrolled undergraduate and graduate students from any faculty.\n\n• Valid student ID (digital or physical card) required at Gate 4 entrance check-in.',
        style: EviaTheme.caption,
      ),
    ],
  );
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.screen, required this.event});
  final String screen;
  final EventPresentation event;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(event.title, style: EviaTheme.section),
      const SizedBox(height: AppSpacing.lg),
      _EventOrganizer(screen: screen),
      const SizedBox(height: AppSpacing.lg),
      for (final item in RegistrationMockData.agenda) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Icon(
                Icons.circle,
                size: AppSpacing.sm,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: EviaTheme.label),
                  Text(item.description, style: EviaTheme.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(item.time, style: EviaTheme.caption),
          ],
        ),
        const Divider(height: AppSpacing.xl),
      ],
      const Text(
        'Schedule subject to minor changes. Final artist lineup confirmed upon check-in.',
        style: EviaTheme.caption,
      ),
    ],
  );
}

class _LocationPanel extends StatelessWidget {
  const _LocationPanel();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: SizedBox(
          height: FlowTheme.mapHeight,
          child: Stack(
            children: [
              const Center(
                child: ActivityIcon(
                  '2083:5137',
                  'img1MapPreviewVisualStyledCampusMapVectorCardShowingMainStadiumLawnPinWithCleanStreet',
                ),
              ),
              const Positioned(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                child: EventBadge(
                  'University Ave',
                  color: AppColors.surface,
                  foreground: AppColors.textSecondary,
                ),
              ),
              const Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: EventBadge(
                  'West Lawn Quad',
                  color: AppColors.surface,
                  foreground: AppColors.textSecondary,
                ),
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: ActivityIcon('2083:5137', 'imgContainer7'),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    EventBadge(
                      '• Main Stadium Lawn',
                      color: AppColors.surface,
                      foreground: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: EviaCard(
            color: AppColors.background,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: AppSpacing.lg,
                  backgroundColor: AppColors.primarySoft,
                  child: ActivityIcon('2083:5137', 'imgContainer${8 + i}'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          'Main Stadium',
                          'Entrance & Check-in',
                          'Accessibility & Transit',
                        ][i],
                        style: EviaTheme.label,
                      ),
                      if (i == 0) const EventBadge('GATE 4'),
                      Text(
                        [
                          'West Campus Lawn • University Ave Entrance',
                          'Active Student ID required for gate check-in. Doors open at 17:30. Follow signs to Gate 4.',
                          'Wheelchair accessible entrance via North Ramp at Gate 4. Campus Shuttle Blue Line stops at Stadium North. Student Lot B parking open with valid digital permit.',
                        ][i],
                        style: EviaTheme.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      OutlinedButton(
        onPressed: () => showActivityHelp(
          context,
          'Campus map',
          'Map preview: Main Stadium Lawn, West Campus Lawn • University Ave Entrance. Enter via Gate 4.',
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActivityIcon('2083:5137', 'imgContainer11'),
            SizedBox(width: AppSpacing.sm),
            Text('Open in Maps'),
          ],
        ),
      ),
    ],
  );
}
