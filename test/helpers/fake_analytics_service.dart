import 'package:prm393_lab03/services/analytics_service.dart';

class FakeAnalyticsService implements AnalyticsService {
  final events =
      <({String name, Map<String, Object> parameters, String? uid})>[];
  final identities = <String?>[];
  bool fail = false;
  String? uid;
  @override
  Future<void> setUserId(String? userId) async {
    if (fail) throw StateError('analytics offline');
    uid = userId;
    identities.add(userId);
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (fail) throw StateError('analytics offline');
    events.add((name: name, parameters: parameters ?? {}, uid: uid));
  }
}
