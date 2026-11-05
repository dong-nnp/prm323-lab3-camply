import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/models/auth_session.dart';
import 'package:prm393_lab03/models/firebase_status.dart';
import 'package:prm393_lab03/viewmodels/authentication_view_model.dart';
import 'package:prm393_lab03/viewmodels/evia_view_model.dart';
import 'package:prm393_lab03/viewmodels/startup_view_model.dart';

import '../helpers/fake_firebase_initializer.dart';
import '../helpers/startup_test_auth.dart';

void main() {
  Future<ProviderContainer> open(
    AuthSession session, {
    Future<FirebaseStatus> Function()? initialize,
  }) async {
    final container = ProviderContainer(
      overrides: [
        firebaseInitializerProvider.overrideWithValue(
          FakeFirebaseInitializer(
            initialize ?? () async => FirebaseStatus.notConfigured,
          ),
        ),
        authenticationViewModelProvider.overrideWith(
          () => StartupTestAuth(Stream.value(session)),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(startupDestinationProvider, (_, _) {});
    await container.read(authenticationViewModelProvider.future);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('waits for initialization even when signed out', () async {
    final pending = Completer<FirebaseStatus>();
    final c = await open(
      const AuthSession.signedOut(),
      initialize: () => pending.future,
    );
    expect(c.read(startupDestinationProvider), isNull);
    pending.complete(FirebaseStatus.notConfigured);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(startupDestinationProvider), '/');
  });

  test('unavailable and signed-out sessions go to Welcome', () async {
    for (final session in [
      const AuthSession.signedOut(),
      const AuthSession.unavailable(),
    ]) {
      final c = await open(session);
      expect(c.read(startupDestinationProvider), '/');
    }
  });

  test('signed-in routing uses profile flag, not mock interests', () async {
    final pending = await open(const AuthSession.signedIn('pending'));
    expect(pending.read(eviaViewModelProvider).interests, isNotEmpty);
    expect(pending.read(startupDestinationProvider), '/interests');
    final completed = await open(
      const AuthSession.signedIn('complete', personalizationHandled: true),
    );
    expect(completed.read(startupDestinationProvider), '/discover');
  });

  test('explicit skip preserves interests and is scoped to the user', () async {
    final c = await open(const AuthSession.signedIn('first'));
    final before = c.read(eviaViewModelProvider).interests;
    expect(
      c
          .read(eviaViewModelProvider.notifier)
          .finishPersonalization(skipped: true),
      '/discover',
    );
    expect(c.read(startupDestinationProvider), '/discover');
    expect(c.read(eviaViewModelProvider).interests, before);
    expect(c.read(eviaViewModelProvider).personalizedUsers, {'first'});
  });

  test('initialization failure opens existing retry screen', () async {
    final c = await open(
      const AuthSession.signedOut(),
      initialize: () async => throw const AppException(
        code: 'test',
        message: 'Initialization unavailable',
      ),
    );
    expect(c.read(startupDestinationProvider), '/foundation');
  });

  test('waits for auth and does not reuse another users completion', () async {
    final sessions = StreamController<AuthSession>();
    addTearDown(sessions.close);
    final c = ProviderContainer(
      overrides: [
        firebaseInitializerProvider.overrideWithValue(
          FakeFirebaseInitializer(() async => FirebaseStatus.notConfigured),
        ),
        authenticationViewModelProvider.overrideWith(
          () => StartupTestAuth(sessions.stream),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(startupDestinationProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(startupDestinationProvider), isNull);
    sessions.add(const AuthSession.signedIn('first'));
    await Future<void>.delayed(Duration.zero);
    c.read(eviaViewModelProvider.notifier).finishPersonalization();
    expect(c.read(startupDestinationProvider), '/discover');
    sessions.add(const AuthSession.signedIn('second'));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(startupDestinationProvider), '/interests');
    sessions.addError(StateError('Session unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(startupDestinationProvider), '/');
  });
}
