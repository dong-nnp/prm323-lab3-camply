import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';

void main() {
  late ProviderContainer container;
  late EviaViewModel vm;
  setUp(() {
    container = ProviderContainer(
      overrides: [hasAuthenticatedSessionProvider.overrideWithValue(true)],
    );
    vm = container.read(eviaViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());
  test('date, time and custom range filter known event metadata', () {
    vm.showSearch(referenceResults: true);
    vm.beginFilters();
    vm.selectFilter('Time', 'Morning');
    vm.applyFilters();
    expect(vm.searchResults.single.id, 'design');
    vm.resetDraft();
    vm.selectDateRange(DateTime(2026, 11, 6), DateTime(2026, 11, 6));
    vm.applyFilters();
    expect(vm.searchResults.single.id, 'mobile');
    vm.resetDraft();
    vm.selectFilter('Duration', 'Under 1 hour');
    vm.applyFilters();
    expect(
      vm.searchResults,
      isEmpty,
      reason: 'Unknown duration must not claim a match',
    );
  });
  test('search, category and participation filters combine; reset restores results', () {
    vm.showSearch(referenceResults: true);
    expect(vm.searchResults.length, 3);
    vm.selectCategory('Technology');
    expect(vm.searchResults.length, 2);
    vm.beginFilters();
    vm.selectFilter('Registration Policy', 'Walk-in allowed');
    expect(
      vm.searchResults.length,
      2,
      reason: 'Draft must not apply before confirmation',
    );
    vm.applyFilters();
    expect(vm.searchResults, isEmpty);
    vm.clearFilters();
    expect(vm.searchResults.length, 3);
    vm.submitSearch('zzzz');
    expect(vm.searchResults, isEmpty);
  });
  test('search history deduplicates and bookmark/follow state is shared', () {
    vm.submitSearch('hackathon');
    expect(
      container
          .read(eviaViewModelProvider)
          .history
          .where((s) => s == 'hackathon')
          .length,
      1,
    );
    vm.removeHistory('hackathon');
    expect(
      container.read(eviaViewModelProvider).history,
      isNot(contains('hackathon')),
    );
    vm.toggleSaved('ai');
    expect(container.read(eviaViewModelProvider).saved, contains('ai'));
    vm.toggleSaved('ai');
    expect(container.read(eviaViewModelProvider).saved, isNot(contains('ai')));
    vm.toggleFollowed('union');
    expect(
      container.read(eviaViewModelProvider).followed,
      isNot(contains('union')),
    );
  });
}
