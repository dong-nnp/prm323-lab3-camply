import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../models/auth_session.dart';
import '../core/utils/exception_mapper.dart';

final authenticationViewModelProvider =
    StreamNotifierProvider<AuthenticationViewModel, AuthSession>(
      AuthenticationViewModel.new,
    );

final hasAuthenticatedSessionProvider = Provider<bool>((ref) {
  final auth = ref.watch(authenticationViewModelProvider);
  return !auth.isLoading && auth.asData?.value.status == AuthStatus.signedIn;
});

/// Observes the selected authentication adapter and handles sign-out.
class AuthenticationViewModel extends StreamNotifier<AuthSession> {
  Future<String?> signOut() async {
    try {
      await ref.read(authenticationRepositoryProvider).signOut();
      return null;
    } catch (error) {
      return ExceptionMapper.map(error).message;
    }
  }

  @override
  Stream<AuthSession> build() =>
      ref.watch(authenticationRepositoryProvider).watchSession();
}
