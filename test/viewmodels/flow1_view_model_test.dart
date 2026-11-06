import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/evia_models.dart';
import 'package:prm393_lab03/models/flow1_models.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/repositories/flow1_repository.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';

import '../helpers/flow1_backend.dart';
import '../helpers/startup_test_auth.dart';
import '../helpers/sign_up_test_service.dart';

void main() {
  late Flow1TestBackend backend;
  late ProviderContainer c;
  setUp(() async {
    backend = Flow1TestBackend();
    c = ProviderContainer(
      overrides: [
        signedInTestSession,
        backendServiceProvider.overrideWithValue(backend),
      ],
    );
    c.listen(flow1ViewModelProvider, (_, _) {});
    c.listen(flow1RegistrationProvider('server-event-17'), (_, _) {});
    await c.pump();
    await c.read(flow1ViewModelProvider.future);
  });
  tearDown(() => c.dispose());

  test('pagination continues after an empty filtered page; nullable capacity remains unlimited', () async {
    backend.handle = (name, input) async {
      if (name == 'getPublicCatalog' && input['kind'] == 'events') {
        return input['cursor'] == null
            ? {'items': [], 'nextCursor': 'candidate-50'}
            : {
                'items': [testEvent(spots: null)],
                'nextCursor': null,
              };
      }
      return backend.respond(name, input);
    };
    final data = await Flow1Repository(backend).load(false);
    expect(data.events.single.id, 'server-event-17');
    expect(data.events.single.spots, isNull);
    expect(data.account, isNull);
    expect(
      backend.calls
          .lastWhere(
            (c) => c.name == 'getPublicCatalog' && c.input['kind'] == 'events',
          )
          .input['cursor'],
      'candidate-50',
    );
  });
  test('repeated cursor fails instead of looping indefinitely', () async {
    backend.handle = (name, input) async => {'items': [], 'nextCursor': 'same'};
    await expectLater(
      Flow1Repository(backend).load(false),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'invalid_cursor'),
      ),
    );
  });
  test(
    'date range is inclusive by Vietnam day and filters use server keys',
    () async {
      await Flow1Repository(backend).search(
        ' Flutter ',
        'All',
        EventFilters(
          date: 'Custom range',
          rangeStart: DateTime(2026, 11, 30),
          rangeEnd: DateTime(2026, 12, 1),
          availability: 'Full',
          time: 'Morning',
          duration: '1–3 hours',
        ),
      );
      final input = backend.calls.last.input;
      expect(input['q'], 'Flutter');
      expect(input['from'], '2026-11-29T17:00:00.000Z');
      expect(input['until'], '2026-12-01T17:00:00.000Z');
      expect(input['availability'], 'full');
      expect(input['timeOfDay'], 'morning');
      expect(input['duration'], 'one_to_three_hours');
    },
  );
  test(
    'follow blocks duplicate taps and changes only after server success',
    () async {
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async {
        if (name == 'followOrganizer') {
          final result = await gate.future;
          backend.following = true;
          return result;
        }
        return backend.respond(name, input);
      };
      final vm = c.read(flow1ViewModelProvider.notifier);
      final first = vm.follow('server-club-4');
      expect(c.read(flow1ViewModelProvider).requireValue.followed, isEmpty);
      expect(c.read(flow1ViewModelProvider).requireValue.busy, isTrue);
      expect(await vm.follow('server-club-4'), isFalse);
      gate.complete({});
      expect(await first, isTrue);
      expect(c.read(flow1ViewModelProvider).requireValue.followed, {
        'server-club-4',
      });
      expect(
        backend.calls.where((c) => c.name == 'followOrganizer'),
        hasLength(1),
      );
    },
  );
  test('bookmark responds immediately, blocks duplicate and rolls back failed removal', () async {
    final gate = Completer<void>();
    backend.handle = (name, input) async {
      if (name == 'setBookmark') await gate.future;
      return backend.respond(name, input);
    };
    final vm = c.read(flow1ViewModelProvider.notifier);
    final reads = backend.calls
        .where((call) => call.name == 'getPublicCatalog')
        .length;
    final pending = vm.bookmark('server-event-17');
    expect(
      c.read(flow1ViewModelProvider).requireValue.saved,
      contains('server-event-17'),
    );
    expect(c.read(flow1ViewModelProvider).requireValue.busy, isTrue);
    expect(await vm.bookmark('server-event-17'), isFalse);
    expect(
      backend.calls.where((call) => call.name == 'setBookmark'),
      hasLength(1),
    );
    gate.complete();
    expect(await pending, isTrue);
    expect(
      backend.calls.where((call) => call.name == 'getPublicCatalog'),
      hasLength(reads),
    );

    final failed = Completer<void>();
    backend.handle = (name, input) async {
      if (name == 'setBookmark') {
        await failed.future;
        throw const AppException(code: 'unavailable', message: 'Offline');
      }
      return backend.respond(name, input);
    };
    final removal = vm.bookmark('server-event-17');
    expect(c.read(flow1ViewModelProvider).requireValue.saved, isEmpty);
    failed.complete();
    expect(await removal, isFalse);
    expect(
      c.read(flow1ViewModelProvider).requireValue.saved,
      contains('server-event-17'),
    );
    expect(c.read(flow1ViewModelProvider).requireValue.actionError, 'Offline');
    expect(c.read(flow1ViewModelProvider).requireValue.busy, isFalse);
  });

  test('failed bookmark keeps prior data and supports a real retry', () async {
    backend.handle = (name, input) async {
      if (name == 'setBookmark') {
        throw const AppException(code: 'unavailable', message: 'Offline');
      }
      return backend.respond(name, input);
    };
    final vm = c.read(flow1ViewModelProvider.notifier);
    expect(await vm.bookmark('server-event-17'), isFalse);
    final failed = c.read(flow1ViewModelProvider).requireValue;
    expect(failed.saved, isEmpty);
    expect(failed.actionError, 'Offline');
    expect(failed.busy, isFalse);
    backend.handle = null;
    expect(await vm.bookmark('server-event-17'), isTrue);
    expect(c.read(flow1ViewModelProvider).requireValue.saved, {
      'server-event-17',
    });
  });
  test('onboarding waits for server and uses interest IDs', () async {
    final vm = c.read(flow1ViewModelProvider.notifier);
    vm.selectInterest('sports');
    expect(await vm.saveInterests(), isFalse);
    vm.selectInterest('arts');
    expect(await vm.saveInterests(), isTrue);
    expect(backend.selected, {'technology', 'music', 'arts'});
    expect(
      backend.calls
          .lastWhere((c) => c.name == 'saveInterests')
          .input['interests'],
      contains('arts'),
    );
  });
  final fields = {
    'fullName': ' Student Name ',
    'studentId': 'se123456',
    'universityEmail': ' Student@FPT.EDU.VN ',
    'phoneNumber': '',
  };
  test('invalid identity or missing terms never sends registration', () async {
    final vm = c.read(flow1RegistrationProvider('server-event-17').notifier);
    expect(
      await vm.submit(Flow1Event(testEvent()), {
        ...fields,
        'studentId': '123',
        'universityEmail': 'a@@gmail.com',
      }, false),
      isFalse,
    );
    expect(
      c.read(flow1RegistrationProvider('server-event-17')).errors.keys,
      containsAll(['studentId', 'universityEmail', 'terms']),
    );
    expect(backend.calls.where((c) => c.name == 'registerForEvent'), isEmpty);
  });
  test(
    'timeout recovers receipt before any retry debit and blocks duplicate taps',
    () async {
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async {
        if (name == 'registerForEvent') return gate.future;
        if (name == 'getOperationStatus') {
          return {
            'result': {'ticketId': 'committed-on-server'},
          };
        }
        return backend.respond(name, input);
      };
      final vm = c.read(flow1RegistrationProvider('server-event-17').notifier),
          event = Flow1Event(testEvent());
      final first = vm.submit(event, fields, true);
      expect(await vm.submit(event, fields, true), isFalse);
      gate.completeError(
        const AppException(code: 'deadline-exceeded', message: 'Timed out'),
      );
      expect(await first, isFalse);
      expect(
        c.read(flow1RegistrationProvider('server-event-17')).uncertain,
        isTrue,
      );
      final request = backend.calls
          .singleWhere((c) => c.name == 'registerForEvent')
          .input;
      expect((request['attendeeInput'] as Map)['studentId'], 'SE123456');
      expect(await vm.submit(event, fields, true), isTrue);
      expect(
        backend.calls.where((c) => c.name == 'registerForEvent'),
        hasLength(1),
      );
      expect(
        backend.calls
            .singleWhere((c) => c.name == 'getOperationStatus')
            .input['operationId'],
        request['requestId'],
      );
    },
  );
  test(
    'missing receipt retries exactly the original payload and request ID',
    () async {
      var attempts = 0;
      backend.handle = (name, input) async {
        if (name == 'registerForEvent' && attempts++ == 0) {
          throw const AppException(code: 'unavailable', message: 'Offline');
        }
        if (name == 'getOperationStatus') {
          throw const AppException(code: 'NOT_FOUND', message: 'No receipt');
        }
        return backend.respond(name, input);
      };
      final vm = c.read(flow1RegistrationProvider('server-event-17').notifier),
          event = Flow1Event(testEvent());
      expect(await vm.submit(event, fields, true), isFalse);
      expect(
        await vm.submit(event, {...fields, 'fullName': 'Changed'}, true),
        isTrue,
      );
      final requests = backend.calls
          .where((c) => c.name == 'registerForEvent')
          .toList();
      expect(requests[0].input, requests[1].input);
    },
  );
  test(
    'price change requires terms confirmation again and a fresh request',
    () async {
      backend.handle = (name, input) async {
        if (name == 'registerForEvent') {
          throw const AppException(
            code: 'QUOTE_CHANGED',
            message: 'Price changed',
          );
        }
        return backend.respond(name, input);
      };
      final vm = c.read(flow1RegistrationProvider('server-event-17').notifier);
      expect(await vm.submit(Flow1Event(testEvent()), fields, true), isFalse);
      expect(
        c.read(flow1RegistrationProvider('server-event-17')).uncertain,
        isFalse,
      );
      expect(
        await vm.submit(Flow1Event(testEvent(deposit: 70)), fields, false),
        isFalse,
      );
      backend.handle = null;
      expect(
        await vm.submit(Flow1Event(testEvent(deposit: 70)), fields, true),
        isTrue,
      );
      final requests = backend.calls
          .where((c) => c.name == 'registerForEvent')
          .toList();
      expect(requests[1].input['expectedDepositCoins'], 70);
      expect(
        requests[1].input['requestId'],
        isNot(requests[0].input['requestId']),
      );
    },
  );
  test(
    'registration requests belong to one event, including uncertain retries',
    () async {
      backend.handle = (name, input) async {
        if (name == 'registerForEvent') {
          throw const AppException(code: 'unavailable', message: 'Offline');
        }
        return backend.respond(name, input);
      };
      final first = c.read(
        flow1RegistrationProvider('server-event-17').notifier,
      );
      await first.submit(Flow1Event(testEvent()), fields, true);
      c.listen(flow1RegistrationProvider('other-event'), (_, _) {});
      final second = c.read(flow1RegistrationProvider('other-event').notifier);
      expect(
        await second.submit(Flow1Event(testEvent()), fields, true),
        isFalse,
      );
      backend.handle = null;
      expect(
        await second.submit(
          Flow1Event({...testEvent(), 'id': 'other-event'}),
          fields,
          true,
        ),
        isTrue,
      );
      expect(
        c.read(flow1RegistrationProvider('server-event-17')).uncertain,
        isTrue,
      );
      expect(
        backend.calls.where((c) => c.name == 'getOperationStatus'),
        isEmpty,
      );
      final requests = backend.calls
          .where((c) => c.name == 'registerForEvent')
          .toList();
      expect(requests[0].input['eventId'], 'server-event-17');
      expect(requests[1].input['eventId'], 'other-event');
      expect(
        requests[0].input['requestId'],
        isNot(requests[1].input['requestId']),
      );
    },
  );
  test('switching accounts clears uncertain requests and ignores late actions from the old UID', () async {
    final auth = SignUpTestService()
      ..session = const AuthSession.signedIn(
        'user-a',
        personalizationHandled: true,
      );
    c.dispose();
    c = ProviderContainer(
      overrides: [
        authenticationServiceProvider.overrideWithValue(auth),
        backendServiceProvider.overrideWithValue(backend),
      ],
    );
    c.listen(flow1ViewModelProvider, (_, _) {});
    c.listen(flow1RegistrationProvider('server-event-17'), (_, _) {});
    await c.pump();
    await c.read(flow1ViewModelProvider.future);
    backend.handle = (name, input) async {
      if (name == 'registerForEvent') {
        throw const AppException(code: 'unavailable', message: 'Offline');
      }
      return backend.respond(name, input);
    };
    await c
        .read(flow1RegistrationProvider('server-event-17').notifier)
        .submit(Flow1Event(testEvent()), fields, true);
    expect(
      c.read(flow1RegistrationProvider('server-event-17')).uncertain,
      isTrue,
    );
    final gate = Completer<Map<String, dynamic>>();
    backend.handle = (name, input) async =>
        name == 'followOrganizer' ? gate.future : backend.respond(name, input);
    final action = c
        .read(flow1ViewModelProvider.notifier)
        .follow('server-club-4');
    auth.publish(
      const AuthSession.signedIn('user-b', personalizationHandled: true),
    );
    await c.pump();
    await c.read(flow1ViewModelProvider.future);
    expect(
      c.read(flow1RegistrationProvider('server-event-17')).uncertain,
      isFalse,
    );
    gate.complete({});
    expect(await action, isFalse);
    expect(c.read(flow1ViewModelProvider).requireValue.followed, isEmpty);
    c.dispose();
    await auth.close();
  });
}
