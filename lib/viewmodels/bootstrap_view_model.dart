import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../models/app_state.dart';
import '../models/firebase_status.dart';

final bootstrapViewModelProvider =
    NotifierProvider<BootstrapViewModel, AppState<FirebaseStatus>>(
      BootstrapViewModel.new,
    );

class BootstrapViewModel extends Notifier<AppState<FirebaseStatus>> {
  bool _isLoading = false;

  @override
  AppState<FirebaseStatus> build() {
    // Defer the action until the initial state has been published.
    unawaited(Future<void>.microtask(refresh));
    return const AppLoading();
  }

  Future<void> refresh() async {
    if (_isLoading || !ref.mounted) return;
    _isLoading = true;
    state = const AppLoading();

    try {
      final status = await ref.read(bootstrapRepositoryProvider).initialize();
      if (!ref.mounted) return;
      state = switch (status) {
        FirebaseStatus.notConfigured => const AppEmpty(
          AppStrings.notConfigured,
        ),
        FirebaseStatus.ready => AppData(status),
      };
    } catch (error) {
      if (ref.mounted) state = AppError(ExceptionMapper.map(error));
    } finally {
      _isLoading = false;
    }
  }
}
