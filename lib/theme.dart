// ============================================================
//  lib/theme.dart  —  Hissa colors + typography.
//  Goes in:  hissa_mobile/lib/theme.dart   (replace all)
//
//  Requires:  flutter pub add google_fonts
//  Fonts: Plus Jakarta Sans (headings) + Inter (body/UI)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

ThemeData buildHissaTheme() {
  // Inter drives body/UI text; Plus Jakarta Sans is used for headings.
  final base = ThemeData(useMaterial3: true);
  final bodyFont = GoogleFonts.interTextTheme(base.textTheme);
  final headingFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  final text = bodyFont.copyWith(
    // headings / display styles use Plus Jakarta Sans
    displayLarge: headingFont.displayLarge,
    displayMedium: headingFont.displayMedium,
    displaySmall: headingFont.displaySmall,
    headlineLarge: headingFont.headlineLarge,
    headlineMedium: headingFont.headlineMedium,
    headlineSmall: headingFont.headlineSmall,
    titleLarge: headingFont.titleLarge,
    titleMedium: headingFont.titleMedium,
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand, primary: AppColors.brand),
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}

/// Use for big headings so they always render in Plus Jakarta Sans.
TextStyle hHeading({double size = 22, FontWeight weight = FontWeight.w800, Color color = AppColors.ink, double spacing = -0.5, double height = 1.15}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);