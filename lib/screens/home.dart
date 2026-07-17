// ============================================================
//  lib/screens/home.dart  —  Discover (carousel + grid + more).
//  Goes in:  hissa_mobile/lib/screens/home.dart   (replace all)
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/property_service.dart';
import 'detail.dart';
import 'portfolio.dart';
import 'wallet.dart';
import 'settings.dart';
import 'notifications.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int nav = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DiscoverTab(),
      const PortfolioTab(),
      const WalletTab(),
      SettingsTab(onLogout: widget.onLogout),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(child: tabs[nav]),
          _BottomNav(index: nav, onTap: (i) => setState(() => nav = i)),
        ]),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.home_outlined, Icons.bar_chart, Icons.account_balance_wallet_outlined, Icons.settings_outlined];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: List.generate(4, (i) {
          final on = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Center(
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: on ? AppColors.ink : Colors.transparent, shape: BoxShape.circle),
                  child: Icon(icons[i], color: on ? Colors.white : const Color(0xFF9AA8A2), size: 24),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final _service = PropertyService();
  late Future<List<Property>> _future;
  String cityFilter = 'All';
  String typeFilter = 'All';
  String query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.getProperties();
  }

  void _open(Property p) => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(p: p)));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Property>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: CircularProgressIndicator(color: AppColors.brand)));
        }
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: AppColors.negative, size: 40),
              const SizedBox(height: 12),
              const Text('Could not load properties', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('\${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ));
        }
        if (!snap.hasData) return const Center(child: Text('No properties'));

        final all = snap.data!;
        final cities = ['All', ...{for (final p in all) p.city}];
        var list = all.where((p) {
          if (cityFilter != 'All' && p.city != cityFilter) return false;
          if (typeFilter != 'All' && p.type != typeFilter) return false;
          if (query.trim().isNotEmpty && !'${p.title} ${p.area} ${p.city}'.toLowerCase().contains(query.toLowerCase())) return false;
          return true;
        }).toList()
          ..sort((a, b) => b.fundedPct - a.fundedPct);

        final maxYield = all.map((p) => p.expectedYield).reduce((a, b) => a > b ? a : b);
        final avgYield = all.map((p) => p.expectedYield).reduce((a, b) => a + b) / all.length;
        final investors = all.map((p) => p.investors).reduce((a, b) => a + b);
        final featured = [...all]..sort((a, b) => b.fundedPct - a.fundedPct);
        final resCount = all.where((p) => p.type == 'Residential').length;
        final comCount = all.where((p) => p.type == 'Commercial').length;

        final boxW = (MediaQuery.of(context).size.width - 40 - 14) / 2;

        return ListView(padding: EdgeInsets.zero, children: [
          _header(),
          _hero(maxYield, avgYield, investors),
          _trustChips(),
          _search(),
          _chips(cities),

          if (query.isEmpty && cityFilter == 'All' && typeFilter == 'All') ...[
            _sectionHead('Featured', trailing: 'Swipe →'),
            _featuredCarousel(featured),
          ],

          _sectionHead('Browse by type'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _typeCard('Residential', Icons.home_work_outlined, resCount),
              const SizedBox(width: 12),
              _typeCard('Commercial', Icons.storefront_outlined, comCount),
            ]),
          ),

          _sectionHead(typeFilter == 'All' ? 'Properties' : typeFilter, trailing: '${list.length} available'),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Text('No properties match your filters.', style: TextStyle(color: AppColors.muted)))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 14, runSpacing: 14,
                children: list.map((p) => SizedBox(width: boxW, child: SmallBox(p: p, onTap: () => _open(p)))).toList(),
              ),
            ),

          _sectionHead('Why Hissa'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _benefit(Icons.savings_outlined, 'From PKR 5k', 'Low entry'),
              const SizedBox(width: 10),
              _benefit(Icons.payments_outlined, 'Monthly', 'Rental income'),
              const SizedBox(width: 10),
              _benefit(Icons.handshake_outlined, 'Managed', 'Hands-off'),
            ]),
          ),

          _sectionHead('How Hissa works'),
          _howStep(1, 'Browse & invest', 'Pick a vetted property and buy shares from PKR 5,000.'),
          _howStep(2, 'Earn monthly rent', 'Your share of the rent lands in your wallet every month.'),
          _howStep(3, 'Exit anytime', 'Sell your shares on the in-app marketplace.'),

          _referralCard(),
          _aboutCard(),
          const SizedBox(height: 16),
        ]);
      },
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]), shape: BoxShape.circle), child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)))),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        Text('Discover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ])),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        child: Stack(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(99)), child: const Icon(Icons.notifications_none, size: 20, color: AppColors.ink)),
          Positioned(top: 9, right: 10, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: const Color(0xFFE2564D), shape: BoxShape.circle, border: Border.all(color: AppColors.field, width: 2)))),
        ]),
      ),
    ]),
  );

  Widget _hero(double maxYield, double avgYield, int investors) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('REAL ESTATE INVESTING', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(height: 10),
      Text.rich(TextSpan(children: [
        const TextSpan(text: 'Earn up to '),
        TextSpan(text: '${maxYield.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.gold)),
        const TextSpan(text: '\nrental yield'),
      ]), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.6)),
      const SizedBox(height: 8),
      const Text('Own a share of vetted property across Pakistan from just PKR 5,000.', style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.45)),
      const SizedBox(height: 18),
      const Divider(color: Colors.white24, height: 1),
      const SizedBox(height: 14),
      Row(children: [
        _heroStat('${avgYield.toStringAsFixed(1)}%', 'Avg. yield'),
        _heroStat('4', 'Properties'),
        _heroStat(grp(investors), 'Investors'),
      ]),
    ]),
  );

  Widget _heroStat(String value, String label) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]));

  Widget _trustChips() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
    child: Wrap(spacing: 8, runSpacing: 8, children: [
      _trust(Icons.verified_user_outlined, 'SECP-registered SPV'),
      _trust(Icons.nightlight_round, 'Shariah-compliant'),
      _trust(Icons.description_outlined, 'Title documents'),
    ]),
  );

  Widget _trust(IconData ic, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 14, color: AppColors.brand), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))]),
  );

  Widget _search() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
    child: Container(
      height: 50,
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.search, size: 20, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Search properties or cities', hintStyle: TextStyle(color: AppColors.muted, fontSize: 15)))),
        const SizedBox(width: 14),
      ]),
    ),
  );

  Widget _chips(List<String> cities) => SizedBox(
    height: 46,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      children: cities.map((c) {
        final on = c == cityFilter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => cityFilter = c),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), alignment: Alignment.center, decoration: BoxDecoration(color: on ? AppColors.ink : AppColors.field, borderRadius: BorderRadius.circular(99)), child: Text(c, style: TextStyle(color: on ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13))),
          ),
        );
      }).toList(),
    ),
  );

  Widget _sectionHead(String title, {String? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _featuredCarousel(List<Property> featured) => SizedBox(
    height: 258,
    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: featured.map((p) => FeatureCard(p: p, onTap: () => _open(p))).toList()),
  );

  Widget _typeCard(String label, IconData ic, int count) {
    final on = typeFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => typeFilter = on ? 'All' : label),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: on ? AppColors.tint : Colors.white, border: Border.all(color: on ? AppColors.brand : AppColors.line, width: 1.5), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: AppColors.brand, size: 21)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('$count ${count == 1 ? 'property' : 'properties'}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }

  Widget _benefit(IconData ic, String title, String sub) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(ic, color: AppColors.brand, size: 24),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    ),
  );

  Widget _howStep(int n, String title, String sub) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(11)), child: Center(child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
      ])),
    ]),
  );

  Widget _referralCard() => Container(
    margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE2A33B), Color(0xFFF4D79B)]), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.card_giftcard, color: Color(0xFF5A3E08))),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Invite friends, earn PKR 1,000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF3A2604))),
        SizedBox(height: 3),
        Text('For every friend who makes their first investment.', style: TextStyle(fontSize: 12.5, color: Color(0xFF5A3E08), height: 1.35)),
      ])),
      const Icon(Icons.chevron_right, color: Color(0xFF5A3E08)),
    ]),
  );

  Widget _aboutCard() => Container(
    margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.tint, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]), borderRadius: BorderRadius.circular(9)), child: Center(child: Container(width: 11, height: 11, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(3))))),
        const SizedBox(width: 10),
        const Text('About Hissa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      const Text('Hissa lets anyone in Pakistan own a share of vetted real estate from as little as PKR 5,000, earn monthly rental income, and exit through a secondary marketplace.', style: TextStyle(fontSize: 13.5, color: Color(0xFF4A5B56), height: 1.55)),
      const SizedBox(height: 14),
      _aboutPoint(Icons.shield_outlined, 'Every property held in a SECP-registered SPV'),
      _aboutPoint(Icons.nightlight_round, '100% Shariah-compliant — no interest (riba)'),
      _aboutPoint(Icons.payments_outlined, 'Rent paid into your wallet every month'),
    ]),
  );

  Widget _aboutPoint(IconData ic, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Icon(ic, size: 17, color: AppColors.brand), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4)))]),
  );
}

