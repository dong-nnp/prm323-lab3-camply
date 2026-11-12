import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/constants/app_strings.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/screens/evia/explore_screen.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/flow1_view_model.dart';
import 'package:prm393_lab03/widgets/evia_skeleton.dart';
import 'package:prm393_lab03/widgets/evia_widgets.dart';
import 'package:prm393_lab03/widgets/status_widgets.dart';

import '../helpers/fake_analytics_service.dart';
import '../helpers/flow1_backend.dart';
import '../helpers/sign_up_test_service.dart';

void main() {
  Future<void> pumpExplore(
    WidgetTester tester, {
    required Size size,
    required Flow1TestBackend backend,
    required SignUpTestService auth,
    required FakeAnalyticsService analytics,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realBackendEnabledProvider.overrideWithValue(true),
          analyticsEnabledProvider.overrideWithValue(true),
          authenticationServiceProvider.overrideWithValue(auth),
          backendServiceProvider.overrideWithValue(backend),
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const EviaExploreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'TC19 offline error hides skeleton, keeps retry visible, and recovers cleanly on ${width.toInt()}dp',
      (tester) async {
        final auth = SignUpTestService()
          ..session = const AuthSession.signedIn('student-1');
        addTearDown(auth.close);
        final analytics = FakeAnalyticsService();
        final backend = Flow1TestBackend();
        var offline = false;
        Completer<Map<String, dynamic>>? retryGate;
        backend.handle = (op, input) async {
          if (op == 'getPublicCatalog' && offline) {
            final gate = retryGate;
            if (gate != null) {
              return gate.future;
            }
            throw const AppException(
              code: 'unavailable',
              message: 'No internet connection.',
            );
          }
          return backend.respond(op, input);
        };

        await pumpExplore(
          tester,
          size: Size(width, 640),
          backend: backend,
          auth: auth,
          analytics: analytics,
        );

        offline = true;
        await tester.enterText(find.byType(TextField), 'Server');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(find.byType(AppErrorWidget), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        expect(find.byType(EviaSkeleton), findsNothing);
        expect(find.text('Searching…'), findsNothing);
        expect(find.byType(SearchEventCard), findsNothing);

        final retryRect = tester.getRect(find.text(AppStrings.retry));
        expect(retryRect.bottom, lessThanOrEqualTo(640.0));
        expect(tester.takeException(), isNull);

        retryGate = Completer<Map<String, dynamic>>();
        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();

        expect(find.byType(EviaSkeleton), findsOneWidget);
        expect(find.text('Searching…'), findsOneWidget);
        expect(find.byType(AppErrorWidget), findsNothing);

        offline = false;
        retryGate.complete(
          backend.respond('getPublicCatalog', {'kind': 'events'}),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EviaSkeleton), findsNothing);
        expect(find.byType(AppErrorWidget), findsNothing);
        expect(find.text('1 events found'), findsOneWidget);
        expect(find.byType(SearchEventCard), findsOneWidget);
      },
    );
  }

  testWidgets('TC19 error screen handles 2.0x text scale without overflow', (
    tester,
  ) async {
    final auth = SignUpTestService()
      ..session = const AuthSession.signedIn('student-1');
    addTearDown(auth.close);
    final analytics = FakeAnalyticsService();
    final backend = Flow1TestBackend();
    var offline = false;
    backend.handle = (op, input) async {
      if (op == 'getPublicCatalog' && offline) {
        throw const AppException(
          code: 'unavailable',
          message: 'No internet connection.',
        );
      }
      return backend.respond(op, input);
    };

    await pumpExplore(
      tester,
      size: const Size(360, 640),
      backend: backend,
      auth: auth,
      analytics: analytics,
      textScale: 2.0,
    );

    offline = true;
    await tester.enterText(find.byType(TextField), 'Server');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EviaSkeleton), findsNothing);
    expect(find.byType(AppErrorWidget), findsOneWidget);
    await tester.ensureVisible(find.text(AppStrings.retry));
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('TC03 submitting search renders results and emits AN-04', (
    tester,
  ) async {
    final auth = SignUpTestService()
      ..session = const AuthSession.signedIn('student-1');
    addTearDown(auth.close);
    final analytics = FakeAnalyticsService();
    final backend = Flow1TestBackend();

    await pumpExplore(
      tester,
      size: const Size(412, 915),
      backend: backend,
      auth: auth,
      analytics: analytics,
    );

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(EviaExploreScreen)),
    );
    await scope.read(flow1ViewModelProvider.future);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Server');
    await tester.pump();
    expect(analytics.events.where((e) => e.name == 'search'), isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await scope.pump();

    expect(find.text('1 events found'), findsOneWidget);
    expect(find.byType(SearchEventCard), findsOneWidget);
    final searchEvents = analytics.events
        .where((e) => e.name == 'search')
        .toList();
    expect(searchEvents, hasLength(1));
    expect(searchEvents.single.parameters, {
      'search_term': 'free_text_redacted',
      'loaded_count': 1,
      'has_more': 0,
      'outcome': 'data',
    });
  });
}
