import 'dart:async';

import 'package:prm393_lab03/services/ai_filter_service.dart';
import 'package:prm393_lab03/viewmodels/ai_filter_view_model.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/evia_models.dart';
import 'package:prm393_lab03/repositories/ai_filter_repository.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/widgets/ai_filter_panel.dart';

class FakeAiService implements AiFilterService {
  final response = Completer<String>();
  int calls = 0;
  @override
  Future<String> suggest(String keywords, Map<String, List<String>> choices) {
    calls++;
    return response.future;
  }
}

class TestEviaViewModel extends EviaViewModel {
  @override
  EviaState build() => const EviaState();
  @override
  List<String> get categories => ['All', 'Workshop'];
}

void main() {
  test(
    'AI blocks duplicate calls, waits for acceptance and ignores disposal',
    () async {
      final service = FakeAiService();
      final container = ProviderContainer(
        overrides: [
          realBackendEnabledProvider.overrideWithValue(true),
          analyticsEnabledProvider.overrideWithValue(false),
          aiFilterServiceProvider.overrideWithValue(service),
          eviaViewModelProvider.overrideWith(TestEviaViewModel.new),
        ],
      );
      final subscription = container.listen(
        aiFilterViewModelProvider,
        (_, _) {},
      );
      final vm = container.read(aiFilterViewModelProvider.notifier);
      vm.setInput('workshop afternoon');
      final pending = vm.suggest();
      await vm.suggest();
      expect(service.calls, 1);
      expect(container.read(aiFilterViewModelProvider).loading, isTrue);
      service.response.complete(
        jsonEncode({
          'Category': 'Workshop',
          'Date': 'Any date',
          'Time': 'Afternoon',
          'Duration': 'Any duration',
        }),
      );
      await pending;
      expect(container.read(eviaViewModelProvider).draft.category, 'All');
      vm.useSuggestion();
      expect(container.read(eviaViewModelProvider).draft.category, 'Workshop');
      expect(container.read(eviaViewModelProvider).filters.category, 'All');
      subscription.close();
      container.dispose();
    },
  );
  test('late failed request is safe after disposal', () async {
    final service = FakeAiService();
    final container = ProviderContainer(
      overrides: [
        realBackendEnabledProvider.overrideWithValue(true),
        analyticsEnabledProvider.overrideWithValue(false),
        aiFilterServiceProvider.overrideWithValue(service),
        eviaViewModelProvider.overrideWith(TestEviaViewModel.new),
      ],
    );
    container.listen(aiFilterViewModelProvider, (_, _) {});
    final vm = container.read(aiFilterViewModelProvider.notifier);
    vm.setInput('workshop');
    final pending = vm.suggest();
    container.dispose();
    service.response.completeError(
      const AppException(code: 'unavailable', message: 'Offline'),
    );
    await pending;
  });
  const choices = {
    'Category': ['All', 'Workshop'],
    'Date': ['Any date', 'This weekend'],
    'Time': ['Any time', 'Afternoon'],
    'Duration': ['Any duration', '1–3 hours'],
  };
  String output({String category = 'Workshop'}) => jsonEncode({
    'Category': category,
    'Date': 'This weekend',
    'Time': 'Afternoon',
    'Duration': 'Any duration',
  });
  test('only allowlisted keywords leave the device', () {
    expect(
      AiFilterRepository.keywords(
        'Alice alice@example.com 0901234567 workshop afternoon',
      ),
      'workshop afternoon',
    );
    expect(
      () => AiFilterRepository.keywords('Alice'),
      throwsA(isA<AppException>()),
    );
    expect(
      () => AiFilterRepository.keywords('a' * 301),
      throwsA(isA<AppException>()),
    );
  });
  test('valid JSON becomes editable filters with actual weekend dates', () {
    final result = AiFilterRepository.parse(
      output(),
      choices,
      now: DateTime(2026, 11, 9),
    );
    expect(result.category, 'Workshop');
    expect(result.time, 'Afternoon');
    expect(result.rangeStart, DateTime(2026, 11, 14));
    expect(result.rangeEnd, DateTime(2026, 11, 15));
    expect(
      AiFilterRepository.parse(
        output(),
        choices,
        now: DateTime(2026, 11, 15),
      ).rangeStart,
      DateTime(2026, 11, 15),
    );
  });
  test('invalid, missing and unsupported output never becomes filters', () {
    for (final invalid in ['oops', '{}', '[]', output(category: 'Unknown')]) {
      expect(
        () => AiFilterRepository.parse(invalid, choices),
        throwsA(isA<AppException>()),
      );
    }
  });
  test(
    'accept edits only draft, preserves other fields and waits for Apply',
    () {
      final container = ProviderContainer(
        overrides: [realBackendEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      final vm = container.read(eviaViewModelProvider.notifier);
      vm.selectFilter('Availability', 'Full');
      vm.useAiFilters(
        const EventFilters(
          category: 'Workshop',
          time: 'Afternoon',
        ).withRange(DateTime(2026, 11, 14), DateTime(2026, 11, 15)),
      );
      expect(container.read(eviaViewModelProvider).filters.category, 'All');
      expect(container.read(eviaViewModelProvider).draft.availability, 'Full');
      vm.selectFilter('Time', 'Evening');
      vm.applyFilters();
      expect(container.read(eviaViewModelProvider).filters.time, 'Evening');
      expect(
        container.read(eviaViewModelProvider).filters.rangeEnd,
        DateTime(2026, 11, 15),
      );
    },
  );
  for (final width in [360.0, 412.0]) {
    testWidgets('AI panel has safe fallback at width $width with large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [realBackendEnabledProvider.overrideWithValue(false)],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(child: AiFilterPanel()),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'workshop afternoon');
      await tester.ensureVisible(find.text('Suggest filters'));
      await tester.tap(find.text('Suggest filters'));
      await tester.pump();
      expect(find.textContaining('Enable Firebase'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
