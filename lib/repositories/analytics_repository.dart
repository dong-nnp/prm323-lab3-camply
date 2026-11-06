import 'dart:developer' as developer;

import '../models/analytics_events.dart';
import '../core/utils/exception_mapper.dart';
import '../services/analytics_service.dart';

/// Ordered identity/events; analytics failures never change a business result.
final class AnalyticsRepository {
  AnalyticsRepository(this._service, {required this.enabled});
  final AnalyticsService _service;
  final bool enabled;
  Future<void> _pending = Future.value();
  String? _userId;
  bool _identified = false;
  final _sent = <String>{};

  Future<void> _enqueue(Future<void> Function() work) {
    if (!enabled) return Future.value();
    return _pending = _pending.then((_) async {
      try {
        await work();
      } catch (_) {
        developer.log('Analytics operation failed', name: 'evia.analytics');
      }
    });
  }

  Future<void> identify(String? uid) {
    if (_userId != uid) _sent.clear();
    _userId = uid;
    return _enqueue(() async {
      _identified = false;
      await _service.setUserId(uid);
      _identified = true;
    });
  }

  Future<void> track(
    String name, {
    Map<String, Object> parameters = const {},
    String? once,
  }) {
    if (once != null && !_sent.add('$name:$once')) return Future.value();
    final values = Map<String, Object>.unmodifiable(parameters);
    return _enqueue(() async {
      AnalyticsEvents.validate(name, values);
      if (_identified) await _service.logEvent(name, parameters: values);
    });
  }

  Future<void> error(String action, Object error) {
    final code = ExceptionMapper.map(error).code;
    return track(
      'action_error',
      parameters: {
        'action': action,
        'error_code': AnalyticsEvents.errorCodes.contains(code)
            ? code
            : 'unexpected',
      },
    );
  }
}
