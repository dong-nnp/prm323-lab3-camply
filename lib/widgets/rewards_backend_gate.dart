import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/service_providers.dart';
import '../core/utils/exception_mapper.dart';
import '../viewmodels/flow1_view_model.dart';
import '../viewmodels/flow3_view_model.dart';
import 'evia_widgets.dart';
import 'status_widgets.dart';

/// Uses the existing loading/error presentation around the original reward screens.
class RewardsBackendGate extends ConsumerStatefulWidget {
  const RewardsBackendGate({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<RewardsBackendGate> createState() => _RewardsBackendGateState();
}

class _RewardsBackendGateState extends ConsumerState<RewardsBackendGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted &&
          ref.read(realBackendEnabledProvider) &&
          ref.read(flow3ViewModelProvider).hasValue) {
        ref.read(flow3ViewModelProvider.notifier).refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(realBackendEnabledProvider)) {
      ref.read(flow3ViewModelProvider.notifier).refresh();
      ref.read(flow1ViewModelProvider.notifier).refresh();
      ref.invalidate(voucherCodeProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(realBackendEnabledProvider)) return widget.child;
    ref.watch(flow1ViewModelProvider);
    ref.listen(flow3ViewModelProvider, (previous, next) {
      final error = next.asData?.value.error;
      if (error != null && error != previous?.asData?.value.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            ScaffoldMessenger.maybeOf(context)
                ?.showSnackBar(SnackBar(content: Text(error)));
          }
        });
      }
    });
    return ref
        .watch(flow3ViewModelProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          data: (_) => widget.child,
          loading: () =>
              const EviaPage(child: Center(child: AppLoadingWidget())),
          error: (error, _) => EviaPage(
            child: Center(
              child: AppErrorWidget(
                message: ExceptionMapper.map(error).message,
                onRetry: () =>
                    ref.read(flow3ViewModelProvider.notifier).refresh(),
              ),
            ),
          ),
        );
  }
}
