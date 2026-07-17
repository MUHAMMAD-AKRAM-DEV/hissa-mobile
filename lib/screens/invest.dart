// ============================================================
//  lib/screens/invest.dart  —  Buy-shares flow.
//  Goes in:  hissa_mobile/lib/screens/invest.dart   (new file)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/investment_service.dart';
import '../services/wallet_service.dart';

enum _Step { amount, review, pay, success }

class InvestScreen extends StatefulWidget {
  final Property p;
  const InvestScreen({super.key, required this.p});
  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  _Step step = _Step.amount;
  int shares = 1;
  String method = 'wallet';
  bool busy = false;
  String? payError;
  double walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await walletService.getBalance();
      if (mounted) setState(() => walletBalance = b);
    } catch (_) {}
  }

  Property get p => widget.p;
  int get subtotal => shares * p.sharePrice;
  int get fee => (subtotal * (p.fees['acquisition']! / 100)).round();
  int get total => subtotal + fee;
  double get ownPct => (shares / p.totalShares) * 100;
  int get monthly => (subtotal * (p.expectedYield / 100) / 12).round();

  String get firstPayout {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month + 1);
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[d.month - 1]} ${d.year}';
  }

  void setShares(int n) => setState(() => shares = n.clamp(1, p.sharesLeft));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          if (step != _Step.success) _topBar(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _content())),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: _footer()),
        ]),
      ),
    );
  }

  Widget _topBar() => Row(children: [
    IconButton(
      onPressed: () {
        if (step == _Step.amount) { Navigator.pop(context); }
        else if (step == _Step.review) { setState(() => step = _Step.amount); }
        else if (step == _Step.pay) { setState(() => step = _Step.review); }
      },
      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
    ),
    Text(step == _Step.amount ? 'Invest' : step == _Step.review ? 'Review order' : 'Payment',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
  ]);

  Widget _content() {
    switch (step) {
      case _Step.amount: return _amount();
      case _Step.review: return _review();
      case _Step.pay: return _pay();
      case _Step.success: return _success();
    }
  }

  Widget _propCard() => Container(
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p.images[0], width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: AppColors.imgBg))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text('${pkr(p.sharePrice)}/share · ${p.expectedYield}% yield', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ])),
    ]),
  );

  // ---------- amount ----------
  Widget _amount() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _propCard(),
      const Text('How many shares?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: 1.5), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _stepBtn(Icons.remove, shares > 1 ? () => setShares(shares - 1) : null),
          Column(children: [
            Text('$shares', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('of ${grp(p.sharesLeft)} left', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
          _stepBtn(Icons.add, shares < p.sharesLeft ? () => setShares(shares + 1) : null),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _chip('₨25k', () => setShares((25000 / p.sharePrice).round())),
        _chip('₨50k', () => setShares((50000 / p.sharePrice).round())),
        _chip('₨100k', () => setShares((100000 / p.sharePrice).round())),
        _chip('Max', () => setShares(p.sharesLeft)),
      ]),
      const SizedBox(height: 22),
      _note([
        ['Investment', pkr(subtotal), false],
        ['You’ll own', '${ownPct.toStringAsFixed(2)}% of property', false],
        ['Est. monthly income', pkr(monthly), true],
      ]),
    ]);
  }

  // ---------- review ----------
  Widget _review() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _propCard(),
      _order([
        ['$shares share${shares > 1 ? 's' : ''} × ${pkr(p.sharePrice)}', pkr(subtotal), false],
        ['Acquisition fee (${p.fees['acquisition']}%)', pkr(fee), false],
        ['Total payable', pkr(total), true],
      ]),
      _note([
        ['You’ll own', '${ownPct.toStringAsFixed(2)}% of property', false],
        ['Est. monthly income', pkr(monthly), true],
        ['First payout', firstPayout, false],
      ]),
      const SizedBox(height: 14),
      const Text('By continuing you agree to the subscription agreement for this property’s SPV.',
          style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
    ]);
  }

  // ---------- pay ----------
  Widget _pay() {
    final methods = [
      ['wallet', 'Hissa Wallet', 'Balance: ${pkr(walletBalance)}', Icons.account_balance_wallet_outlined],
      ['bank', 'Bank transfer', 'Coming soon', Icons.account_balance_outlined],
      ['card', 'Debit / Credit card', 'Coming soon', Icons.credit_card],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _propCard(),
      const Text('Pay with', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 10),
      ...methods.map((m) {
        final on = method == m[0];
        return GestureDetector(
          onTap: () => setState(() => method = m[0] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: on ? AppColors.tint : Colors.white,
              border: Border.all(color: on ? AppColors.brand : AppColors.line, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(11)), child: Icon(m[3] as IconData, size: 20, color: AppColors.brand)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m[1] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(m[2] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ])),
              Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? AppColors.brand : AppColors.line, width: 2)),
                  child: on ? const Center(child: CircleAvatar(radius: 5.5, backgroundColor: AppColors.brand)) : null),
            ]),
          ),
        );
      }),
      const SizedBox(height: 6),
      _order([['Total payable', pkr(total), true]]),
      if (payError != null) Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEA),
            border: Border.all(color: const Color(0xFFF5C6C0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.negative, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(payError!, style: const TextStyle(color: AppColors.negative, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    ]);
  }

  // ---------- success ----------
  Widget _success() {
    return Column(children: [
      const SizedBox(height: 30),
      Container(width: 88, height: 88, decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 44)),
      const SizedBox(height: 24),
      const Text('Investment confirmed 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('You now own $shares share${shares > 1 ? 's' : ''} — ${ownPct.toStringAsFixed(2)}% of ${p.title}.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.5)),
      const SizedBox(height: 24),
      _order([
        ['Amount paid', pkr(total), false],
        ['Shares owned', '$shares', false],
        ['Est. monthly income', pkr(monthly), false],
        ['First payout', firstPayout, true],
      ]),
    ]);
  }

  // ---------- footer ----------
  // Buy shares on the real backend.
  Future<void> _buy() async {
    setState(() { busy = true; payError = null; });
    try {
      await investmentService.invest(p.id, shares);
      if (!mounted) return;
      setState(() { busy = false; step = _Step.success; });
    } catch (e) {
      if (!mounted) return;
      // surface the backend's own message (e.g. "Insufficient wallet balance")
      final msg = e.toString();
      String friendly = 'Payment failed. Try again.';
      if (msg.contains('Insufficient')) friendly = 'Not enough wallet balance. Add funds first.';
      else if (msg.contains('remaining')) friendly = 'Not enough shares remaining.';
      else if (msg.contains('401')) friendly = 'Please log in again.';
      setState(() { busy = false; payError = friendly; });
    }
  }

  Widget _footer() {
    switch (step) {
      case _Step.amount: return _primary('Continue', () => setState(() => step = _Step.review));
      case _Step.review: return _primary('Continue to payment', () => setState(() => step = _Step.pay));
      case _Step.pay: return _primary(busy ? 'Processing…' : 'Pay ${pkr(total)}', busy ? null : _buy);
      case _Step.success: return _primary('Done', () => Navigator.pop(context));
    }
  }

  // ---------- bits ----------
  Widget _stepBtn(IconData ic, VoidCallback? onTap) => Material(
    color: AppColors.field,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(width: 46, height: 46, child: Icon(ic, color: onTap == null ? AppColors.muted : AppColors.ink)),
    ),
  );

  Widget _chip(String label, VoidCallback onTap) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    ),
  );

  Widget _note(List<List<dynamic>> rows) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      for (int i = 0; i < rows.length; i++)
        Container(
          decoration: BoxDecoration(border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.line)) : null),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(rows[i][0] as String, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            Text(rows[i][1] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: (rows[i][2] as bool) ? AppColors.brand : AppColors.ink)),
          ]),
        ),
    ]),
  );

  Widget _order(List<List<dynamic>> rows) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      for (int i = 0; i < rows.length; i++)
        Container(
          decoration: BoxDecoration(border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.line)) : null),
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(rows[i][0] as String, style: TextStyle(color: (rows[i][2] as bool) ? AppColors.ink : AppColors.muted, fontSize: 14, fontWeight: (rows[i][2] as bool) ? FontWeight.w700 : FontWeight.w400)),
            Text(rows[i][1] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: (rows[i][2] as bool) ? 18 : 14)),
          ]),
        ),
    ]),
  );

  Widget _primary(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFB8C2BE), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );
}