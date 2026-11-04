import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/activity_assets.dart';
import '../../data/mock/activity_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';

class EventMilestonesScreen extends ConsumerWidget {
  const EventMilestonesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      activityViewModelProvider.select((s) => s.verified.length),
    );
    return EviaPage(
      header: const ActivityHeader(
        'Event Milestones',
        screen: '2083:4156',
        backAsset: 'imgContainer1',
      ),
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Explore Events',
            trailing: const ActivityIcon('2083:4156', 'imgContainer'),
            onPressed: () => context.go('/explore'),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EviaCard(
              color: ActivityTheme.wallet,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EventBadge('CURRENT ACHIEVEMENT'),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Explorer', style: ActivityTheme.title),
                        Text(
                          '$count verified events attended',
                          style: EviaTheme.caption,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$count / 5 events',
                                style: EviaTheme.label,
                              ),
                            ),
                            Text('${(count / 5 * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: (count / 5).clamp(0, 1),
                          minHeight: AppSpacing.sm,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Attend ${(5 - count).clamp(0, 5)} more events to reach Active Student.',
                          style: EviaTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Image.asset(
                    ActivityAssets.path(
                      '2083:4156',
                      'imgCheerfulBlueTicketAchievementMascot',
                    ),
                    width: EviaTheme.thumbnail,
                    height: EviaTheme.thumbnail,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              children: [
                Expanded(
                  child: Text('Your Milestones', style: EviaTheme.section),
                ),
                EventBadge('2 of 5 unlocked'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            EviaCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < ActivityMockData.milestones.length; i++)
                    _MilestoneRow(index: i),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            EviaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ActivityIcon('2083:4156', 'imgContainer8'),
                      SizedBox(width: AppSpacing.sm),
                      Text('How it works', style: EviaTheme.cardTitle),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  for (final rule in [
                    'Only verified event check-ins count.',
                    'Each eligible event counts once, whether walk-in or registered.',
                    'Progress never expires; milestone rewards are awarded only once.',
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ActivityIcon('2083:4156', 'imgMargin'),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(rule, style: EviaTheme.caption)),
                        ],
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

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final milestone = ActivityMockData.milestones[index];
    final claimed = index < 2;
    final next = index == 2;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: claimed
                      ? AppColors.success
                      : next
                      ? ActivityTheme.action
                      : AppColors.surfaceMuted,
                ),
                child: ActivityIcon(
                  '2083:4156',
                  claimed
                      ? 'imgContainer2'
                      : next
                      ? 'imgContainer5'
                      : 'imgContainer6',
                ),
              ),
              if (index < 4)
                Expanded(
                  child: VerticalDivider(
                    color: claimed
                        ? AppColors.successSurface
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.xl,
                top: AppSpacing.sm,
              ),
              decoration: next
                  ? BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Text(
                        milestone.title,
                        style: EviaTheme.label.copyWith(
                          color: index > 2 ? EviaTheme.muted : null,
                        ),
                      ),
                      EventBadge(
                        '${milestone.events} ${milestone.events == 1 ? 'EVENT' : 'EVENTS'}',
                        color: next
                            ? AppColors.primarySoft
                            : AppColors.surfaceMuted,
                        foreground: EviaTheme.muted,
                        category: true,
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: index > 2
                              ? AppColors.surfaceMuted
                              : AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActivityIcon(
                              '2083:4156',
                              index > 2 ? 'imgContainer7' : 'imgContainer4',
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '+${milestone.coins}',
                              style: EviaTheme.caption.copyWith(
                                color: index > 2
                                    ? ActivityTheme.disabled
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (claimed)
                    const Row(
                      children: [
                        ActivityIcon('2083:4156', 'imgContainer3'),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Claimed',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ],
                    ),
                  if (next) const EventBadge('NEXT GOAL'),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    milestone.description,
                    style: EviaTheme.caption.copyWith(
                      color: index > 2 ? ActivityTheme.disabled : null,
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
