import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/activity_assets.dart';
import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/coin_icon.dart';

class RewardDetailsScreen extends ConsumerWidget {
  const RewardDetailsScreen({
    this.rewardId = 'cafe',
    this.confirm = false,
    super.key,
  });
  final String rewardId;
  final bool confirm;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final reward = vm.reward(rewardId);
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: Image.asset(
              confirm
                  ? ActivityAssets.image('2083:3865', 0)
                  : reward.id == 'cafe'
                  ? ActivityAssets.image('2083:3959', 0)
                  : reward.image,
              height: ActivityTheme.detailImageHeight,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EviaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventBadge(
                  reward.category.toUpperCase(),
                  category: true,
                  color: AppColors.accent,
                  foreground: AppColors.textPrimary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(reward.title, style: ActivityTheme.title),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _DetailBadge(
                      '${reward.redeemCost} coins',
                      'imgContainer',
                      warning: true,
                    ),
                    _DetailBadge(
                      vm.rewardStatus(reward.id),
                      'imgContainer1',
                      positive: vm.canRedeem(reward.id),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(reward.description, style: EviaTheme.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EviaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Reward Information', style: EviaTheme.cardTitle),
                const SizedBox(height: AppSpacing.md),
                _RewardInfoRow(
                  'Validity',
                  vm.validityLabel(reward),
                  'imgContainer2',
                ),
                const Divider(),
                _RewardInfoRow(
                  'Where to use',
                  reward.location,
                  'imgContainer3',
                ),
                const Divider(),
                _RewardInfoRow(
                  'Terms & Conditions',
                  'View reward terms',
                  'imgContainer4',
                  onTap: () => showActivityHelp(
                    context,
                    'Terms & Conditions',
                    '${reward.terms} ${vm.validityLabel(reward)}.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EviaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to Redeem', style: EviaTheme.cardTitle),
                SizedBox(height: AppSpacing.md),
                _RedeemStep(1, 'Redeem with coins', 'Confirm the exchange.'),
                _RedeemStep(
                  2,
                  'Find it in My Rewards',
                  'Your reward appears after successful redemption.',
                ),
                _RedeemStep(3, 'Use your reward', reward.instructions),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () =>
                showActivityHelp(context, 'Need help?', reward.instructions),
            child: const Text('Need help?'),
          ),
        ],
      ),
    );
    return EviaPage(
      header: const ActivityHeader(
        'Reward Details',
        screen: '2083:3959',
        backAsset: 'imgContainer6',
      ),
      footer: confirm
          ? null
          : Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: vm.canRedeem(reward.id)
                      ? 'Redeem for ${reward.redeemCost} coins'
                      : vm.demoAvailable
                      ? vm.rewardStatus(reward.id)
                      : 'Coin API not connected',
                  trailing: const CoinIcon(),
                  onPressed: vm.canRedeem(reward.id)
                      ? () => context.push('/rewards/confirm?id=${reward.id}')
                      : null,
                ),
              ),
            ),
      child: confirm
          ? ActivityOverlay(
              background: _RedemptionBackdrop(reward: reward),
              child: _ConfirmRedemption(reward: reward),
            )
          : content,
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge(
    this.label,
    this.asset, {
    this.warning = false,
    this.positive = true,
  });
  final String label, asset;
  final bool warning, positive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: warning
          ? AppColors.warningSurface
          : positive
          ? AppColors.successSurface
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (warning)
          const CoinIcon()
        else if (positive)
          ActivityIcon('2083:3959', asset)
        else
          const Icon(
            Icons.info_outline,
            size: AppSpacing.lg,
            color: AppColors.textSecondary,
          ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: EviaTheme.caption.copyWith(
              color: warning
                  ? AppColors.warning
                  : positive
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RewardInfoRow extends StatelessWidget {
  const _RewardInfoRow(this.label, this.value, this.asset, {this.onTap});
  final String label, value, asset;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: EviaTheme.lavender,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: ActivityIcon('2083:3959', asset),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: EviaTheme.caption),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RedeemStep extends StatelessWidget {
  const _RedeemStep(this.number, this.title, this.subtitle);
  final int number;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: AppSpacing.md,
          backgroundColor: ActivityTheme.actionDark,
          child: Text(
            '$number',
            style: const TextStyle(color: AppColors.surface),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: EviaTheme.label),
              Text(subtitle, style: EviaTheme.caption),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RedemptionBackdrop extends StatelessWidget {
  const _RedemptionBackdrop({required this.reward});
  final CampusReward reward;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          reward.id == 'cafe'
              ? ActivityAssets.image('2083:3865', 0)
              : reward.image,
          height: ActivityTheme.detailImageHeight,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.title, style: ActivityTheme.title),
              const SizedBox(height: AppSpacing.md),
              Text(reward.description),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const CoinIcon(),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${reward.redeemCost} Student Coins'),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Row(
                children: [
                  ActivityIcon('2083:3865', 'imgContainer1'),
                  SizedBox(width: AppSpacing.sm),
                  Text('Redemption Locations'),
                ],
              ),
              Text(reward.location),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ConfirmRedemption extends ConsumerWidget {
  const _ConfirmRedemption({required this.reward});
  final CampusReward reward;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    void close() => context.canPop()
        ? context.pop()
        : context.go('/rewards/detail?id=${reward.id}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Confirm Redemption', style: EviaTheme.section),
            ),
            IconButton(
              tooltip: 'Close redemption',
              onPressed: close,
              icon: const ActivityIcon('2083:3865', 'imgContainer2'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        EviaCard(
          color: AppColors.background,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Image.asset(
                  reward.id == 'cafe'
                      ? ActivityAssets.image('2083:3865', 1)
                      : reward.image,
                  width: EviaTheme.compactThumbnail,
                  height: EviaTheme.compactThumbnail,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title, style: EviaTheme.compactTitle),
                    Text(reward.category, style: EviaTheme.caption),
                    Row(
                      children: [
                        const CoinIcon(),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${reward.redeemCost} coins',
                          style: EviaTheme.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        EviaCard(
          color: AppColors.background,
          child: Column(
            children: [
              DetailRow(
                'Available Coins',
                '${state.available}',
                icon: const ActivityIcon('2083:3865', 'imgContainer4'),
              ),
              DetailRow(
                'Reward Cost',
                '−${reward.redeemCost}',
                color: AppColors.error,
                icon: const CoinIcon(color: AppColors.error),
              ),
              const Divider(),
              DetailRow('Remaining Balance', 'Confirmed by server'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ActivityInfo(
          vm.demoAvailable
              ? 'Demo only · coins and rewards reset when the app restarts.'
              : ActivityViewModel.coinServiceMessage,
          icon: const ActivityIcon('2083:3865', 'imgMargin'),
        ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(state.message!),
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Confirm Redemption',
          trailing: const ActivityIcon('2083:3865', 'imgContainer6'),
          onPressed: vm.canRedeem(reward.id)
              ? () {
                  if (vm.redeem(reward.id)) context.go('/rewards/success');
                }
              : null,
        ),
        TextButton(onPressed: close, child: const Text('Cancel')),
      ],
    );
  }
}
