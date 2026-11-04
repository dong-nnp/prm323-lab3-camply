import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.border,
      error: AppColors.error,
      onError: AppColors.surface,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
    );

    const textTheme = TextTheme(
      displayLarge: _display,
      displayMedium: _display,
      displaySmall: _display,
      headlineLarge: _headline,
      headlineMedium: _headline,
      headlineSmall: _headline,
      titleLarge: _subhead,
      titleMedium: _title,
      titleSmall: _title,
      bodyLarge: _bodyLarge,
      bodyMedium: _body,
      bodySmall: _body,
      labelLarge: _button,
      labelMedium: _label,
      labelSmall: _label,
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
    );
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
      borderSide: BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.background,
      disabledColor: AppColors.textDisabled,
      // TODO(design): Bundle licensed Inter assets; use the handoff's system
      // fallback until font assets are supplied. No runtime font downloads.
      fontFamily: 'Roboto',
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        titleTextStyle: _subhead,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size.square(AppSizes.minimumTouchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: shape,
              textStyle: _button,
              elevation: AppElevation.none,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return null;
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primaryPressed;
                }
                return AppColors.primary;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minimumTouchTarget),
          padding: const EdgeInsets.all(AppSpacing.md),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: shape,
          textStyle: _button,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minimumTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(
          minHeight: AppSizes.minimumTouchTarget,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: _body.copyWith(color: AppColors.textSecondary),
        errorStyle: _body.copyWith(color: AppColors.error),
        errorMaxLines: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSizes.borderWidth,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.extraLarge)),
        ),
      ),
    );
  }

  static const _display = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _headline = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _subhead = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _title = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const _bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );
  static const _body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );
  static const _label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const _button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
}
