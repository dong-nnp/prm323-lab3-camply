import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: isLoading ? null : onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: AppSizes.progressIndicator,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: label,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
