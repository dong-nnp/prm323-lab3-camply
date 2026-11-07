import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/flow_assets.dart';
import '../../data/mock/registration_mock_data.dart';
import '../../data/mock/evia_mock_data.dart';
import '../../models/registration_models.dart';
import '../../models/flow1_models.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../widgets/status_widgets.dart';
import '../../widgets/evia_skeleton.dart';
import '../../core/utils/exception_mapper.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/flow_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../viewmodels/authentication_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/registration_view_model.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/authenticated_action.dart';
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
    ref.watch(eviaViewModelProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    if (vm.live) ref.watch(eventDetailViewModelProvider(eventId));
    final remote = vm.live ? ref.watch(flow1EventProvider(eventId)) : null;
    if (remote != null && !remote.hasValue) {
      if (!remote.hasError) {
        return const EviaLoadingPage(
          title: 'Event Details',
          layout: SkeletonLayout.detail,
        );
      }
      return EviaPage(
        child: Center(
          child: AppErrorWidget(
            message: ExceptionMapper.map(remote.error!).message,
            onRetry: () => ref.invalidate(flow1EventProvider(eventId)),
          ),
        ),
      );
    }
    final raw = remote?.asData?.value;
    final event = ref
        .read(registrationViewModelProvider.notifier)
        .findEvent(eventId);
    final authenticated = ref.watch(hasAuthenticatedSessionProvider);
    if (event == null) {
      return const EviaPage(
        header: ActivityHeader('Event Details'),
        child: Center(child: Text('Event not found.')),
      );
    }
    final music = event.id == 'music' || event.id == 'music-live';
    final screen = tab == 'schedule'
        ? '2083:4752'
        : tab == 'location'
        ? '2083:5137'
        : '2083:5523';
    final saved =
        authenticated &&
        ref.watch(
          profileViewModelProvider.select((s) => s.saved.contains(event.id)),
        );
    final registered =
        authenticated &&
        ref.watch(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.spots case final spots?)
                    Text('$spots spots remaining', style: EviaTheme.label)
                  else
                    Text(event.policy, style: EviaTheme.label),
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
                    : raw != null &&
                          !raw.walkIn &&
                          !raw.registrationOpen(DateTime.now().toUtc())
                    ? (raw.spots == 0
                          ? 'Registration Full'
                          : 'Registration Closed')
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
                onPressed:
                    event.past ||
                        (raw != null &&
                            !registered &&
                            !raw.walkIn &&
                            !raw.registrationOpen(DateTime.now().toUtc()))
                    ? null
                    : () async {
                        if (!ensureAuthenticated(context, ref)) return;
                        if (registered) {
                          context.go('/my-events');
                        } else if (event.walkIn) {
                          final saved = await ref
                              .read(registrationViewModelProvider.notifier)
                              .markGoing(eventId);
                          if (!context.mounted || !saved) return;
                          context.push('/registration/going?event=${event.id}');
                        } else {
                          context.push(
                            Uri(
                              path: '/registration',
                              queryParameters: {'event': eventId},
                            ).toString(),
                          );
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
                    child: raw != null
                        ? catalogImage(
                            raw.imageUrl,
                            FlowAssets.image(screen, 0),
                            fit: BoxFit.cover,
                          )
                        : switch (music
                              ? FlowAssets.image(screen, 0)
                              : event.image) {
                            final image? => Image.asset(
                              image,
                              fit: BoxFit.cover,
                            ),
                            null => const ColoredBox(
                              color: AppColors.primarySoft,
                              child: Center(
                                child: Icon(
                                  Icons.event_outlined,
                                  size: AppSizes.statusIcon,
                                ),
                              ),
                            ),
                          },
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
                                : context.go(
                                    authenticated
                                        ? '/discover'
                                        : '/discover/guest',
                                  ),
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
                            onPressed: vm.live && vm.catalog?.busy == true
                                ? null
                                : () async {
                                    if (!ensureAuthenticated(context, ref)) {
                                      return;
                                    }
                                    final success = await ref
                                        .read(profileViewModelProvider.notifier)
                                        .toggleSaved(event.id);
                                    if (!context.mounted || !success) return;
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
                            icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_border,
                              color: saved
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
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
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              EventBadge(
                                event.category.toUpperCase(),
                                category: true,
                                color: AppColors.accent,
                                foreground: AppColors.textPrimary,
                              ),
                              if (event.spots case final spots?)
                                EventBadge('$spots spots left'),
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
                          if (event.organizer.isNotEmpty)
                            _EventOrganizer(
                              screen: screen,
                              event: event,
                              organizerId: raw?.organizerId,
                            ),
                          const Divider(height: AppSpacing.xl),
                          FlowMeta(
                            event.date,
                            subtitle: raw == null
                                ? (music ? 'Fall Semester Showcase' : null)
                                : raw.data['subtitle'] as String?,
                            screen: screen,
                            asset: 'imgContainer3',
                          ),
                          FlowMeta(
                            event.time,
                            subtitle: raw == null
                                ? (music ? 'Doors open: 17:30' : null)
                                : raw.data['doorsOpenAt'] == null
                                ? null
                                : 'Doors open: ${eventDate(DateTime.parse(raw.data['doorsOpenAt'] as String)).split(' · ').last}',
                            screen: screen,
                            asset: 'imgContainer4',
                          ),
                          FlowMeta(
                            event.venue,
                            subtitle: raw == null
                                ? (music
                                      ? 'West Campus Lawn • Gate 4 Entrance'
                                      : null)
                                : raw.venue['address'] as String?,
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
                              EventBadge(
                                event.audience,
                                color: AppColors.surfaceMuted,
                                foreground: AppColors.textSecondary,
                              ),
                              EventBadge(
                                event.walkIn ? 'Walk-in allowed' : event.policy,
                                color: AppColors.surfaceMuted,
                                foreground: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (raw?.walkIn == true) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                if (!ensureAuthenticated(context, ref)) return;
                                context.push(
                                  '/my-events/check-in?event=${event.id}',
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan Event QR'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (event.coins > 0)
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
                          if (event.deposit > 0)
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
                                          '${event.deposit}-coin deposit required',
                                          style: EviaTheme.label,
                                        ),
                                        const Text(
                                          'Held during registration · Cancel: 30% refund, rounded down · No-show: no refund',
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
                                    onPressed: () => context.replace(
                                      Uri(
                                        path: '/event/$section',
                                        queryParameters: {'event': eventId},
                                      ).toString(),
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
                            raw != null
                                ? _AboutPanel(remote: raw)
                                : music
                                ? const _AboutPanel()
                                : Text(
                                    '${event.title}\n${event.audience}',
                                    style: EviaTheme.caption,
                                  )
                          else if (tab == 'schedule')
                            _SchedulePanel(
                              screen: screen,
                              event: event,
                              remote: raw,
                              music: music,
                            )
                          else
                            raw != null || music
                                ? _LocationPanel(remote: raw)
                                : FlowMeta(
                                    event.venue,
                                    screen: screen,
                                    asset: 'imgContainer5',
                                  ),
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
  const _EventOrganizer({required this.screen, this.event, this.organizerId});
  final EventPresentation? event;
  final String? organizerId;
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = event?.organizer ?? '';
    final id =
        organizerId ??
        EviaMockData.organizers
            .where((organizer) => organizer.name == event?.organizer)
            .firstOrNull
            ?.id;
    final followed = ref.watch(
      eviaViewModelProvider.select((s) => s.followed.contains(id)),
    );
    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.lg,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            name
                .split(' ')
                .where((word) => word.isNotEmpty)
                .take(2)
                .map((word) => word[0])
                .join(),
            style: const TextStyle(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: InkWell(
            onTap: id == null
                ? null
                : () => context.push(
                    '/organizer?id=${Uri.encodeQueryComponent(id)}',
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Organized by', style: EviaTheme.caption),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event?.organizer ?? 'Student Union',
                        style: EviaTheme.label,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (id == 'union') ActivityIcon(screen, 'imgContainer2'),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (id != null)
          OutlinedButton(
            onPressed: () {
              if (!ensureAuthenticated(context, ref)) return;
              ref.read(eviaViewModelProvider.notifier).toggleFollowed(id);
            },
            child: Text(followed ? 'Following' : '+ Follow'),
          ),
      ],
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({this.remote});
  final Flow1Event? remote;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('About This Event', style: EviaTheme.cardTitle),
      const SizedBox(height: AppSpacing.md),
      Text(
        remote?.description ?? 'Kick off the fall semester with the biggest live music showcase on campus! Featuring student bands, guest DJ sets, food trucks, and light installations across the Main Stadium lawn.',
        style: EviaTheme.caption,
      ),
      const SizedBox(height: AppSpacing.xl),
      const Text("What You'll Gain", style: EviaTheme.cardTitle),
      const SizedBox(height: AppSpacing.md),
      for (
        var i = 0;
        i <
            (remote == null
                ? 3
                : jsonRows(remote!.data['benefits'] ?? []).length);
        i++
      ) ...[
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
                    remote == null
                        ? [
                            'Live Performances',
                            'Campus Networking',
                            'Free Merch & Snacks',
                          ][i]
                        : jsonRows(remote!.data['benefits'])[i]['title']
                              as String,
                    style: EviaTheme.label,
                  ),
                  Text(
                    remote == null
                        ? [
                            'Experience live sets from top student bands and guest artists.',
                            'Connect with peers across faculties and student club leaders.',
                            'Exclusive festival wristbands, stickers, and local food vouchers.',
                          ][i]
                        : jsonRows(remote!.data['benefits'])[i]['description']
                              as String,
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
      Text(
        remote != null
            ? (remote!.data['participantRequirements'] as List? ?? [])
                  .map((r) => '• $r')
                  .join('\n\n')
            : '• Open to all currently enrolled undergraduate and graduate students from any faculty.\n\n• Valid student ID (digital or physical card) required at Gate 4 entrance check-in.',
        style: EviaTheme.caption,
      ),
    ],
  );
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.screen,
    required this.event,
    this.remote,
    required this.music,
  });
  final Flow1Event? remote;
  final String screen;
  final EventPresentation event;
  final bool music;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(event.title, style: EviaTheme.section),
      const SizedBox(height: AppSpacing.lg),
      if (event.organizer.isNotEmpty)
        _EventOrganizer(
          screen: screen,
          event: event,
          organizerId: remote?.organizerId,
        ),
      const SizedBox(height: AppSpacing.lg),
      for (final item
          in (remote == null
              ? (music
                    ? RegistrationMockData.agenda
                    : [
                        EventAgendaItem(
                          event.time,
                          'Event starts',
                          '${event.date} · ${event.venue}',
                        ),
                      ])
              : remote!.schedule.map(
                  (s) => EventAgendaItem(
                    eventDate(DateTime.parse(s['startAt'] as String))
                        .split(' · ')
                        .last,
                    s['title'] as String,
                    s['description'] as String? ?? '',
                  ),
                ))) ...[
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
      if (remote != null || music)
        Text(
          remote == null
              ? 'Schedule subject to minor changes. Final artist lineup confirmed upon check-in.'
              : remote!.data['scheduleNote'] as String? ?? '',
          style: EviaTheme.caption,
        ),
    ],
  );
}

class _LocationPanel extends StatelessWidget {
  const _LocationPanel({this.remote});
  final Flow1Event? remote;
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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: ActivityIcon('2083:5137', 'imgContainer7'),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    EventBadge(
                      remote == null
                          ? '• Main Stadium Lawn'
                          : '• ${remote!.venue['name']}',
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
                        remote != null && i == 0
                            ? remote!.venue['name'] as String
                            : [
                                'Main Stadium',
                                'Entrance & Check-in',
                                'Accessibility & Transit',
                              ][i],
                        style: EviaTheme.label,
                      ),
                      if (i == 0)
                        EventBadge(
                          remote == null
                              ? 'GATE 4'
                              : remote!.venue['entranceLabel'] as String? ?? '',
                        ),
                      Text(
                        remote != null
                            ? [
                                    remote!.venue['address'] ?? '',
                                    remote!.venue['checkInInstructions'] ?? '',
                                    [
                                      remote!.venue['accessibilityNotes'],
                                      remote!.venue['transitNotes'],
                                    ].whereType<String>().join(' · '),
                                  ][i]
                                  as String
                            : [
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
          remote == null
              ? 'Map preview: Main Stadium Lawn, West Campus Lawn • University Ave Entrance. Enter via Gate 4.'
              : '${remote!.venue['name']} · ${remote!.venue['address'] ?? ''}',
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
