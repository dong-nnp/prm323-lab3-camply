import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../models/evia_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/status_widgets.dart';

class EviaFollowingScreen extends ConsumerWidget {
  const EviaFollowingScreen({this.organizers = false, super.key});
  final bool organizers;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eviaViewModelProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    final events = organizers ? const <CampusEvent>[] : vm.followingEvents;
    return EviaPage(
      header: EviaHeader(
        title: organizers ? 'Followed Organizers' : 'Following',
        subtitle: 'Events from the campus clubs you follow',
        backAsset: FigmaIcon(
          organizers ? '2083:1873' : '2083:1582',
          'imgContainer${organizers ? 12 : 13}',
        ),
        trailing: organizers
            ? IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push('/profile'),
                icon: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: FigmaIcon('2083:1873', 'imgContainer13'),
                ),
              )
            : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FollowingTabs(organizers: organizers),
            const SizedBox(height: AppSpacing.md),
            if (organizers) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Following Organizers',
                      style: EviaTheme.section,
                    ),
                  ),
                  EventBadge('${state.followed.length} Active'),
                  IconButton(
                    tooltip: 'Sort organizers',
                    onPressed: ref
                        .read(eviaViewModelProvider.notifier)
                        .toggleSort,
                    icon: const FigmaIcon('2083:1873', 'imgContainer2'),
                  ),
                ],
              ),
              const Text(
                'Manage the campus organizers you follow',
                style: EviaTheme.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final organizer
                  in ref
                      .read(eviaViewModelProvider.notifier)
                      .followedOrganizers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _OrganizerCard(organizer: organizer),
                ),
              if (state.followed.isEmpty)
                const AppEmptyWidget(
                  title: 'No followed organizers',
                  message: 'Follow an organizer to keep up with their campus events.',
                ),
              const SizedBox(height: AppSpacing.lg),
              _SuggestedOrganizers(),
              const SizedBox(height: AppSpacing.xl),
              const EviaCard(
                color: EviaTheme.lavenderSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FigmaIcon('2083:1873', 'imgContainer11'),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stay in the loop', style: EviaTheme.label),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Follow campus organizers to find them again in this list.',
                            style: EviaTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final name in [
                      'All',
                      ...vm.followedClubEvents
                          .map((event) => event.organizer)
                          .whereType<String>()
                          .where((name) => name.isNotEmpty)
                          .toSet(),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: EviaPill(
                          name,
                          selected: state.organizer == name,
                          leading: name == 'All'
                              ? const FigmaIcon('2083:1582', 'imgContainer')
                              : null,
                          onTap: () => ref
                              .read(eviaViewModelProvider.notifier)
                              .selectOrganizer(name),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(
                    child: Text('Their Events', style: EviaTheme.section),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: ref
                          .read(eviaViewModelProvider.notifier)
                          .toggleSort,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              state.descending
                                  ? 'Date: Latest'
                                  : 'Date: Soonest',
                              style: EviaTheme.caption,
                            ),
                          ),
                          const FigmaIcon('2083:1582', 'imgContainer1'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (events.isEmpty)
                const AppEmptyWidget(
                  title: 'No events from followed clubs',
                  message: 'Follow clubs to discover their events here.',
                ),
              for (final event in events)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FollowingEvent(event: event),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          "You've reached the end",
                          textAlign: TextAlign.center,
                          style: EviaTheme.caption,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              SectionHeading(
                'Recommended Organizers',
                arrow: const FigmaIcon('2083:1582', 'imgContainer8'),
                onSeeAll: () => context.go('/following/organizers'),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final organizer
                          in (vm.live
                              ? vm.suggestedOrganizers
                              : EviaMockData.recommendations))
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: SizedBox(
                            width: EviaTheme.phoneWidth * .4,
                            child: _RecommendedOrganizer(organizer: organizer),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _FollowingTabs extends StatelessWidget {
  const _FollowingTabs({required this.organizers});
  final bool organizers;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: EviaTheme.lavender,
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: Material(
              color: (i == 1) == organizers
                  ? AppColors.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.small),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.small),
                onTap: () => context.go(
                  i == 0 ? '/following/events' : '/following/organizers',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (organizers) ...[
                        FigmaIcon(
                          '2083:1873',
                          i == 0 ? 'imgContainer' : 'imgContainer1',
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          i == 0 ? 'Their Events' : 'Organizers',
                          textAlign: TextAlign.center,
                          style: EviaTheme.label.copyWith(
                            color: (i == 1) == organizers
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FollowingEvent extends StatelessWidget {
  const _FollowingEvent({required this.event});
  final CampusEvent event;
  @override
  Widget build(BuildContext context) => EviaCard(
    onTap: () => showEvent(context, event),
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventThumbnail(event: event),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(event.title, style: EviaTheme.cardTitle),
                  ),
                  BookmarkButton(
                    event: event,
                    screen: '2083:1582',
                    asset: 'imgContainer2',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (event.organizer case final name? when name.isNotEmpty)
                Row(
                  children: [
                    FigmaIcon(
                      '2083:1582',
                      event.id == 'club' ? 'imgContainer3' : 'imgContainer6',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        name,
                        style: EviaTheme.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              EventMeta(
                event.date,
                screen: '2083:1582',
                asset: event.id == 'club' ? 'imgContainer4' : 'imgContainer7',
              ),
              Text(event.location, style: EviaTheme.caption),
              const SizedBox(height: AppSpacing.md),
              EventBadge(
                event.policy,
                color: event.policy == 'Walk-in allowed'
                    ? AppColors.successSurface
                    : EviaTheme.lavender,
                foreground: event.policy == 'Walk-in allowed'
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const CoinIcon(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '+${event.coins} coins',
                      style: EviaTheme.label.copyWith(color: EviaTheme.gold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrganizerCard extends ConsumerWidget {
  const _OrganizerCard({required this.organizer});
  final CampusOrganizer organizer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(
      eviaViewModelProvider.select((s) => s.followed.contains(organizer.id)),
    );
    final recommendation = {
      'drama',
      'gaming',
      'environment',
    }.contains(organizer.id);
    Widget button() => TextButton(
      onPressed: () =>
          ref.read(eviaViewModelProvider.notifier).toggleFollowed(organizer.id),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (followed)
            const FigmaIcon('2083:1873', 'imgContainer6')
          else
            const Icon(Icons.add),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(followed ? 'Following' : 'Follow')),
        ],
      ),
    );
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: organizer.icon == 2
                    ? AppColors.accent
                    : AppColors.primarySoft,
                radius: AppSpacing.xl,
                child: FigmaIcon(
                  recommendation ? '2083:1582' : '2083:1873',
                  recommendation
                      ? [
                          'imgContainer9',
                          'imgContainer11',
                          'imgContainer12',
                        ][organizer.icon]
                      : organizer.icon == 0
                      ? 'imgContainer3'
                      : organizer.icon == 1
                      ? 'imgContainer7'
                      : 'imgContainer9',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizer.name,
                      style: EviaTheme.compactTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (organizer.badge == 'verified')
                      const FigmaIcon('2083:1873', 'imgContainer4'),
                    if (organizer.badge == 'CLUB')
                      const EventBadge(
                        'CLUB',
                        color: AppColors.accent,
                        foreground: AppColors.textPrimary,
                        category: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            organizer.description,
            style: EviaTheme.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (organizer.upcomingCount > 0)
                EventBadge(
                  '${organizer.upcomingCount} upcoming ${organizer.upcomingCount == 1 ? 'event' : 'events'}',
                ),
              if (organizer.followers.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: AppSizes.navigationIcon,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(organizer.followers, style: EviaTheme.caption),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(alignment: Alignment.centerRight, child: button()),
        ],
      ),
    );
  }
}

class _SuggestedOrganizers extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(eviaViewModelProvider);
    final suggestions = ref
        .read(eviaViewModelProvider.notifier)
        .suggestedOrganizers;
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FigmaIcon('2083:1873', 'imgContainer8'),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Suggested for you', style: EviaTheme.label),
              ),
              Flexible(child: Text('RECOMMENDED', style: EviaTheme.caption)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (suggestions.isEmpty)
            const Text('You’re following all suggested organizers.'),
          for (final organizer in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: FigmaIcon(
                      '2083:1873',
                      organizer.icon == 2
                          ? 'imgContainer9'
                          : organizer.icon == 0
                          ? 'imgContainer3'
                          : 'imgContainer7',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(organizer.name, style: EviaTheme.compactTitle),
                        Text(organizer.description, style: EviaTheme.caption),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => ref
                        .read(eviaViewModelProvider.notifier)
                        .toggleFollowed(organizer.id),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FigmaIcon('2083:1873', 'imgContainer10'),
                        Text('Follow'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendedOrganizer extends ConsumerWidget {
  const _RecommendedOrganizer({required this.organizer});
  final CampusOrganizer organizer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(
      eviaViewModelProvider.select((s) => s.followed.contains(organizer.id)),
    );
    return EviaCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          CircleAvatar(
            radius: AppSpacing.xl,
            backgroundColor: EviaTheme.lavender,
            child: FigmaIcon(
              '2083:1582',
              [
                'imgContainer9',
                'imgContainer11',
                'imgContainer12',
              ][organizer.icon],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            organizer.name,
            textAlign: TextAlign.center,
            style: EviaTheme.compactTitle,
          ),
          Text(
            organizer.description,
            textAlign: TextAlign.center,
            style: EviaTheme.caption,
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => ref
                .read(eviaViewModelProvider.notifier)
                .toggleFollowed(organizer.id),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!followed) const FigmaIcon('2083:1582', 'imgContainer10'),
                Flexible(child: Text(followed ? 'Following' : 'Follow')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
