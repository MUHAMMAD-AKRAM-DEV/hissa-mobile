// ============================================================
//  lib/screens/kyc.dart  —  Identity verification (REAL upload).
//  Goes in:  hissa_mobile/lib/screens/kyc.dart   (replace all)
//
//  Requires:  flutter pub add image_picker
//  Matches the backend: POST /kyc/submit (multipart)
//    fields: cnicNumber, fullNameOnCnic
//    files : cnicImage, selfieImage
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/kyc_service.dart';

class _Pick {
  final Uint8List bytes;
  final String name;
  _Pick(this.bytes, this.name);
}

class KycScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDone;
  final VoidCallback onSkip;
  const KycScreen({super.key, required this.onBack, required this.onDone, required this.onSkip});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  int step = 0; // 0 intro · 1 details · 2 cnic · 3 selfie · 4 review · 5 done
  final cnic = TextEditingController();
  final legalName = TextEditingController();
  _Pick? cnicImage;
  _Pick? selfieImage;
  bool busy = false;
  String? error;

  final _picker = ImagePicker();

  @override
  void dispose() { cnic.dispose(); legalName.dispose(); super.dispose(); }

  bool get detailsOk => cnic.text.trim().length >= 13 && legalName.text.trim().isNotEmpty;

  Future<void> _pick(ImageSource source, bool isSelfie) async {
    try {
      final x = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        if (isSelfie) {
          selfieImage = _Pick(bytes, x.name);
        } else {
          cnicImage = _Pick(bytes, x.name);
        }
      });
    } catch (e) {
      setState(() => error = 'Could not open the image. Try again.');
    }
  }

  // Ask camera vs gallery (camera isn't available on all platforms/browsers).
  void _chooseSource(bool isSelfie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 10),
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_camera_outlined, color: AppColors.brand, size: 20)),
            title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); _pick(ImageSource.camera, isSelfie); },
          ),
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, color: AppColors.brand, size: 20)),
            title: const Text('Upload from device', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(ctx); _pick(ImageSource.gallery, isSelfie); },
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { busy = true; error = null; });
    try {
      await kycService.submit(
        cnicNumber: cnic.text,
        fullNameOnCnic: legalName.text,
        cnicBytes: cnicImage!.bytes,
        cnicFilename: cnicImage!.name,
        selfieBytes: selfieImage!.bytes,
        selfieFilename: selfieImage!.name,
      );
      if (!mounted) return;
      setState(() { busy = false; step = 5; });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        busy = false;
        error = msg.contains('401') ? 'Please log in again.' : 'Submission failed. Please try again.';
      });
    }
  }

  void _back() => step == 0 ? widget.onBack() : setState(() => step--);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
            child: Row(children: [
              IconButton(onPressed: busy ? null : _back, icon: const Icon(Icons.arrow_back, color: AppColors.ink)),
              Expanded(
                child: (step >= 1 && step <= 4)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(value: step / 4, minHeight: 6, backgroundColor: AppColors.line, color: AppColors.brand),
                )
                    : const SizedBox(),
              ),
              const SizedBox(width: 12),
              if (step >= 1 && step <= 4) Text('$step/4', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 8), child: _content())),
          Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 20), child: _footer()),
        ]),
      ),
    );
  }

  Widget _content() {
    switch (step) {
      case 0: return _intro();
      case 1: return _details();
      case 2: return _upload('Photo of your CNIC', 'Capture or upload the front of your ID card. Make sure all text is readable.', Icons.credit_card, cnicImage, () => _chooseSource(false));
      case 3: return _upload('Take a selfie', 'Your face should be clearly visible and well lit.', Icons.face_outlined, selfieImage, () => _chooseSource(true));
      case 4: return _review();
      default: return _done();
    }
  }

  Widget _intro() {
    Widget bullet(IconData ic, String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: AppColors.brand, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 14.5, height: 1.4))),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Center(child: Container(width: 84, height: 84, decoration: const BoxDecoration(color: AppColors.tile, shape: BoxShape.circle), child: const Icon(Icons.verified_user_outlined, color: AppColors.brand, size: 40))),
      const SizedBox(height: 22),
      const Text('Verify your identity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 8),
      const Text('A one-time check required by regulation before your first investment. Takes about 2 minutes.', style: TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.5)),
      const SizedBox(height: 22),
      bullet(Icons.badge_outlined, 'Your CNIC number and name as printed'),
      bullet(Icons.credit_card, 'A photo of your CNIC'),
      bullet(Icons.face_outlined, 'A quick selfie'),
    ]);
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: AppColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
  );

  Widget _details() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    const Text('Your CNIC details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
    const SizedBox(height: 8),
    const Text('Enter these exactly as they appear on your card.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
    const SizedBox(height: 22),
    const Text('CNIC number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
    const SizedBox(height: 8),
    TextField(controller: cnic, keyboardType: TextInputType.text, onChanged: (_) => setState(() {}), decoration: _dec('42101-1234567-1')),
    const SizedBox(height: 16),
    const Text('Full name on CNIC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
    const SizedBox(height: 8),
    TextField(controller: legalName, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: _dec('e.g. Muhammad Akram')),
  ]);

  Widget _upload(String title, String subtitle, IconData icon, _Pick? pick, VoidCallback onTap) {
    final done = pick != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 230,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF9),
            border: Border.all(color: done ? AppColors.brand : AppColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: done
              ? ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(fit: StackFit.expand, children: [
              Image.memory(pick.bytes, fit: BoxFit.cover),
              Positioned(right: 10, top: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              )),
            ]),
          )
              : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: AppColors.tile, shape: BoxShape.circle), child: Icon(icon, color: AppColors.brand, size: 30)),
            const SizedBox(height: 14),
            const Text('Take photo or upload', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('JPG or PNG', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ])),
        ),
      ),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13))),
    ]);
  }

  Widget _review() {
    Widget item(String label, String value, bool ok) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: ok ? AppColors.positive : AppColors.muted, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('Review & submit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      const SizedBox(height: 8),
      const Text('Check everything is right — you can’t edit after submitting.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 22),
      item('CNIC number', cnic.text, cnic.text.trim().isNotEmpty),
      item('Name on CNIC', legalName.text, legalName.text.trim().isNotEmpty),
      item('CNIC photo', cnicImage != null ? 'Attached' : 'Missing', cnicImage != null),
      item('Selfie', selfieImage != null ? 'Attached' : 'Missing', selfieImage != null),
      if (cnicImage != null) ...[
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(cnicImage!.bytes, height: 130, width: double.infinity, fit: BoxFit.cover)),
      ],
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13))),
    ]);
  }

  Widget _done() => Column(children: [
    const SizedBox(height: 40),
    Container(width: 88, height: 88, decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 44)),
    const SizedBox(height: 24),
    const Text('Verification submitted', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text('Our team will review your documents shortly. You can browse properties meanwhile — you’ll be able to invest once approved.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.55)),
    ),
  ]);

  Widget _footer() {
    String label;
    VoidCallback? onTap;
    switch (step) {
      case 0: label = 'Start verification'; onTap = () => setState(() => step = 1); break;
      case 1: label = 'Continue'; onTap = detailsOk ? () => setState(() => step = 2) : null; break;
      case 2: label = 'Continue'; onTap = cnicImage != null ? () => setState(() => step = 3) : null; break;
      case 3: label = 'Continue'; onTap = selfieImage != null ? () => setState(() => step = 4) : null; break;
      case 4:
        label = busy ? 'Submitting…' : 'Submit for review';
        onTap = (!busy && cnicImage != null && selfieImage != null && detailsOk) ? _submit : null;
        break;
      default: label = 'Continue to app'; onTap = widget.onDone;
    }
    return Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFB8C2BE), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      )),
      if (step == 0)
        TextButton(onPressed: widget.onSkip, child: const Text('Skip for now', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600))),
    ]);
  }
}