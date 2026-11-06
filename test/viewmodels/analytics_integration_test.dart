import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/repository_providers.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/models/flow1_models.dart';
import 'package:prm393_lab03/services/report_export_service.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';
import 'package:prm393_lab03/viewmodels/flow3_view_model.dart';
import 'package:prm393_lab03/viewmodels/report_export_view_model.dart';
import 'package:prm393_lab03/viewmodels/sign_up_view_model.dart';
import 'package:prm393_lab03/models/account_creation_result.dart';

import '../helpers/fake_analytics_service.dart';
import '../helpers/flow1_backend.dart';
import '../helpers/flow3_backend.dart';
import '../helpers/sign_up_test_service.dart';

class _ReportService implements ReportExportService {
  Uint8List? bytes;
  bool save = true, fail = false;
  Completer<bool>? gate;
  int calls = 0;
  @override
  Future<bool> saveCsv(Uint8List value) async {
    calls++;
    bytes = value;
    if (fail) throw StateError('disk unavailable');
    return gate?.future ?? save;
  }
}

void main() {
  late ProviderContainer c;
  late Flow3TestBackend backend;
  late SignUpTestService auth;
  late FakeAnalyticsService analytics;
  late _ReportService reports;
  Future<void> settle() async {
    await c.pump();
    // Queue a harmless identity update to wait for all preceding telemetry.
    await c.read(analyticsRepositoryProvider).identify(auth.session.userId);
  }

  setUp(() async {
    backend = Flow3TestBackend();
    auth = SignUpTestService()
      ..session = const AuthSession.signedIn('test-user');
    analytics = FakeAnalyticsService();
    reports = _ReportService();
    c = ProviderContainer(
      overrides: [
        realBackendEnabledProvider.overrideWithValue(true),
        analyticsEnabledProvider.overrideWithValue(true),
        authenticationServiceProvider.overrideWithValue(auth),
        backendServiceProvider.overrideWithValue(backend),
        analyticsServiceProvider.overrideWithValue(analytics),
        reportExportServiceProvider.overrideWithValue(reports),
      ],
    );
    c.listen(authenticationViewModelProvider, (_, _) {});
    await c.read(authenticationViewModelProvider.future);
    c.listen(flow1ViewModelProvider, (_, _) {});
    await c.read(flow1ViewModelProvider.future);
    c.listen(flow3ViewModelProvider, (_, _) {});
    await c.read(flow3ViewModelProvider.future);
  });
  tearDown(() async {
    c.dispose();
    await auth.close();
  });

  test(
    'email account creation records sign_up only after confirmed success',
    () async {
      auth.publish(const AuthSession.signedOut());
      await c.pump();
      c.listen(signUpViewModelProvider, (_, _) {});
      final vm = c.read(signUpViewModelProvider.notifier)..acceptTerms(true);
      auth.create = () async {
        auth.publish(const AuthSession.signedIn('new-student'));
        return AccountCreationResult.signedIn;
      };
      await vm.createAccount(
        fullName: 'Private name',
        email: 'private@example.com',
        password: 'test-password',
        confirmation: 'test-password',
      );
      await settle();
      expect(analytics.events.single.name, 'sign_up');
      expect(analytics.events.single.uid, 'new-student');
      expect(analytics.events.single.parameters, {'method': 'password'});
    },
  );

  test('late export completion after account switch cannot update the new account or its analytics', () async {
    c.listen(reportExportViewModelProvider, (_, _) {});
    reports.gate = Completer<bool>();
    final pending = c
        .read(reportExportViewModelProvider.notifier)
        .exportHistory();
    auth.publish(const AuthSession.signedIn('another-student'));
    await c.pump();
    reports.gate!.complete(true);
    await pending;
    await settle();
    expect(analytics.events.where((e) => e.name == 'generate_report'), isEmpty);
    expect(c.read(reportExportViewModelProvider).message, isNull);
  });

  test('successful signup survives disposal of the signup screen during authentication', () async {
    auth.publish(const AuthSession.signedOut());
    await c.pump();
    final subscription = c.listen(signUpViewModelProvider, (_, _) {});
    final vm = c.read(signUpViewModelProvider.notifier)..acceptTerms(true);
    final gate = Completer<AccountCreationResult>();
    auth.create = () => gate.future;
    final pending = vm.createAccount(
      fullName: 'Private name',
      email: 'private@example.com',
      password: 'test-password',
      confirmation: 'test-password',
    );
    subscription.close();
    await c.pump();
    auth.publish(const AuthSession.signedIn('new-student'));
    gate.complete(AccountCreationResult.signedIn);
    await pending;
    await settle();
    expect(analytics.events.single.name, 'sign_up');
    expect(analytics.events.single.uid, 'new-student');
  });

  test('restored session sets identity without inventing a login; logout clears it', () async {
    await settle();
    expect(analytics.uid, 'test-user');
    expect(analytics.events, isEmpty);
    expect(
      await c.read(authenticationViewModelProvider.notifier).signOut(),
      isNull,
    );
    await settle();
    expect(analytics.uid, isNull);
    expect(analytics.events.single.name, 'logout');
  });
  test(
    'Google login logs only after success, not on cancelled sign-in',
    () async {
      final vm = c.read(eviaViewModelProvider.notifier);
      auth.google = () async =>
          throw const AppException(code: 'cancelled', message: 'Cancelled');
      await vm.continueWithGoogle();
      await settle();
      expect(analytics.events.single.name, 'action_error');
      auth.google = () async {};
      await vm.continueWithGoogle();
      await settle();
      expect(analytics.events.last.name, 'login');
      expect(analytics.events.last.parameters, {'method': 'google'});
    },
  );
  test('event and reward views track once across rebuilds', () async {
    c.listen(eventDetailViewModelProvider('server-event-17'), (_, _) {});
    await c.read(flow1EventProvider('server-event-17').future);
    c.read(flow1EventProvider('server-event-17'));
    c.listen(rewardDetailViewModelProvider('server-reward'), (_, _) {});
    await c.read(rewardDetailViewModelProvider('server-reward').future);
    await c.read(flow3ViewModelProvider.notifier).refresh();
    await settle();
    expect(analytics.events.map((e) => e.name), ['view_event', 'view_reward']);
  });
  test(
    'registration blocks duplicate submissions and sends no form fields',
    () async {
      c.listen(flow1RegistrationProvider('server-event-17'), (_, _) {});
      final vm = c.read(flow1RegistrationProvider('server-event-17').notifier);
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async => name == 'registerForEvent'
          ? gate.future
          : backend.respond(name, input);
      const fields = {
        'fullName': 'Private name',
        'studentId': 'SE123456',
        'universityEmail': 'private@example.com',
        'phoneNumber': '',
      };
      final first = vm.submit(Flow1Event(testEvent()), fields, true);
      expect(await vm.submit(Flow1Event(testEvent()), fields, true), isFalse);
      gate.complete({'ticketId': 'private-ticket'});
      expect(await first, isTrue);
      expect(await vm.submit(Flow1Event(testEvent()), fields, true), isTrue);
      await settle();
      expect(analytics.events.single.parameters, {
        'event_id': 'server-event-17',
        'deposit_coins': 50,
      });
    },
  );
  test(
    'redemption receipt retry after a failed refresh records success once',
    () async {
      var committed = false, failLoad = true;
      backend.handle = (name, input) async {
        if (name == 'getAccount' && committed && failLoad) {
          throw const AppException(code: 'unavailable', message: 'Offline');
        }
        final result = backend.respond(name, input);
        if (name == 'redeemReward') committed = true;
        return result;
      };
      final vm = c.read(flow3ViewModelProvider.notifier);
      final reward = c.read(flow3ViewModelProvider).requireValue.rewards.single;
      expect(await vm.redeem(reward), isFalse);
      failLoad = false;
      expect(await vm.redeem(reward), isTrue);
      await settle();
      expect(
        analytics.events.where((e) => e.name == 'redeem_reward'),
        hasLength(1),
      );
      expect(backend.redemptions, hasLength(1));
    },
  );
  test('attendance tracks new server transitions but not reloads or historical records', () async {
    var attendance = false;
    backend.handle = (name, input) async => name == 'listMyEvents'
        ? {
            'items': [
              {
                'event': testEvent(),
                'registration': {'state': 'registered'},
                'attendance': attendance
                    ? {'verifiedAt': '2026-11-06T00:00:00Z'}
                    : null,
              },
            ],
            'nextCursor': null,
          }
        : backend.respond(name, input);
    await c.read(flow1ViewModelProvider.notifier).refresh();
    attendance = true;
    await c.read(flow1ViewModelProvider.notifier).refresh();
    await c.read(flow1ViewModelProvider.notifier).refresh();
    await settle();
    expect(analytics.events.single.name, 'check_in_event');
    analytics.events.clear();
    c.invalidate(flow1ViewModelProvider);
    await c.read(flow1ViewModelProvider.future);
    await settle();
    expect(analytics.events, isEmpty);
  });
  test('CSV exports loaded filtered rows; success only after save and double tap is blocked', () async {
    await c
        .read(flow3ViewModelProvider.notifier)
        .redeem(c.read(flow3ViewModelProvider).requireValue.rewards.single);
    await settle();
    analytics.events.clear();
    c.listen(reportExportViewModelProvider, (_, _) {});
    reports.gate = Completer<bool>();
    final vm = c.read(reportExportViewModelProvider.notifier);
    final first = vm.exportHistory();
    await vm.exportHistory();
    expect(reports.calls, 1);
    expect(analytics.events, isEmpty);
    reports.gate!.complete(true);
    await first;
    await settle();
    expect(analytics.events.single.name, 'generate_report');
    final csv = utf8.decode(reports.bytes!);
    expect(csv, contains('spent,-200'));
    expect(csv, isNot(contains('Server Café')));
    c.read(activityViewModelProvider.notifier).historyFilter('Earned');
    reports.gate = null;
    await vm.exportHistory();
    expect(
      utf8.decode(reports.bytes!).split('\n').where((s) => s.isNotEmpty),
      hasLength(1),
    );
  });
  test('cancel and failed export never record success; analytics outage cannot break redemption', () async {
    c.listen(reportExportViewModelProvider, (_, _) {});
    reports.save = false;
    await c.read(reportExportViewModelProvider.notifier).exportHistory();
    await settle();
    expect(analytics.events, isEmpty);
    reports.fail = true;
    await c.read(reportExportViewModelProvider.notifier).exportHistory();
    await settle();
    expect(analytics.events.single.name, 'action_error');
    analytics.fail = true;
    expect(
      await c
          .read(flow3ViewModelProvider.notifier)
          .redeem(c.read(flow3ViewModelProvider).requireValue.rewards.single),
      isTrue,
    );
  });
}
