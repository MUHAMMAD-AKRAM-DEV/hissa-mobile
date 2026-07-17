// ============================================================
//  lib/screens/wallet.dart  —  Wallet tab (REAL backend).
//  Goes in:  hissa_mobile/lib/screens/wallet.dart   (replace all)
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/wallet_service.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});
  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  double balance = 0;
  List<WalletTxn> txns = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final b = await walletService.getBalance();
      final t = await walletService.getTransactions();
      if (!mounted) return;
      setState(() { balance = b; txns = t; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = 'Could not load wallet. Is the server running?'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    if (loading) {
      return Center(child: Padding(padding: EdgeInsets.only(top: 80), child: CircularProgressIndicator(color: c.brand)));
    }
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: c.negative, size: 36),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: c.brand,
      child: ListView(padding: EdgeInsets.zero, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text('Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),

        // balance card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.brand, c.brandDeep]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.32), blurRadius: 28, offset: const Offset(0, 14))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Text(money(balance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _action('Deposit', Icons.add, () => _sheet(true))),
              const SizedBox(width: 10),
              Expanded(child: _action('Withdraw', Icons.arrow_outward, () => _sheet(false))),
            ]),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text('Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),

        if (txns.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
            child: Column(children: [
              Icon(Icons.receipt_long_outlined, size: 40, color: c.muted),
              SizedBox(height: 12),
              Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Deposit funds to get started.', style: TextStyle(fontSize: 13, color: c.muted)),
            ]),
          )
        else
          ...txns.map(_txnRow),

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _action(String label, IconData ic, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(ic, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );

  Widget _txnRow(WalletTxn t) {
    final c = C.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: c.tile, borderRadius: BorderRadius.circular(12)),
          child: Icon(t.isCredit ? Icons.south_west : Icons.north_east, size: 18, color: t.isCredit ? c.positive : c.ink),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.description.isEmpty ? (t.isCredit ? 'Deposit' : 'Withdrawal') : t.description,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(t.dateLabel, style: TextStyle(fontSize: 12, color: c.muted)),
        ])),
        Text('${t.isCredit ? '+' : '−'}${money(t.amountPkr)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.isCredit ? c.positive : c.ink)),
      ]),
    );
  }

  // deposit / withdraw sheet
  void _sheet(bool isDeposit) {
    final c = C.of(context);
    final amount = TextEditingController();
    bool busy = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, MediaQuery.of(ctx).viewInsets.bottom + 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 16),
            Text(isDeposit ? 'Deposit funds' : 'Withdraw funds', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(isDeposit ? 'Test deposit — no real payment is taken yet.' : 'Available: ${money(balance)}',
                style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 18),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setSheet(() {}),
              decoration: InputDecoration(
                prefixText: 'PKR  ',
                hintText: '10000',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.brand, width: 1.5)),
              ),
            ),
            if (sheetError != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(sheetError!, style: TextStyle(color: c.negative, fontSize: 13))),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : () async {
                  final v = double.tryParse(amount.text.trim()) ?? 0;
                  if (v <= 0) { setSheet(() => sheetError = 'Enter an amount.'); return; }
                  if (!isDeposit && v > balance) { setSheet(() => sheetError = 'Not enough balance.'); return; }
                  setSheet(() { busy = true; sheetError = null; });
                  try {
                    if (isDeposit) {
                      await walletService.deposit(v);
                    } else {
                      await walletService.withdraw(v);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load(); // refresh balance + transactions from the server
                  } catch (e) {
                    final msg = e.toString();
                    setSheet(() {
                      busy = false;
                      sheetError = msg.contains('Insufficient') ? 'Insufficient wallet balance.' : 'Failed. Try again.';
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.btn, foregroundColor: c.onBtn,
                  disabledBackgroundColor: const Color(0xFFB8C2BE), elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(busy ? 'Please wait…' : (isDeposit ? 'Deposit' : 'Withdraw'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}