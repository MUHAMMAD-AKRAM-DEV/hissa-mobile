// ============================================================
//  lib/main.dart  —  App entry point.
//  Goes in:  hissa_mobile/lib/main.dart   (replace ALL contents)
// ============================================================

import 'package:flutter/material.dart';
import 'theme.dart';
import 'app.dart';

void main() => runApp(const HissaApp());

class HissaApp extends StatelessWidget {
  const HissaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hissa',
      debugShowCheckedModeBanner: false,
      theme: buildHissaTheme(),
      home: const AppShell(),
    );
  }
}