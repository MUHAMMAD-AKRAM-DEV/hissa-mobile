// ============================================================
//  lib/screens/settings.dart  —  Settings tab + sub-pages.
//  Goes in:  hissa_mobile/lib/screens/settings.dart   (new file)
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/property.dart';
import '../store.dart';
import '../services/auth_service.dart';
import '../services/kyc_service.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsTab({super.key, required this.onLogout});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool notif = true;
  bool bio = false;
  KycStatus? kyc;

  @override
  void initState() {
    super.initState();
    kycService.getStatus().then((v) { if (mounted) setState(() => kyc = v); });
  }

  String get _displayName => (authService.currentUser?.fullName?.trim().isNotEmpty ?? false) ? authService.currentUser!.fullName! : 'Your account';
  String get _displayPhone => authService.currentUser?.phoneNumber ?? '';
  String get _avatarLetter => _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'H';

  void _push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));

  @override
  Widget build(BuildContext context) {
    final invested = store.holdings.fold<int>(0, (s, h) => s + h.invested);
    final count = store.holdings.length;

    return ListView(padding: EdgeInsets.zero, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4))),

      // profile card
      GestureDetector(
        onTap: () => _push(const _PersonalScreen()),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Container(width: 58, height: 58, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]), shape: BoxShape.circle),
                child: Center(child: Text(_avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(_displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                const SizedBox(width: 6),
                Icon(
                  kyc?.state == KycState.approved ? Icons.verified : Icons.verified_outlined,
                  size: 16,
                  color: kyc?.state == KycState.approved ? AppColors.positive : AppColors.muted,
                ),
              ]),
              const SizedBox(height: 2),
              Text(_displayPhone, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),

      // portfolio stat strip
      Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          _stat(pkrShort(invested), 'Invested'),
          _stat('$count', 'Properties'),
          _stat('2026', 'Member since'),
        ]),
      ),

      _group('Account', [
        _row(Icons.person_outline, 'Personal details', () => _push(const _PersonalScreen())),
        _row(Icons.account_balance_outlined, 'Bank accounts', _soon, val: '1 linked'),
        _row(Icons.verified_user_outlined, 'Verification', _soon, val: 'Verified'),
      ]),
      _group('Security', [
        _row(Icons.lock_outline, 'Change PIN', _soon),
        _toggle(Icons.fingerprint, 'Biometric unlock', bio, (v) => setState(() => bio = v)),
      ]),
      _group('Preferences', [
        _toggle(Icons.notifications_none, 'Notifications', notif, (v) => setState(() => notif = v)),
        _row(Icons.language, 'Language', _soon, val: 'English'),
      ]),
      _group('Support', [
        _row(Icons.headset_mic_outlined, 'Help center', () => _push(const _HelpScreen())),
        _row(Icons.description_outlined, 'Terms & privacy', () => _push(const _AboutScreen(terms: true))),
        _row(Icons.info_outline, 'About Hissa', () => _push(const _AboutScreen(terms: false)), val: 'v1.0.0'),
      ]),
      _group(null, [
        _row(Icons.logout, 'Log out', () async { await authService.logout(); kycService.clear(); widget.onLogout(); }, danger: true),
      ]),

      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Text('Hissa · Made in Pakistan 🇵🇰', style: TextStyle(fontSize: 12, color: AppColors.muted)))),
      const SizedBox(height: 12),
    ]);
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accent)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ]),
  );

  Widget _group(String? label, List<Widget> rows) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 8), child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.6))),
      Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            rows[i],
          ],
        ]),
      ),
    ]),
  );

  Widget _row(IconData ic, String label, VoidCallback onTap, {String? val, bool danger = false}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: danger ? const Color(0xFFFDECEC) : AppColors.tile, borderRadius: BorderRadius.circular(10)), child: Icon(ic, size: 18, color: danger ? AppColors.negative : AppColors.brand)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, fontWeight: danger ? FontWeight.w600 : FontWeight.w400, color: danger ? AppColors.negative : AppColors.ink))),
        if (val != null) Text(val, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        if (!danger) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.chevron_right, size: 18, color: AppColors.muted)),
      ]),
    ),
  );

  Widget _toggle(IconData ic, String label, bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(10)), child: Icon(ic, size: 18, color: AppColors.brand)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14.5))),
      Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.brand, activeColor: Colors.white),
    ]),
  );
}

// ---------- sub-pages ----------
class _PersonalScreen extends StatelessWidget {
  const _PersonalScreen();
  @override
  Widget build(BuildContext context) {
    Widget field(String label, String value, {bool enabled = true}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 6), child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted))),
      TextField(
        controller: TextEditingController(text: value),
        enabled: enabled,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        ),
      ),
    ]);
    return Scaffold(
      appBar: AppBar(title: const Text('Personal details')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        field('Full name', authService.currentUser?.fullName ?? ''),
        field('Email', 'akram@example.com'),
        field('Phone', authService.currentUser?.phoneNumber ?? '', enabled: false),
        field('CNIC', '35202-1234567-1', enabled: false),
        field('Address', 'House 12, DHA Phase 6, Karachi'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved'))); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Save changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();
  @override
  Widget build(BuildContext context) {
    const faqs = [
      ['How do I earn returns?', 'You receive your share of the property\'s rent every month, paid into your Hissa wallet automatically.'],
      ['Can I sell my shares?', 'Yes — list them on the secondary marketplace from your Portfolio. Listings clear during bi-annual exit windows.'],
      ['Is Hissa Shariah-compliant?', 'Yes. Every property is structured to be Shariah-compliant, with no interest (riba).'],
      ['How is my investment protected?', 'Each property is held in its own SECP-registered SPV, and you receive share certificates for your ownership.'],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help center')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final f in faqs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(f[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [Text(f[1], style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.55))],
            ),
          ),
      ]),
    );
  }
}

class _AboutScreen extends StatelessWidget {
  final bool terms;
  const _AboutScreen({required this.terms});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(terms ? 'Terms & privacy' : 'About Hissa')),
      body: ListView(padding: const EdgeInsets.all(20), children: terms
          ? const [
        Text('By using Hissa you agree to invest through property SPVs registered with the SECP. Real estate values can fall and rental income isn\'t guaranteed. Shares may be illiquid until an exit window.', style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5B56), height: 1.6)),
        SizedBox(height: 14),
        Text('We collect your CNIC, selfie, and contact details solely to verify your identity and comply with regulations. Your data is encrypted and never sold.', style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5B56), height: 1.6)),
        SizedBox(height: 14),
        Text('This app is a design prototype. Figures shown are illustrative and not investment advice.', style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5B56), height: 1.6)),
      ]
          : const [
        Center(child: Text('Hissa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
        Center(child: Text('Version 1.0.0', style: TextStyle(color: AppColors.muted))),
        SizedBox(height: 18),
        Text('Hissa lets anyone in Pakistan own a share of vetted real estate from as little as PKR 5,000, earn monthly rental income, and exit through a secondary marketplace — all Shariah-compliant.', style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5B56), height: 1.6)),
      ]),
    );
  }
}