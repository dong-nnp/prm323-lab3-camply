import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/repositories/milestone_presentation_repository.dart';
import 'package:prm393_lab03/services/remote_config_service.dart';

void main() {
  test(
    'disabled presentation hides the intro even if copy is available',
    () async {
      final repository = MilestonePresentationRepository(
        _Config(enabled: 'false', intro: 'QA intro'),
      );
      expect(await repository.loadIntro(), isNull);
    },
  );

  test('a failed refresh uses the last available presentation', () async {
    final repository = MilestonePresentationRepository(
      _Config(enabled: 'true', intro: 'QA intro', offline: true),
    );
    expect(await repository.loadIntro(), 'QA intro');
  });
}

class _Config implements RemoteConfigService {
  const _Config({
    required this.enabled,
    required this.intro,
    this.offline = false,
  });

  final String enabled;
  final String intro;
  final bool offline;

  @override
  Future<bool> fetchAndActivate() async {
    if (offline) throw Exception('Offline');
    return true;
  }

  @override
  String getString(String key) => switch (key) {
    'event_milestones_enabled' => enabled,
    'event_milestones_intro' => intro,
    _ => throw ArgumentError.value(key),
  };
}
