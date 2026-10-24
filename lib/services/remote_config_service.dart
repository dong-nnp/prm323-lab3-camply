abstract interface class RemoteConfigService {
  Future<bool> fetchAndActivate();
  String getString(String key);
}
