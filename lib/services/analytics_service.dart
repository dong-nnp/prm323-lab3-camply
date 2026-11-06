abstract interface class AnalyticsService {
  Future<void> setUserId(String? userId);
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}
