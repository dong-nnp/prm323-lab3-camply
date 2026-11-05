import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../models/auth_session.dart';

final authenticationViewModelProvider =
    StreamNotifierProvider<AuthenticationViewModel, AuthSession>(
      AuthenticationViewModel.new,
    );

final hasAuthenticatedSessionProvider = Provider<bool>((ref) {
  final auth = ref.watch(authenticationViewModelProvider);
  return !auth.isLoading && auth.asData?.value.status == AuthStatus.signedIn;
});

/// Session observation only. Sign-in/out actions belong here once in scope.
class AuthenticationViewModel extends StreamNotifier<AuthSession> {
  @override
  Stream<AuthSession> build() =>
      ref.watch(authenticationRepositoryProvider).watchSession();
}
