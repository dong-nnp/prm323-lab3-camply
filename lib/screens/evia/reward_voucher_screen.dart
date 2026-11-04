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

class RewardsLockerScreen extends ConsumerWidget {
  const RewardsLockerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final used = ref.watch(
      activityViewModelProvider.select((s) => s.usedRewards),
    );
    return EviaPage(
      header: const ActivityHeader(
        'My Rewards',
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
              icons: const [
                ActivityIcon('2083:3267', 'imgContainer'),
                ActivityIcon('2083:3267', 'imgContainer1'),
              ],
              activeColor: ActivityTheme.action,
              activeForeground: AppColors.surface,
              labels: const ['Available (1)', 'Used & Expired (2)'],
              selected: used ? 1 : 0,
              onSelected: (index) => ref
                  .read(activityViewModelProvider.notifier)
                  .selectLockerTab(index == 1),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (used) ...[
              for (final archived in ActivityMockData.archivedRewards)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: EviaCard(
                    child: Row(
                      children: [
                        const ActivityIcon('2083:3267', 'imgContainer1'),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(archived.title)),
                        EventBadge(
                          archived.status,
                          color: AppColors.surfaceMuted,
                          foreground: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ] else
              InkWell(
                onTap: () => context.push('/rewards/voucher'),
                child: EviaCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                            child: Image.asset(
                              ActivityAssets.path('2083:3267', 'imgCampusCafe'),
                              width: EviaTheme.thumbnail - AppSpacing.sm,
                              height: EviaTheme.thumbnail - AppSpacing.sm,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                EventBadge(
                                  '• Ready to use',
                                  color: AppColors.successSurface,
                                  foreground: AppColors.success,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Campus Café \$10 Voucher',
                                  style: EviaTheme.cardTitle,
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    ActivityIcon('2083:3267', 'imgContainer2'),
                                    SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Redeemed Oct 28, 2026',
                                        style: EviaTheme.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ActivityIcon('2083:3267', 'imgContainer3'),
                              SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  'Valid until Nov 27, 2026',
                                  style: EviaTheme.caption,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Flexible(
                                child: Text(
                                  'View Voucher & QR',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const ActivityIcon('2083:3267', 'imgContainer4'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const ActivityInfo(
              'Open a reward to view its code, usage instructions, and redemption details.',
              icon: ActivityIcon('2083:3267', 'imgMargin'),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardVoucherScreen extends StatelessWidget {
  const RewardVoucherScreen({super.key});
  @override
  Widget build(BuildContext context) => EviaPage(
    header: const ActivityHeader(
      'My Voucher',
      screen: '2083:4059',
      backAsset: 'imgContainer4',
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: EventBadge(
              '• Ready to use',
              color: AppColors.successSurface,
              foreground: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Campus Café \$10 Voucher',
            textAlign: TextAlign.center,
            style: ActivityTheme.title,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Show this QR code at the cashier.',
            textAlign: TextAlign.center,
            style: EviaTheme.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          EviaCard(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: ActivityIcon('2083:4059', 'imgSvg'),
                ),
                const SizedBox(height: AppSpacing.lg),
                EviaCard(
                  color: AppColors.background,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VOUCHER CODE', style: EviaTheme.caption),
                            Text(
                              ActivityMockData.voucherCode,
                              style: ActivityTheme.code,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => copyActivityCode(
                          context,
                          ActivityMockData.voucherCode,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActivityIcon('2083:4059', 'imgContainer'),
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
          const Text('Voucher Details', style: EviaTheme.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          const EviaCard(
            child: Column(
              children: [
                DetailRow(
                  'Status',
                  'Unused',
                  color: AppColors.success,
                  icon: ActivityIcon('2083:4059', 'imgContainer1'),
                ),
                Divider(),
                DetailRow(
                  'Valid until',
                  ActivityMockData.validUntil,
                  icon: ActivityIcon('2083:4059', 'imgContainer2'),
                ),
                Divider(),
                DetailRow(
                  'Where to use',
                  'Participating campus cafés',
                  icon: ActivityIcon('2083:4059', 'imgContainer3'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const ActivityInfo(
            'This voucher can be used once. Its status updates after successful verification.',
            icon: ActivityIcon('2083:4059', 'imgIcon'),
          ),
        ],
      ),
    ),
  );
}

class RedemptionSuccessScreen extends ConsumerWidget {
  const RedemptionSuccessScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt =
        ref.watch(activityViewModelProvider).receipt ??
        ActivityMockData.referenceReceipt;
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
            const Text(
              'Your reward is ready and saved in My Rewards.',
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
                    icon: const ActivityIcon('2083:3788', 'imgContainer1'),
                  ),
                  DetailRow(
                    'New Available Balance',
                    '${receipt.balance} Available Coins',
                    icon: const ActivityIcon('2083:3788', 'imgContainer2'),
                  ),
                  const DetailRow(
                    'Expiration Date',
                    'Valid until Nov 27, 2026',
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
