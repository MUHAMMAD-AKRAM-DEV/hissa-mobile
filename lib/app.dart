// ============================================================
//  lib/app.dart  —  App shell / traffic-cop (auth -> kyc -> main)
//  Goes in:  hissa_mobile/lib/app.dart   (replace all)
// ============================================================

import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/kyc.dart';
import 'services/auth_service.dart';
import 'services/kyc_service.dart';

enum AppView { splash, login, kyc, main }

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppView view = AppView.splash;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  // If a saved session exists, skip login and go straight to the app.
  Future<void> _restore() async {
    final ok = await authService.restoreSession();
    if (ok && mounted) setState(() => view = AppView.main);
  }

  // After login: only show KYC if they actually still need to do it.
  Future<void> _afterLogin() async {
    kycService.clear(); // this may be a different user than last time
    final status = await kycService.getStatus(refresh: true);
    if (!mounted) return;
    // approved or already under review -> straight into the app
    final done = status.state == KycState.approved || status.state == KycState.pending;
    setState(() => view = done ? AppView.main : AppView.kyc);
  }

  void go(AppView v) => setState(() => view = v);

  @override
  Widget build(BuildContext context) {
    switch (view) {
      case AppView.splash:
        return SplashScreen(onStart: () => go(AppView.login));
      case AppView.login:
        return LoginFlow(
          onBack: () => go(AppView.splash),
          onDone: _afterLogin,
          onSkip: () => go(AppView.main),
        );
      case AppView.kyc:
        return KycScreen(
          onBack: () => go(AppView.main),
          onDone: () { kycService.clear(); go(AppView.main); },
          onSkip: () => go(AppView.main),
        );
      case AppView.main:
        return HomeScreen(onLogout: () { kycService.clear(); go(AppView.splash); });
    }
  }
}