import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/rewards_wallet.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({this.catalog = false, super.key});
  final bool catalog;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final screen = catalog ? '2083:3327' : '2083:3522';
    return EviaPage(
      header: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Expanded(child: Text('Rewards', style: ActivityTheme.title)),
            IconButton(
              tooltip: 'Rewards help',
              onPressed: () => showActivityHelp(
                context,
                'Rewards',
                'Earn coins by attending campus events and checking in daily. Exchange available coins for rewards.',
              ),
              icon: ActivityIcon(
                screen,
                catalog ? 'imgContainer14' : 'imgContainer',
              ),
            ),
            if (catalog)
              IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push('/'),
                icon: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: ActivityIcon('2083:3327', 'imgContainer15'),
                ),
              ),
          ],
        ),
      ),
      footer: ActivityBottomBar(
        screen: screen,
        start: catalog ? 16 : 12,
        selected: 2,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RewardsWallet(screen: screen),
            const SizedBox(height: AppSpacing.lg),
            ActivityTabs(
              activeColor: catalog ? AppColors.primary : AppColors.surface,
              activeForeground: catalog ? AppColors.surface : AppColors.primary,
              labels: const ['Earn Coins', 'Redeem Rewards'],
              selected: catalog ? 1 : 0,
              onSelected: (index) =>
                  context.go(index == 0 ? '/rewards' : '/rewards/catalog'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (catalog) ...[
              InkWell(
                onTap: () => context.push('/rewards/locker'),
                child: const EviaCard(
                  child: Row(
                    children: [
                      ActivityIcon('2083:3327', 'imgContainer5'),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Rewards', style: EviaTheme.cardTitle),
                            Text(
                              'View your redeemed vouchers',
                              style: EviaTheme.caption,
                            ),
                          ],
                        ),
                      ),
                      ActivityIcon('2083:3327', 'imgContainer6'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                initialValue: state.rewardQuery,
                onChanged: vm.searchRewards,
                decoration: const InputDecoration(
                  hintText: 'Search rewards...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: ActivityIcon('2083:3327', 'imgContainer7'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: EviaPill(
                          [
                            'All',
                            'Food & Drinks',
                            'Merchandise',
                            'Experiences',
                          ][i],
                          selected:
                              state.rewardCategory ==
                              [
                                'All',
                                'Food & Drinks',
                                'Merchandise',
                                'Experiences',
                              ][i],
                          leading: ActivityIcon(
                            '2083:3327',
                            'imgContainer${8 + i}',
                          ),
                          onTap: () => vm.selectRewardCategory(
                            [
                              'All',
                              'Food & Drinks',
                              'Merchandise',
                              'Experiences',
                            ][i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (vm.visibleRewards.isEmpty)
                const EviaCard(child: Text('No rewards match your search.')),
              for (var i = 0; i < vm.visibleRewards.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _RewardCard(reward: vm.visibleRewards[i]),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: i + 1 < vm.visibleRewards.length
                              ? _RewardCard(reward: vm.visibleRewards[i + 1])
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              _DailyCheckIn(),
              const SizedBox(height: AppSpacing.lg),
              _MilestoneSummary(),
              const SizedBox(height: AppSpacing.md),
              const Text('More Ways to Earn', style: EviaTheme.section),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    onTap: () => i == 0
                        ? context.push('/my-events/check-in')
                        : showActivityHelp(
                            context,
                            'Complete Missions',
                            'New campus missions will appear here when available.',
                          ),
                    child: EviaCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: i == 0
                                ? AppColors.accent
                                : AppColors.primarySoft,
                            child: ActivityIcon(
                              '2083:3522',
                              i == 0 ? 'imgContainer3' : 'imgContainer4',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i == 0
                                      ? 'Attend Events'
                                      : 'Complete Missions',
                                  style: EviaTheme.label,
                                ),
                                Text(
                                  i == 0
                                      ? 'Check in at events to earn coins'
                                      : 'Finish activities to earn rewards',
                                  style: EviaTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          const Text('›'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends ConsumerWidget {
  const _RewardCard({required this.reward});
  final CampusReward reward;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(
      activityViewModelProvider.select((s) => s.available),
    );
    final eligible = balance >= reward.catalogCost;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/rewards/detail?id=${reward.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(reward.image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: eligible
                            ? AppColors.successSurface
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eligible)
                            const ActivityIcon('2083:3327', 'imgContainer12'),
                          Flexible(
                            child: Text(
                              eligible
                                  ? 'Eligible'
                                  : 'Need ${reward.catalogCost - balance} coins',
                              style: EviaTheme.caption.copyWith(
                                color: eligible ? AppColors.success : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(reward.title, style: EviaTheme.compactTitle),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const ActivityIcon('2083:3327', 'imgContainer13'),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '${reward.catalogCost} coins',
                      style: EviaTheme.caption,
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

class _DailyCheckIn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checked = ref.watch(
      activityViewModelProvider.select((s) => s.checkedInToday),
    );
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Check-in', style: EviaTheme.cardTitle),
                    Text(
                      'Check in every day to earn more coins.',
                      style: EviaTheme.caption,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ActivityIcon('2083:3522', 'imgContainer7'),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          checked ? '4-day streak' : '3-day streak',
                          style: EviaTheme.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        i == 3 ? 'Today' : 'Day ${i + 1}',
                        style: ActivityTheme.smallLabel.copyWith(
                          color: i == 3 ? AppColors.primary : EviaTheme.muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 3 || (i == 3 && checked)
                              ? ActivityTheme.actionDark
                              : i == 6
                              ? AppColors.warningSurface
                              : AppColors.primarySoft,
                        ),
                        child: i < 3 || (i == 3 && checked)
                            ? const ActivityIcon('2083:3522', 'imgContainer8')
                            : i == 3
                            ? const ActivityIcon('2083:3522', 'imgContainer9')
                            : i == 6
                            ? const ActivityIcon('2083:3522', 'imgContainer10')
                            : const Icon(
                                Icons.circle,
                                size: AppSpacing.xs,
                                color: AppColors.border,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '+${[5, 5, 10, 10, 15, 15, 20][i]}',
                        style: ActivityTheme.smallLabel.copyWith(
                          color: EviaTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: Text(
              'Miss a day? Your streak restarts at Day 1.',
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: checked
                  ? 'Checked In Today · +10 coins'
                  : 'Check In Today · +10 coins',
              trailing: const ActivityIcon('2083:3522', 'imgContainer11'),
              onPressed: checked
                  ? null
                  : ref.read(activityViewModelProvider.notifier).dailyCheckIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      activityViewModelProvider.select((s) => s.verified.length),
    );
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.warningSurface,
                child: ActivityIcon('2083:3522', 'imgContainer1'),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Milestones', style: EviaTheme.cardTitle),
                    Text(
                      'Earn bonus coins by joining campus events',
                      style: EviaTheme.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/rewards/milestones'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Text('$count of 5 events attended')),
              Text(
                '${(count / 5 * 100).round()}%',
                style: EviaTheme.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (count / 5).clamp(0, 1),
            minHeight: AppSpacing.sm,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          const SizedBox(height: AppSpacing.md),
          EviaCard(
            color: AppColors.primarySoft,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next: Active Student',
                        style: EviaTheme.label,
                      ),
                      Text(
                        'Attend ${(5 - count).clamp(0, 5)} more events',
                        style: EviaTheme.caption,
                      ),
                    ],
                  ),
                ),
                const EventBadge('+150 COINS'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (final label in ['1 Event', '3 Events', '5 Events'])
                Expanded(
                  child: Column(
                    children: [
                      Text(label, style: EviaTheme.caption),
                      SizedBox(height: AppSpacing.sm),
                      CircleAvatar(
                        radius: AppSpacing.md,
                        backgroundColor: label == '5 Events'
                            ? AppColors.primarySoft
                            : AppColors.primary,
                        child: label == '5 Events'
                            ? const Icon(
                                Icons.circle,
                                size: AppSpacing.sm,
                                color: AppColors.primary,
                              )
                            : const ActivityIcon('2083:3522', 'imgContainer2'),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        label == '5 Events' ? 'Next Goal' : 'Claimed',
                        style: EviaTheme.caption,
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
}
