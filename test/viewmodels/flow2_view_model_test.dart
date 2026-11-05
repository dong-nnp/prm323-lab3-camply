import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';
import 'package:prm393_lab03/viewmodels/profile_view_model.dart';

import '../helpers/flow1_backend.dart';
import '../helpers/startup_test_auth.dart';

void main() {
  late Flow1TestBackend backend;
  late ProviderContainer c;
  setUp(() async {
    backend = Flow1TestBackend()..registered = true;
    c = ProviderContainer(
      overrides: [
        signedInTestSession,
        realBackendEnabledProvider.overrideWithValue(true),
        backendServiceProvider.overrideWithValue(backend),
      ],
    );
    c.listen(flow1ViewModelProvider, (_, _) {});
    await c.read(flow1ViewModelProvider.future);
    c.listen(activityViewModelProvider, (_, _) {});
  });
  tearDown(() => c.dispose());

  test(
    'cancellation waits for server, blocks duplicate taps and reloads account',
    () async {
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async => name == 'cancelRegistration'
          ? gate.future
          : backend.respond(name, input);
      final vm = c.read(activityViewModelProvider.notifier);
      final pending = vm.cancelEvent('server-event-17');
      expect(c.read(activityViewModelProvider).cancelled, isEmpty);
      expect(await vm.cancelEvent('server-event-17'), isFalse);
      backend.registered = false;
      gate.complete({
        'state': 'cancelled',
        'depositRefunded': 16,
        'depositForfeited': 39,
        'wallet': {'availableCoins': 216, 'heldCoins': 0},
      });
      expect(await pending, isTrue);
      expect(
        backend.calls.where((v) => v.name == 'cancelRegistration'),
        hasLength(1),
      );
      expect(c.read(activityViewModelProvider).message, contains('16'));
    },
  );

  test('timeout retries same cancellation id through receipt, without second mutation', () async {
    String? firstId;
    backend.handle = (name, input) async {
      if (name == 'cancelRegistration') {
        firstId = input['requestId'] as String;
        throw const AppException(code: 'deadline-exceeded', message: 'Timeout');
      }
      if (name == 'getOperationStatus') {
        expect(input['operationKind'], 'cancel');
        expect(input['operationId'], firstId);
        backend.registered = false;
        return {
          'result': {'state': 'cancelled', 'depositRefunded': 15},
        };
      }
      return backend.respond(name, input);
    };
    final vm = c.read(activityViewModelProvider.notifier);
    expect(await vm.cancelEvent('server-event-17'), isFalse);
    expect(c.read(activityViewModelProvider).cancelled, isEmpty);
    expect(await vm.cancelEvent('server-event-17'), isTrue);
    expect(
      backend.calls.where((v) => v.name == 'cancelRegistration'),
      hasLength(1),
    );
  });

  test(
    'walk-in Going removal uses intent API without refunding coins',
    () async {
      backend.handle = (name, input) async {
        if (name == 'listMyEvents') {
          return {
            'items': [
              {
                'event': {...testEvent(), 'participationMode': 'walk_in'},
                'going': true,
                'attendance': null,
                'registration': null,
                'past': false,
              },
            ],
            'nextCursor': null,
          };
        }
        if (name == 'setWalkInGoing') {
          expect(input['going'], isFalse);
          return {};
        }
        return backend.respond(name, input);
      };
      await c.read(flow1ViewModelProvider.notifier).refresh();
      expect(
        await c
            .read(activityViewModelProvider.notifier)
            .cancelEvent('server-event-17'),
        isTrue,
      );
      expect(
        backend.calls.where((v) => v.name == 'cancelRegistration'),
        isEmpty,
      );
      expect(c.read(activityViewModelProvider).available, 200);
    },
  );

  test(
    'calendar uses Vietnam day and attendance reward is server snapshot',
    () async {
      backend.handle = (name, input) async {
        if (name == 'listMyEvents') {
          return {
            'items': [
              {
                'event': {...testEvent(), 'startAt': '2030-01-01T18:30:00Z'},
                'registration': {'state': 'attended'},
                'going': false,
                'past': true,
                'attendance': {
                  'rewardCoinsGranted': 45,
                  'verifiedAt': '2030-01-01T18:31:00Z',
                },
              },
            ],
            'nextCursor': null,
          };
        }
        return backend.respond(name, input);
      };
      await c.read(flow1ViewModelProvider.notifier).refresh();
      final vm = c.read(activityViewModelProvider.notifier);
      vm.selectTab(true);
      vm.selectDate(DateTime(2030, 1, 2));
      expect(vm.visibleEvents.single.coins, 45);
      expect(vm.visibleEvents.single.status, 'Attended');
      expect(vm.visibleEvents.single.canCancel, isFalse);
    },
  );

  test('walk-in retry reuses request id and includes selected event', () async {
    final ids = <String>[];
    backend.handle = (name, input) async {
      if (name == 'verifyWalkInCode') {
        ids.add(input['requestId'] as String);
        expect(input['code'], 'ABCDEFGH');
        expect(input['expectedEventId'], 'server-event-17');
        if (ids.length == 1) {
          throw const AppException(code: 'unavailable', message: 'Offline');
        }
        return {'eventId': 'server-event-17', 'coinsGranted': 80};
      }
      return backend.respond(name, input);
    };
    final vm = c.read(activityViewModelProvider.notifier);
    expect(
      await vm.verifyWalkIn('server-event-17', 'abcd-efgh', manual: true),
      isFalse,
    );
    expect(
      await vm.verifyWalkIn('server-event-17', 'abcd-efgh', manual: true),
      isTrue,
    );
    expect(ids[0], ids[1]);
  });

  test('notification reads wait for server and use notification IDs', () async {
    var read = false;
    final gate = Completer<Map<String, dynamic>>();
    backend.handle = (name, input) async {
      if (name == 'listOwned' && input['kind'] == 'notifications') {
        return {
          'items': [
            {
              'id': 'real-notice',
              'type': 'new_event',
              'title': 'New campus event',
              'body': 'Server notification body',
              'entityType': 'event',
              'entityId': 'server-event-17',
              'createdAt': '2026-11-05T03:00:00Z',
              'readAt': read ? '2026-11-05T04:00:00Z' : null,
            },
          ],
          'nextCursor': null,
        };
      }
      if (name == 'markNotificationsRead') {
        expect(input['notificationIds'], ['real-notice']);
        return gate.future;
      }
      return backend.respond(name, input);
    };
    c.listen(notificationsViewModelProvider, (_, _) {});
    await c.read(notificationsViewModelProvider.future);
    final vm = c.read(profileViewModelProvider.notifier);
    expect(vm.notices.single.destination, '/event/about?event=server-event-17');
    final pending = vm.markAllRead();
    expect(vm.unreadCount, 1);
    read = true;
    gate.complete({'updatedCount': 1});
    expect(await pending, isTrue);
    await c.read(notificationsViewModelProvider.future);
    expect(vm.unreadCount, 0);
  });
}
