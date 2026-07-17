// ============================================================
//  lib/theme.dart  —  Hissa colors + typography.
//  Goes in:  hissa_mobile/lib/theme.dart   (replace all)
//
//  Fonts are BUNDLED (no runtime download, works offline).
//  Requires the two .ttf files in assets/fonts/ and the
//  `fonts:` block in pubspec.yaml.
// ============================================================

import 'package:flutter/material.dart';

/// Brand palette (matches the web app + design system).
class AppColors {
  static const ink = Color(0xFF14231F);        // text / dark buttons
  static const brand = Color(0xFF0C5A4E);      // primary green
  static const brandDeep = Color(0xFF073E36);
  static const accent = Color(0xFF2FA39A);     // teal numbers/links
  static const gold = Color(0xFFE2A33B);
  static const goldSoft = Color(0xFFF4D79B);
  static const muted = Color(0xFF7C8B85);
  static const line = Color(0xFFE9EFEC);
  static const card = Color(0xFFFFFFFF);
  static const positive = Color(0xFF137A47);
  static const negative = Color(0xFFC0392B);
  static const tint = Color(0xFFF7FBF9);       // subtle notes/panels
  static const tile = Color(0xFFEEF5F2);       // icon tiles
  static const field = Color(0xFFF1F5F3);      // search / inputs
  static const imgBg = Color(0xFFDFE9E5);      // image placeholder
}

// Font family names as declared in pubspec.yaml
const String kHeadingFont = 'PlusJakartaSans';
const String kBodyFont = 'Inter';

ThemeData buildHissaTheme() {
  final base = ThemeData(useMaterial3: true);

  // Inter for body/UI, Plus Jakarta Sans for headings/titles.
  final text = base.textTheme
      .apply(fontFamily: kBodyFont, bodyColor: AppColors.ink, displayColor: AppColors.ink)
      .copyWith(
    displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: kHeadingFont, color: AppColors.ink),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand, primary: AppColors.brand),
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: kHeadingFont, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}

/// Use for big headings so they always render in Plus Jakarta Sans.
TextStyle hHeading({double size = 22, FontWeight weight = FontWeight.w800, Color color = AppColors.ink, double spacing = -0.5, double height = 1.15}) =>
    TextStyle(fontFamily: kHeadingFont, fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);