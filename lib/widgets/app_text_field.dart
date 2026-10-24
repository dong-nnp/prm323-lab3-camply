import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.onChanged,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: AppSpacing.xs),
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(hintText: hintText, errorText: errorText),
        ),
      ),
    ],
  );
}
