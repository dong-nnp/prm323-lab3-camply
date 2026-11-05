import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/repositories/push_notification_repository.dart';
import 'package:prm393_lab03/services/messaging_service.dart';

import '../helpers/flow1_backend.dart';

class TestMessaging implements MessagingService {
  bool granted = true, disabled = false;
  int permissionCalls = 0;
  Future<String?> Function()? token;
  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    return granted;
  }

  @override
  Future<String?> getToken() async => token == null
      ? granted
            ? 'test-only-fcm-token'
            : null
      : token!();
  @override
  Future<void> disable() async {
    disabled = true;
  }

  @override
  Future<Map<String, String>?> initialMessage() async => null;
  @override
  Stream<String> get tokenChanges => const Stream.empty();
  @override
  Stream<Map<String, String>> get foregroundMessages => const Stream.empty();
  @override
  Stream<Map<String, String>> get openedMessages => const Stream.empty();
}

void main() {
  test('permission denial does not register a device', () async {
    final messaging = TestMessaging()..granted = false;
    final backend = Flow1TestBackend();
    final repo = PushNotificationRepository(messaging, backend);
    expect(await repo.enable(askPermission: true), isFalse);
    expect(messaging.permissionCalls, 1);
    expect(backend.calls, isEmpty);
  });
  test('register, rotate token, unregister and disable are ordered', () async {
    final messaging = TestMessaging();
    final backend = Flow1TestBackend()..handle = (_, _) async => {};
    final repo = PushNotificationRepository(messaging, backend);
    expect(await repo.enable(), isTrue);
    expect(messaging.permissionCalls, 0);
    await repo.register('new-test-only-token');
    await repo.detach();
    await repo.register('late-test-only-token');
    expect(backend.calls.map((v) => v.name), [
      'registerDevice',
      'registerDevice',
      'unregisterDevice',
    ]);
    expect(
      backend.calls.map((v) => v.input['installationId']).toSet(),
      hasLength(1),
    );
    expect(messaging.disabled, isTrue);
  });
  test('logout cancels registration that is waiting on a token', () async {
    final gate = Completer<String?>();
    final messaging = TestMessaging()..token = () => gate.future;
    final backend = Flow1TestBackend()..handle = (_, _) async => {};
    final repo = PushNotificationRepository(messaging, backend);
    final enabling = repo.enable();
    await Future<void>.delayed(Duration.zero);
    final logout = repo.detach();
    gate.complete('late-test-only-token');
    expect(await enabling, isFalse);
    await logout;
    expect(backend.calls, isEmpty);
    expect(messaging.disabled, isTrue);
  });
}
