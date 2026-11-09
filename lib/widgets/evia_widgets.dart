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
import '../viewmodels/flow1_view_model.dart';
import '../core/providers/service_providers.dart';
import 'authenticated_action.dart';
import 'coin_icon.dart';

class FigmaIcon extends StatelessWidget {
  const FigmaIcon(this.screen, this.name, {super.key});
  final String screen, name;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(FigmaAssets.path(screen, name));
}

Widget catalogImage(
  String? url,
  String fallback, {
  double? width,
  double? height,
  BoxFit? fit,
  String? semanticLabel,
}) => url != null && Uri.tryParse(url)?.hasScheme == true
    ? Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => Uri.tryParse(fallback)?.hasScheme == true
            ? const ColoredBox(color: AppColors.surfaceMuted)
            : Image.asset(
                fallback,
                width: width,
                height: height,
                fit: fit,
                semanticLabel: semanticLabel,
              ),
      )
    : Image.asset(
        url ?? fallback,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
      );

class EviaPage extends StatelessWidget {
  const EviaPage({
    required this.child,
    this.header,
    this.footer,
    this.floatingActionButton,
    this.background = AppColors.background,
    super.key,
  });
  final Widget child;
  final Widget? header, footer, floatingActionButton;
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
                Expanded(
                  child: floatingActionButton == null
                      ? child
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            child,
                            Positioned(
                              right: AppSpacing.lg,
                              bottom: AppSpacing.lg,
                              child: floatingActionButton!,
                            ),
                          ],
                        ),
                ),
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
    this.maxLines,
    super.key,
  });
  final String text, screen, asset;
  final bool compact;
  final int? maxLines;
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
        Expanded(
          child: Text(
            text,
            style: EviaTheme.caption,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
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
    final busy =
        ref.watch(realBackendEnabledProvider) &&
        ref.watch(
          flow1ViewModelProvider.select(
            (state) => state.asData?.value.busy ?? false,
          ),
        );
    final icon = Icon(
      saved ? Icons.bookmark : Icons.bookmark_border,
      size: AppSizes.navigationIcon,
      color: saved ? AppColors.primary : AppColors.textSecondary,
    );
    return IconButton(
      tooltip: saved
          ? 'Remove ${event.title} from saved'
          : 'Save ${event.title}',
      isSelected: saved,
      onPressed: busy
          ? null
          : () {
              if (!ensureAuthenticated(context, ref)) return;
              ref.read(eviaViewModelProvider.notifier).toggleSaved(event.id);
            },
      icon: overlay
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: icon,
            )
          : icon,
    );
  }
}

void showEvent(BuildContext context, CampusEvent event) => context.push(
  Uri(
    path: '/event/schedule',
    queryParameters: {'event': event.detailKey},
  ).toString(),
);

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({required this.event, this.guest = false, super.key});
  final CampusEvent event;
  final bool guest;
  @override
  Widget build(BuildContext context) {
    final screen = guest ? '2083:1143' : '2083:456';
    return EviaCard(
      onTap: () => showEvent(context, event),
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
                      child: Text(event.title, style: EviaTheme.compactTitle),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchEventCard extends StatelessWidget {
  const SearchEventCard({required this.event, this.idle = false, super.key});
  final CampusEvent event;
  final bool idle;
  @override
  Widget build(BuildContext context) => UpcomingEventCard(event: event);
}

class EventThumbnail extends StatelessWidget {
  const EventThumbnail({
    required this.event,
    this.showImage = true,
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
                ? catalogImage(
                    event.image,
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
  const EviaBottomBar({this.guest = false, this.selected = 0, super.key});
  final bool guest;
  final int selected;
  @override
  Widget build(BuildContext context) {
    const labels = ['Discover', 'Events', 'Rewards', 'Profile'];
    const icons = [
      Icons.explore_outlined,
      Icons.calendar_today_outlined,
      Icons.card_giftcard_outlined,
      Icons.person_outline,
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Semantics(
                label: '${labels[i]} tab',
                button: true,
                selected: i == selected,
                child: InkWell(
                  onTap: () {
                    if (i == selected) return;
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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[i],
                          size: AppSizes.navigationIcon,
                          color: i == selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          labels[i],
                          style: EviaTheme.caption.copyWith(
                            color: i == selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox.square(
                          dimension: AppSpacing.xs,
                          child: i == selected
                              ? const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
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
}
