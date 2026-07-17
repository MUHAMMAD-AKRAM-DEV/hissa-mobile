// ============================================================
//  lib/theme.dart  —  Colors, dark mode, typography.
//  Goes in:  hissa_mobile/lib/theme.dart   (replace all)
//
//  MIGRATION NOTE:
//   • AppColors.*  = the old LIGHT constants. Screens not yet
//     migrated still use these and keep compiling.
//   • C.of(context).*  = theme-aware colors (light OR dark).
//     Screens get migrated to this one at a time.
//  When every screen uses C.of(context), AppColors can go.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Legacy light palette. Still used by screens not yet migrated.
class AppColors {
  static const ink = Color(0xFF14231F);
  static const brand = Color(0xFF0C5A4E);
  static const brandDeep = Color(0xFF073E36);
  static const accent = Color(0xFF2FA39A);
  static const gold = Color(0xFFE2A33B);
  static const goldSoft = Color(0xFFF4D79B);
  static const muted = Color(0xFF7C8B85);
  static const line = Color(0xFFE9EFEC);
  static const card = Color(0xFFFFFFFF);
  static const positive = Color(0xFF137A47);
  static const negative = Color(0xFFC0392B);
  static const tint = Color(0xFFF7FBF9);
  static const tile = Color(0xFFEEF5F2);
  static const field = Color(0xFFF1F5F3);
  static const imgBg = Color(0xFFDFE9E5);
}

/// Theme-aware palette. Same names as AppColors, plus `bg`.
class HissaColors {
  final Color ink, brand, brandDeep, accent, gold, goldSoft, muted, line,
      card, positive, negative, tint, tile, field, imgBg, bg,
      btn, onBtn; // primary button bg + its text/icon colour
  final bool isDark;

  const HissaColors({
    required this.ink, required this.brand, required this.brandDeep,
    required this.accent, required this.gold, required this.goldSoft,
    required this.muted, required this.line, required this.card,
    required this.positive, required this.negative, required this.tint,
    required this.tile, required this.field, required this.imgBg,
    required this.bg, required this.btn, required this.onBtn,
    required this.isDark,
  });

  static const light = HissaColors(
    ink: Color(0xFF14231F),
    brand: Color(0xFF0C5A4E),
    brandDeep: Color(0xFF073E36),
    accent: Color(0xFF2FA39A),
    gold: Color(0xFFE2A33B),
    goldSoft: Color(0xFFF4D79B),
    muted: Color(0xFF7C8B85),
    line: Color(0xFFE9EFEC),
    card: Color(0xFFFFFFFF),
    positive: Color(0xFF137A47),
    negative: Color(0xFFC0392B),
    tint: Color(0xFFF7FBF9),
    tile: Color(0xFFEEF5F2),
    field: Color(0xFFF1F5F3),
    imgBg: Color(0xFFDFE9E5),
    bg: Color(0xFFFFFFFF),
    btn: Color(0xFF14231F),      // near-black button
    onBtn: Color(0xFFFFFFFF),
    isDark: false,
  );

  // Dark palette from the design system: bg #0E1A17, card #16241F,
  // text #EAF2EE, brand #35B7AD.
  static const dark = HissaColors(
    ink: Color(0xFFEAF2EE),        // primary text
    brand: Color(0xFF35B7AD),      // brighter green so it reads on dark
    brandDeep: Color(0xFF0C5A4E),
    accent: Color(0xFF4FD1C5),
    gold: Color(0xFFE2A33B),
    goldSoft: Color(0xFFF4D79B),
    muted: Color(0xFF8FA39C),
    line: Color(0xFF25352F),
    card: Color(0xFF16241F),
    positive: Color(0xFF3FBF7F),
    negative: Color(0xFFE2564D),
    tint: Color(0xFF16241F),
    tile: Color(0xFF1E2F29),
    field: Color(0xFF1E2F29),
    imgBg: Color(0xFF25352F),
    bg: Color(0xFF0E1A17),
    btn: Color(0xFF35B7AD),      // brand teal reads well on dark
    onBtn: Color(0xFF07211C),
    isDark: true,
  );
}

/// Global dark-mode switch. Toggle it and the app rebuilds.
final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

/// Flip dark mode and remember the choice.
Future<void> setDarkMode(bool on) async {
  darkMode.value = on;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hissa_dark', on);
  } catch (_) {}
}

/// Shorthand: `final c = C.of(context);` then use `c.ink`, `c.card`, …
class C {
  static HissaColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? HissaColors.dark : HissaColors.light;
}

const String kHeadingFont = 'PlusJakartaSans';
const String kBodyFont = 'Inter';

ThemeData buildHissaTheme({bool dark = false}) {
  final p = dark ? HissaColors.dark : HissaColors.light;
  final base = ThemeData(useMaterial3: true, brightness: dark ? Brightness.dark : Brightness.light);

  final text = base.textTheme
      .apply(fontFamily: kBodyFont, bodyColor: p.ink, displayColor: p.ink)
      .copyWith(
    displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: kHeadingFont, color: p.ink),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: kHeadingFont, color: p.ink),
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.brand,
      primary: p.brand,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: kHeadingFont, fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
    ),
  );
}

TextStyle hHeading({double size = 22, FontWeight weight = FontWeight.w800, Color color = AppColors.ink, double spacing = -0.5, double height = 1.15}) =>
    TextStyle(fontFamily: kHeadingFont, fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);