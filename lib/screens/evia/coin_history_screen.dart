import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity_models.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/activity_view_model.dart';
import '../../viewmodels/report_export_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_widgets.dart';
import '../../widgets/activity_widgets.dart';
import '../../widgets/rewards_wallet.dart';
import '../../widgets/coin_icon.dart';

class CoinHistoryScreen extends ConsumerWidget {
  const CoinHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityViewModelProvider);
    final vm = ref.read(activityViewModelProvider.notifier);
    final export = ref.watch(reportExportViewModelProvider);
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
            if (vm.rewardsLive) ...[
              AppButton(
                label: 'Xuất CSV các giao dịch đang hiển thị',
                isLoading: export.busy,
                onPressed: vm.rewardsData == null || vm.rewardsBusy
                    ? null
                    : () => ref
                          .read(reportExportViewModelProvider.notifier)
                          .exportHistory(),
              ),
              if (export.message != null)
                Semantics(liveRegion: true, child: Text(export.message!)),
              const SizedBox(height: AppSpacing.lg),
            ],
            const Row(
              children: [
                Expanded(child: Text('Transactions', style: EviaTheme.section)),
                Text('All dates', style: EviaTheme.caption),
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
            if (vm.historyGroups.isEmpty)
              const EviaCard(child: Text('No transactions in this category.')),
            for (final group in vm.historyGroups) ...[
              Row(
                children: [
                  Expanded(child: Text(group.label, style: EviaTheme.label)),
                  Text(
                    '${group.entries.length} items',
                    style: EviaTheme.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              EviaCard(
                child: Column(
                  children: [
                    for (var i = 0; i < group.entries.length; i++) ...[
                      if (i != 0) const Divider(height: AppSpacing.xl),
                      _CoinEntryRow(entry: group.entries[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
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
    final earned =
        entry.kind == CoinKind.earned || entry.kind == CoinKind.refund;
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
          child: entry.kind == CoinKind.spent
              ? const CoinIcon(color: AppColors.error)
              : ActivityIcon('2083:4356', 'imgContainer${entry.icon}'),
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
            entry.amountLabel ??
                (deposit
                    ? '${entry.amount} held'
                    : '${earned ? '+' : ''}${entry.amount} coins'),
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
