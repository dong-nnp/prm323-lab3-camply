import 'package:flutter/material.dart';

import '../core/constants/flow_assets.dart';
import '../models/registration_models.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import '../theme/flow_theme.dart';
import 'activity_widgets.dart';
import 'evia_widgets.dart';

class FlowMeta extends StatelessWidget {
  const FlowMeta(
    this.text, {
    required this.screen,
    required this.asset,
    this.subtitle,
    this.compact = false,
    super.key,
  });
  final String text, screen, asset;
  final String? subtitle;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: compact ? 0 : AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: ActivityIcon(screen, asset),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: EviaTheme.caption),
              if (subtitle != null) Text(subtitle!, style: FlowTheme.helpText),
            ],
          ),
        ),
      ],
    ),
  );
}

class FlowEventSummary extends StatelessWidget {
  const FlowEventSummary({
    required this.screen,
    required this.event,
    this.form = false,
    this.legacy = false,
    this.legacyError = false,
    this.full = false,
    super.key,
  });
  final String screen;
  final EventPresentation event;
  final bool form, legacy, legacyError, full;
  @override
  Widget build(BuildContext context) {
    final isGoing = screen == '2083:5861';
    final modern = screen == '2083:5709' || screen == '2083:5329';
    final legacyDefault = screen == '2083:5029' || screen == '2083:5987';
    final dateIcon = legacyError
        ? 'imgSvg1'
        : screen == '2083:5329'
        ? 'imgSvg'
        : 'imgContainer';
    final venueIcon = legacyError
        ? 'imgSvg2'
        : screen == '2083:5329'
        ? 'imgSvg2'
        : modern
        ? 'imgContainer2'
        : 'imgContainer1';
    return EviaCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: legacyError || screen == '2083:5329'
                ? 78
                : form
                ? FlowTheme.formThumbnail
                : EviaTheme.thumbnail - AppSpacing.lg,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Stack(
                children: [
                  if (event.id != 'music-live' && event.id != 'club-live')
                    Positioned.fill(
                      child: switch (event.image) {
                        final image? => catalogImage(
                          image,
                          FlowAssets.image(screen, 0),
                          fit: BoxFit.cover,
                        ),
                        null => const ColoredBox(
                          color: AppColors.primarySoft,
                          child: Icon(Icons.event_outlined),
                        ),
                      },
                    )
                  else if (legacyError || screen == '2083:5329')
                    Positioned(
                      left: -28,
                      top: -73,
                      width: 334,
                      height: 715.5,
                      child: catalogImage(
                        event.image,
                        FlowAssets.image(screen, 0),
                        fit: BoxFit.fill,
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Image.asset(
                        FlowAssets.image(
                          screen,
                          isGoing ||
                                  screen == '2083:4961' ||
                                  screen == '2083:5931'
                              ? 1
                              : 0,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (modern || legacyError || isGoing)
                    Positioned(
                      left: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: EventBadge(
                        legacyError ? 'LIVE' : event.category.toUpperCase(),
                        category: true,
                        color: AppColors.accent,
                        foreground: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (legacyError)
                  const Row(
                    children: [
                      ActivityIcon('2083:4627', 'imgSvg'),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'FESTIVAL',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                if (!form && !isGoing)
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
                      if (full)
                        const EventBadge(
                          'EVENT FULL',
                          color: AppColors.warningSurface,
                          foreground: AppColors.warning,
                        ),
                    ],
                  ),
                Text(event.title, style: EviaTheme.cardTitle),
                FlowMeta(
                  legacy || legacyDefault
                      ? 'Oct 26, 2026 • 18:00 – 22:00'
                      : modern
                      ? event.date
                      : '${event.date} · ${event.time}',
                  screen: screen,
                  asset: dateIcon,
                  compact: true,
                ),
                if (modern)
                  FlowMeta(
                    event.time,
                    screen: screen,
                    asset: screen == '2083:5329' ? 'imgSvg1' : 'imgContainer1',
                    compact: true,
                  ),
                FlowMeta(
                  event.venue,
                  screen: screen,
                  asset: venueIcon,
                  compact: true,
                ),
                if (isGoing) const EventBadge('Walk-in allowed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
