// ============================================================
//  lib/main.dart  —  App entry point.
//  Goes in:  hissa_mobile/lib/main.dart   (replace ALL contents)
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // restore the saved dark-mode choice before the first frame
  try {
    final prefs = await SharedPreferences.getInstance();
    darkMode.value = prefs.getBool('hissa_dark') ?? false;
  } catch (_) {}
  runApp(const HissaApp());
}

class HissaApp extends StatelessWidget {
  const HissaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever darkMode flips.
    return ValueListenableBuilder<bool>(
      valueListenable: darkMode,
      builder: (context, isDark, _) => MaterialApp(
        title: 'Hissa',
        debugShowCheckedModeBanner: false,
        theme: buildHissaTheme(dark: false),
        darkTheme: buildHissaTheme(dark: true),
        // Dark mode is PARKED: several screens still hardcode light surfaces,
        // so enabling it makes their text unreadable. Flip back to
        // `isDark ? ThemeMode.dark : ThemeMode.light` once every screen
        // uses C.of(context) instead of AppColors.
        themeMode: ThemeMode.light,
        home: const AppShell(),
      ),
    );
  }
}