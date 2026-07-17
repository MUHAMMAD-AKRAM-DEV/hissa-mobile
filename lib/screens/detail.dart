// ============================================================
//  lib/screens/detail.dart  —  Property detail (rich).
//  Goes in:  hissa_mobile/lib/screens/detail.dart   (new file)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/kyc_service.dart';
import 'kyc.dart';
import 'invest.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property p;
  const PropertyDetailScreen({super.key, required this.p});
  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  KycStatus? kyc;

  @override
  void initState() {
    super.initState();
    _loadKyc();
  }

  Future<void> _loadKyc() async {
    final s = await kycService.getStatus();
    if (mounted) setState(() => kyc = s);
  }

  // Not verified -> explain and send them to the KYC flow.
  void _needsKyc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.verified_user_outlined, color: AppColors.brand)),
          const SizedBox(height: 14),
          Text(kyc?.state == KycState.pending ? 'Verification under review' : 'Verify your identity first', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(kyc?.blurb ?? 'Verification is required before investing.', style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 20),
          if (kyc?.state != KycState.pending)
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => KycScreen(onBack: () => Navigator.pop(context), onDone: () { kycService.clear(); Navigator.pop(context); _loadKyc(); }, onSkip: () => Navigator.pop(context))));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Verify now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ))
          else
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Got it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            )),
        ]),
      ),
    );
  }

  int active = 0;
  bool fav = false;
  bool expanded = false;

  Property get p => widget.p;

  @override
  Widget build(BuildContext context) {
    final raise = p.totalShares * p.sharePrice;
    final breakdown = [
      ['Property acquisition', 0.935, Icons.apartment],
      ['Transaction & registration', 0.04, Icons.description_outlined],
      ['Platform fee', 0.015, Icons.sell_outlined],
      ['Cash reserve', 0.01, Icons.account_balance_wallet_outlined],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _hero(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // trust chips
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _trust(Icons.verified_user_outlined, 'SECP-registered SPV'),
                  if (p.shariah) _trust(Icons.nightlight_round, 'Shariah-compliant'),
                  _trust(Icons.description_outlined, 'Title documents'),
                ]),
                const SizedBox(height: 16),
                // headline stats
                Row(children: [
                  _statTile('Annualised', '${p.annualised.toStringAsFixed(1)}%'),
                  const SizedBox(width: 12),
                  _statTile('Rental yield', '${p.expectedYield}%'),
                  const SizedBox(width: 12),
                  _statTile('Occupancy', '${p.occupancy}%'),
                ]),

                _sec('Projected returns'),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(children: [
                    _retRow('Rental income (p.a.)', '${p.expectedYield}%', false),
                    _retRow('Capital appreciation (p.a.)', '${p.projectedAppreciation}%', false),
                    const Divider(color: Colors.white24, height: 20),
                    _retRow('Projected annualised return', '${p.annualised.toStringAsFixed(1)}%', true),
                    const SizedBox(height: 10),
                    Text('Projections over a ${p.holdingPeriod} term. Not guaranteed — actual returns may vary.',
                        style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4)),
                  ]),
                ),

                _sec('Funding'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${p.fundedPct}% funded', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${grp(p.investors)} investors', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: p.fundedPct / 100, minHeight: 7, backgroundColor: AppColors.line, color: AppColors.brand)),
                    const SizedBox(height: 12),
                    _kv('Target raise', pkrShort(raise)),
                    _kv(p.funded ? 'Status' : 'Funding closes', p.funded ? 'Fully funded' : p.fundingDeadline),
                    _kv('Income distribution', p.distribution),
                  ]),
                ),

                _sec('Key details'),
                Row(children: [
                  _fig(Icons.sell_outlined, 'Price / share', pkr(p.sharePrice)),
                  const SizedBox(width: 12),
                  _fig(Icons.trending_up, 'Min investment', pkr(p.sharePrice)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _fig(Icons.apartment, 'Property value', pkrShort(p.totalValue)),
                  const SizedBox(width: 12),
                  _fig(Icons.layers_outlined, 'Total shares', grp(p.totalShares)),
                ]),

                _sec('Where your money goes'),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    for (final b in breakdown)
                      _bdRow(b[2] as IconData, b[0] as String, b[1] as double, raise),
                    Container(
                      decoration: const BoxDecoration(color: AppColors.tint),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total raise', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text(pkrShort(raise), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.brand)),
                      ]),
                    ),
                  ]),
                ),

                _sec('Fees'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    _feeRow('Acquisition fee', 'one-off', '${p.fees['acquisition']}%'),
                    const Divider(color: AppColors.line, height: 1),
                    _feeRow('Management fee', 'per year', '${p.fees['management']}%'),
                    const Divider(color: AppColors.line, height: 1),
                    _feeRow('Exit fee', 'on sale', '${p.fees['exit']}%'),
                  ]),
                ),

                _sec('About this property'),
                _about(),

                _sec('Highlights'),
                Column(children: p.highlights.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_outline, size: 19, color: AppColors.brand),
                    const SizedBox(width: 10),
                    Expanded(child: Text(h, style: const TextStyle(fontSize: 14))),
                  ]),
                )).toList()),

                _sec('Location'),
                _locationMap(),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${p.area}, ${p.city}', style: const TextStyle(fontSize: 14))),
                ]),

                _sec('Documents'),
                Column(children: p.documents.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(children: [
                    const Icon(Icons.description_outlined, size: 18, color: AppColors.brand),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d, style: const TextStyle(fontSize: 14))),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                  ]),
                )).toList()),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Property values can fall and rental income isn’t guaranteed. Shares may be illiquid until an exit window. This is not investment advice.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
                ),
              ]),
            ),
          ]),
        ),
        _bottomBar(),
      ]),
    );
  }

  // ---------- hero ----------
  Widget _hero() {
    return SizedBox(
      height: 380,
      child: Stack(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Image.network(
            p.images[active],
            height: 380, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.imgBg),
            loadingBuilder: (c, w, prog) => prog == null ? w : Container(color: AppColors.imgBg),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent]),
            ),
          ),
        ),
        // back
        Positioned(top: 44, left: 16, child: _round(Icons.chevron_left, () => Navigator.pop(context))),
        // fav
        Positioned(top: 44, right: 16, child: _round(fav ? Icons.favorite : Icons.favorite_border, () => setState(() => fav = !fav), fg: fav ? const Color(0xFFE2564D) : AppColors.ink)),
        // thumbnails
        Positioned(top: 96, right: 16, child: Column(children: List.generate(p.images.length, (i) {
          final on = i == active;
          return GestureDetector(
            onTap: () => setState(() => active = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: on ? Colors.white : Colors.white54, width: 2),
                image: DecorationImage(image: NetworkImage(p.images[i]), fit: BoxFit.cover),
              ),
            ),
          );
        }))),
        // caption
        Positioned(left: 20, right: 90, bottom: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: Text(p.type, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
          const SizedBox(height: 5),
          Text('📍 ${p.area}, ${p.city}', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
        ])),
      ]),
    );
  }

  Widget _round(IconData ic, VoidCallback onTap, {Color fg = AppColors.ink}) => GestureDetector(
    onTap: onTap,
    child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle), child: Icon(ic, color: fg, size: 22)),
  );

  Widget _trust(IconData ic, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ic, size: 14, color: AppColors.brand),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _statTile(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
      ]),
    ),
  );

  Widget _sec(String t) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 10), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)));

  Widget _retRow(String label, String value, bool big) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 14)),
      Text(value, style: TextStyle(color: big ? AppColors.gold : Colors.white, fontSize: big ? 20 : 14, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
    ]),
  );

  Widget _fig(IconData ic, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(10)), child: Icon(ic, size: 17, color: AppColors.brand)),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _bdRow(IconData ic, String label, double pct, int raise) => Container(
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(9)), child: Icon(ic, size: 15, color: AppColors.brand)),
      const SizedBox(width: 12),
      Expanded(child: Text.rich(TextSpan(children: [
        TextSpan(text: label, style: const TextStyle(fontSize: 13.5)),
        TextSpan(text: '  ${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]))),
      Text(pkrShort(raise * pct), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
    ]),
  );

  Widget _feeRow(String label, String sub, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text.rich(TextSpan(children: [
        TextSpan(text: label, style: const TextStyle(fontSize: 13.5)),
        TextSpan(text: '  $sub', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
    ]),
  );

  Widget _about() {
    final long = p.description.length > 120;
    final shown = (!expanded && long) ? '${p.description.substring(0, 120)}…' : p.description;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(shown, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5B56), height: 1.65)),
      if (long)
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(expanded ? 'Read less' : 'Read More', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
    ]);
  }

  Widget _locationMap() {
    // no coordinates -> simple placeholder box
    if (p.latitude == null || p.longitude == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: const Color(0xFFE8F0EC), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Icon(Icons.location_on, color: AppColors.ink, size: 30)),
      );
    }
    final point = LatLng(p.latitude!, p.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hissa.mobile',
            ),
            MarkerLayer(markers: [
              Marker(
                point: point,
                width: 40, height: 40,
                child: const Icon(Icons.location_on, color: AppColors.brand, size: 40),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(top: false, child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Price / share', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(pkr(p.sharePrice), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ])),
        ElevatedButton(
          onPressed: p.funded ? null : () {
            if (kyc != null && !kyc!.canInvest) { _needsKyc(); return; }
            Navigator.push(context, MaterialPageRoute(builder: (_) => InvestScreen(p: p)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink, foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB8C2BE),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(p.funded ? 'Fully funded' : 'Invest', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (!p.funded) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 19)],
          ]),
        ),
      ])),
    );
  }
}