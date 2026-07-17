// ============================================================
//  lib/screens/marketplace.dart  —  Browse all shares for sale.
//  Goes in:  hissa_mobile/lib/screens/marketplace.dart  (NEW file)
//
//  Shows every open listing across all properties, so you can
//  buy shares from other investors without hunting property by
//  property. Buying is KYC-gated, same as primary investing.
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/marketplace_service.dart';
import '../services/property_service.dart';
import '../services/auth_service.dart';
import '../services/kyc_service.dart';
import 'detail.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Listing> listings = [];
  Map<String, Property> props = {};
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
      final ls = await marketplaceService.getListings();
      final all = await PropertyService().getProperties();
      if (!mounted) return;
      setState(() {
        listings = ls.where((l) => l.isOpen).toList();
        props = {for (final p in all) p.id: p};
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = 'Could not load the marketplace. Are you logged in?'; });
    }
  }

  Future<void> _buy(Listing l, Property? p) async {
    final c = C.of(context);
    // must be verified to buy, same as primary investing
    final kyc = await kycService.getStatus();
    if (!kyc.canInvest) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kyc.state == KycState.pending
            ? 'Your verification is still under review.'
            : 'Verify your identity before investing.')),
      );
      return;
    }
    if (!mounted) return;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          const Text('Confirm purchase', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('${grp(l.shares)} ${l.shares == 1 ? 'share' : 'shares'} of ${p?.title ?? 'this property'} at ${pkr(l.pricePerShare)} each, from another investor.',
              style: TextStyle(fontSize: 14, color: c.muted, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.tint, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total from your wallet', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text(pkr(l.totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: c.btn, foregroundColor: c.onBtn, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Buy for ${pkr(l.totalPrice)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await marketplaceService.buyListing(l.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shares purchased — check your portfolio.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final friendly = msg.contains('Insufficient')
          ? 'Not enough wallet balance.'
          : msg.contains('no longer available')
          ? 'That listing was just taken.'
          : msg.contains('own listing')
          ? 'You can’t buy your own listing.'
          : 'Purchase failed. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Marketplace')),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.brand))
          : error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: c.negative, size: 36),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ))
          : RefreshIndicator(
        onRefresh: _load,
        color: c.brand,
        child: listings.isEmpty ? _empty() : _list(),
      ),
    );
  }

  Widget _empty() {
    final c = C.of(context);
    return ListView(children: [
      const SizedBox(height: 90),
      Icon(Icons.storefront_outlined, size: 44, color: c.muted),
      const SizedBox(height: 14),
      const Center(child: Text('Nothing listed right now', style: TextStyle(fontWeight: FontWeight.w700))),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text('When investors list shares for sale, they’ll appear here. You can also list your own from Portfolio.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.muted, height: 1.5)),
      ),
    ]);
  }

  Widget _list() {
    final c = C.of(context);
    final myId = authService.currentUser?.id;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      Text('${listings.length} ${listings.length == 1 ? 'listing' : 'listings'} from other investors',
          style: TextStyle(fontSize: 13, color: c.muted)),
      const SizedBox(height: 14),
      ...listings.map((l) {
        final p = props[l.propertyId];
        final mine = l.sellerId == myId;
        // how the asking price compares to the platform price
        final diff = (p == null || p.sharePrice == 0) ? 0.0 : ((l.pricePerShare - p.sharePrice) / p.sharePrice) * 100;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            // property row (tappable -> detail)
            GestureDetector(
              onTap: p == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(p: p))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: p == null
                        ? Container(width: 54, height: 54, color: c.imgBg)
                        : Image.network(p.images[0], width: 54, height: 54, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 54, height: 54, color: c.imgBg)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p?.title ?? 'Property', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${grp(l.shares)} ${l.shares == 1 ? 'share' : 'shares'} · ${p?.city ?? ''}', style: TextStyle(fontSize: 12.5, color: c.muted)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(pkr(l.pricePerShare), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text('per share', style: TextStyle(fontSize: 11, color: c.muted)),
                  ]),
                ]),
              ),
            ),
            Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total ${pkr(l.totalPrice)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  if (p != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      diff == 0
                          ? 'Same as platform price'
                          : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}% vs platform price',
                      style: TextStyle(fontSize: 11.5, color: diff > 0 ? c.negative : c.positive, fontWeight: FontWeight.w600),
                    ),
                  ],
                ])),
                if (mine)
                  Text('Your listing', style: TextStyle(fontSize: 12.5, color: c.muted, fontWeight: FontWeight.w600))
                else
                  ElevatedButton(
                    onPressed: () => _buy(l, p),
                    style: ElevatedButton.styleFrom(backgroundColor: c.brand, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Buy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ]),
        );
      }),
    ]);
  }
}