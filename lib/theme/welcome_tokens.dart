import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// S01 supplied reference; overrides are local to Welcome.
abstract final class WelcomeTokens {
  static const heroAsset = 'assets/EVIA_Welcome_Hero.png';
  static const primary = Color(0xFF1769F5);
  static const navy = Color(0xFF17243B);
  static const secondaryText = Color(0xFF64748B);
  static const logoWidth = 160.0;
  static const heroMinHeight = 180.0;
  static const heroMaxHeight = 300.0;
  static const nonHeroSpace = 520.0;
  static const buttonHeight = 52.0;
  static const heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: navy,
  );
  static const description = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: secondaryText,
  );
  static const background = BoxDecoration(color: AppColors.entryBackground);
  static ThemeData theme(ThemeData base) => base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(buttonHeight),
        padding: const EdgeInsets.all(AppSpacing.md),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        minimumSize: const Size.fromHeight(buttonHeight),
        padding: const EdgeInsets.all(AppSpacing.md),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
