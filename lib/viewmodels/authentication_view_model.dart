import 'dart:async';

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
  ({String name, String method})? _authEvent;
  bool _signingOut = false;

  void recordLogin(String method) => _recordAuthEvent('login', method);
  void recordSignUp() => _recordAuthEvent('sign_up', 'password');

  void _recordAuthEvent(String name, String method) {
    if (!ref.mounted) return;
    if (state.asData?.value.status == AuthStatus.signedIn) {
      unawaited(
        ref
            .read(analyticsRepositoryProvider)
            .track(name, parameters: {'method': method}),
      );
    } else {
      _authEvent = (name: name, method: method);
    }
  }

  Future<String?> signOut() async {
    if (_signingOut) return null;
    _signingOut = true;
    final analytics = ref.read(analyticsRepositoryProvider);
    try {
      await ref.read(authenticationRepositoryProvider).signOut();
      _authEvent = null;
      unawaited(analytics.identify(null));
      unawaited(analytics.track('logout'));
      return null;
    } catch (error) {
      unawaited(analytics.error('logout', error));
      return ExceptionMapper.map(error).message;
    } finally {
      _signingOut = false;
    }
  }

  @override
  Stream<AuthSession> build() {
    final repository = ref.watch(authenticationRepositoryProvider);
    final analytics = ref.watch(analyticsRepositoryProvider);
    return repository
        .watchSession()
        .map((session) {
          unawaited(analytics.identify(session.userId));
          if (session.status == AuthStatus.signedIn && _authEvent != null) {
            unawaited(
              analytics.track(
                _authEvent!.name,
                parameters: {'method': _authEvent!.method},
              ),
            );
            _authEvent = null;
          }
          return session;
        })
        .handleError((Object error, StackTrace stack) {
          unawaited(analytics.identify(null));
          Error.throwWithStackTrace(error, stack);
        });
  }
}
