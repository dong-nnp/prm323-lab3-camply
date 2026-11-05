import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/services/firebase_messaging_service.dart';
import 'package:prm393_lab03/core/errors/app_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('evia/notifications');
  late StreamController<RemoteMessage> messages;
  late List<MethodCall> calls;
  setUp(() {
    messages = StreamController<RemoteMessage>();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() async {
    await messages.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('foreground FCM displays a system notification and preserves event routing data', () async {
    final service = FirebaseMessagingService(
      () async {},
      messages: messages.stream,
    );
    final received = service.foregroundMessages.first;
    messages.add(
      RemoteMessage.fromMap({
        'messageId': 'test-fcm-message',
        'notification': {
          'title': 'New event',
          'body': 'Your club published an event',
        },
        'data': {
          'notificationId': 'notice-1',
          'entityType': 'event',
          'entityId': 'event-1',
        },
      }),
    );
    expect(await received, {
      'notificationId': 'notice-1',
      'entityType': 'event',
      'entityId': 'event-1',
    });
    expect(calls.single.method, 'showNotification');
    expect(calls.single.arguments, {
      'title': 'New event',
      'body': 'Your club published an event',
      'messageId': 'test-fcm-message',
      'tag': 'notice-1',
    });
  });
  test(
    'data-only FCM refreshes state without creating an empty notification',
    () async {
      final service = FirebaseMessagingService(
        () async {},
        messages: messages.stream,
      );
      final received = service.foregroundMessages.first;
      messages.add(const RemoteMessage(data: {'entityId': 'event-2'}));
      expect(await received, {'entityId': 'event-2'});
      expect(calls, isEmpty);
    },
  );
  test(
    'native notification failure is reported instead of claiming success',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(code: 'notification_failed'),
          );
      final service = FirebaseMessagingService(
        () async {},
        messages: messages.stream,
      );
      final received = expectLater(
        service.foregroundMessages.first,
        throwsA(isA<AppException>()),
      );
      messages.add(
        RemoteMessage.fromMap({
          'messageId': 'test-failed',
          'notification': {'title': 'New event'},
        }),
      );
      await received;
    },
  );
}
