// shortcut: keep token APIs compatible with the deployed token sender; migrate both to FIDs before removal.
// ignore_for_file: deprecated_member_use
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'messaging_service.dart';
import '../core/errors/app_exception.dart';

class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService(this.ready, {this.messages});
  final Future<void> Function() ready;
  final Stream<RemoteMessage>? messages;
  static const _notifications = MethodChannel('evia/notifications');
  Future<T> _run<T>(Future<T> Function() work) async {
    try {
      await ready();
      return await work();
    } catch (_) {
      throw const AppException(
        code: 'messaging_unavailable',
        message: 'Push notifications are unavailable. Check your connection and reopen Notifications to retry.',
      );
    }
  }

  Map<String, String> _data(RemoteMessage m) => {
    for (final entry in m.data.entries) entry.key: '${entry.value}',
  };
  @override
  Future<bool> requestPermission() => _run(() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  });

  @override
  Future<String?> getToken() => _run(() async {
    await _notifications.invokeMethod<void>('ensureChannel');
    final status = (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      return null;
    }
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 20),
    );
  });

  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Stream<Map<String, String>> get foregroundMessages =>
      (messages ?? FirebaseMessaging.onMessage).asyncMap((message) async {
        if (message.notification != null) {
          await _run(
            () => _notifications.invokeMethod<void>('showNotification', {
              'title': message.notification!.title ?? 'Evia',
              'body': message.notification!.body ?? '',
              'messageId': message.messageId,
              'tag': message.data['notificationId'] ?? message.messageId,
            }),
          );
        }
        return _data(message);
      });
  @override
  Stream<Map<String, String>> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_data);
  @override
  Future<Map<String, String>?> initialMessage() => _run(() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _data(message);
  });

  @override
  Future<void> disable() => _run(() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    await FirebaseMessaging.instance.deleteToken().timeout(
      const Duration(seconds: 20),
    );
  });
}
