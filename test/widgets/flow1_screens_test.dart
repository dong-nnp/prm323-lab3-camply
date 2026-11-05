import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/app/app.dart';
import 'package:prm393_lab03/app/router.dart';
import 'package:prm393_lab03/screens/evia/discover_screen.dart';
import 'package:prm393_lab03/screens/evia/event_details_screen.dart';
import 'package:prm393_lab03/screens/evia/interests_screen.dart';
import 'package:prm393_lab03/screens/evia/registration_form_screen.dart';
import 'package:prm393_lab03/screens/evia/registration_result_screen.dart';
import 'package:prm393_lab03/screens/evia/ticket_screen.dart';
import 'package:prm393_lab03/viewmodels/activity_view_model.dart';
import 'package:prm393_lab03/models/registration_models.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/registration_view_model.dart';
import 'package:prm393_lab03/screens/evia/login_screen.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/models/flow1_models.dart';
import 'package:prm393_lab03/widgets/event_flow_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/flow1_backend.dart';
import '../helpers/startup_test_auth.dart';
import '../helpers/sign_up_test_service.dart';

Future<ProviderContainer> open(
  WidgetTester tester,
  Flow1TestBackend backend,
  String route, {
  bool signed = true,
  double width = 390,
  double textScale = 1,
  Stream<AuthSession>? sessions,
}) async {
  tester.view.physicalSize = Size(width, 884);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final c = ProviderContainer(
    overrides: [
      realBackendEnabledProvider.overrideWithValue(true),
      backendServiceProvider.overrideWithValue(backend),
      authenticationViewModelProvider.overrideWith(
        () => StartupTestAuth(
          sessions ??
              Stream.value(
                signed
                    ? AuthSession.signedIn(
                        'test-user',
                        personalizationHandled: backend.onboarded,
                      )
                    : const AuthSession.signedOut(),
              ),
        ),
      ),
      initialLocationProvider.overrideWithValue(route),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 884),
          textScaler: TextScaler.linear(textScale),
        ),
        child: const LabApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets(
    'merged Following uses server registrations and keeps the event ID',
    (tester) async {
      final backend = Flow1TestBackend()..registered = true;
      await open(tester, backend, '/following/events');
      expect(find.text('Server event title'), findsOneWidget);
      expect(find.text('Server club'), findsWidgets);
      expect(find.text('Campus Music Night'), findsNothing);
      await tester.tap(find.text('Server event title'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(
        tester
            .widget<EventDetailsScreen>(find.byType(EventDetailsScreen))
            .eventId,
        'server-event-17',
      );
      expect(
        tester.widget<EventDetailsScreen>(find.byType(EventDetailsScreen)).tab,
        'schedule',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('merged event summary accepts a remote image URL', (
    tester,
  ) async {
    final event = Flow1Event({
      ...testEvent(),
      'imageUrl': 'https://example.invalid/event.jpg',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlowEventSummary(
            screen: '2083:5709',
            event: event.presentation('Server club'),
            form: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any((image) => image.image is NetworkImage),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('live catalog keeps the original Discover and its cards', (
    tester,
  ) async {
    await open(tester, Flow1TestBackend(), '/discover', width: 360);
    expect(find.byType(EviaDiscoverScreen), findsOneWidget);
    expect(find.text('Server event title'), findsWidgets);
    expect(find.text('200 coins'), findsOneWidget);
    expect(find.text('Campus Music Night'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'pushed Login returns to the original event after a session update',
    (tester) async {
      final auth = SignUpTestService();
      final c = await open(
        tester,
        Flow1TestBackend(),
        '/event/about?event=server-event-17',
        sessions: auth.watchSession(),
      );
      await tester.tap(find.text('Register Now'));
      await tester.pumpAndSettle();
      expect(find.byType(EviaLoginScreen), findsOneWidget);
      auth.publish(
        const AuthSession.signedIn('test-user', personalizationHandled: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EviaLoginScreen), findsNothing);
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Server event title'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await auth.close();
    },
  );
  testWidgets(
    'original eight interest cards wait for the server and send canonical IDs',
    (tester) async {
      final backend = Flow1TestBackend()
        ..onboarded = false
        ..selected = {};
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async {
        if (name == 'saveInterests') {
          await gate.future;
        }
        return backend.respond(name, input);
      };
      final c = await open(tester, backend, '/profile');
      expect(find.byType(EviaInterestsScreen), findsOneWidget);
      expect(find.text('Gaming'), findsNothing);
      expect(find.text('Environment'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      for (final label in ['Technology', 'Music & Gigs', 'Arts & Culture']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pump();
      }
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(c.read(eviaViewModelProvider).isSavingInterests, isTrue);
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/interests',
      );
      gate.complete({});
      await tester.pumpAndSettle();
      expect(backend.selected, {'technology', 'music', 'arts'});
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/profile',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed onboarding keeps the original error text and supports retry',
    (tester) async {
      final backend = Flow1TestBackend()..onboarded = false;
      backend.handle = (name, input) async {
        if (name == 'saveInterests') {
          throw const AppException(code: 'unavailable', message: 'Save failed');
        }
        return backend.respond(name, input);
      };
      final c = await open(tester, backend, '/interests');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(EviaInterestsScreen), findsOneWidget);
      expect(find.text('Save failed'), findsOneWidget);
      backend.handle = null;
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(EviaDiscoverScreen), findsOneWidget);
      expect(c.read(eviaViewModelProvider).isSavingInterests, isFalse);
    },
  );
  testWidgets('original full event disables Register and offers no Waitlist', (
    tester,
  ) async {
    final backend = Flow1TestBackend();
    backend.handle = (name, input) async =>
        name == 'getEvent' ? testEvent(spots: 0) : backend.respond(name, input);
    await open(tester, backend, '/event/about?event=server-event-17');
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(find.text('Registration Full'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Registration Full'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Waitlist'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'original form loading result and ticket wait for a server receipt',
    (tester) async {
      final backend = Flow1TestBackend();
      final gate = Completer<Map<String, dynamic>>();
      backend.handle = (name, input) async {
        if (name == 'registerForEvent') {
          await gate.future;
        }
        return backend.respond(name, input);
      };
      final c = await open(
        tester,
        backend,
        '/event/about?event=server-event-17',
        width: 412,
      );
      await tester.tap(find.text('Register Now'));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationFormScreen), findsOneWidget);
      expect(find.text('Account verified'), findsNothing);
      final agree = find.bySemanticsLabel(
        'Accept registration and deposit terms',
      );
      await tester.ensureVisible(agree);
      await tester.tap(agree);
      await tester.pump();
      await tester.tap(find.text('Confirm Registration'));
      await tester.pump();
      expect(
        c.read(registrationViewModelProvider).status,
        RegistrationStatus.loading,
      );
      expect(find.text('Registration Successful!'), findsNothing);
      gate.complete({});
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationResultScreen), findsOneWidget);
      expect(find.text('50 coins on hold'), findsOneWidget);
      await tester.ensureVisible(find.text('View My Digital Ticket'));
      await tester.tap(find.text('View My Digital Ticket'));
      await tester.pumpAndSettle();
      expect(find.byType(TicketScreen), findsOneWidget);
      expect(find.text('EVIA-SERVER-17'), findsOneWidget);
      expect(tester.widget<QrImageView>(find.byType(QrImageView)).size, 208);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    },
  );
  testWidgets('opening success directly does not fabricate a registration', (
    tester,
  ) async {
    final c = await open(
      tester,
      Flow1TestBackend(),
      '/registration/success?event=server-event-17',
    );
    expect(find.text('Registration Successful!'), findsNothing);
    expect(find.text('No registration'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    c.dispose();
  });
  testWidgets('original filters send canonical category to API', (
    tester,
  ) async {
    final backend = Flow1TestBackend();
    await open(tester, backend, '/filters');
    await tester.tap(find.text('technology'));
    await tester.pump();
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(
      backend.calls
          .lastWhere(
            (c) => c.name == 'getPublicCatalog' && c.input['kind'] == 'events',
          )
          .input['category'],
      'technology',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('catalog network error uses the existing retry component', (
    tester,
  ) async {
    final backend = Flow1TestBackend()
      ..handle = (name, input) async => throw const AppException(
        code: 'unavailable',
        message: 'Network unavailable',
      );
    await open(tester, backend, '/discover');
    expect(find.text('Network unavailable'), findsOneWidget);
    backend.handle = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(EviaDiscoverScreen), findsOneWidget);
    expect(find.text('Server event title'), findsWidgets);
  });
  testWidgets(
    'old registration VM preserves receipt retry without fake coins',
    (tester) async {
      final backend = Flow1TestBackend();
      final attempts = <Map<String, dynamic>>[];
      backend.handle = (name, input) async {
        if (name == 'registerForEvent') {
          attempts.add(Map.of(input));
          throw const AppException(
            code: 'unavailable',
            message: 'Connection lost',
          );
        }
        if (name == 'getOperationStatus') {
          backend.registered = true;
          return {
            'result': {'ticketId': 'server-ticket'},
          };
        }
        return backend.respond(name, input);
      };
      final c = await open(
        tester,
        backend,
        '/registration?event=server-event-17',
      );
      final vm = c.read(registrationViewModelProvider.notifier);
      vm.agree(true);
      expect(await vm.submit(), RegistrationStatus.failed);
      expect(c.read(activityViewModelProvider).available, 200);
      expect(vm.pendingConfirmation, isTrue);
      expect(await vm.submit(), RegistrationStatus.success);
      expect(attempts, hasLength(1));
      expect(
        backend.calls
            .singleWhere((c) => c.name == 'getOperationStatus')
            .input['operationId'],
        attempts.single['requestId'],
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('saving eight UI interests preserves unseen server IDs', (
    tester,
  ) async {
    final backend = Flow1TestBackend()
      ..selected = {'technology', 'music', 'arts', 'gaming', 'environment'};
    final c = await open(tester, backend, '/interests');
    final vm = c.read(eviaViewModelProvider.notifier);
    vm.toggleInterest('Photography');
    expect(await vm.finishPersonalization(), '/discover');
    expect(backend.selected, {
      'technology',
      'music',
      'arts',
      'photography',
      'gaming',
      'environment',
    });
    expect(find.text('Gaming'), findsNothing);
    expect(find.text('Environment'), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
