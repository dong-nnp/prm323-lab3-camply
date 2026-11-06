import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/activity_assets.dart';
import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/milestone_presentation_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/coin_icon.dart';

class EventMilestonesScreen extends ConsumerWidget {
  const EventMilestonesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityViewModelProvider);
    final count = ref.read(activityViewModelProvider.notifier).verifiedCount;
    final vm = ref.read(activityViewModelProvider.notifier);
    final intro = ref.watch(milestoneIntroProvider).value;
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
            if (intro != null) ...[
              EviaCard(child: Text(intro, style: EviaTheme.caption)),
              const SizedBox(height: AppSpacing.md),
            ],
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
                        Text(vm.currentAchievement, style: ActivityTheme.title),
                        Text(
                          '$count verified events attended',
                          style: EviaTheme.caption,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$count / ${vm.milestoneTarget} events',
                                style: EviaTheme.label,
                              ),
                            ),
                            Text('${vm.milestonePercent}%'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(
                          value: vm.milestoneFraction,
                          minHeight: AppSpacing.sm,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          vm.nextMilestone?.description ??
                              'All milestones reached.',
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
            Row(
              children: [
                Expanded(
                  child: Text('Your Milestones', style: EviaTheme.section),
                ),
                Flexible(
                  child: EventBadge(
                    '${vm.unlockedMilestones} of ${vm.milestones.length} unlocked',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            EviaCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < vm.milestones.length; i++)
                    _MilestoneRow(
                      progress: vm.milestones[i],
                      last: i == vm.milestones.length - 1,
                    ),
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
                      Flexible(
                        child: Text('How it works', style: EviaTheme.cardTitle),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  for (final rule in [
                    'Only verified event check-ins count.',
                    'Each eligible event counts once, whether walk-in or registered.',
                    'Progress is saved to your account. Claim each milestone once.',
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

class _MilestoneRow extends ConsumerWidget {
  const _MilestoneRow({required this.progress, required this.last});
  final MilestoneProgress progress;
  final bool last;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestone = progress.milestone;
    final claimed = progress.claimed;
    final next = progress.next;
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
              if (!last)
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
                          color: !claimed && !next ? EviaTheme.muted : null,
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
                          color: !claimed && !next
                              ? AppColors.surfaceMuted
                              : AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoinIcon(
                              color: !claimed && !next
                                  ? ActivityTheme.disabled
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '+${milestone.coins}',
                              style: EviaTheme.caption.copyWith(
                                color: !claimed && !next
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
                  if (!claimed)
                    Text(
                      progress.reached ? 'Ready to claim' : 'Not reached',
                      style: EviaTheme.caption,
                    ),
                  if (progress.reached && !claimed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: progress.claiming ? 'Claiming…' : 'Claim reward',
                      isLoading: progress.claiming,
                      onPressed: progress.canClaim
                          ? () async {
                              await ref
                                  .read(activityViewModelProvider.notifier)
                                  .claimMilestone(milestone.id);
                              if (!context.mounted) return;
                              final message = ref
                                  .read(activityViewModelProvider)
                                  .message;
                              if (message != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                  if (next) const EventBadge('NEXT GOAL'),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    progress.description,
                    style: EviaTheme.caption.copyWith(
                      color: !claimed && !next ? ActivityTheme.disabled : null,
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
