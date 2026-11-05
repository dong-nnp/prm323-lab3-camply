import 'dart:math';

import '../services/backend_service.dart';
import '../services/messaging_service.dart';

class PushNotificationRepository {
  PushNotificationRepository(this.messaging, this.backend);
  final MessagingService messaging;
  final BackendService backend;
  // Server moves the existing token binding on restart; no device identifier is collected.
  final installationId = List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  bool _registered = false;
  bool _started = false;
  bool _enabled = false;
  Future<void> _pending = Future.value();
  Future<T> _queue<T>(Future<T> Function() work) {
    final result = _pending.then((_) => work());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> enable({bool askPermission = false}) {
    _enabled = true;
    return _queue(() async {
      if (askPermission && !await messaging.requestPermission()) return false;
      final token = await messaging.getToken();
      if (token != null) _started = true;
      if (token == null || !_enabled) return false;
      await _register(token);
      return true;
    });
  }

  Future<void> register(String token) => _queue(() async {
    if (_enabled) await _register(token);
  });
  Future<void> _register(String token) async {
    await backend.call('registerDevice', {
      'installationId': installationId,
      'token': token,
      'platform': 'android',
    });
    _registered = true;
  }

  Future<void> detach() {
    _enabled = false;
    return _queue(() async {
      if (_registered) {
        await backend.call('unregisterDevice', {
          'installationId': installationId,
        });
      }
      if (_started) await messaging.disable();
      _registered = false;
      _started = false;
    });
  }
}
