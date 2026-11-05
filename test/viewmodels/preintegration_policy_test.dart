import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/data/mock/activity_mock_data.dart';
import 'package:prm393_lab03/data/mock/evia_mock_data.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';
import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';

import '../helpers/fake_campus_service.dart';
import '../helpers/startup_test_auth.dart';

void main() {
  test('milestone claim waits for the server, rejects double taps and uses the server wallet', () async {
    final response = Completer<MilestoneClaimResult>();
    final service = FakeCampusService()
      ..onClaim = (id, version) {
        expect(id, 'first-event');
        expect(version, 1);
        return response.future;
      };
    final c = ProviderContainer(
      overrides: [
        hasAuthenticatedSessionProvider.overrideWithValue(true),
        campusServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(c.dispose);
    final vm = c.read(activityViewModelProvider.notifier);
    expect(vm.milestones.first.canClaim, isTrue);
    final pending = vm.claimMilestone('first-event');
    expect(c.read(activityViewModelProvider).available, 420);
    expect(vm.milestones.first.claiming, isTrue);
    expect(await vm.claimMilestone('first-event'), isFalse);
    response.complete(
      const MilestoneClaimResult(
        milestoneId: 'first-event',
        availableCoins: 777,
        heldCoins: 25,
      ),
    );
    expect(await pending, isTrue);
    expect(c.read(activityViewModelProvider).available, 777);
    expect(c.read(activityViewModelProvider).deposits, 25);
    expect(vm.milestones.first.claimed, isTrue);
    expect(vm.milestones.first.canClaim, isFalse);
    expect(await vm.claimMilestone('first-event'), isFalse);
    expect(service.claimCalls, 1);
  });

  test(
    'unavailable backend cannot finish onboarding or claim milestone money',
    () async {
      final c = ProviderContainer(
        overrides: [
          hasAuthenticatedSessionProvider.overrideWithValue(true),
          authenticationViewModelProvider.overrideWith(
            () => StartupTestAuth(
              Stream.value(const AuthSession.signedIn('pending-school-user')),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(authenticationViewModelProvider, (_, _) {});
      await c.read(authenticationViewModelProvider.future);
      expect(
        await c.read(eviaViewModelProvider.notifier).finishPersonalization(),
        isNull,
      );
      expect(c.read(eviaViewModelProvider).personalizedUsers, isEmpty);
      expect(c.read(eviaViewModelProvider).isSavingInterests, isFalse);
      final vm = c.read(activityViewModelProvider.notifier);
      expect(await vm.claimMilestone('first-event'), isFalse);
      expect(c.read(activityViewModelProvider).available, 420);
      expect(vm.milestones.first.canClaim, isTrue);
      expect(vm.milestones.first.claiming, isFalse);
    },
  );
  test('cancelling refunds 30 percent of the held deposit once', () {
    final c = ProviderContainer(
      overrides: [
        demoAuthEnabledProvider.overrideWithValue(true),
        hasAuthenticatedSessionProvider.overrideWithValue(true),
      ],
    );
    addTearDown(c.dispose);
    c.read(activityViewModelProvider.notifier).cancelRegistration('ai');
    expect(c.read(activityViewModelProvider).available, 2030);
    expect(c.read(activityViewModelProvider).deposits, 0);
    expect(c.read(activityViewModelProvider).heldDeposits, isEmpty);
  });

  test(
    'daily policy, Cafe price and available filters match confirmed scope',
    () {
      expect(ActivityMockData.dailyCheckInPreview.coins, 100);
      expect(ActivityMockData.rewards.first.redeemCost, 200);
      expect(
        EviaMockData.filterGroups['Availability'],
        isNot(contains('Waitlist Available')),
      );
      expect(EviaMockData.filterGroups['Audience'], [
        'Any audience',
        'Open to Everyone',
      ]);
    },
  );

  test(
    'registration accepts any valid email while preserving student ID format',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final vm = c.read(registrationViewModelProvider.notifier);
      vm.edit('studentId', 'se123456');
      vm.edit('email', 'student@fpt.edu.vn');
      expect(vm.validate(), isTrue);
      vm.edit('email', 'staff@fe.edu.vn');
      expect(vm.validate(), isTrue);
      vm.edit('email', 'person@gmail.com');
      expect(vm.validate(), isTrue);
      vm.edit('email', 'person@outlook.com');
      expect(vm.validate(), isTrue);
      vm.edit('email', 'invalid@');
      expect(vm.validate(), isFalse);
      vm.edit('email', 'student@fpt.edu.vn');
      vm.edit('studentId', 'STU-123456');
      expect(vm.validate(), isFalse);
    },
  );
}
