import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const FlexSchemeColor lightScheme = FlexSchemeColor(
    primary: primary,
    primaryContainer: Color(0xFFD8F3DC),
    secondary: Color(0xFF52796F),
    secondaryContainer: Color(0xFFDDEDE8),
    tertiary: Color(0xFF6C584C),
    tertiaryContainer: Color(0xFFF2E8DF),
    appBarColor: primary,
    error: Color(0xFFBA1A1A),
  );

  static const Color primary = Color(0xFF1B4332);
  static const Color surface = Color(0xFFFCFCFF);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F6F9);
  static const Color surfaceContainer = Color(0xFFF0F0F3);
  static const Color surfaceContainerHigh = Color(0xFFEAEAED);
  static const Color surfaceContainerHighest = Color(0xFFE4E4E7);
}
