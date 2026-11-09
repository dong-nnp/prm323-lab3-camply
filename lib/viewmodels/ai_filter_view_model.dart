import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/providers/repository_providers.dart';
import '../core/providers/service_providers.dart';
import '../data/mock/evia_mock_data.dart';
import '../models/evia_models.dart';
import 'evia_view_model.dart';

class AiFilterState {
  const AiFilterState({
    this.loading = false,
    this.result,
    this.message,
    this.accepted = false,
  });
  final bool loading, accepted;
  final EventFilters? result;
  final String? message;
}

final aiFilterViewModelProvider =
    NotifierProvider.autoDispose<AiFilterViewModel, AiFilterState>(
      AiFilterViewModel.new,
    );

class AiFilterViewModel extends Notifier<AiFilterState> {
  String _input = '';
  @override
  AiFilterState build() => const AiFilterState();
  void setInput(String value) {
    _input = value;
  }

  Future<void> suggest() async {
    if (state.loading) return;
    if (!ref.read(realBackendEnabledProvider)) {
      state = const AiFilterState(
        message: 'Enable Firebase to use AI suggestions. Manual filters remain available.',
      );
      return;
    }
    final analytics = ref.read(analyticsRepositoryProvider);
    final vm = ref.read(eviaViewModelProvider.notifier);
    final choices = <String, List<String>>{
      'Category': vm.categories,
      'Date': [
        ...EviaMockData.filterGroups['Date']!,
        'Today',
        'Tomorrow',
        'This weekend',
      ].where((v) => v != 'Custom range').toList(),
      'Time': EviaMockData.filterGroups['Time']!,
      'Duration': EviaMockData.filterGroups['Duration']!,
    };
    state = const AiFilterState(loading: true);
    unawaited(analytics.track('ai_request'));
    try {
      final result = await ref
          .read(aiFilterRepositoryProvider)
          .suggest(_input, choices);
      if (ref.mounted) state = AiFilterState(result: result);
    } catch (error) {
      unawaited(analytics.track('ai_error'));
      if (ref.mounted) {
        state = AiFilterState(
          message: error is AppException
              ? error.message
              : 'AI is unavailable. Please choose filters manually.',
        );
      }
    }
  }

  void useSuggestion() {
    final result = state.result;
    if (result == null) return;
    ref.read(eviaViewModelProvider.notifier).useAiFilters(result);
    state = const AiFilterState(accepted: true);
    unawaited(
      ref.read(analyticsRepositoryProvider).track('ai_result_accepted'),
    );
  }
}
