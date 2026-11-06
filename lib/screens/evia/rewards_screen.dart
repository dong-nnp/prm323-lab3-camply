import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/flow1_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/rewards_wallet.dart';
import '../../widgets/coin_icon.dart';
import '../../data/mock/activity_mock_data.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({this.catalog = false, super.key});
  final bool catalog;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
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
              icon: const ActivityIcon('2083:3522', 'imgContainer'),
            ),
          ],
        ),
      ),
      footer: ActivityBottomBar(screen: '2083:3522', start: 12, selected: 2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RewardsWallet(screen: '2083:3522'),
            const SizedBox(height: AppSpacing.lg),
            ActivityTabs(
              activeColor: AppColors.surface,
              activeForeground: AppColors.primary,
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
                    onTap: () => context.push(
                      i == 0 ? '/my-events' : '/rewards/milestones',
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
                                  i == 0 ? 'Attend Events' : 'Event Milestones',
                                  style: EviaTheme.label,
                                ),
                                Text(
                                  i == 0
                                      ? 'View your events and check-in options'
                                      : 'Track your event attendance milestones',
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
    ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final eligible = vm.canRedeem(reward.id);
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
                    child: catalogImage(
                      reward.image,
                      ActivityMockData.rewards.first.image,
                      fit: BoxFit.cover,
                    ),
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
                              vm.rewardStatus(reward.id),
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
                  const CoinIcon(),
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

class _DailyCheckIn extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DailyCheckIn> createState() => _DailyCheckInState();
}

class _DailyCheckInState extends ConsumerState<_DailyCheckIn> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(realBackendEnabledProvider) &&
          ref.read(flow1ViewModelProvider).hasValue) {
        ref.read(flow1ViewModelProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final live = ref.watch(realBackendEnabledProvider);
    final account = live ? ref.watch(flow1ViewModelProvider) : null;
    final liveVm = live ? ref.read(flow1ViewModelProvider.notifier) : null;
    final server = liveVm?.dailyProgress;
    if (live && server == null) {
      return EviaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Check-in', style: EviaTheme.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            if (account?.isLoading == true)
              const Text('Loading daily check-in…')
            else
              TextButton(
                onPressed: liveVm?.refresh,
                child: const Text('Reload daily check-in'),
              ),
          ],
        ),
      );
    }
    final demo = ActivityMockData.dailyCheckInPreview;
    final days = server?.days ?? demo.days;
    final streakDay = server?.day ?? demo.day;
    final coins = server?.coins ?? demo.coins;
    final checkedIn = server?.checkedInToday ?? state.dailyClaimed;
    final saving = live
        ? vm.dailySaving || (server?.saving ?? false)
        : demo.saving;
    final error = vm.rewardsData?.error ?? account?.asData?.value.actionError;
    return EviaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Daily Check-in', style: EviaTheme.cardTitle),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                          '$streakDay-day streak',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final minimum =
                  MediaQuery.textScalerOf(context).scale(AppSpacing.xxxl) *
                  days.length;
              final width = constraints.maxWidth > minimum
                  ? constraints.maxWidth
                  : minimum;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final day in days)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                day.today ? 'Today' : 'Day ${day.day}',
                                textAlign: TextAlign.center,
                                style: ActivityTheme.smallLabel.copyWith(
                                  color: day.today
                                      ? AppColors.primary
                                      : EviaTheme.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                width: AppSpacing.xxl,
                                height: AppSpacing.xxl,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      (day.claimed || (day.today && checkedIn))
                                      ? ActivityTheme.actionDark
                                      : day.today
                                      ? AppColors.warningSurface
                                      : AppColors.primarySoft,
                                ),
                                child: (day.claimed || (day.today && checkedIn))
                                    ? const ActivityIcon(
                                        '2083:3522',
                                        'imgContainer8',
                                      )
                                    : const CoinIcon(size: AppSpacing.lg),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '+${day.coins}',
                                style: ActivityTheme.smallLabel.copyWith(
                                  color: EviaTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Day 7 onward · +${server?.lastDayCoins ?? demo.coins} coins daily',
            textAlign: TextAlign.center,
            style: EviaTheme.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Miss a day? Streak resets.',
            textAlign: TextAlign.center,
            style: EviaTheme.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: saving
                ? 'Saving check-in...'
                : checkedIn
                ? 'Checked In Today · +$coins coins'
                : 'Check In · +$coins coins',
            isLoading: saving,
            onPressed: checkedIn || saving || (live && vm.rewardsBusy)
                ? null
                : live
                ? vm.claimDailyRemote
                : vm.demoAvailable
                ? vm.claimDaily
                : null,
          ),
          if (error != null) Text(error, style: EviaTheme.caption),
        ],
      ),
    );
  }
}

class _MilestoneSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityViewModelProvider);
    final count = ref.read(activityViewModelProvider.notifier).verifiedCount;
    final vm = ref.read(activityViewModelProvider.notifier);
    final next = vm.nextMilestone;
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
              Flexible(
                child: TextButton(
                  onPressed: () => context.push('/rewards/milestones'),
                  child: const Text('View all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('$count of ${vm.milestoneTarget} events attended'),
              ),
              Text(
                '${vm.milestonePercent}%',
                style: EviaTheme.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: vm.milestoneFraction,
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
                      Text(
                        next == null
                            ? 'All milestones reached'
                            : 'Next: ${next.milestone.title}',
                        style: EviaTheme.label,
                      ),
                      Text(
                        next?.description ??
                            'You have reached every milestone.',
                        style: EviaTheme.caption,
                      ),
                    ],
                  ),
                ),
                if (next != null)
                  Flexible(child: EventBadge('+${next.milestone.coins} COINS')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (final progress in vm.milestones.take(3))
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${progress.milestone.events} ${progress.milestone.events == 1 ? 'Event' : 'Events'}',
                        style: EviaTheme.caption,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      CircleAvatar(
                        radius: AppSpacing.md,
                        backgroundColor: !progress.reached
                            ? AppColors.primarySoft
                            : AppColors.primary,
                        child: !progress.reached
                            ? const Icon(
                                Icons.circle,
                                size: AppSpacing.sm,
                                color: AppColors.primary,
                              )
                            : const ActivityIcon('2083:3522', 'imgContainer2'),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        progress.reached
                            ? 'Reached'
                            : progress.next
                            ? 'Next Goal'
                            : 'Locked',
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
