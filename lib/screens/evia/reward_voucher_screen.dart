import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../viewmodels/flow3_view_model.dart';
import '../../widgets/status_widgets.dart';
import '../../core/utils/exception_mapper.dart';

import '../../core/constants/activity_assets.dart';
import '../../data/mock/activity_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../theme/activity_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/coin_icon.dart';

class RewardsLockerScreen extends ConsumerWidget {
  const RewardsLockerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    void backToRewards() => context.go('/rewards/catalog');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) backToRewards();
      },
      child: EviaPage(
        header: ActivityHeader(
          'My Rewards',
          onBack: backToRewards,
          screen: '2083:3267',
          backAsset: 'imgContainer5',
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Your Rewards', style: EviaTheme.heading),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                "All the rewards you've redeemed",
                style: EviaTheme.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              ActivityTabs(
                icons: [
                  ActivityIcon(
                    '2083:3267',
                    'imgContainer',
                    color: state.usedRewards
                        ? AppColors.textSecondary
                        : AppColors.surface,
                  ),
                  ActivityIcon(
                    '2083:3267',
                    'imgContainer1',
                    color: state.usedRewards
                        ? AppColors.surface
                        : AppColors.textSecondary,
                  ),
                ],
                activeColor: ActivityTheme.action,
                activeForeground: AppColors.surface,
                labels: [
                  'Available (${vm.availableReceipts.length})',
                  'Used & Expired (${vm.archivedReceipts.length})',
                ],
                selected: state.usedRewards ? 1 : 0,
                onSelected: (index) => vm.selectLockerTab(index == 1),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.usedRewards)
                for (final archived in vm.archivedReceipts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: EviaCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                            child: catalogImage(
                              archived.reward.image,
                              ActivityMockData.rewards.first.image,
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
                                Text(
                                  archived.reward.title,
                                  style: EviaTheme.compactTitle,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  archived.reward.category,
                                  style: EviaTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          EventBadge(
                            archived.status,
                            color: archived.status == 'Expired'
                                ? AppColors.warningSurface
                                : AppColors.surfaceMuted,
                            foreground: archived.status == 'Expired'
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  )
              else if (vm.availableReceipts.isEmpty)
                EviaCard(
                  child: Column(
                    children: [
                      const Text('No rewards yet', style: EviaTheme.cardTitle),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Redeem a reward to find it here.',
                        style: EviaTheme.caption,
                      ),
                      TextButton(
                        onPressed: () => context.go('/rewards/catalog'),
                        child: const Text('Browse rewards'),
                      ),
                    ],
                  ),
                )
              else
                for (final receipt in vm.availableReceipts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      child: InkWell(
                        onTap: () => context.push(
                          '/rewards/voucher?code=${Uri.encodeQueryComponent(receipt.code)}',
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        child: EviaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.medium,
                                    ),
                                    child: catalogImage(
                                      receipt.reward.image,
                                      ActivityMockData.rewards.first.image,
                                      width:
                                          EviaTheme.thumbnail - AppSpacing.sm,
                                      height:
                                          EviaTheme.thumbnail - AppSpacing.sm,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        EventBadge(
                                          vm.rewardsLive
                                              ? vm.receiptStatus(receipt)
                                              : 'Saved demo reward',
                                          color: AppColors.successSurface,
                                          foreground: AppColors.success,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          receipt.reward.title,
                                          style: EviaTheme.cardTitle,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Redeemed ${vm.dateLabel(receipt.redeemedOn)}',
                                          style: EviaTheme.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                vm.expiryLabel(receipt),
                                style: EviaTheme.caption,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'View Reward',
                                      style: EviaTheme.label,
                                    ),
                                  ),
                                  ActivityIcon('2083:3267', 'imgContainer4'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.lg),
              ActivityInfo(
                vm.rewardsLive
                    ? 'Your redeemed rewards are saved to your account.'
                    : 'Demo rewards are stored only during this app session.',
                icon: ActivityIcon('2083:3267', 'imgMargin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RewardVoucherScreen extends ConsumerWidget {
  const RewardVoucherScreen({this.code, super.key});
  final String? code;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final receipt = vm.voucher(code);
    if (receipt == null) {
      return const _MissingReward(title: 'No reward selected');
    }
    final reward = receipt.reward;
    final usable = receipt.available(DateTime.now().toUtc());
    final remote = vm.rewardsLive && receipt.voucherId != null && usable
        ? ref.watch(voucherCodeProvider(receipt.voucherId!))
        : null;
    if (remote != null &&
        (remote.isLoading || remote.hasError || !remote.hasValue)) {
      return EviaPage(
        header: const ActivityHeader('My Reward'),
        child: Center(
          child: remote.hasError
              ? AppErrorWidget(
                  message: ExceptionMapper.map(remote.error!).message,
                  onRetry: () {
                    ref.invalidate(voucherCodeProvider(receipt.voucherId!));
                    ref.read(flow3ViewModelProvider.notifier).refresh();
                  },
                )
              : const AppLoadingWidget(),
        ),
      );
    }
    final displayCode =
        remote?.asData?.value['code'] as String? ?? receipt.code;
    final payload = remote?.asData?.value['qrPayload'] as String?;
    return EviaPage(
      header: const ActivityHeader(
        'My Reward',
        screen: '2083:4059',
        backAsset: 'imgContainer4',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: EventBadge(
                vm.rewardsLive
                    ? vm.receiptStatus(receipt)
                    : 'Saved demo reward',
                color: AppColors.successSurface,
                foreground: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: ActivityTheme.title,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reward.instructions,
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            EviaCard(
              child: Column(
                children: [
                  if (vm.rewardsLive && payload != null)
                    QrImageView(data: payload, size: 208)
                  else if (!vm.rewardsLive && reward.id == 'cafe') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: ActivityIcon('2083:4059', 'imgSvg'),
                    ),
                    const Text(
                      'Illustrative demo QR. Not valid for payment.',
                      style: EviaTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ] else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      child: catalogImage(
                        reward.image,
                        ActivityMockData.rewards.first.image,
                        height: ActivityTheme.detailImageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  EviaCard(
                    color: AppColors.background,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vm.rewardsLive
                                    ? receipt.voucherId == null
                                          ? 'REDEMPTION ID'
                                          : 'VOUCHER CODE'
                                    : 'DEMO REWARD CODE',
                                style: EviaTheme.caption,
                              ),
                              Text(displayCode, style: ActivityTheme.code),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: vm.rewardsLive && !usable
                              ? null
                              : () => copyActivityCode(context, displayCode),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActivityIcon('2083:4059', 'imgContainer'),
                              SizedBox(width: AppSpacing.xs),
                              Text('Copy'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Reward Details', style: EviaTheme.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            EviaCard(
              child: Column(
                children: [
                  DetailRow(
                    'Status',
                    vm.rewardsLive
                        ? vm.receiptStatus(receipt)
                        : 'Saved in this session',
                    color: AppColors.success,
                    icon: ActivityIcon('2083:4059', 'imgContainer1'),
                  ),
                  const Divider(),
                  DetailRow(
                    'Validity',
                    vm.expiryLabel(receipt),
                    icon: const ActivityIcon('2083:4059', 'imgContainer2'),
                  ),
                  const Divider(),
                  DetailRow(
                    'Where to use',
                    reward.location,
                    icon: const ActivityIcon('2083:4059', 'imgContainer3'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ActivityInfo(
              vm.rewardsLive
                  ? reward.fulfillmentType == 'physical'
                        ? reward.instructions
                        : 'Present the voucher for admin verification. Each voucher can be used once.'
                  : 'Demo preview. Real reward verification is not connected.',
              icon: ActivityIcon('2083:4059', 'imgIcon'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingReward extends StatelessWidget {
  const _MissingReward({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => EviaPage(
    header: ActivityHeader(
      'My Rewards',
      onBack: () => context.go('/rewards/catalog'),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: EviaTheme.section, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Browse rewards',
              onPressed: () => context.go('/rewards/catalog'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RedemptionSuccessScreen extends ConsumerWidget {
  const RedemptionSuccessScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activityViewModelProvider);
    final receipt = ref.read(activityViewModelProvider.notifier).lastReceipt;
    final vm = ref.read(activityViewModelProvider.notifier);
    if (receipt == null) {
      return const _MissingReward(title: 'No redemption to display');
    }
    return EviaPage(
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: 'View My Rewards',
              trailing: const ActivityIcon('2083:3788', 'imgContainer4'),
              onPressed: () => context.go('/rewards/locker'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.go('/rewards/catalog'),
              child: const Text('Continue Browsing'),
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Dismiss success',
                onPressed: () => context.go('/rewards/catalog'),
                icon: const ActivityIcon('2083:3788', 'imgContainer'),
              ),
            ),
            Image.asset(
              ActivityAssets.path('2083:3788', 'imgCheerfulMascotInGiftBox'),
              height: ActivityTheme.successMascotHeight,
              width: ActivityTheme.successMascotWidth,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Redemption Successful!',
              textAlign: TextAlign.center,
              style: EviaTheme.heading,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              vm.rewardsLive
                  ? 'Your reward has been saved to My Rewards.'
                  : ref.read(activityViewModelProvider.notifier).demoAvailable
                  ? 'Demo redemption complete. No real reward was issued.'
                  : 'Preview result only. The coin API is not connected.',
              textAlign: TextAlign.center,
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            EviaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('YOUR REWARD', style: ActivityTheme.smallLabel),
                  const SizedBox(height: AppSpacing.md),
                  Text(receipt.reward.title, style: EviaTheme.cardTitle),
                  const SizedBox(height: AppSpacing.lg),
                  EviaCard(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Voucher ID',
                                style: EviaTheme.caption,
                              ),
                              Text(receipt.code, style: ActivityTheme.code),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              copyActivityCode(context, receipt.code),
                          child: const Text('Copy'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  DetailRow(
                    'Cost Deducted',
                    '-${receipt.cost} coins',
                    color: AppColors.error,
                    icon: const CoinIcon(color: AppColors.error),
                  ),
                  DetailRow(
                    'New Available Balance',
                    '${receipt.balance} Available Coins',
                    icon: const ActivityIcon('2083:3788', 'imgContainer2'),
                  ),
                  DetailRow(
                    'Validity',
                    vm.expiryLabel(receipt),
                    icon: ActivityIcon('2083:3788', 'imgContainer3'),
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
