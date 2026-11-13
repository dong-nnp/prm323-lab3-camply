import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'router.dart';

class LabApp extends ConsumerWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: AppStrings.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) => AppFeedback(child: child!),
  );
}
