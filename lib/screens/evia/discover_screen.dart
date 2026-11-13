import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../models/evia_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/app_motion.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../core/providers/service_providers.dart';
import '../../widgets/evia_brand.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/evibaby_chat.dart';
import '../../widgets/coin_icon.dart';
import 'explore_screen.dart';

class EviaDiscoverScreen extends ConsumerStatefulWidget {
  const EviaDiscoverScreen({this.guest = false, super.key});
  final bool guest;
  @override
  ConsumerState<EviaDiscoverScreen> createState() => _EviaDiscoverScreenState();
}

class _EviaDiscoverScreenState extends ConsumerState<EviaDiscoverScreen> {
  bool _searchExpanded = false;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(eviaViewModelProvider.notifier).showSearch();
    if (widget.guest) {
      setState(() => _searchExpanded = true);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } else {
      context.push('/explore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = widget.guest;
    ref.watch(eviaViewModelProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    final live = ref.watch(realBackendEnabledProvider);
    final demo = ref.watch(demoAuthEnabledProvider);
    final featured = vm.featuredEvents;
    final recommendations = vm.recommended;
    final balance = ref.watch(
      activityViewModelProvider.select((s) => s.available),
    );
    final followedEvents = guest
        ? const <CampusEvent>[]
        : vm.followedClubEvents;
    final screen = guest ? '2083:1143' : '2083:456';
    return EviaPage(
      floatingActionButton: const EvibabyLauncher(),
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
              Expanded(
                child: Text(vm.discoverName, style: EviaTheme.compactTitle),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          live || demo ? '$balance coins' : EviaMockData.points,
                          style: EviaTheme.caption,
                        ),
                      ),
                    ],
                  ),
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
                onPressed: () => context.push('/login'),
                child: const Text('Log in'),
              ),
            ],
          ],
        ),
      ),
      footer: EviaBottomBar(guest: guest),
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searchExpanded)
                EviaExploreScreen(
                  onClose: () => setState(() => _searchExpanded = false),
                )
              else
                Semantics(
                  button: true,
                  label: 'Search events, organizers',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    onTap: _search,
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
              if (featured.isNotEmpty)
                _FeaturedCarousel(
                  key: ValueKey(featured.map((event) => event.id).join(',')),
                  events: featured,
                  guest: guest,
                ),
              if (guest || recommendations.isNotEmpty) ...[
                SectionHeading(
                  guest ? 'Popular Events' : 'Recommended for You',
                  subtitle: guest
                      ? 'Trending on campus'
                      : vm.recommendationSubtitle,
                  onSeeAll: _search,
                ),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < recommendations.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width:
                                  constraints.maxWidth *
                                  EviaTheme.recommendedCardWidthFactor,
                              child: _RecommendedCard(
                                event: recommendations[i],
                                guest: guest,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (!guest) ...[
                SectionHeading(
                  'From Clubs You Follow',
                  arrow: const FigmaIcon('2083:456', 'imgContainer11'),
                  subtitle: 'Discover events from your followed clubs',
                  onSeeAll: () => context.push('/following/events'),
                ),
                if (followedEvents.isEmpty)
                  EviaCard(
                    child: Text(
                      vm.followedOrganizers.isEmpty
                          ? 'Follow a club to see its events here.'
                          : 'Your followed clubs have no events to show yet.',
                      style: EviaTheme.caption,
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final event in followedEvents)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.md,
                            ),
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
                onSeeAll: _search,
              ),
              for (final event in (live ? vm.events : EviaMockData.upcoming))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: UpcomingEventCard(event: event, guest: guest),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({
    required this.events,
    required this.guest,
    super.key,
  });
  final List<CampusEvent> events;
  final bool guest;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel>
    with WidgetsBindingObserver {
  int _active = 0;
  final _controller = ScrollController(keepScrollOffset: false);
  Timer? _timer;
  bool _enabled = false;
  bool _foreground = true;
  bool _animating = false;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _restartTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_enabled || !_foreground || _touching || widget.events.length < 2) {
      return;
    }
    _timer = Timer.periodic(AppMotion.bannerInterval, (_) => _advance());
  }

  Future<void> _advance() async {
    if (!mounted ||
        _animating ||
        !_controller.hasClients ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final width = _controller.position.viewportDimension;
    if (width <= 0) return;
    _animating = true;
    try {
      final next = (_controller.offset / width).round() + 1;
      await _controller.animateTo(
        next * width,
        duration: AppMotion.bannerTransition,
        curve: Curves.easeInOutCubic,
      );
      // The extra first slide makes the last-to-first transition slide forward.
      if (mounted &&
          _controller.hasClients &&
          _controller.offset >= width * widget.events.length) {
        _controller.jumpTo(0);
      }
    } finally {
      _animating = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LayoutBuilder(
        builder: (context, constraints) =>
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification.metrics.axis == Axis.horizontal) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _timer?.cancel();
                  }
                  final page =
                      (notification.metrics.pixels / constraints.maxWidth)
                          .round()
                          .clamp(0, widget.events.length) %
                      widget.events.length;
                  if (page != _active) setState(() => _active = page);
                  if (notification is ScrollEndNotification) {
                    if (!_animating &&
                        _controller.offset >=
                            constraints.maxWidth * widget.events.length) {
                      _controller.jumpTo(0);
                    }
                    _restartTimer();
                  }
                }
                return false;
              },
              child: Listener(
                onPointerDown: (_) {
                  _touching = true;
                  _timer?.cancel();
                },
                onPointerUp: (_) {
                  _touching = false;
                  _restartTimer();
                },
                onPointerCancel: (_) {
                  _touching = false;
                  _restartTimer();
                },
                child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const PageScrollPhysics(),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final event in [
                          ...widget.events,
                          if (widget.events.length > 1) widget.events.first,
                        ])
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _FeaturedEvent(
                              guest: widget.guest,
                              event: event,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
      if (widget.events.length > 1) ...[
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: 'Featured event ${_active + 1} of ${widget.events.length}',
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.events.length; i++)
                  _CarouselDot(active: i == _active),
              ],
            ),
          ),
        ),
      ],
    ],
  );
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
  const _FeaturedEvent({required this.guest, required this.event});
  final bool guest;
  final CampusEvent event;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    return GestureDetector(
      onTap: () => showEvent(context, event),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: EviaTheme.featuredBannerMinHeight,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          gradient: EviaTheme.featuredGradient,
        ),
        child: Stack(
          children: [
            if (event.image != null) ...[
              Positioned.fill(
                child: catalogImage(
                  event.image,
                  event.image!,
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: EviaTheme.featuredImageOverlay,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            const EventBadge(
                              'FEATURED',
                              color: AppColors.textSecondary,
                              foreground: AppColors.surface,
                              category: true,
                            ),
                            EventBadge(
                              event.category.toUpperCase(),
                              color: AppColors.accent,
                              foreground: AppColors.textPrimary,
                              category: true,
                            ),
                          ],
                        ),
                      ),
                      BookmarkButton(
                        event: event,
                        overlay: true,
                        screen: screen,
                        asset: 'imgContainer1',
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.lg),
                  Transform.translate(
                    offset: const Offset(0, AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: EviaTheme.section.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FigmaIcon(screen, 'imgContainer2'),
                            Text(
                              event.date,
                              style: EviaTheme.caption.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                            FigmaIcon(screen, 'imgContainer3'),
                            Text(
                              event.location,
                              style: EviaTheme.caption.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CoinIcon(),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                '+${event.coins} coins',
                                style: EviaTheme.caption.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showEvent(context, event),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.surface,
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(child: Text('View event')),
                          const SizedBox(width: AppSpacing.xs),
                          FigmaIcon(screen, 'imgContainer5'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final scaler = MediaQuery.textScalerOf(context);
    Widget twoLines(Widget child, TextStyle style, {double padding = 0}) =>
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                scaler.scale(style.fontSize!) * style.height! * 2 + padding,
          ),
          child: child,
        );
    Widget meta(String text, String asset) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: EventMeta(text, screen: screen, asset: asset, maxLines: 2),
    );
    return EviaCard(
      onTap: () => showEvent(context, event),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: EviaTheme.recommendedImageAspectRatio,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Stack(
                children: [
                  if (event.image != null)
                    Positioned.fill(
                      child: catalogImage(
                        event.image,
                        event.image!,
                        fit: BoxFit.cover,
                      ),
                    ),
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
          twoLines(
            Text(
              event.title,
              style: EviaTheme.compactTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            EviaTheme.compactTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          meta(event.date, 'imgContainer7'),
          meta(event.location, 'imgContainer8'),
          meta(event.audience, 'imgContainer9'),
          const Spacer(),
          const Divider(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                  const CoinIcon(),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '+${event.coins} coins',
                      style: EviaTheme.caption.copyWith(color: EviaTheme.gold),
                    ),
                  ),
                ],
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
    onTap: () => showEvent(context, event),
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.md,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                event.category.substring(0, 1),
                style: EviaTheme.badge,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                (event.organizer?.isNotEmpty ?? false)
                    ? event.organizer!
                    : event.policy,
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
                  Text(event.title, style: EviaTheme.compactTitle),
                  EventMeta(
                    event.date,
                    screen: '2083:456',
                    asset: 'imgContainer13',
                  ),
                  Row(
                    children: [
                      const CoinIcon(),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          '+${event.coins} coins',
                          style: EviaTheme.caption.copyWith(
                            color: EviaTheme.gold,
                          ),
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
