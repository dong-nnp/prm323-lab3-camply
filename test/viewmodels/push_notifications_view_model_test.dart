import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/providers/service_providers.dart';
import 'package:prm393_lab03/viewmodels/push_notifications_view_model.dart';

import '../helpers/flow1_backend.dart';
import '../helpers/startup_test_auth.dart';
import '../services/push_notification_repository_test.dart' show TestMessaging;

void main() {
  test('FCM restore does not prompt or loop; explicit permission reinitializes listeners once', () async {
    final messaging = TestMessaging();
    final backend = Flow1TestBackend()..handle = (_, _) async => {};
    final c = ProviderContainer(
      overrides: [
        signedInTestSession,
        realBackendEnabledProvider.overrideWithValue(true),
        messagingServiceProvider.overrideWithValue(messaging),
        backendServiceProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(c.dispose);
    c.listen(pushNotificationsViewModelProvider, (_, _) {});
    for (var i = 0; i < 8; i++) {
      await c.pump();
    }
    expect(c.read(pushNotificationsViewModelProvider).enabled, isTrue);
    expect(messaging.permissionCalls, 0);
    expect(backend.calls, hasLength(1));
    await c
        .read(pushNotificationsViewModelProvider.notifier)
        .requestPermission();
    for (var i = 0; i < 8; i++) {
      await c.pump();
    }
    expect(messaging.permissionCalls, 1);
    expect(backend.calls, hasLength(3));
  });

  test(
    'FCM startup failure is reported and can recover on Notifications retry',
    () async {
      var offline = true;
      final messaging = TestMessaging()
        ..token = () async {
          if (offline) throw StateError('Test network unavailable');
          return 'test-only-registration-token';
        };
      final backend = Flow1TestBackend()..handle = (_, _) async => {};
      final c = ProviderContainer(
        overrides: [
          signedInTestSession,
          realBackendEnabledProvider.overrideWithValue(true),
          messagingServiceProvider.overrideWithValue(messaging),
          backendServiceProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(c.dispose);
      c.listen(pushNotificationsViewModelProvider, (_, _) {});
      for (var i = 0; i < 8; i++) {
        await c.pump();
      }
      expect(c.read(pushNotificationsViewModelProvider).error, isNotNull);
      offline = false;
      await c
          .read(pushNotificationsViewModelProvider.notifier)
          .requestPermission();
      for (var i = 0; i < 8; i++) {
        await c.pump();
      }
      expect(c.read(pushNotificationsViewModelProvider).enabled, isTrue);
      expect(c.read(pushNotificationsViewModelProvider).error, isNull);
    },
  );
}
