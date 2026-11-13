import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppFeedback extends StatefulWidget {
  const AppFeedback({required this.child, super.key});

  final Widget child;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    context.findAncestorStateOfType<_AppFeedbackState>()?._show(
      message,
      isError,
    );
  }

  @override
  State<AppFeedback> createState() => _AppFeedbackState();
}

class _AppFeedbackState extends State<AppFeedback> {
  ({String message, bool isError})? _feedback;
  Timer? _timer;

  void _show(String message, bool isError) {
    _timer?.cancel();
    setState(() => _feedback = (message: message, isError: isError));
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _timer = Timer(const Duration(seconds: 4), _dismiss);
    }
  }

  void _dismiss() {
    _timer?.cancel();
    setState(() => _feedback = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (feedback != null)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.contentMaxWidth,
                    ),
                    child: _FeedbackCard(
                      message: feedback.message,
                      isError: feedback.isError,
                      onDismiss: _dismiss,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Card(
      margin: EdgeInsets.zero,
      color: isError ? AppColors.errorSurface : AppColors.successSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: color.withValues(alpha: .25)),
      ),
      child: SingleChildScrollView(
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            IconButton(
              color: color,
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                semanticLabel: MaterialLocalizations.of(context)
                    .closeButtonTooltip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
