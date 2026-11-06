import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow3_view_model.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';

import '../helpers/flow3_backend.dart';
import '../helpers/startup_test_auth.dart';

void main() {
  late Flow3TestBackend backend;
  late ProviderContainer c;
  setUp(() async {
    backend = Flow3TestBackend();
    c = ProviderContainer(
      overrides: [
        signedInTestSession,
        realBackendEnabledProvider.overrideWithValue(true),
        backendServiceProvider.overrideWithValue(backend),
      ],
    );
    c.listen(authenticationViewModelProvider, (_, _) {});
    await c.read(authenticationViewModelProvider.future);
    c.listen(flow1ViewModelProvider, (_, _) {});
    await c.read(flow1ViewModelProvider.future);
    c.listen(flow3ViewModelProvider, (_, _) {});
    await c.read(flow3ViewModelProvider.future);
  });
  tearDown(() => c.dispose());
  test(
    'event wallet changes refresh deposits and refunds in Rewards',
    () async {
      final activity = c.read(activityViewModelProvider.notifier);
      expect(activity.rewardHeld, 0);
      for (final held in [100, 0]) {
        final updated = Completer<void>();
        final subscription = c.listen(flow3ViewModelProvider, (_, next) {
          if (next.asData?.value.heldCoins == held && !updated.isCompleted) {
            updated.complete();
          }
        });
        backend.held = held;
        backend.available = held == 100 ? 210 : 310;
        await c.read(flow1ViewModelProvider.notifier).refresh();
        await updated.future.timeout(const Duration(seconds: 5));
        expect(activity.rewardHeld, held);
        expect(activity.rewardAvailable, backend.available);
        subscription.close();
      }
    },
  );

  test('daily reads the admin schedule again after refresh', () async {
    backend.dailyRewards = [5, 12, 15, 30, 50, 70, 150];
    backend.dailyDay = 2;
    backend.dailyCoins = 12;
    await c.read(flow3ViewModelProvider.notifier).refresh();
    final progress = c
        .read(flow3ViewModelProvider)
        .requireValue
        .dailyPresentation;
    expect(progress.days.map((day) => day.coins), [5, 12, 15, 30, 50, 70, 150]);
    expect(progress.coins, 12);
    expect(progress.message, contains('150 coins'));

    backend.dailyDay = 8;
    backend.dailyCoins = 150;
    await c.read(flow3ViewModelProvider.notifier).refresh();
    final next = c.read(flow3ViewModelProvider).requireValue.dailyPresentation;
    expect(next.days.last.coins, 150);
    expect(next.message, 'Max reward unlocked · +150 coins daily');
  });

  test('a policy change preserves coins already claimed today', () async {
    backend.dailyRewards = [5, 12, 15, 30, 50, 70, 80];
    backend.dailyDay = 8;
    backend.dailyCoins = 100;
    backend.claimedDaily = true;
    await c.read(flow3ViewModelProvider.notifier).refresh();
    final progress = c
        .read(flow3ViewModelProvider)
        .requireValue
        .dailyPresentation;
    expect(progress.coins, 100);
    expect(progress.days.last.coins, 100);
    expect(progress.message, contains('+80 coins daily'));
    expect(progress.checkedInToday, isTrue);
  });

  test(
    'invalid or missing API schedules fail instead of showing made-up amounts',
    () async {
      for (final schedule in [
        null,
        [5, 12],
        [5, -1, 15, 30, 50, 70, 100],
      ]) {
        backend.handle = (name, input) async {
          final response = backend.respond(name, input);
          if (name == 'getAccount') {
            response['daily'] = {
              ...response['daily'] as Map<String, dynamic>,
              'rewards': schedule,
            };
          }
          return response;
        };
        await c.read(flow3ViewModelProvider.notifier).refresh();
        expect(c.read(flow3ViewModelProvider).error, isA<AppException>());
      }
    },
  );
  test(
    'reward eligibility uses the latest reward wallet after refresh',
    () async {
      c.listen(activityViewModelProvider, (_, _) {});
      backend.available = 10;
      await c.read(flow3ViewModelProvider.notifier).refresh();
      final vm = c.read(activityViewModelProvider.notifier);
      expect(vm.canRedeem('server-reward'), isFalse);
      expect(vm.rewardStatus('server-reward'), 'Not enough coins');
    },
  );
  test(
    'daily uses server day and reward and updates only after server commit',
    () async {
      backend.dailyDay = 8;
      backend.dailyCoins = 100;
      await c.read(flow3ViewModelProvider.notifier).refresh();
      final data = c.read(flow3ViewModelProvider).requireValue;
      expect(data.dailyPresentation.day, 8);
      expect(data.dailyPresentation.days.last.coins, 100);
      final gate = Completer<void>();
      backend.handle = (name, input) async {
        if (name == 'claimDailyCheckin') await gate.future;
        return backend.respond(name, input);
      };
      final vm = c.read(flow3ViewModelProvider.notifier);
      final pending = vm.claimDaily();
      expect(await vm.claimDaily(), isFalse);
      expect(
        c
            .read(flow3ViewModelProvider)
            .requireValue
            .dailyPresentation
            .checkedInToday,
        isFalse,
      );
      gate.complete();
      expect(await pending, isTrue);
      expect(
        c
            .read(flow3ViewModelProvider)
            .requireValue
            .dailyPresentation
            .checkedInToday,
        isTrue,
      );
      expect(c.read(flow1ViewModelProvider).requireValue.available, 410);
    },
  );
  test('milestones use server IDs and versions and preserve claimed state after reload', () async {
    final vm = c.read(flow3ViewModelProvider.notifier);
    expect(await vm.claimMilestone('server-first', 4), isTrue);
    expect(
      backend.calls.lastWhere((v) => v.name == 'claimEventMilestone').input,
      {'milestoneId': 'server-first', 'expectedVersion': 4},
    );
    c.invalidate(flow3ViewModelProvider);
    expect(
      (await c.read(flow3ViewModelProvider.future)).milestones.first.claimed,
      isTrue,
    );
  });
  test(
    'redemption timeout recovers receipt rather than debiting again',
    () async {
      backend.handle = (name, input) async {
        final value = backend.respond(name, input);
        if (name == 'redeemReward') {
          throw const AppException(
            code: 'deadline-exceeded',
            message: 'Timeout',
          );
        }
        return value;
      };
      final vm = c.read(flow3ViewModelProvider.notifier);
      final reward = c.read(flow3ViewModelProvider).requireValue.rewards.single;
      expect(await vm.redeem(reward), isFalse);
      expect(await vm.redeem(reward), isTrue);
      expect(backend.redemptions, hasLength(1));
      expect(backend.available, 110);
      expect(
        backend.calls.where((v) => v.name == 'redeemReward'),
        hasLength(1),
      );
      expect(
        c.read(flow3ViewModelProvider).requireValue.lastRedemptionId,
        'redemption-1',
      );
    },
  );
  test(
    'locker loads physical rewards without requesting a voucher secret',
    () async {
      backend.fulfillment = 'physical';
      await c.read(flow3ViewModelProvider.notifier).refresh();
      final vm = c.read(flow3ViewModelProvider.notifier);
      expect(
        await vm.redeem(
          c.read(flow3ViewModelProvider).requireValue.rewards.single,
        ),
        isTrue,
      );
      final receipt = c
          .read(flow3ViewModelProvider)
          .requireValue
          .receipts
          .single;
      expect(receipt.voucherId, isNull);
      expect(receipt.reward.fulfillmentType, 'physical');
      expect(backend.calls.where((v) => v.name == 'getVoucherCode'), isEmpty);
    },
  );

  test('changed price reloads the quote and requires a new confirmation without charging', () async {
    var changed = false;
    backend.handle = (name, input) async {
      if (name == 'redeemReward') {
        changed = true;
        throw const AppException(
          code: 'PRICE_CHANGED',
          message: 'Price changed',
        );
      }
      if (changed && name == 'getPublicCatalog' && input['kind'] == 'rewards') {
        return {
          'items': [testReward(price: 250)],
          'nextCursor': null,
        };
      }
      return backend.respond(name, input);
    };
    final vm = c.read(flow3ViewModelProvider.notifier);
    expect(
      await vm.redeem(
        c.read(flow3ViewModelProvider).requireValue.rewards.single,
      ),
      isFalse,
    );
    expect(backend.available, 310);
    expect(backend.redemptions, isEmpty);
    expect(
      c.read(flow3ViewModelProvider).requireValue.rewards.single.redeemCost,
      250,
    );
    expect(c.read(flow3ViewModelProvider).requireValue.error, 'Price changed');
  });

  test(
    'refresh failure after committed redemption retains its receipt key',
    () async {
      var unavailable = false;
      backend.handle = (name, input) async {
        if (name == 'getEventMilestones' && unavailable) {
          throw const AppException(
            code: 'unavailable',
            message: 'Refresh failed',
          );
        }
        final response = backend.respond(name, input);
        if (name == 'redeemReward') unavailable = true;
        return response;
      };
      final vm = c.read(flow3ViewModelProvider.notifier),
          reward = c.read(flow3ViewModelProvider).requireValue.rewards.single;
      expect(await vm.redeem(reward), isFalse);
      unavailable = false;
      expect(await vm.redeem(reward), isTrue);
      expect(backend.redemptions, hasLength(1));
      expect(backend.available, 110);
    },
  );
}
