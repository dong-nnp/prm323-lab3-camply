import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/activity_assets.dart';
import '../theme/app_tokens.dart';
import '../theme/evia_theme.dart';
import '../theme/activity_theme.dart';
import '../viewmodels/activity_view_model.dart';
import 'activity_widgets.dart';

class RewardsWallet extends ConsumerWidget {
  const RewardsWallet({required this.screen, super.key});
  final String screen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final earn = screen == '2083:3522';
    final history = screen == '2083:4356';
    final bg = history
        ? 'imgSectionBalanceSummaryHeroCard'
        : earn
        ? 'imgPastelCloudscapeBackground'
        : 'imgCoinWalletHeroCard';
    final mascot = history
        ? 'imgCheerfulTicketMascot'
        : earn
        ? 'imgCheerfulBlueTicketRewardsMascot'
        : 'imgEviaTicketMascotJumpingWithGoldCoins';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ActivityTheme.wallet,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              ActivityAssets.path(screen, bg),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!history)
                                ActivityIcon(
                                  screen,
                                  earn ? 'imgSvg' : 'imgContainer',
                                ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'AVAILABLE COINS',
                                  style: ActivityTheme.smallLabel.copyWith(
                                    color: ActivityTheme.actionDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              if (earn)
                                const _CoinStack()
                              else if (history)
                                ActivityIcon(screen, 'imgSvg'),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  '${state.available}',
                                  style: ActivityTheme.balance,
                                ),
                              ),
                              if (!earn && !history)
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ActivityIcon(screen, 'imgContainer1'),
                                ),
                            ],
                          ),
                          if (!history)
                            TextButton(
                              onPressed: () => context.push('/rewards/history'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Flexible(
                                    child: Text('View coin history'),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  if (earn)
                                    const Icon(
                                      Icons.north_east,
                                      size: AppSpacing.md,
                                    )
                                  else
                                    const ActivityIcon(
                                      '2083:3327',
                                      'imgContainer2',
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Image.asset(
                      ActivityAssets.path(screen, mascot),
                      width: history
                          ? ActivityTheme.historyMascotWidth
                          : earn
                          ? ActivityTheme.earnMascotWidth
                          : ActivityTheme.catalogMascotSize,
                      height: history
                          ? ActivityTheme.historyMascotHeight
                          : earn
                          ? ActivityTheme.earnMascotHeight
                          : ActivityTheme.catalogMascotSize,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Material(
                  color: AppColors.surface.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    onTap: () => showActivityHelp(
                      context,
                      'Coins in deposits',
                      '${state.deposits} coins are temporarily locked for your registered events. They are separate from your available balance.',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          ActivityIcon(
                            screen,
                            history
                                ? 'imgContainer'
                                : earn
                                ? 'imgContainer5'
                                : 'imgContainer3',
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'In Deposits',
                                  style: EviaTheme.label,
                                ),
                                if (earn || history)
                                  const Text(
                                    'Temporarily locked',
                                    style: EviaTheme.caption,
                                  ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${state.deposits} coins',
                              style: EviaTheme.label,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ActivityIcon(
                            screen,
                            history
                                ? 'imgContainer1'
                                : earn
                                ? 'imgContainer6'
                                : 'imgContainer4',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  const _CoinStack();
  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 36,
    child: Stack(
      children: [
        Positioned(
          left: 4,
          top: 22.5,
          child: ActivityIcon('2083:3522', 'imgVector'),
        ),
        Positioned(
          left: 4,
          top: 21,
          child: ActivityIcon('2083:3522', 'imgVector1'),
        ),
        Positioned(
          left: 4,
          top: 16.5,
          child: ActivityIcon('2083:3522', 'imgVector2'),
        ),
        Positioned(
          left: 4,
          top: 10.5,
          child: ActivityIcon('2083:3522', 'imgVector3'),
        ),
        Positioned(
          left: 4,
          top: 9,
          child: ActivityIcon('2083:3522', 'imgVector1'),
        ),
        Positioned(
          left: 4,
          top: 4.5,
          child: ActivityIcon('2083:3522', 'imgVector4'),
        ),
        Positioned(
          left: 6,
          top: 5.4,
          child: ActivityIcon('2083:3522', 'imgVector5'),
        ),
        Positioned(
          left: 15,
          top: 6.5,
          child: ActivityIcon('2083:3522', 'imgVector6'),
        ),
      ],
    ),
  );
}
