import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/data/mock/activity_mock_data.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';

void main() {
  late ProviderContainer container;
  late ActivityViewModel vm;
  setUp(() {
    container = ProviderContainer();
    vm = container.read(activityViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());
  test('date, past tab and cancellation change the visible registrations', () {
    vm.setReference('past-empty');
    expect(vm.visibleEvents, isEmpty);
    vm.selectDate(DateTime(2026, 10, 26));
    expect(vm.visibleEvents.single.id, 'music');
    vm.setReference('selected');
    expect(vm.visibleEvents.single.id, 'ai');
    vm.cancelRegistration('ai');
    expect(vm.visibleEvents, isEmpty);
    expect(vm.countFor(false), 1);
    vm.setReference('upcoming');
    expect(vm.visibleEvents.single.id, 'mobile');
  });
  test(
    'calendar draft is not applied until confirmed and handles year boundary',
    () {
      vm.setReference('selected');
      vm.beginCalendar();
      vm.draftDate(DateTime(2026, 11, 6));
      expect(vm.visibleEvents.single.id, 'ai');
      vm.applyDate();
      expect(vm.visibleEvents.single.id, 'mobile');
      vm.shiftMonth(2);
      expect(
        container.read(activityViewModelProvider).calendarMonth.year,
        2027,
      );
    },
  );
  test(
    'daily reward and redemption are idempotent and leave deposits unchanged',
    () {
      vm.dailyCheckIn();
      vm.dailyCheckIn();
      expect(container.read(activityViewModelProvider).available, 430);
      expect(vm.redeem('cafe'), isTrue);
      expect(vm.redeem('cafe'), isFalse);
      final state = container.read(activityViewModelProvider);
      expect(state.available, 180);
      expect(state.deposits, 100);
      expect(state.receipt!.balance, 180);
      expect(state.transactions.first.amount, -250);
      vm.historyFilter('Spent');
      expect(vm.history.every((entry) => entry.amount < 0), isTrue);
    },
  );
  test('invalid code cannot confirm attendance; duplicate code cannot credit twice', () {
    expect(vm.checkIn('wrong'), isFalse);
    expect(container.read(activityViewModelProvider).available, 420);
    expect(vm.checkIn(ActivityMockData.demoCheckInCode), isTrue);
    expect(vm.checkIn(ActivityMockData.demoCheckInCode), isTrue);
    expect(container.read(activityViewModelProvider).available, 500);
    expect(container.read(activityViewModelProvider).verified.length, 4);
  });
  test('insufficient balance rejects redemption without changing wallet or voucher', () {
    expect(vm.redeem('hoodie'), isFalse);
    expect(container.read(activityViewModelProvider).available, 420);
    expect(container.read(activityViewModelProvider).receipt, isNull);
    vm.selectRewardCategory('Merchandise');
    expect(vm.visibleRewards.length, 2);
    vm.searchRewards('tote');
    expect(vm.visibleRewards.single.id, 'tote');
  });
}
