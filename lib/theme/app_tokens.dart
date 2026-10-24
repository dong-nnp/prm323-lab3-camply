import 'package:flutter/material.dart';

/// Camply Lab 2: handoff/flutter-handoff.md and design/DESIGN.md.
abstract final class AppColors {
  static const primary = Color(0xFF2457F5);
  static const primaryPressed = Color(0xFF1745D5);
  static const primarySoft = Color(0xFFEAF0FF);
  static const accent = Color(0xFFC9F46A);
  static const background = Color(0xFFF8F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F8);
  static const textPrimary = Color(0xFF171923);
  static const textSecondary = Color(0xFF525866);
  static const textDisabled = Color(0xFF737987);
  static const border = Color(0xFFDCE0E8);
  static const success = Color(0xFF18794E);
  static const successSurface = Color(0xFFE7F5ED);
  static const warning = Color(0xFF8A5700);
  static const warningSurface = Color(0xFFFFF3D8);
  static const error = Color(0xFFB42336);
  static const errorSurface = Color(0xFFFDECEF);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const section = 48.0;
}

abstract final class AppRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 20.0;
  static const pill = 999.0;
}

abstract final class AppElevation {
  // The foundation uses the flat treatment allowed by DESIGN.md.
  // TODO(design): Map the documented CSS shadows when floating UI is in scope.
  static const none = 0.0;
}

abstract final class AppSizes {
  static const minimumTouchTarget = 48.0;
  static const contentMaxWidth = 560.0;
  static const progressIndicator = 24.0;
  static const statusIcon = 48.0;
  static const borderWidth = 1.0;
}