// ============================================================
//  Large featured card (horizontal carousel)
// ============================================================
class FeatureCard extends StatelessWidget {
  final Property p;
  final VoidCallback onTap;
  const FeatureCard({super.key, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 14))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(children: [
              Image.network(p.images[0], height: 168, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 168, color: AppColors.imgBg)),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent])))),
              Positioned(top: 12, left: 12, child: _chip('▲ ${p.expectedYield}%', Colors.white.withValues(alpha: 0.94), AppColors.brand)),
              Positioned(top: 12, right: 12, child: p.funded ? _chip('Funded', AppColors.positive, Colors.white) : _chip('Open', AppColors.gold, const Color(0xFF3A2604))),
              Positioned(left: 14, right: 14, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('📍 ${p.area}, ${p.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: p.fundedPct / 100, minHeight: 6, backgroundColor: AppColors.line, color: AppColors.brand)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${p.fundedPct}% funded', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                Text('From ${kpkr(p.sharePrice)}', style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)), child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)));
}

// ============================================================
//  Small grid box
// ============================================================
class SmallBox extends StatelessWidget {
  final Property p;
  final VoidCallback onTap;
  const SmallBox({super.key, required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF073E36).withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 12))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(children: [
              Image.network(p.images[0], height: 104, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 104, color: AppColors.imgBg)),
              Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(99)), child: Text('▲ ${p.expectedYield}%', style: const TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w700)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 34,
                child: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.25)),
              ),
              const SizedBox(height: 3),
              Text('📍 ${p.city}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              const SizedBox(height: 9),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: p.fundedPct / 100, minHeight: 5, backgroundColor: AppColors.line, color: AppColors.brand)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(kpkr(p.sharePrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(p.funded ? 'Funded' : '${p.fundedPct}%', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}