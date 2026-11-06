import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../models/app_state.dart';
import '../viewmodels/bootstrap_view_model.dart';
import '../widgets/app_button.dart';
import '../widgets/responsive_body.dart';
import '../widgets/status_widgets.dart';

class FoundationScreen extends ConsumerWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bootstrapViewModelProvider);
    final viewModel = ref.read(bootstrapViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: ResponsiveBody(
        child: switch (state) {
          AppLoading() => const AppLoadingWidget(
            message: AppStrings.checkingConfiguration,
          ),
          AppEmpty(:final message) => AppEmptyWidget(
            title: message,
            message: AppStrings.configurationHint,
            action: AppButton(
              label: AppStrings.checkAgain,
              onPressed: viewModel.refresh,
            ),
          ),
          AppError(:final error) => AppErrorWidget(
            message: error.message,
            onRetry: viewModel.refresh,
          ),
          AppData() => const AppEmptyWidget(
            title: AppStrings.firebaseReady,
            message: AppStrings.integrationPending,
          ),
        },
      ),
    );
  }
}
