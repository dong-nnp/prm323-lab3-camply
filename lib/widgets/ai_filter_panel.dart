import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_tokens.dart';
import '../viewmodels/ai_filter_view_model.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class AiFilterPanel extends ConsumerWidget {
  const AiFilterPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiFilterViewModelProvider);
    final vm = ref.read(aiFilterViewModelProvider.notifier);
    final result = state.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'AI filter assistant',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'What kind of event?',
          hintText: 'Workshop this month, afternoon',
          enabled: !state.loading,
          onChanged: vm.setInput,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Only recognized event keywords are sent to Gemini. Avoid personal information. AI uses the available filter options.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Suggest filters',
          isLoading: state.loading,
          onPressed: vm.suggest,
        ),
        if (state.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(liveRegion: true, child: Text(state.message!)),
        ],
        if (result != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              'AI suggestion\n${result.category} · ${result.date} · ${result.time} · ${result.duration}${result.rangeStart == null ? '' : '\n${result.rangeStart!.toIso8601String().substring(0, 10)} – ${result.rangeEnd!.toIso8601String().substring(0, 10)}'}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(label: 'Use suggestion', onPressed: vm.useSuggestion),
        ],
        if (state.accepted) ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'AI suggestion added below. Review or edit it, then tap Apply Filters.',
          ),
        ],
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }
}
