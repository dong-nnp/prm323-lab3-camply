import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/activity_mock_data.dart';
import '../../core/constants/activity_assets.dart';
import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import 'monthly_calendar.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({this.view = '', this.cancelId = 'music', super.key});
  final String view, cancelId;
  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(activityViewModelProvider.notifier).setReference(widget.view);
      }
    });
  }

  String screenFor(ActivityState state) {
    if (widget.view == 'calendar') return '2083:2481';
    if (state.past) {
      if (state.selectedDate == null) return '2083:2931';
      return state.selectedDate!.day == 26 ? '2083:2170' : '2083:2012';
    }
    return state.selectedDate == null ? '2083:273' : '2083:3108';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final screen = screenFor(state);
    final start = switch (screen) {
      '2083:2170' => 11,
      '2083:2931' => 13,
      '2083:273' => 9,
      '2083:2481' => 12,
      _ => 8,
    };
    final calendar = switch (screen) {
      '2083:2012' => 7,
      '2083:2170' => 10,
      '2083:2931' => 12,
      _ => 0,
    };
    final content = Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Events', style: ActivityTheme.title),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage your registrations and passes',
                      style: EviaTheme.caption,
                    ),
                  ],
                ),
              ),
              EviaCard(
                padding: EdgeInsets.zero,
                child: IconButton(
                  tooltip: 'Open monthly calendar',
                  onPressed: () {
                    vm.beginCalendar();
                    context.push('/my-events/calendar');
                  },
                  icon: ActivityIcon(screen, 'imgContainer$calendar'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActivityTabs(
                  labels: [
                    'Upcoming  ${vm.countFor(false)}',
                    'Past  ${vm.countFor(true)}',
                  ],
                  selected: state.past ? 1 : 0,
                  onSelected: (index) => vm.selectTab(index == 1),
                ),
                const SizedBox(height: AppSpacing.lg),
                _WeekStrip(screen: screen),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.selectedDate == null
                            ? 'All ${state.past ? 'Past' : 'Upcoming'} Events'
                            : 'Events on ${monthName(state.selectedDate!.month).substring(0, 3)} ${state.selectedDate!.day}, ${state.selectedDate!.year}',
                        style: EviaTheme.section,
                      ),
                    ),
                    EventBadge(
                      screen == '2083:2931'
                          ? '${vm.visibleEvents.length} event${vm.visibleEvents.length == 1 ? '' : 's'}'
                          : '${vm.visibleEvents.length}',
                    ),
                    if (state.selectedDate != null)
                      TextButton(
                        onPressed: vm.showAll,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Show all'),
                            const SizedBox(width: AppSpacing.xs),
                            ActivityIcon(
                              screen,
                              screen == '2083:2170' || screen == '2083:2012'
                                  ? 'imgContainer2'
                                  : 'imgContainer3',
                            ),
                          ],
                        ),
                      ),
                    if (screen == '2083:2931')
                      TextButton(
                        onPressed: () {
                          vm.beginCalendar();
                          context.push('/my-events/calendar');
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActivityIcon('2083:2931', 'imgContainer3'),
                            Text('Filter'),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (vm.visibleEvents.isEmpty) ...[
                  EviaCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: AppSpacing.xxxl,
                                  backgroundColor: AppColors.primarySoft,
                                  child: CircleAvatar(
                                    radius: AppSpacing.xl + AppSpacing.xs,
                                    backgroundColor: AppColors.surface,
                                    child: ActivityIcon(
                                      '2083:2012',
                                      'imgContainer4',
                                    ),
                                  ),
                                ),
                                const CircleAvatar(
                                  radius: AppSpacing.lg,
                                  backgroundColor: ActivityTheme.actionDark,
                                  child: ActivityIcon(
                                    '2083:2012',
                                    'imgContainer5',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text(
                            'No events on this date',
                            textAlign: TextAlign.center,
                            style: EviaTheme.section,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'You have no ${state.past ? 'past events recorded' : 'upcoming events'} for this day.',
                            textAlign: TextAlign.center,
                            style: EviaTheme.caption,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppButton(
                            label: state.past
                                ? 'Show all past events'
                                : 'Show all events',
                            onPressed: vm.showAll,
                            trailing: const ActivityIcon(
                              '2083:2012',
                              'imgContainer3',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.past) ...[
                    const SizedBox(height: AppSpacing.lg),
                    EviaCard(
                      color: EviaTheme.lavender,
                      child: Row(
                        children: [
                          const ActivityIcon('2083:2012', 'imgContainer6'),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Looking for earlier records?',
                                  style: EviaTheme.label,
                                ),
                                Text(
                                  'Monday, Oct 26 has 1 registered activity',
                                  style: EviaTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                vm.selectDate(DateTime(2026, 10, 26)),
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else
                  for (final event in vm.visibleEvents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _RegisteredCard(event: event, screen: screen),
                    ),
                if (state.past && vm.visibleEvents.isNotEmpty) ...[
                  if (state.selectedDate != null)
                    EviaCard(
                      color: EviaTheme.lavender,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: ActivityIcon('2083:2170', 'imgContainer9'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: InkWell(
                              onTap: () => showActivityHelp(
                                context,
                                'Event feedback',
                                'Thanks for joining Campus Music Night. Feedback submissions are currently unavailable.',
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Did you enjoy this concert?',
                                    style: EviaTheme.label,
                                  ),
                                  Text(
                                    'Leave feedback to earn an extra 20 campus perks.',
                                    style: EviaTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    EviaCard(
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: ActivityIcon('2083:2931', 'imgContainer10'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fall Semester Active',
                                  style: EviaTheme.label,
                                ),
                                Text(
                                  '1 of 4 required seasonal campus events verified.',
                                  style: EviaTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'View event milestones',
                            onPressed: () =>
                                context.push('/rewards/milestones'),
                            icon: const ActivityIcon(
                              '2083:2931',
                              'imgContainer11',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
    return EviaPage(
      footer: ActivityBottomBar(
        screen: widget.view == 'cancel' ? '2083:2795' : screen,
        start: widget.view == 'cancel' ? 9 : start,
        selected: widget.view == 'cancel' ? 2 : 1,
        legacy: widget.view == 'cancel',
      ),
      child: widget.view == 'calendar'
          ? ActivityOverlay(
              background: content,
              bottom: true,
              child: const MonthlyCalendar(),
            )
          : widget.view == 'cancel'
          ? ActivityOverlay(
              background: const _CancellationBackdrop(),
              child: _CancelRegistration(eventId: widget.cancelId),
            )
          : content,
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final end = state.week.add(const Duration(days: 6));
    final previous = switch (screen) {
      '2083:2012' || '2083:2170' => 0,
      _ => 1,
    };
    final strip = Column(
      children: [
        Row(
          children: [
            if (screen == '2083:2931') ...[
              const ActivityIcon('2083:2931', 'imgContainer'),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                '${monthName(state.week.month).substring(0, 3)} ${state.week.day} – ${monthName(end.month).substring(0, 3)} ${end.day}, ${end.year}',
                style: EviaTheme.label,
              ),
            ),
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => vm.shiftWeek(-1),
              icon: ActivityIcon(screen, 'imgContainer$previous'),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: () => vm.shiftWeek(1),
              icon: ActivityIcon(screen, 'imgContainer${previous + 1}'),
            ),
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs / 2,
                  ),
                  child: _DayCell(day: state.week.add(Duration(days: i))),
                ),
              ),
          ],
        ),
      ],
    );
    return screen == '2083:2012' || screen == '2083:2931'
        ? EviaCard(padding: const EdgeInsets.all(AppSpacing.md), child: strip)
        : strip;
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final selected =
        state.selectedDate != null && vm.sameDay(day, state.selectedDate!);
    final today = vm.sameDay(day, ActivityMockData.referenceDate);
    return Semantics(
      selected: selected,
      label: '${monthName(day.month)} ${day.day}',
      button: true,
      child: Material(
        color: selected
            ? ActivityTheme.action
            : today
            ? ActivityTheme.lavender
            : state.past
            ? Colors.transparent
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: () => vm.selectDate(day),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                Text(
                  today && !state.past
                      ? 'TODAY'
                      : [
                          'MON',
                          'TUE',
                          'WED',
                          'THU',
                          'FRI',
                          'SAT',
                          'SUN',
                        ][day.weekday - 1],
                  style: ActivityTheme.smallLabel.copyWith(
                    color: selected
                        ? AppColors.surface
                        : today
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${day.day}',
                  style: EviaTheme.label.copyWith(
                    color: selected ? AppColors.surface : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: AppSpacing.xs,
                  child: vm.hasEvent(day)
                      ? Icon(
                          Icons.circle,
                          size: AppSpacing.xs,
                          color: selected
                              ? AppColors.surface
                              : AppColors.primary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisteredCard extends ConsumerWidget {
  const _RegisteredCard({required this.event, required this.screen});
  final RegisteredEvent event;
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = event.attended;
    final allPast = screen == '2083:2931';
    final meta = past
        ? allPast
              ? 6
              : 5
        : screen == '2083:273'
        ? 4
        : 5;
    final status = past
        ? allPast
              ? 4
              : 3
        : screen == '2083:273'
        ? event.waitlisted
              ? 7
              : 3
        : 4;
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: EviaTheme.thumbnail,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: event.image != null
                            ? Image.asset(event.image!, fit: BoxFit.cover)
                            : const ColoredBox(color: EviaTheme.lavender),
                      ),
                      Positioned(
                        left: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: EventBadge(
                          event.category.toUpperCase(),
                          category: true,
                          color: AppColors.accent,
                          foreground: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: event.waitlisted
                                ? AppColors.warningSurface
                                : AppColors.successSurface,
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActivityIcon(screen, 'imgContainer$status'),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  past
                                      ? 'Attended'
                                      : event.waitlisted
                                      ? 'Waitlisted · #4 in line'
                                      : 'Registered',
                                  style: EviaTheme.caption.copyWith(
                                    color: event.waitlisted
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (past)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ActivityIcon(
                                  screen,
                                  allPast ? 'imgContainer5' : 'imgContainer4',
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '+${event.coins} Coins',
                                  style: EviaTheme.caption.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(event.title, style: EviaTheme.cardTitle),
                    _ActivityMeta(
                      event.dateLabel,
                      ActivityIcon(screen, 'imgContainer$meta'),
                    ),
                    _ActivityMeta(
                      event.venue,
                      ActivityIcon(screen, 'imgContainer${meta + 1}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (past) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: ActivityTheme.lavender,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Row(
                children: [
                  ActivityIcon(
                    screen,
                    allPast ? 'imgContainer8' : 'imgContainer7',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Attendance verified at Gate B',
                      style: EviaTheme.caption,
                    ),
                  ),
                  if (allPast)
                    const Flexible(
                      child: Text(
                        '18:14 CHECK-IN',
                        style: ActivityTheme.smallLabel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () =>
                  context.push('/my-events/ticket?event=${event.id}'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('View Details'),
                  const SizedBox(width: AppSpacing.xs),
                  ActivityIcon(
                    screen,
                    allPast ? 'imgContainer9' : 'imgContainer8',
                  ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: event.waitlisted
                        ? 'View Status'
                        : event.walkIn
                        ? 'Check In'
                        : 'View Ticket',
                    onPressed: () {
                      if (event.waitlisted) {
                        showActivityHelp(
                          context,
                          'Waitlist status',
                          'You are #4 in line. We’ll let you know when a spot becomes available.',
                        );
                      } else if (event.walkIn) {
                        context.push('/my-events/check-in');
                      } else {
                        context.push('/my-events/ticket?event=${event.id}');
                      }
                    },
                    trailing: ActivityIcon(
                      screen,
                      screen == '2083:273'
                          ? event.waitlisted
                                ? 'imgContainer8'
                                : 'imgContainer6'
                          : 'imgContainer7',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/my-events/cancel?event=${event.id}'),
                    child: Text(event.waitlisted ? 'Leave Waitlist' : 'Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta(this.label, this.icon);
  final String label;
  final Widget icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: EviaTheme.caption)),
      ],
    ),
  );
}

class _CancellationBackdrop extends StatelessWidget {
  const _CancellationBackdrop();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Events', style: ActivityTheme.title),
                  Text(
                    'Manage your registrations and passes',
                    style: EviaTheme.caption,
                  ),
                ],
              ),
            ),
            ActivityIcon('2083:2795', 'imgContainer'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ActivityTabs(
          labels: const ['Upcoming  2', 'Past  1'],
          selected: 0,
          onSelected: (_) {},
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: EviaCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: ActivityTheme.detailImageHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            ActivityAssets.image('2083:2795', i),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.md,
                          left: AppSpacing.md,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActivityIcon(
                                '2083:2795',
                                i == 0 ? 'imgContainer1' : 'imgContainer6',
                              ),
                              EventBadge(
                                i == 0 ? 'REGISTERED' : 'CONFIRMED',
                                color: AppColors.accent,
                                foreground: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                        if (i == 0)
                          const Positioned(
                            bottom: AppSpacing.md,
                            right: AppSpacing.md,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ActivityIcon('2083:2795', 'imgContainer2'),
                                Text(
                                  'Row C • Seat 14',
                                  style: TextStyle(color: AppColors.surface),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 0
                              ? 'Campus Music Night'
                              : 'AI & Future Careers Workshop',
                          style: EviaTheme.section,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ActivityMeta(
                          i == 0
                              ? 'Friday, Oct 24 • 7:00 PM'
                              : 'Nov 2, 2026 • 09:00 - 12:00',
                          ActivityIcon(
                            '2083:2795',
                            i == 0 ? 'imgContainer3' : 'imgContainer6',
                          ),
                        ),
                        _ActivityMeta(
                          i == 0
                              ? 'Campus Amphitheater'
                              : 'Innovation Hub • Hall A',
                          ActivityIcon(
                            '2083:2795',
                            i == 0 ? 'imgContainer4' : 'imgContainer7',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Expanded(child: Text('View Ticket')),
                            const ActivityIcon('2083:2795', 'imgContainer5'),
                            const SizedBox(width: AppSpacing.lg),
                            const Text('Cancel'),
                          ],
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
  );
}

class _CancelRegistration extends ConsumerWidget {
  const _CancelRegistration({required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(activityViewModelProvider.notifier);
    final event = vm.event(eventId);
    void close() => context.canPop() ? context.pop() : context.go('/my-events');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            backgroundColor: AppColors.errorSurface,
            child: ActivityIcon('2083:2795', 'imgContainer8'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Cancel Registration?', style: ActivityTheme.title),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Are you sure you want to cancel your registration for ${event.title}? Your ticket will no longer be available.',
          style: EviaTheme.caption,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: close,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('Keep Registration'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () {
            vm.cancelRegistration(eventId);
            close();
          },
          child: const Text(
            'Yes, Cancel',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
