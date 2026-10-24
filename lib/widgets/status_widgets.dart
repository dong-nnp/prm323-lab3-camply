import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({this.message = AppStrings.loading, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => _StatusContent(
    indicator: CircularProgressIndicator(semanticsLabel: message),
    title: message,
  );
}

class AppEmptyWidget extends StatelessWidget {
  const AppEmptyWidget({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StatusContent(
    indicator: Icon(
      Icons.info_outline,
      size: AppSizes.statusIcon,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    title: title,
    message: message,
    action: action,
  );
}

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StatusContent(
    indicator: Icon(
      Icons.error_outline,
      size: AppSizes.statusIcon,
      color: Theme.of(context).colorScheme.error,
    ),
    title: message,
    action: onRetry == null
        ? null
        : AppButton(label: AppStrings.retry, onPressed: onRetry),
  );
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.indicator,
    required this.title,
    this.message,
    this.action,
  });

  final Widget indicator;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    ),
  );
}
