import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../models/evia_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/evia_brand.dart';
import '../../widgets/evia_widgets.dart';

class EviaDiscoverScreen extends ConsumerWidget {
  const EviaDiscoverScreen({this.guest = false, super.key});
  final bool guest;
  void _search(BuildContext context, WidgetRef ref) {
    ref.read(eviaViewModelProvider.notifier).showSearch();
    context.push('/explore');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(eviaViewModelProvider.select((s) => s.followed));
    final screen = guest ? '2083:1143' : '2083:456';
    return EviaPage(
      header: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const EviaLogo(),
            if (!guest) ...[
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  EviaMockData.discoverName,
                  style: EviaTheme.compactTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FigmaIcon('2083:456', 'imgContainer18'),
                    SizedBox(width: AppSpacing.xs),
                    Text(EviaMockData.points, style: EviaTheme.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push('/profile/notifications'),
                icon: const FigmaIcon('2083:456', 'imgContainer19'),
              ),
            ] else ...[
              const Spacer(),
              FilledButton(
                onPressed: () => context.push('/'),
                child: const Text('Log in'),
              ),
            ],
          ],
        ),
      ),
      footer: EviaBottomBar(guest: guest),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'Search events, organizers',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                onTap: () => _search(context, ref),
                child: EviaCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      FigmaIcon(screen, 'imgContainer'),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Search events, organizers...',
                          style: EviaTheme.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FeaturedEvent(guest: guest),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CarouselDot(active: true),
                _CarouselDot(),
                _CarouselDot(),
              ],
            ),
            SectionHeading(
              guest ? 'Popular Events' : 'Recommended for You',
              subtitle: guest
                  ? 'Trending on campus'
                  : 'Based on your interests in Technology & Arts',
              onSeeAll: () => _search(context, ref),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RecommendedCard(
                      event: EviaMockData.recommendedAi,
                      guest: guest,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _RecommendedCard(
                      event: EviaMockData.photoWalk,
                      guest: guest,
                    ),
                  ),
                ],
              ),
            ),
            if (!guest) ...[
              SectionHeading(
                'From Your Following',
                arrow: const FigmaIcon('2083:456', 'imgContainer11'),
                subtitle: 'Events from organizers you follow',
                onSeeAll: () => context.push('/following/events'),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final event
                        in ref
                            .read(eviaViewModelProvider.notifier)
                            .followedEventFeed)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: SizedBox(
                          width: EviaTheme.phoneWidth * .72,
                          child: _FollowingPreview(event: event),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SectionHeading(
              'Happening Soon',
              subtitle: 'Upcoming events on campus',
              onSeeAll: () => _search(context, ref),
            ),
            for (final event in EviaMockData.upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _UpcomingCard(event: event, guest: guest),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _CarouselDot extends StatelessWidget {
  const _CarouselDot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
    width: active ? AppSpacing.lg : AppSpacing.xs,
    height: AppSpacing.xs,
    decoration: BoxDecoration(
      color: active ? EviaTheme.blue : AppColors.border,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
  );
}

class _FeaturedEvent extends StatelessWidget {
  const _FeaturedEvent({required this.guest});
  final bool guest;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    return Container(
      constraints: const BoxConstraints(minHeight: EviaTheme.heroHeight),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: EviaTheme.featuredGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EventBadge(
                'FEATURED',
                color: AppColors.textSecondary,
                foreground: AppColors.surface,
                category: true,
              ),
              const SizedBox(width: AppSpacing.xs),
              const EventBadge(
                'MUSIC',
                color: AppColors.accent,
                foreground: AppColors.textPrimary,
                category: true,
              ),
              const Spacer(),
              BookmarkButton(
                event: EviaMockData.music,
                overlay: true,
                screen: screen,
                asset: 'imgContainer1',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Campus Music Night',
            style: EviaTheme.section.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FigmaIcon(screen, 'imgContainer2'),
              Text(
                'Oct 26 · 18:00',
                style: EviaTheme.caption.copyWith(color: AppColors.surface),
              ),
              FigmaIcon(screen, 'imgContainer3'),
              Text(
                'Main Stadium',
                style: EviaTheme.caption.copyWith(color: AppColors.surface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FigmaIcon(screen, 'imgContainer4'),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                '+120 coins',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
          TextButton(
            onPressed: () => showEvent(context, EviaMockData.music),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.surface,
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('View event'),
                const SizedBox(width: AppSpacing.xs),
                FigmaIcon(screen, 'imgContainer5'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.event, required this.guest});
  final CampusEvent event;
  final bool guest;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    return EviaCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: BookmarkButton(
                      event: event,
                      overlay: true,
                      screen: screen,
                      asset: 'imgContainer6',
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.xs,
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
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => showEvent(context, event),
            child: Text(event.title, style: EviaTheme.compactTitle),
          ),
          const SizedBox(height: AppSpacing.sm),
          EventMeta(event.date, screen: screen, asset: 'imgContainer7'),
          EventMeta(event.location, screen: screen, asset: 'imgContainer8'),
          EventMeta(event.audience, screen: screen, asset: 'imgContainer9'),
          const Spacer(),
          const Divider(height: AppSpacing.xl),
          EventBadge(
            event.policy,
            color: event.policy == 'Walk-in allowed'
                ? AppColors.successSurface
                : AppColors.primarySoft,
            foreground: event.policy == 'Walk-in allowed'
                ? AppColors.success
                : AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FigmaIcon(screen, 'imgContainer10'),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '+${event.coins} coins',
                style: EviaTheme.caption.copyWith(color: EviaTheme.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowingPreview extends StatelessWidget {
  const _FollowingPreview({required this.event});
  final CampusEvent event;
  @override
  Widget build(BuildContext context) => EviaCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                event.id == 'club' ? 'SU' : 'PC',
                style: EviaTheme.badge,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                event.organizer!,
                style: EviaTheme.label.copyWith(color: AppColors.primary),
              ),
            ),
            BookmarkButton(
              event: event,
              screen: '2083:456',
              asset: 'imgContainer12',
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventThumbnail(
              event: event,
              showImage: true,
              size: EviaTheme.compactThumbnail,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => showEvent(context, event),
                    child: Text(event.title, style: EviaTheme.compactTitle),
                  ),
                  EventMeta(
                    event.date,
                    screen: '2083:456',
                    asset: 'imgContainer13',
                  ),
                  Row(
                    children: [
                      const FigmaIcon('2083:456', 'imgContainer14'),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '+${event.coins} coins',
                        style: EviaTheme.caption.copyWith(
                          color: EviaTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.event, required this.guest});
  final CampusEvent event;
  final bool guest;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    return EviaCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventThumbnail(event: event, size: EviaTheme.thumbnail),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => showEvent(context, event),
                        child: Text(event.title, style: EviaTheme.compactTitle),
                      ),
                    ),
                    BookmarkButton(
                      event: event,
                      screen: screen,
                      asset: guest
                          ? event.id == 'football'
                                ? 'imgContainer11'
                                : 'imgContainer12'
                          : event.id == 'football'
                          ? 'imgContainer15'
                          : 'imgContainer17',
                    ),
                  ],
                ),
                EventMeta(event.date, screen: screen, asset: 'imgContainer7'),
                EventMeta(
                  event.location,
                  screen: screen,
                  asset: 'imgContainer8',
                ),
                if (guest)
                  EventMeta(
                    event.audience,
                    screen: screen,
                    asset: 'imgContainer9',
                  ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    EventBadge(
                      event.policy,
                      color: event.policy == 'Walk-in allowed'
                          ? AppColors.successSurface
                          : AppColors.primarySoft,
                      foreground: event.policy == 'Walk-in allowed'
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FigmaIcon(
                          screen,
                          guest ? 'imgContainer10' : 'imgContainer16',
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '+${event.coins} coins',
                          style: EviaTheme.caption.copyWith(
                            color: EviaTheme.gold,
                          ),
                        ),
                      ],
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
}
