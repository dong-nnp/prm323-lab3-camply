import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/repositories/evibaby_repository.dart';
import 'package:prm393_lab03/services/backend_service.dart';
import 'package:prm393_lab03/theme/app_theme.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/evibaby_view_model.dart';
import 'package:prm393_lab03/widgets/evia_widgets.dart';
import 'package:prm393_lab03/widgets/evibaby_chat.dart';

import 'helpers/startup_test_auth.dart';

Map<String, dynamic> reply() => {
  'reply': 'Evibaby thấy workshop này hợp với bạn nè!',
  'events': [
    {
      'id': 'test-workshop',
      'title': 'Workshop kiểm thử',
      'organizerId': 'test-club',
      'category': 'technology',
      'status': 'published',
      'visibility': 'public',
      'participationMode': 'registration',
      'startAt': '2026-11-14T03:00:00Z',
      'endAt': '2026-11-14T05:00:00Z',
      'venue': {'name': 'Phòng A'},
      'depositCoins': 50,
      'attendanceRewardCoins': 100,
      'spotsRemaining': 5,
    },
  ],
};

class ChatBackend implements BackendService {
  final requests = <Map<String, dynamic>>[];
  Completer<Map<String, dynamic>> pending = Completer();
  @override
  Future<Map<String, dynamic>> call(
    String operation, [
    Map<String, dynamic> input = const {},
  ]) {
    expect(operation, 'chatWithEvibaby');
    requests.add(input);
    return pending.future;
  }
}

ProviderContainer container(ChatBackend backend, {Stream<AuthSession>? auth}) {
  final c = ProviderContainer(
    overrides: [
      backendServiceProvider.overrideWithValue(backend),
      authenticationViewModelProvider.overrideWith(
        () => StartupTestAuth(
          auth ?? Stream.value(const AuthSession.signedIn('test-user')),
        ),
      ),
    ],
  );
  c.listen(evibabyViewModelProvider, (_, _) {});
  return c;
}

void main() {
  test(
    'blocks duplicate sends and keeps the last successful chat as context',
    () async {
      final backend = ChatBackend(), c = container(backend);
      addTearDown(c.dispose);
      await c.read(authenticationViewModelProvider.future);
      final vm = c.read(evibabyViewModelProvider.notifier);
      final pending = vm.send('Gợi ý workshop');
      expect(c.read(evibabyViewModelProvider).busy, isTrue);
      expect(await vm.send('Gửi trùng'), isFalse);
      expect(backend.requests, hasLength(1));
      backend.pending.complete(reply());
      expect(await pending, isTrue);
      expect(
        c.read(evibabyViewModelProvider).messages.last.events.single.id,
        'test-workshop',
      );
      backend.pending = Completer();
      final next = vm.send('Cần cọc bao nhiêu?');
      final history = backend.requests.last['history'] as List;
      expect(history, hasLength(2));
      expect(history.last['content'], contains('test-workshop'));
      backend.pending.complete({
        'reply': 'Evibaby đọc được mức cọc 50 xu.',
        'events': [],
      });
      await next;
    },
  );

  test(
    'failed messages can be retried without duplicating the transcript',
    () async {
      final backend = ChatBackend(), c = container(backend);
      addTearDown(c.dispose);
      await c.read(authenticationViewModelProvider.future);
      final vm = c.read(evibabyViewModelProvider.notifier);
      final pending = vm.send('Gợi ý');
      backend.pending.completeError(
        const AppException(
          code: 'EVIBABY_NOT_CONFIGURED',
          message: 'Raw server message',
        ),
      );
      expect(await pending, isFalse);
      expect(c.read(evibabyViewModelProvider).messages, hasLength(1));
      expect(c.read(evibabyViewModelProvider).error, contains('cấu hình'));
      expect(c.read(evibabyViewModelProvider).error, isNot(contains('Raw')));
      backend.pending = Completer();
      final retry = vm.send('Gợi ý');
      backend.pending.complete(reply());
      await retry;
      expect(c.read(evibabyViewModelProvider).messages, hasLength(3));
    },
  );

  test(
    'invalid input and malformed cards never become successful replies',
    () async {
      final backend = ChatBackend(), c = container(backend);
      addTearDown(c.dispose);
      await c.read(authenticationViewModelProvider.future);
      final vm = c.read(evibabyViewModelProvider.notifier);
      expect(await vm.send(' '), isFalse);
      expect(await vm.send('a' * 1501), isFalse);
      expect(backend.requests, isEmpty);
      backend.pending.complete({
        'reply': 'Not trusted',
        'events': [
          {'id': '../bad'},
        ],
      });
      expect(await vm.send('Gợi ý'), isFalse);
      await expectLater(
        EvibabyRepository(backend).send('x', []),
        throwsA(isA<AppException>()),
      );
    },
  );

  test(
    'late replies do not update state after disposal or an account switch',
    () async {
      final sessions = StreamController<AuthSession>();
      final backend = ChatBackend(),
          c = container(backend, auth: sessions.stream);
      final auth = c.read(authenticationViewModelProvider.future);
      sessions.add(const AuthSession.signedIn('alice'));
      await auth;
      final vm = c.read(evibabyViewModelProvider.notifier);
      final pending = vm.send('Tin nhắn riêng của Alice');
      sessions.add(const AuthSession.signedIn('bob'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(evibabyViewModelProvider).messages, hasLength(1));
      backend.pending.complete(reply());
      await pending;
      expect(c.read(evibabyViewModelProvider).messages, hasLength(1));
      backend.pending = Completer();
      final disposed = c.read(evibabyViewModelProvider.notifier).send('Gợi ý');
      c.dispose();
      backend.pending.completeError(StateError('Late error'));
      await disposed;
      await sessions.close();
    },
  );

  for (final width in [360.0, 412.0]) {
    testWidgets(
      'chat at ${width}dp handles large text, keyboard and event navigation',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final backend = ChatBackend(), c = container(backend);
        addTearDown(c.dispose);
        await c.read(authenticationViewModelProvider.future);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const EviaPage(
                floatingActionButton: EvibabyLauncher(),
                child: Text('Discover test'),
              ),
            ),
            GoRoute(
              path: '/event/about',
              builder: (_, state) => Scaffold(
                body: Text('Chi tiết ${state.uri.queryParameters['event']}'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Trò chuyện với Evibaby'));
        await tester.pumpAndSettle();
        expect(find.text('Evibaby'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Gợi ý workshop');
        await tester.tap(find.byTooltip('Gửi tin nhắn'));
        await tester.pump();
        expect(find.textContaining('đang xem'), findsOneWidget);
        backend.pending.complete(reply());
        await tester.pumpAndSettle();
        expect(find.text('Workshop kiểm thử'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Workshop kiểm thử'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Workshop kiểm thử'));
        await tester.pumpAndSettle();
        expect(find.text('Chi tiết test-workshop'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Trò chuyện với Evibaby'));
        await tester.pumpAndSettle();
        expect(find.text('Workshop kiểm thử'), findsOneWidget);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Firebase disabled reports unavailable and keeps the draft for retry',
    (tester) async {
      final c = ProviderContainer(
        overrides: [
          realBackendEnabledProvider.overrideWithValue(false),
          signedInTestSession,
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: EvibabyChat(onOpenEvent: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Tìm sự kiện');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('chưa kết nối Firebase'), findsOneWidget);
      expect(find.text('Thử gửi lại'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Tìm sự kiện',
      );
      expect(c.read(evibabyViewModelProvider).messages, hasLength(1));
    },
  );
}
