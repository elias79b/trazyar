import 'package:design_system/src/colors/app_colors.dart';
import 'package:design_system/src/radius/app_radius.dart';
import 'package:design_system/src/typography/app_typography.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final theme = FlexThemeData.light(
      colors: AppColors.lightScheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: AppRadius.radius12,
        elevatedButtonRadius: AppRadius.radius12,
        outlinedButtonRadius: AppRadius.radius12,
        textButtonRadius: AppRadius.radius12,
        inputDecoratorRadius: AppRadius.radius12,
        cardRadius: AppRadius.radius12,
        bottomSheetRadius: AppRadius.radius16,
        dialogRadius: AppRadius.radius16,
        fabRadius: AppRadius.radius16,
        chipRadius: AppRadius.radius8,
        popupMenuRadius: AppRadius.radius8,
        tooltipRadius: AppRadius.radius8,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorIsFilled: true,
      ),
      useMaterial3: true,
      fontFamily: AppTypography.persianFontFamily,
    );

    return theme.copyWith(
      textTheme: AppTypography.light(theme.colorScheme),
      primaryTextTheme: AppTypography.light(theme.colorScheme),
      typography: AppTypography.persianTypography(theme.colorScheme),
    );
  }
}
