import 'package:firebase_analytics/firebase_analytics.dart';

import '../models/analytics_events.dart';
import 'analytics_service.dart';

final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this.ready);
  final Future<void> Function() ready;
  bool _started = false;

  Future<FirebaseAnalytics> _sdk() async {
    await ready();
    final sdk = FirebaseAnalytics.instance;
    if (!_started) {
      // Clear a persisted identity before enabling this session's collection.
      await sdk.setUserId(id: null);
      await sdk.setAnalyticsCollectionEnabled(true);
      _started = true;
    }
    return sdk;
  }

  @override
  Future<void> setUserId(String? userId) async =>
      (await _sdk()).setUserId(id: userId);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    AnalyticsEvents.validate(name, parameters ?? const {});
    await (await _sdk()).logEvent(name: name, parameters: parameters);
  }
}
