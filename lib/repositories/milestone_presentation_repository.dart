import '../services/remote_config_service.dart';

final class MilestonePresentationRepository {
  const MilestonePresentationRepository(this._remoteConfig);

  final RemoteConfigService _remoteConfig;

  Future<String?> loadIntro() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } on Exception {
      // A failed fetch can still leave activated values or bundled defaults.
    }
    if (_remoteConfig.getString('event_milestones_enabled').toLowerCase() !=
        'true') {
      return null;
    }
    final intro = _remoteConfig.getString('event_milestones_intro');
    return intro.isEmpty ? null : intro;
  }
}
