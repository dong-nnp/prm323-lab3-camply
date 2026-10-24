import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Flexible at 360/412dp, constrained on larger displays, scrollable at large
/// text scales or with the keyboard visible. No fixed-height text containers.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    ),
  );
}
