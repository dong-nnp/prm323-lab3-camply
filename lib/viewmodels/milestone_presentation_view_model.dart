import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/service_providers.dart';
import '../repositories/milestone_presentation_repository.dart';

final milestoneIntroProvider = FutureProvider.autoDispose<String?>((ref) {
  if (!ref.watch(realBackendEnabledProvider)) return null;
  final repository = MilestonePresentationRepository(
    ref.watch(remoteConfigServiceProvider),
  );
  return repository.loadIntro();
});
