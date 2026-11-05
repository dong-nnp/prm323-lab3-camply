import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/data/mock/activity_mock_data.dart';
import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/models/registration_models.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

void main() {
  late ProviderContainer container;
  late ActivityViewModel vm;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        demoAuthEnabledProvider.overrideWithValue(true),
        hasAuthenticatedSessionProvider.overrideWithValue(true),
        registrationDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
    vm = container.read(activityViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('registration holds once, cancellation refunds 30 percent once, re-register holds a new deposit', () async {
    final registration = container.read(registrationViewModelProvider.notifier);
    expect(await registration.submit(), RegistrationStatus.success);
    expect(container.read(activityViewModelProvider).available, 1900);
    expect(container.read(activityViewModelProvider).deposits, 200);
    expect(await registration.submit(), RegistrationStatus.success);
    expect(container.read(activityViewModelProvider).available, 1900);
    expect(vm.visibleEvents.any((e) => e.id == 'music-live'), isTrue);
    vm.cancelRegistration('music-live');
    vm.cancelRegistration('music-live');
    expect(container.read(activityViewModelProvider).available, 1930);
    expect(container.read(activityViewModelProvider).deposits, 100);
    expect(await registration.submit(), RegistrationStatus.success);
    expect(container.read(activityViewModelProvider).available, 1830);
    expect(container.read(activityViewModelProvider).registrations.length, 1);
  });

  test('cancellation refund rounds down and remains a deposit transaction', () {
    vm.addRegistration(
      RegisteredEvent(
        id: 'rounding-event',
        title: 'Test event',
        category: 'technology',
        dateLabel: 'Test date',
        venue: 'Test venue',
        start: DateTime(2026, 11, 6),
      ),
      deposit: 55,
    );
    expect(vm.cancelRegistration('rounding-event'), isTrue);
    expect(vm.cancelRegistration('rounding-event'), isFalse);
    final state = container.read(activityViewModelProvider);
    expect(state.available, 1961);
    expect(state.deposits, 100);
    expect(state.transactions.first.amount, 16);
    expect(state.transactions.first.kind, CoinKind.refund);
  });

  test('check-in and daily reward never award twice; attendance appears in past events', () {
    expect(vm.checkIn('wrong'), isFalse);
    expect(container.read(activityViewModelProvider).available, 2000);
    expect(vm.checkIn(ActivityMockData.demoCheckInCode), isTrue);
    expect(vm.checkIn(ActivityMockData.demoCheckInCode), isTrue);
    expect(container.read(activityViewModelProvider).available, 2080);
    vm.selectTab(true);
    expect(vm.visibleEvents.any((e) => e.id == 'club-live'), isTrue);
    expect(vm.claimDaily(), isTrue);
    expect(vm.claimDaily(), isFalse);
    expect(container.read(activityViewModelProvider).available, 2180);
  });

  test('redemption produces matching receipt and history, prevents duplicates and overdraft', () {
    expect(vm.redeem('tote'), isTrue);
    final state = container.read(activityViewModelProvider);
    expect(state.available, 1600);
    expect(state.receipt!.reward.id, 'tote');
    expect(state.receipt!.code, startsWith('DEMO-TOTE-'));
    expect(vm.voucher(state.receipt!.code), same(state.receipt));
    expect(state.transactions.first.kind, CoinKind.spent);
    expect(vm.redeem('tote'), isFalse);
    expect(vm.redeem('hoodie'), isTrue);
    expect(vm.redeem('cinema'), isTrue);
    expect(vm.redeem('cafe'), isTrue);
    expect(container.read(activityViewModelProvider).available, 100);
    vm.resetDemo();
    expect(container.read(activityViewModelProvider).available, 2000);
    expect(container.read(activityViewModelProvider).redeemed, isEmpty);
    expect(container.read(activityViewModelProvider).dailyClaimed, isFalse);
    final expensive = RegisteredEvent(
      id: 'expensive',
      title: 'Expensive',
      category: 'Test',
      dateLabel: 'Test',
      venue: 'Test',
      start: DateTime(2026),
    );
    expect(vm.addRegistration(expensive, deposit: 2001), isFalse);
    expect(container.read(activityViewModelProvider).available, 2000);
  });

  test('guest cannot use demo money actions', () {
    final guest = ProviderContainer(
      overrides: [
        demoAuthEnabledProvider.overrideWithValue(true),
        hasAuthenticatedSessionProvider.overrideWithValue(false),
      ],
    );
    addTearDown(guest.dispose);
    final guestVm = guest.read(activityViewModelProvider.notifier);
    expect(guestVm.checkIn(ActivityMockData.demoCheckInCode), isFalse);
    expect(guestVm.claimDaily(), isFalse);
    expect(guestVm.redeem('cafe'), isFalse);
    expect(guest.read(activityViewModelProvider).available, 2000);
  });
}
