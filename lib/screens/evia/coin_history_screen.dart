import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/rewards_wallet.dart';

class CoinHistoryScreen extends ConsumerWidget {
  const CoinHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    return EviaPage(
      header: const ActivityHeader(
        'Coin History',
        screen: '2083:4356',
        backAsset: 'imgContainer7',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RewardsWallet(screen: '2083:4356'),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              children: [
                Expanded(child: Text('Transactions', style: EviaTheme.section)),
                Text('Oct 2026', style: EviaTheme.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final filter in ['All', 'Earned', 'Spent', 'Deposits'])
                  EviaPill(
                    filter,
                    selected: state.historyFilter == filter,
                    onTap: () => vm.historyFilter(filter),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(
                  child: Text('OCTOBER 2026 · RECENT', style: EviaTheme.label),
                ),
                Text('${vm.history.length} items', style: EviaTheme.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            EviaCard(
              child: Column(
                children: [
                  for (var i = 0; i < vm.history.length; i++) ...[
                    if (i != 0) const Divider(height: AppSpacing.xl),
                    _CoinEntryRow(entry: vm.history[i]),
                  ],
                  if (vm.history.isEmpty)
                    const Text('No transactions in this category.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinEntryRow extends StatelessWidget {
  const _CoinEntryRow({required this.entry});
  final CoinEntry entry;
  @override
  Widget build(BuildContext context) {
    final deposit = entry.kind == CoinKind.deposit;
    final earned = entry.kind == CoinKind.earned;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: deposit
                ? AppColors.warningSurface
                : earned
                ? entry.icon == 3
                      ? AppColors.primarySoft
                      : AppColors.successSurface
                : AppColors.errorSurface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: ActivityIcon('2083:4356', 'imgContainer${entry.icon}'),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: EviaTheme.compactTitle),
              Text(entry.subtitle, style: EviaTheme.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(
            deposit
                ? '${entry.amount} held'
                : '${earned ? '+' : ''}${entry.amount} coins',
            textAlign: TextAlign.right,
            style: EviaTheme.label.copyWith(
              color: deposit
                  ? AppColors.warning
                  : earned
                  ? AppColors.success
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
