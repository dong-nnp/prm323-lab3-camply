import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/evia_mock_data.dart';
import '../../theme/app_tokens.dart';
import '../../theme/evia_theme.dart';
import '../../viewmodels/evia_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/evia_brand.dart';
import '../../widgets/evia_widgets.dart';

class EviaInterestsScreen extends ConsumerWidget {
  const EviaInterestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      eviaViewModelProvider.select((s) => s.interests),
    );
    final ready = ref.read(eviaViewModelProvider.notifier).canContinue;
    return EviaPage(
      footer: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Continue',
            trailing: const FigmaIcon('2088:2', 'imgContainer11'),
            onPressed: ready
                ? () {
                    final destination = ref
                        .read(eviaViewModelProvider.notifier)
                        .finishPersonalization();
                    if (destination != null) context.go(destination);
                  }
                : null,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const EviaLogo(interests: true),
                TextButton(
                  onPressed: () {
                    final destination = ref
                        .read(eviaViewModelProvider.notifier)
                        .finishPersonalization(skipped: true);
                    if (destination != null) context.go(destination);
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const EventBadge('PERSONALIZE YOUR FEED'),
            const SizedBox(height: AppSpacing.md),
            const Text('What interests you?', style: EviaTheme.heading),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Choose the topics you enjoy so we can recommend events you’ll actually want to join.',
              style: EviaTheme.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  const FigmaIcon('2088:2', 'imgContainer'),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ready
                          ? 'Nice! You’ve selected enough to continue.'
                          : 'Choose at least 3 interests to continue.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - AppSpacing.lg) / 2;
                return Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (var i = 0; i < EviaMockData.topics.length; i += 2)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var j = i; j < i + 2; j++) ...[
                              if (j != i) const SizedBox(width: AppSpacing.lg),
                              SizedBox(
                                width: width,
                                child: _InterestCard(
                                  index: j,
                                  selected: selected.contains(
                                    EviaMockData.topics[j].name,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Icon(
                  Icons.circle,
                  size: AppSpacing.sm,
                  color: EviaTheme.blue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${selected.length} interests selected',
                    style: EviaTheme.label,
                  ),
                ),
                Flexible(
                  child: Text(
                    ready
                        ? 'Ready to continue'
                        : 'Select ${3 - selected.length} more',
                    style: EviaTheme.label.copyWith(color: EviaTheme.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Pick as many as you like', style: EviaTheme.caption),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _InterestCard extends ConsumerWidget {
  const _InterestCard({required this.index, required this.selected});
  final int index;
  final bool selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = EviaMockData.topics[index];
    return Semantics(
      selected: selected,
      button: true,
      label: topic.name,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(
            color: selected ? EviaTheme.blue : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => ref
              .read(eviaViewModelProvider.notifier)
              .toggleInterest(topic.name),
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: selected
                            ? EviaTheme.selectedIcon
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: FigmaIcon('2088:2', topic.asset),
                    ),
                    Container(
                      width: EviaTheme.selectionSize,
                      height: EviaTheme.selectionSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? EviaTheme.blue : AppColors.surface,
                        border: Border.all(
                          color: selected ? EviaTheme.blue : AppColors.border,
                        ),
                      ),
                      child: Opacity(
                        opacity: selected ? 1 : 0,
                        child: FigmaIcon(
                          '2088:2',
                          selected ? 'imgContainer2' : 'imgContainer6',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(topic.name, style: EviaTheme.compactTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(topic.description, style: EviaTheme.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
