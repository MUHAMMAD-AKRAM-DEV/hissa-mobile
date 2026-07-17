// ============================================================
//  lib/screens/notifications.dart  —  Activity feed (REAL data).
//  Goes in:  hissa_mobile/lib/screens/notifications.dart  (replace all)
//
//  There's no /notifications endpoint, so the feed is built from
//  real data the user already has: wallet transactions + investments.
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/property.dart';
import '../services/wallet_service.dart';
import '../services/investment_service.dart';
import '../services/property_service.dart';
import '../services/kyc_service.dart';

class _Activity {
  final IconData icon;
  final String title, sub;
  final DateTime when;
  _Activity(this.icon, this.title, this.sub, this.when);

  String get ago {
    final d = DateTime.now().difference(when);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'} ago';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return '${d.inDays} days ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()} week${d.inDays >= 14 ? 's' : ''} ago';
    return '${(d.inDays / 30).floor()} month${d.inDays >= 60 ? 's' : ''} ago';
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Activity> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <_Activity>[];

    // KYC status
    try {
      final kyc = await kycService.getStatus(refresh: true);
      switch (kyc.state) {
        case KycState.approved:
          out.add(_Activity(Icons.verified_user_outlined, 'Identity verified', 'You can now invest in properties.', DateTime.now()));
        case KycState.pending:
          out.add(_Activity(Icons.hourglass_empty, 'Verification under review', 'We’re checking your documents.', DateTime.now()));
        case KycState.rejected:
          out.add(_Activity(Icons.error_outline, 'Verification rejected', kyc.blurb, DateTime.now()));
        default:
          out.add(_Activity(Icons.verified_user_outlined, 'Verify your identity', 'Complete verification to start investing.', DateTime.now()));
      }
    } catch (_) {}

    // wallet activity
    try {
      final txns = await walletService.getTransactions();
      for (final t in txns) {
        final when = DateTime.tryParse(t.createdAt) ?? DateTime.now();
        out.add(_Activity(
          t.isCredit ? Icons.account_balance_wallet_outlined : Icons.north_east,
          t.isCredit ? 'Funds added' : 'Withdrawal',
          '${money(t.amountPkr)} ${t.isCredit ? 'added to' : 'sent from'} your wallet.',
          when,
        ));
      }
    } catch (_) {}

    // investments
    try {
      final records = await investmentService.getInvestments();
      if (records.isNotEmpty) {
        final props = await PropertyService().getProperties();
        final byId = {for (final p in props) p.id: p};
        for (final r in records) {
          final name = byId[r.propertyId]?.title ?? 'a property';
          final when = DateTime.tryParse(r.createdAt) ?? DateTime.now();
          // Sales on the secondary market are stored as NEGATIVE records.
          final sold = r.shares < 0;
          final count = r.shares.abs();
          out.add(_Activity(
            sold ? Icons.storefront : Icons.apartment,
            sold ? 'Shares sold' : 'Investment confirmed',
            sold
                ? 'You sold ${grp(count)} share${count == 1 ? '' : 's'} in $name for ${pkr(r.total.abs())}.'
                : 'You bought ${grp(count)} share${count == 1 ? '' : 's'} in $name for ${pkr(r.total)}.',
            when,
          ));
        }
      }
    } catch (_) {}

    out.sort((a, b) => b.when.compareTo(a.when));
    if (mounted) setState(() { items = out; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: loading
          ? Center(child: CircularProgressIndicator(color: c.brand))
          : items.isEmpty
          ? Center(child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none, size: 44, color: c.muted),
          const SizedBox(height: 12),
          const Text('Nothing yet', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your activity will show up here.', style: TextStyle(fontSize: 13, color: c.muted)),
        ]),
      ))
          : RefreshIndicator(
        onRefresh: _load,
        color: c.brand,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (_, i) {
            final n = items[i];
            final fresh = DateTime.now().difference(n.when).inHours < 48;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              decoration: BoxDecoration(
                color: fresh ? c.tint : c.card,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: c.tile, borderRadius: BorderRadius.circular(12)), child: Icon(n.icon, size: 19, color: c.brand)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(n.sub, style: TextStyle(fontSize: 12.5, color: c.muted, height: 1.45)),
                  const SizedBox(height: 5),
                  Text(n.ago, style: TextStyle(fontSize: 11, color: c.muted)),
                ])),
                if (fresh) Container(margin: const EdgeInsets.only(top: 6), width: 8, height: 8, decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle)),
              ]),
            );
          },
        ),
      ),
    );
  }
}