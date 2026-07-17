// ============================================================
//  lib/screens/portfolio.dart  —  Portfolio tab (REAL backend).
//  Goes in:  hissa_mobile/lib/screens/portfolio.dart   (replace all)
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/investment_service.dart';
import '../services/marketplace_service.dart';
import 'detail.dart';
import 'sell.dart';

class PortfolioTab extends StatefulWidget {
  const PortfolioTab({super.key});
  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  List<PortfolioHolding> holdings = [];
  List<Listing> listings = [];
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
      final h = await investmentService.getPortfolio();
      List<Listing> ls = [];
      try { ls = await marketplaceService.getMyListings(); } catch (_) {}
      if (!mounted) return;
      setState(() { holdings = h; listings = ls; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = 'Could not load portfolio. Are you logged in?'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: CircularProgressIndicator(color: AppColors.brand)));
    }
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 36),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ));
    }

    final invested = holdings.fold<double>(0, (s, h) => s + h.invested);
    final value = holdings.fold<double>(0, (s, h) => s + h.value);
    final income = holdings.fold<double>(0, (s, h) => s + h.monthlyIncome);
    final gain = value - invested;
    final gainPct = invested == 0 ? 0.0 : (gain / invested) * 100;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brand,
      child: ListView(padding: EdgeInsets.zero, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text('Portfolio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        ),

        // summary card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.32), blurRadius: 28, offset: const Offset(0, 14))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PORTFOLIO VALUE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Text(pkr(value), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(gain >= 0 ? Icons.trending_up : Icons.trending_down, color: gain >= 0 ? AppColors.goldSoft : Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('${gain >= 0 ? '+' : ''}${pkr(gain)}  (${gainPct.toStringAsFixed(1)}%)',
                  style: TextStyle(color: gain >= 0 ? AppColors.goldSoft : Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 18),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(children: [
              _stat(pkr(invested), 'Invested'),
              _stat('${holdings.length}', holdings.length == 1 ? 'Property' : 'Properties'),
              _stat(pkr(income), 'Monthly'),
            ]),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text('Your holdings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),

        if (holdings.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 30),
            child: Column(children: [
              Icon(Icons.pie_chart_outline, size: 40, color: AppColors.muted),
              SizedBox(height: 12),
              Text('No investments yet', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Browse properties and buy your first shares.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
          )
        else
          ...holdings.map(_holdingCard),

        if (listings.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text('Your listings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          ...listings.map(_listingRow),
        ],

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _listingRow(Listing l) {
    final prop = holdings.where((h) => h.property.id == l.propertyId).firstOrNull?.property;
    final name = prop?.title ?? 'Property';
    final color = switch (l.status) {
      ListingStatus.open => AppColors.accent,
      ListingStatus.sold => AppColors.positive,
      _ => AppColors.muted,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.brand)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${grp(l.shares)} ${l.shares == 1 ? 'share' : 'shares'} · ${pkr(l.pricePerShare)} each', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
            child: Text(l.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
          if (l.isOpen) ...[
            const SizedBox(height: 2),
            TextButton(
              onPressed: () => _cancel(l),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppColors.negative, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ]),
    );
  }

  Future<void> _cancel(Listing l) async {
    try {
      await marketplaceService.cancelListing(l.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not cancel the listing.')));
      }
    }
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]),
  );

  Widget _holdingCard(PortfolioHolding h) {
    final p = h.property;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(p: p))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.images[0], width: 58, height: 58, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 58, height: 58, color: AppColors.imgBg)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${grp(h.shares)} ${h.shares == 1 ? 'share' : 'shares'} · ${p.city}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(pkr(h.value), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${h.gain >= 0 ? '+' : ''}${h.gainPct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: h.gain >= 0 ? AppColors.positive : AppColors.negative)),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _mini('Invested', pkr(h.invested)),
            const SizedBox(width: 8),
            _mini('Monthly', pkr(h.monthlyIncome)),
            const SizedBox(width: 8),
            _mini('Yield', '${p.expectedYield}%'),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final listed = await Navigator.push(context, MaterialPageRoute(builder: (_) => SellScreen(holding: h)));
                if (listed == true) _load(); // refresh listings
              },
              icon: const Icon(Icons.storefront_outlined, size: 17),
              label: const Text('Sell shares', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _mini(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}