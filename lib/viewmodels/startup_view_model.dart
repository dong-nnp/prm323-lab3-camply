import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_routes.dart';
import '../models/app_state.dart';
import '../models/auth_session.dart';
import 'authentication_view_model.dart';
import 'bootstrap_view_model.dart';
import 'evia_view_model.dart';

/// Resolves startup from existing initialization and session state. The screen
/// separately waits for its first logo frame and accessibility-aware animation.
final startupDestinationProvider = Provider<String?>((ref) {
  final bootstrap = ref.watch(bootstrapViewModelProvider);
  final auth = ref.watch(authenticationViewModelProvider);
  final personalizedUsers = ref.watch(
    eviaViewModelProvider.select((state) => state.personalizedUsers),
  );
  if (bootstrap is AppLoading) return null;
  if (bootstrap is AppError) return AppRoutes.foundation;
  if (auth.isLoading) return null;
  final session = auth.asData?.value;
  if (session?.status != AuthStatus.signedIn) return AppRoutes.home;
  return session!.personalizationHandled ||
          personalizedUsers.contains(session.userId)
      ? AppRoutes.discover
      : AppRoutes.interests;
});
