import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/data/mock/activity_mock_data.dart';
import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';

void main() {
  late ProviderContainer container;
  late ActivityViewModel vm;
  setUp(() {
    container = ProviderContainer(
      overrides: [hasAuthenticatedSessionProvider.overrideWithValue(true)],
    );
    vm = container.read(activityViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());
  test(
    'preview money never changes from check-in or redemption without API',
    () {
      final before = container.read(activityViewModelProvider);
      expect(before.available, 420);
      expect(before.deposits, 100);
      expect(vm.canRedeem('cafe'), isFalse);
      expect(vm.rewardStatus('cafe'), 'Preview');
      expect(vm.redeem('cafe'), isFalse);
      expect(vm.checkIn(ActivityMockData.demoCheckInCode), isFalse);
      final after = container.read(activityViewModelProvider);
      expect(after.available, before.available);
      expect(after.deposits, before.deposits);
      expect(after.transactions, same(before.transactions));
      expect(after.receipts, same(before.receipts));
      expect(after.verified, before.verified);
      expect(after.message, contains('not connected'));
    },
  );
  test('event deposits cannot be held locally', () {
    final event = RegisteredEvent(
      id: 'new',
      title: 'Test event',
      category: 'Test',
      dateLabel: 'Test',
      venue: 'Test',
      start: DateTime(2026, 11, 5),
    );
    expect(vm.addRegistration(event, deposit: 100), isFalse);
    expect(container.read(activityViewModelProvider).registrations, isEmpty);
    expect(container.read(activityViewModelProvider).available, 420);
    expect(container.read(activityViewModelProvider).deposits, 100);
  });
  test('date, past tab and cancellation change event presentation only', () {
    vm.setReference('past-empty');
    expect(vm.visibleEvents, isEmpty);
    vm.selectDate(DateTime(2026, 10, 26));
    expect(vm.visibleEvents.single.id, 'music');
    vm.setReference('selected');
    expect(vm.visibleEvents.single.id, 'ai');
    vm.cancelRegistration('ai');
    expect(vm.visibleEvents, isEmpty);
    vm.setReference('upcoming');
    expect(vm.visibleEvents.single.id, 'mobile');
  });
  test('calendar draft waits for Apply and handles year boundaries', () {
    vm.setReference('selected');
    vm.beginCalendar();
    vm.draftDate(DateTime(2026, 11, 6));
    expect(vm.visibleEvents.single.id, 'ai');
    vm.applyDate();
    expect(vm.visibleEvents.single.id, 'mobile');
    vm.shiftMonth(2);
    expect(container.read(activityViewModelProvider).calendarMonth.year, 2027);
  });
  test('preview search and history filters still work', () {
    vm.selectRewardCategory('Merchandise');
    vm.searchRewards('tote');
    expect(vm.visibleRewards.single.id, 'tote');
    vm.historyFilter('Deposits');
    expect(vm.history.every((e) => e.kind == CoinKind.deposit), isTrue);
    expect(vm.voucher(ActivityMockData.voucherCode)!.reward.id, 'cafe');
    expect(vm.voucher('missing'), isNull);
  });
}
