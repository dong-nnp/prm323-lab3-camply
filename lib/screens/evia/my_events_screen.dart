import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/activity_assets.dart';
import '../../models/activity_models.dart';
import '../../core/providers/service_providers.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../widgets/app_feedback.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/status_widgets.dart';
import 'monthly_calendar.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({this.view = '', this.cancelId = 'music', super.key});
  final String view, cancelId;
  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) {
        ref.read(activityViewModelProvider.notifier).setReference(widget.view);
        if (ref.read(realBackendEnabledProvider)) {
          ref.read(flow1ViewModelProvider.notifier).refresh();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(realBackendEnabledProvider)) {
      ref.read(flow1ViewModelProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
              ],
            ),
          ),
        ),
      ],
    );
    return EviaPage(
      footer: const EviaBottomBar(selected: 1),
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
    final today = vm.sameDay(day, vm.today);
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
        ? 3
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
                            ? catalogImage(
                                event.image,
                                event.image!,
                                fit: BoxFit.cover,
                              )
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
                            color: AppColors.successSurface,
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
                                  past ? 'Attended' : event.status,
                                  style: EviaTheme.caption.copyWith(
                                    color: AppColors.success,
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
                                const CoinIcon(),
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
                  Expanded(
                    child: Text(
                      event.verifiedAt == null
                          ? 'Attendance verified at Gate B'
                          : 'Attendance verified',
                      style: EviaTheme.caption,
                    ),
                  ),
                  if (allPast)
                    Flexible(
                      child: Text(
                        event.verifiedAt == null
                            ? '18:14 CHECK-IN'
                            : '${event.verifiedAt!.toUtc().add(const Duration(hours: 7)).hour.toString().padLeft(2, '0')}:${event.verifiedAt!.toUtc().add(const Duration(hours: 7)).minute.toString().padLeft(2, '0')} CHECK-IN',
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
                    label: event.walkIn ? 'Check In' : 'View Ticket',
                    onPressed: () {
                      if (event.walkIn) {
                        context.push('/my-events/check-in?event=${event.id}');
                      } else {
                        context.push('/my-events/ticket?event=${event.id}');
                      }
                    },
                    trailing: ActivityIcon(
                      screen,
                      screen == '2083:273' ? 'imgContainer6' : 'imgContainer7',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !event.canCancel
                        ? null
                        : () => context.push(
                            '/my-events/cancel?event=${event.id}',
                          ),
                    child: const Text('Cancel'),
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

class _CancellationBackdrop extends ConsumerWidget {
  const _CancellationBackdrop();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(realBackendEnabledProvider);
    ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final events = vm.visibleEvents;
    return SingleChildScrollView(
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
            labels: live
                ? [
                    'Upcoming  ${vm.countFor(false)}',
                    'Past  ${vm.countFor(true)}',
                  ]
                : const ['Upcoming  2', 'Past  1'],
            selected: 0,
            onSelected: (_) {},
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < (live ? events.length : 2); i++)
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
                            child: catalogImage(
                              live ? events[i].image : null,
                              ActivityAssets.image('2083:2795', i % 2),
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
                                  live
                                      ? events[i].status.toUpperCase()
                                      : i == 0
                                      ? 'REGISTERED'
                                      : 'CONFIRMED',
                                  color: AppColors.accent,
                                  foreground: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                          if (i == 0 && !live)
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
                            live
                                ? events[i].title
                                : i == 0
                                ? 'Campus Music Night'
                                : 'AI & Future Careers Workshop',
                            style: EviaTheme.section,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ActivityMeta(
                            live
                                ? events[i].dateLabel
                                : i == 0
                                ? 'Friday, Oct 24 • 7:00 PM'
                                : 'Nov 2, 2026 • 09:00 - 12:00',
                            ActivityIcon(
                              '2083:2795',
                              i == 0 ? 'imgContainer3' : 'imgContainer6',
                            ),
                          ),
                          _ActivityMeta(
                            live
                                ? events[i].venue
                                : i == 0
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
}

class _CancelRegistration extends ConsumerWidget {
  const _CancelRegistration({required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(activityViewModelProvider.notifier);
    final busy = ref.watch(activityViewModelProvider).cancellingEventId != null;
    final event = ref.read(realBackendEnabledProvider)
        ? vm.findEvent(eventId)
        : vm.event(eventId);
    if (event == null) {
      return AppErrorWidget(
        message: 'No registration for this event. Open My Events to select an existing registration.',
        onRetry: () => ref.read(flow1ViewModelProvider.notifier).refresh(),
      );
    }
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
          'Are you sure you want to cancel your registration for ${event.title}? Your ticket will no longer be available. You will receive 30% of your held deposit back, rounded down to whole coins. The remaining deposit is forfeited.',
          style: EviaTheme.caption,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: busy ? null : close,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('Keep Registration'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  final router = GoRouter.of(context);
                  final live = ref.read(realBackendEnabledProvider);
                  final success = await vm.cancelEvent(eventId);
                  if (success) {
                    if (live) {
                      router.go('/my-events');
                    } else if (context.mounted) {
                      close();
                    }
                  } else {
                    if (!context.mounted) return;
                    AppFeedback.show(
                      context,
                      ref.read(activityViewModelProvider).message ??
                          'Please retry.',
                      isError: true,
                    );
                  }
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
