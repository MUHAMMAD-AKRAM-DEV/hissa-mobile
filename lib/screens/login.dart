// ============================================================
//  lib/screens/login.dart  —  Login flow (method -> phone/email
//  -> OTP -> done).  Goes in: hissa_mobile/lib/screens/login.dart  (new)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/auth_service.dart';

enum _Step { method, phone, email, otp, profile, done }

class LoginFlow extends StatefulWidget {
  final VoidCallback onBack; // back to splash
  final VoidCallback onDone; // proceed to KYC
  final VoidCallback onSkip; // skip to app
  const LoginFlow({super.key, required this.onBack, required this.onDone, required this.onSkip});

  @override
  State<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends State<LoginFlow> {
  _Step step = _Step.method;
  final phone = TextEditingController();
  final email = TextEditingController();
  final name = TextEditingController();
  final otp = List.generate(6, (_) => TextEditingController());
  final otpNodes = List.generate(6, (_) => FocusNode());
  String contact = '';
  int seconds = 0;
  Timer? timer;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    email.dispose();
    name.dispose();
    for (final c in otp) c.dispose();
    for (final n in otpNodes) n.dispose();
    timer?.cancel();
    super.dispose();
  }

  void startResend() {
    setState(() => seconds = 30);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds <= 1) {
        t.cancel();
        setState(() => seconds = 0);
      } else {
        setState(() => seconds--);
      }
    });
  }

  Future<void> sendCode(String c, String rawPhone) async {
    setState(() { busy = true; error = null; });
    try {
      await authService.requestOtp(rawPhone);
      for (final x in otp) x.clear();
      setState(() { contact = c; step = _Step.otp; busy = false; });
      startResend();
      WidgetsBinding.instance.addPostFrameCallback((_) => otpNodes[0].requestFocus());
    } catch (e) {
      setState(() { busy = false; error = 'Could not send code. Is the server running?'; });
    }
  }

  Future<void> verify() async {
    setState(() { busy = true; error = null; });
    try {
      final code = otp.map((c) => c.text).join();
      final ok = await authService.verifyOtp(phoneRaw, code);
      if (ok) {
        final isNew = authService.currentUser?.isNew ?? true;
        setState(() { busy = false; step = isNew ? _Step.profile : _Step.done; });
      } else {
        setState(() { busy = false; error = 'Invalid code. Check the backend terminal for the OTP.'; });
      }
    } catch (e) {
      setState(() { busy = false; error = 'Verification failed. Try again.'; });
    }
  }

  String phoneRaw = '';

  Future<void> saveProfile() async {
    setState(() { busy = true; error = null; });
    try {
      await authService.updateProfile(name.text);
      setState(() { busy = false; step = _Step.done; });
    } catch (e) {
      setState(() { busy = false; error = 'Could not save. Try again.'; });
    }
  }

  bool get otpComplete => otp.every((c) => c.text.isNotEmpty);
  bool get phoneValid => phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;
  bool get emailValid => RegExp(r'^\S+@\S+\.\S+$').hasMatch(email.text);
  String get prettyPhone => '+92 ${phone.text}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    switch (step) {
      case _Step.method: return _method();
      case _Step.phone: return _phone();
      case _Step.email: return _email();
      case _Step.otp: return _otp();
      case _Step.profile: return _profile();
      case _Step.done: return _done();
    }
  }

  // ---------- reusable bits ----------
  Widget _topBar(VoidCallback onBack) => Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
  );

  Widget _subtitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Text(t, style: const TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.5)),
  );

  Widget _primary(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB8C2BE),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );

  Widget _outline(Widget child, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: child,
    ),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
  );

  // ---------- METHOD ----------
  // These sign-in methods aren't supported by the backend yet.
  void _soon(String provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.schedule, color: AppColors.brand)),
          const SizedBox(height: 14),
          Text('$provider sign-in coming soon', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('For now, sign in with your phone number — you’ll get a one-time code by SMS.',
              style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); setState(() => step = _Step.phone); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Continue with phone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  Widget _method() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(widget.onBack),
        const SizedBox(height: 4),
        Center(
          child: Column(children: [
            Container(
              width: 74, height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Container(width: 26, height: 26, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8))),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Welcome to Hissa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Sign in or create an account to start investing in property.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 26),
        _primary('Continue with phone', () => setState(() => step = _Step.phone)),
        const SizedBox(height: 18),
        Row(children: const [
          Expanded(child: Divider(color: AppColors.line)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or continue with', style: TextStyle(color: AppColors.muted, fontSize: 12.5))),
          Expanded(child: Divider(color: AppColors.line)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _outline(const _IconLabel(icon: Icons.g_mobiledata, label: 'Google', size: 26), () => _soon('Google'))),
          const SizedBox(width: 12),
          Expanded(child: _outline(const _IconLabel(icon: Icons.apple, label: 'Apple'), () => _soon('Apple'))),
        ]),
        const SizedBox(height: 12),
        _outline(const _IconLabel(icon: Icons.mail_outline, label: 'Continue with email'), () => _soon('Email')),
        const Spacer(),
        const Center(child: Text('By continuing you agree to Hissa’s Terms & Privacy Policy.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.muted))),
      ],
    );
  }

  // ---------- PHONE ----------
  Widget _phone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(() => setState(() => step = _Step.method)),
        _title('Enter your phone number'),
        _subtitle('We’ll text you a one-time code to confirm it’s really you.'),
        const Text('Phone number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: 1.5), borderRadius: BorderRadius.circular(14)),
            child: const Text('🇵🇰 +92', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              onChanged: (_) => setState(() {}),
              decoration: _dec('3XX XXXXXXX'),
            ),
          ),
        ]),
        const Spacer(),
        _primary(busy ? 'Sending…' : 'Send code', (phoneValid && !busy) ? () { phoneRaw = phone.text.trim(); sendCode(prettyPhone, phone.text.trim()); } : null),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13))),
      ],
    );
  }

  // ---------- EMAIL ----------
  Widget _email() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(() => setState(() => step = _Step.method)),
        _title('Continue with email'),
        _subtitle('We’ll email you a one-time code to sign in.'),
        const Text('Email address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          decoration: _dec('you@example.com'),
        ),
        const Spacer(),
        _primary(busy ? 'Sending…' : 'Send code', (emailValid && !busy) ? () { phoneRaw = email.text.trim(); sendCode(email.text, email.text.trim()); } : null),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13))),
      ],
    );
  }

  // ---------- OTP ----------
  Widget _otp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(() => setState(() => step = _Step.method)),
        _title('Enter the code'),
        _subtitle('We sent a 6-digit code to $contact.'),
        Row(
          children: List.generate(6, (i) {
            // Expanded so the 6 boxes always fit any screen width.
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 5 ? 0 : 7),
                child: SizedBox(
                  height: 58,
                  child: TextField(
                    controller: otp[i],
                    focusNode: otpNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) otpNodes[i + 1].requestFocus();
                      if (v.isEmpty && i > 0) otpNodes[i - 1].requestFocus();
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Center(
          child: seconds > 0
              ? Text('Resend code in 0:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.muted, fontSize: 14))
              : TextButton(onPressed: startResend, child: const Text('Resend code', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700))),
        ),
        const Spacer(),
        _primary(busy ? 'Verifying…' : 'Verify', (otpComplete && !busy) ? verify : null),
        const SizedBox(height: 10),
        Center(child: Text(error ?? 'Check the backend terminal for your code.', style: TextStyle(fontSize: 12.5, color: error != null ? AppColors.negative : AppColors.muted))),
      ],
    );
  }

  // ---------- PROFILE ----------
  Widget _profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Complete your profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text('What should we call you? This name appears on your account and share certificates.', style: TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.5)),
        const SizedBox(height: 24),
        const Text('Full name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: _dec('e.g. Muhammad Akram'),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13))),
        const Spacer(),
        _primary(busy ? 'Saving…' : 'Continue', (name.text.trim().isNotEmpty && !busy) ? saveProfile : null),
      ],
    );
  }

  // ---------- DONE ----------
  Widget _done() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 88, height: 88,
          decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 24),
        const Text('You’re in 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Your account is ready.', style: TextStyle(fontSize: 14.5, color: AppColors.muted)),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.goldSoft, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('2', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6A4A08)))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Next: verify your identity (KYC)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 2),
                Text('Required once before your first investment.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ]),
            ),
          ]),
        ),
        const Spacer(),
        _primary('Continue', widget.onDone),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(onPressed: widget.onSkip, child: const Text('Skip for now', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600))),
        ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  const _IconLabel({required this.icon, required this.label, this.size = 20});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: size, color: AppColors.ink),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}