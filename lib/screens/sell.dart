// ============================================================
//  lib/screens/sell.dart  —  List shares on the secondary market.
//  Goes in:  hissa_mobile/lib/screens/sell.dart   (replace all)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/investment_service.dart';
import '../services/marketplace_service.dart';

class SellScreen extends StatefulWidget {
  final PortfolioHolding holding;
  const SellScreen({super.key, required this.holding});
  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  int shares = 1;
  late TextEditingController price;
  bool busy = false;
  bool done = false;
  String? error;

  PortfolioHolding get h => widget.holding;
  Property get p => h.property;

  double get unitPrice => double.tryParse(price.text.trim()) ?? 0;
  double get gross => shares * unitPrice;
  double get exitFee => gross * (p.fees['exit']! / 100);
  double get net => gross - exitFee;

  @override
  void initState() {
    super.initState();
    // default to the current share price
    price = TextEditingController(text: p.sharePrice.toString());
  }

  @override
  void dispose() { price.dispose(); super.dispose(); }

  Future<void> _list() async {
    setState(() { busy = true; error = null; });
    try {
      await marketplaceService.createListing(
        propertyId: p.id,
        shares: shares,
        pricePerShare: unitPrice,
      );
      if (!mounted) return;
      setState(() { busy = false; done = true; });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String friendly = 'Could not create the listing. Try again.';
      if (msg.contains('unlisted shares')) friendly = 'You don’t have that many unlisted shares.';
      else if (msg.contains('401')) friendly = 'Please log in again.';
      setState(() { busy = false; error = friendly; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: done ? null : AppBar(title: const Text('Sell shares')),
      body: SafeArea(
        child: done ? _done() : Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _form())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (busy || unitPrice <= 0) ? null : _list,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFB8C2BE), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(busy ? 'Listing…' : 'List for sale', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _form() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // property
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p.images[0], width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 54, height: 54, color: AppColors.imgBg))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('You own ${grp(h.shares)} ${h.shares == 1 ? 'share' : 'shares'}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ])),
        ]),
      ),
      const SizedBox(height: 22),

      // shares
      const Text('Shares to sell', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 10),
      Row(children: [
        _stepBtn(Icons.remove, shares > 1 ? () => setState(() => shares--) : null),
        Expanded(child: Center(child: Text('$shares', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)))),
        _stepBtn(Icons.add, shares < h.shares ? () => setState(() => shares++) : null),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _chip('25%', () => setState(() => shares = (h.shares * 0.25).ceil().clamp(1, h.shares))),
        _chip('50%', () => setState(() => shares = (h.shares * 0.5).ceil().clamp(1, h.shares))),
        _chip('All', () => setState(() => shares = h.shares)),
      ]),
      const SizedBox(height: 22),

      // price
      const Text('Price per share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 8),
      TextField(
        controller: price,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixText: 'PKR  ',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
        ),
      ),
      const SizedBox(height: 6),
      Text('Current platform price: ${pkr(p.sharePrice)} · you can ask more or less',
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 22),

      // summary
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          _row('Sale value', pkr(gross)),
          _row('Exit fee (${p.fees['exit']}%)', '− ${pkr(exitFee)}'),
          const Divider(color: AppColors.line, height: 1),
          _row('You receive', pkr(net), bold: true),
        ]),
      ),
      const SizedBox(height: 14),
      const Text('Your shares stay yours until a buyer takes the listing. You can cancel any time before then.',
          style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
      if (error != null) Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFDECEA), border: Border.all(color: const Color(0xFFF5C6C0)), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.negative, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(error!, style: const TextStyle(color: AppColors.negative, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    ]);
  }

  Widget _done() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 88, height: 88, decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle), child: const Icon(Icons.storefront, color: Colors.white, size: 42)),
      const SizedBox(height: 24),
      const Text('Listed on the marketplace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text('$shares ${shares == 1 ? 'share' : 'shares'} of ${p.title} at ${pkr(unitPrice)} each. You’ll receive ${pkr(net)} after the exit fee when it sells.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: AppColors.muted, height: 1.55)),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      )),
    ]),
  );

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

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13.5, color: bold ? AppColors.ink : AppColors.muted, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      Text(value, style: TextStyle(fontSize: bold ? 15.5 : 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
    ]),
  );
}