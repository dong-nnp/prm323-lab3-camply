import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/registration_models.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/profile_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        hasAuthenticatedSessionProvider.overrideWithValue(true),
        registrationDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
  });
  tearDown(() => container.dispose());
  test(
    'validation rejects invalid identity and terms without moving wallet',
    () async {
      final vm = container.read(registrationViewModelProvider.notifier);
      vm.preset('error', 'music-live');
      vm.edit('email', 'not-an-email');
      vm.validate();
      expect(
        container.read(registrationViewModelProvider).errors.keys,
        containsAll(['name', 'studentId', 'email', 'terms']),
      );
      expect(await vm.submit(), RegistrationStatus.idle);
      expect(container.read(activityViewModelProvider).available, 420);
      expect(container.read(activityViewModelProvider).registrations, isEmpty);
      vm.edit('name', 'Alex Morgan');
      expect(
        container
            .read(registrationViewModelProvider)
            .errors
            .containsKey('name'),
        isFalse,
      );
    },
  );
  test('registration requiring a coin deposit waits for API without changing preview wallet', () async {
    final vm = container.read(registrationViewModelProvider.notifier);
    expect(await vm.submit(), RegistrationStatus.failed);
    expect(container.read(activityViewModelProvider).available, 420);
    expect(container.read(activityViewModelProvider).deposits, 100);
    expect(container.read(activityViewModelProvider).registrations, isEmpty);
    expect(
      container.read(registrationViewModelProvider).message,
      contains('not connected'),
    );
  });
  test('duplicate submission is blocked while loading', () async {
    final vm = container.read(registrationViewModelProvider.notifier);
    final first = vm.submit();
    expect(
      container.read(registrationViewModelProvider).status,
      RegistrationStatus.loading,
    );
    expect(await vm.submit(), RegistrationStatus.loading);
    await first;
    expect(container.read(activityViewModelProvider).registrations, isEmpty);
  });
  test(
    'failed and full outcomes preserve form, wallet and registrations',
    () async {
      final vm = container.read(registrationViewModelProvider.notifier);
      vm.edit('phone', '0901234567');
      expect(
        await vm.submit(outcome: RegistrationOutcome.failed),
        RegistrationStatus.failed,
      );
      expect(
        await vm.submit(outcome: RegistrationOutcome.full),
        RegistrationStatus.full,
      );
      expect(container.read(registrationViewModelProvider).phone, '0901234567');
      expect(container.read(activityViewModelProvider).available, 420);
      expect(container.read(activityViewModelProvider).registrations, isEmpty);
    },
  );
  test('walk-in Going never holds coins and cannot create duplicate schedule entries', () {
    final vm = container.read(registrationViewModelProvider.notifier);
    vm.markGoing();
    vm.markGoing();
    final activity = container.read(activityViewModelProvider);
    expect(activity.available, 420);
    expect(activity.deposits, 100);
    expect(activity.registrations.length, 1);
    expect(activity.registrations.last.walkIn, isTrue);
  });
  test(
    'pending registration can dispose without mutating disposed state',
    () async {
      final pending = container
          .read(registrationViewModelProvider.notifier)
          .submit();
      container.invalidate(registrationViewModelProvider);
      expect(await pending, RegistrationStatus.idle);
      expect(container.read(activityViewModelProvider).registrations, isEmpty);
    },
  );
  test('saved filters and remove action keep counts consistent', () {
    final vm = container.read(profileViewModelProvider.notifier);
    expect(vm.savedCount('All'), 4);
    expect(vm.savedCount('Upcoming'), 3);
    vm.filterSaved('Past');
    expect(vm.visibleSaved.single.event.id, 'arts');
    vm.toggleSaved('arts');
    expect(vm.visibleSaved, isEmpty);
    expect(vm.savedCount('All'), 3);
  });
  test('preferences require three selections and update Discover state', () {
    final vm = container.read(profileViewModelProvider.notifier);
    vm.toggleInterest('Technology');
    expect(vm.saveInterests(), isFalse);
    expect(container.read(eviaViewModelProvider).interests.length, 3);
    vm.toggleInterest('Photography');
    expect(vm.saveInterests(), isTrue);
    expect(
      container.read(eviaViewModelProvider).interests,
      contains('Photography'),
    );
    expect(
      container.read(eviaViewModelProvider).interests,
      isNot(contains('Technology')),
    );
  });
  test('mark all read clears only unread presentation state', () {
    final vm = container.read(profileViewModelProvider.notifier);
    expect(vm.unreadCount, 2);
    vm.readNotice('registration');
    expect(vm.unreadCount, 1);
    vm.markAllRead();
    expect(vm.unreadCount, 0);
    expect(vm.savedCount('All'), 4);
  });
}
