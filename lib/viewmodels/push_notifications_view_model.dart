import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/service_providers.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import 'authentication_view_model.dart';
import 'profile_view_model.dart';
import 'flow1_view_model.dart';

class PushNotificationState {
  const PushNotificationState({
    this.enabled = false,
    this.destination,
    this.error,
  });
  final bool enabled;
  final String? destination, error;
}

final pushNotificationsViewModelProvider =
    NotifierProvider<PushNotificationsViewModel, PushNotificationState>(
      PushNotificationsViewModel.new,
    );

class PushNotificationsViewModel extends Notifier<PushNotificationState> {
  bool _busy = false;
  @override
  PushNotificationState build() {
    if (!ref.watch(realBackendEnabledProvider)) {
      return const PushNotificationState();
    }
    final uid = ref.watch(authenticationViewModelProvider).asData?.value.userId;
    if (uid == null) return const PushNotificationState();
    var alive = true;
    final subscriptions = <StreamSubscription<Object?>>[];
    ref.onDispose(() {
      alive = false;
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
    });
    Future<void> start() async {
      try {
        final repo = ref.read(pushNotificationRepositoryProvider);
        final enabled = await repo.enable();
        if (!alive) return;
        state = PushNotificationState(enabled: enabled);
        final messaging = repo.messaging;
        void error(Object e) {
          if (alive) {
            state = PushNotificationState(
              enabled: state.enabled,
              error: ExceptionMapper.map(e).message,
            );
          }
        }

        void opened(Map<String, String> data) {
          if (!alive) return;
          final id = data['entityId'];
          final destination =
              data['entityType'] == 'event' &&
                  id != null &&
                  RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)
              ? Uri(
                  path: '/event/about',
                  queryParameters: {'event': id},
                ).toString()
              : '/profile/notifications';
          state = PushNotificationState(
            enabled: state.enabled,
            destination: destination,
          );
        }

        subscriptions.add(
          messaging.tokenChanges.listen((token) async {
            try {
              await repo.register(token);
            } catch (e) {
              error(e);
            }
          }, onError: error),
        );
        subscriptions.add(
          messaging.foregroundMessages.listen((_) {
            if (!alive) return;
            ref.invalidate(notificationsViewModelProvider);
            unawaited(ref.read(flow1ViewModelProvider.notifier).refresh());
          }, onError: error),
        );
        subscriptions.add(
          messaging.openedMessages.listen(opened, onError: error),
        );
        final initial = await messaging.initialMessage();
        if (initial != null) opened(initial);
      } catch (e) {
        if (alive) {
          state = PushNotificationState(error: ExceptionMapper.map(e).message);
        }
      }
    }

    unawaited(Future.microtask(start));
    return const PushNotificationState();
  }

  Future<void> requestPermission() async {
    if (_busy ||
        !ref.read(realBackendEnabledProvider) ||
        ref.read(authenticationViewModelProvider).asData?.value.userId ==
            null) {
      return;
    }
    _busy = true;
    final uid = ref.read(authenticationViewModelProvider).asData?.value.userId;
    try {
      final enabled = await ref
          .read(pushNotificationRepositoryProvider)
          .enable(askPermission: true);
      if (ref.mounted &&
          ref.read(authenticationViewModelProvider).asData?.value.userId ==
              uid) {
        state = PushNotificationState(enabled: enabled);
        if (enabled) ref.invalidateSelf();
      }
    } catch (e) {
      if (ref.mounted) {
        state = PushNotificationState(error: ExceptionMapper.map(e).message);
      }
    } finally {
      _busy = false;
    }
  }

  void clearDestination() =>
      state = PushNotificationState(enabled: state.enabled, error: state.error);
}
