import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/figma_assets.dart';
import '../models/evia_models.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import '../viewmodels/evia_view_model.dart';
import '../viewmodels/authentication_view_model.dart';
import 'authenticated_action.dart';

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.screen, this.name, {super.key});
  final String screen, name;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(FigmaAssets.path(screen, name));
}

class EviaPage extends StatelessWidget {
  const EviaPage({
    required this.child,
    this.header,
    this.footer,
    this.background = AppColors.background,
    super.key,
  });
  final Widget child;
  final Widget? header, footer;
  final Color background;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ColoredBox(
            color: background,
            child: Column(
              children: [
                ?header,
                Expanded(child: child),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EviaCard extends StatelessWidget {
  const EviaCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.surface,
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.large),
      border: Border.all(color: AppColors.border),
      boxShadow: EviaTheme.cardShadow,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    ),
  );
}

class EviaHeader extends StatelessWidget {
  const EviaHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.backAsset,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing, backAsset;
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back to Discover',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/discover'),
          icon: backAsset ?? const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        trailing ?? const SizedBox(width: AppSizes.minimumTouchTarget),
      ],
    ),
  );
}

class EviaPill extends StatelessWidget {
  const EviaPill(
    this.label, {
    this.selected = false,
    this.onTap,
    this.leading,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minimumTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? AppColors.surface
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EventBadge extends StatelessWidget {
  const EventBadge(
    this.label, {
    this.color = AppColors.primarySoft,
    this.foreground = AppColors.primary,
    this.category = false,
    super.key,
  });
  final String label;
  final Color color, foreground;
  final bool category;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(
        category ? AppRadius.small / 2 : AppRadius.small,
      ),
    ),
    child: Text(
      label,
      style: (category ? EviaTheme.badge : EviaTheme.label).copyWith(
        color: foreground,
      ),
    ),
  );
}

class EventMeta extends StatelessWidget {
  const EventMeta(
    this.text, {
    required this.screen,
    required this.asset,
    this.compact = false,
    super.key,
  });
  final String text, screen, asset;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: FigmaIcon(screen, asset),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: EviaTheme.caption)),
      ],
    ),
  );
}

class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    required this.event,
    required this.screen,
    required this.asset,
    this.overlay = false,
    super.key,
  });
  final CampusEvent event;
  final String screen, asset;
  final bool overlay;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(hasAuthenticatedSessionProvider) &&
        ref.watch(
          eviaViewModelProvider.select((s) => s.saved.contains(event.id)),
        );
    final initial = event.id == 'football' || event.id == 'mobile';
    return IconButton(
      tooltip: saved
          ? 'Remove ${event.title} from saved'
          : 'Save ${event.title}',
      isSelected: saved,
      onPressed: () {
        if (!ensureAuthenticated(context, ref)) return;
        ref.read(eviaViewModelProvider.notifier).toggleSaved(event.id);
      },
      icon: saved == initial
          ? overlay
                ? Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: EviaTheme.bookmarkOverlay,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: FigmaIcon(screen, asset),
                  )
                : FigmaIcon(screen, asset)
          : Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? AppColors.primary : AppColors.textSecondary,
            ),
    );
  }
}

void showEvent(BuildContext context, CampusEvent event) => context.push(
  Uri(
    path: '/event/schedule',
    queryParameters: {'event': event.detailKey},
  ).toString(),
);

class SearchEventCard extends StatelessWidget {
  const SearchEventCard({required this.event, this.idle = false, super.key});
  final CampusEvent event;
  final bool idle;
  @override
  Widget build(BuildContext context) {
    final screen = idle ? '2083:993' : '2083:826';
    return EviaCard(
      onTap: () => showEvent(context, event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventThumbnail(event: event, showImage: true),
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
                          screen: screen,
                          asset: idle
                              ? 'imgContainer5'
                              : event.id == 'mobile'
                              ? 'imgContainer10'
                              : 'imgContainer6',
                        ),
                      ],
                    ),
                    EventMeta(
                      event.date,
                      screen: screen,
                      asset: idle ? 'imgContainer6' : 'imgContainer7',
                    ),
                    EventMeta(
                      event.location,
                      screen: screen,
                      asset: idle ? 'imgContainer7' : 'imgContainer8',
                    ),
                    EventMeta(
                      event.audience,
                      screen: screen,
                      asset: idle
                          ? event.id == 'ai'
                                ? 'imgContainer9'
                                : 'imgContainer8'
                          : 'imgContainer9',
                    ),
                    if (!idle) ...[
                      const SizedBox(height: AppSpacing.md),
                      _policy(event),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (idle) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _policy(event),
                if (event.note != null)
                  EventBadge(
                    event.note!,
                    color: event.id == 'music'
                        ? AppColors.successSurface
                        : AppColors.primarySoft,
                    foreground: event.id == 'music'
                        ? AppColors.success
                        : AppColors.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Widget _policy(CampusEvent event) => EventBadge(
  event.policy,
  color: event.policy == 'Walk-in allowed'
      ? AppColors.successSurface
      : event.policy == 'Waitlist available'
      ? AppColors.warningSurface
      : AppColors.primarySoft,
  foreground: event.policy == 'Walk-in allowed'
      ? AppColors.success
      : event.policy == 'Waitlist available'
      ? AppColors.warning
      : AppColors.primary,
);

class EventThumbnail extends StatelessWidget {
  const EventThumbnail({
    required this.event,
    this.showImage = false,
    this.size = EviaTheme.thumbnail,
    super.key,
  });
  final CampusEvent event;
  final bool showImage;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Stack(
        children: [
          Positioned.fill(
            child: showImage && event.image != null
                ? Image.asset(
                    event.image!,
                    fit: BoxFit.cover,
                    semanticLabel: event.title,
                  )
                : const ColoredBox(color: AppColors.surfaceMuted),
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
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    this.subtitle,
    this.onSeeAll,
    this.arrow,
    super.key,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final Widget? arrow;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: EviaTheme.section)),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('See all'),
                    if (arrow != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      arrow!,
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (subtitle != null) Text(subtitle!, style: EviaTheme.caption),
      ],
    ),
  );
}

class EviaBottomBar extends StatelessWidget {
  const EviaBottomBar({this.guest = false, super.key});
  final bool guest;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    final start = guest ? 13 : 20;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (i == 0) {
                    context.go(guest ? '/discover/guest' : '/discover');
                    return;
                  }
                  if (i == 3) {
                    context.go('/profile');
                    return;
                  }
                  context.go(i == 1 ? '/my-events' : '/rewards');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FigmaIcon(screen, 'imgContainer${start + i}'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ['Discover', 'Events', 'Rewards', 'Profile'][i],
                        style: EviaTheme.caption.copyWith(
                          color: i == 0 ? AppColors.primary : EviaTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
