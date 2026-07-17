// ============================================================
//  lib/services/investment_service.dart  —  Investments/portfolio.
//  Goes in:  hissa_mobile/lib/services/investment_service.dart  (NEW file)
//
//  Backend shapes (confirmed):
//    POST /investments  {propertyId, shares}
//      -> {id,userId,propertyId,sharesPurchased,pricePerShare(String),totalAmountPkr(num),createdAt}
//    GET  /investments  -> [ ...same records... ]   (raw, not aggregated)
//
//  There is no /portfolio endpoint, so we aggregate per property here.
// ============================================================

import '../models/property.dart';
import 'api_client.dart';
import 'property_service.dart';

class InvestmentRecord {
  final String id, propertyId, createdAt;
  final int shares;
  final double pricePerShare, total;

  InvestmentRecord({
    required this.id, required this.propertyId, required this.createdAt,
    required this.shares, required this.pricePerShare, required this.total,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;

  factory InvestmentRecord.fromJson(Map<String, dynamic> j) => InvestmentRecord(
    id: (j['id'] ?? '').toString(),
    propertyId: (j['propertyId'] ?? '').toString(),
    createdAt: (j['createdAt'] ?? '').toString(),
    shares: (j['sharesPurchased'] is num)
        ? (j['sharesPurchased'] as num).toInt()
        : int.tryParse(j['sharesPurchased']?.toString() ?? '0') ?? 0,
    pricePerShare: _num(j['pricePerShare']),
    total: _num(j['totalAmountPkr']),
  );
}

// One row in the portfolio: all investments in a single property, combined.
class PortfolioHolding {
  final Property property;
  final int shares;
  final double invested;
  final String firstDate;
  PortfolioHolding({required this.property, required this.shares, required this.invested, required this.firstDate});

  // current value = shares x today's share price
  double get value => shares * property.sharePrice.toDouble();
  double get gain => value - invested;
  double get gainPct => invested == 0 ? 0 : (gain / invested) * 100;
  // this holding's share of the property's monthly rent
  double get monthlyIncome => value * (property.expectedYield / 100) / 12;
}

class InvestmentService {
  Future<List<InvestmentRecord>> getInvestments() async {
    final res = await apiClient.getJson('/investments') as List;
    return res.map((e) => InvestmentRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Buy shares. Throws with the backend's message on failure
  // (e.g. "Insufficient wallet balance", "Only X shares remaining").
  Future<void> invest(String propertyId, int shares) async {
    await apiClient.postJson('/investments', {'propertyId': propertyId, 'shares': shares});
  }

  // Raw records -> one holding per property, with property details attached.
  Future<List<PortfolioHolding>> getPortfolio() async {
    final records = await getInvestments();
    if (records.isEmpty) return [];

    final props = await PropertyService().getProperties();
    final byId = {for (final p in props) p.id: p};

    final grouped = <String, List<InvestmentRecord>>{};
    for (final r in records) {
      grouped.putIfAbsent(r.propertyId, () => []).add(r);
    }

    final out = <PortfolioHolding>[];
    grouped.forEach((propertyId, rows) {
      final prop = byId[propertyId];
      if (prop == null) return; // property deleted/unknown -> skip
      // Sales are negative records, so summing gives the true net position.
      final shares = rows.fold<int>(0, (s, r) => s + r.shares);
      if (shares <= 0) return; // fully sold out of this property -> not a holding
      final invested = rows.fold<double>(0, (s, r) => s + r.total);
      final dates = rows.map((r) => r.createdAt).toList()..sort();
      out.add(PortfolioHolding(property: prop, shares: shares, invested: invested, firstDate: dates.first));
    });

    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }
}

final investmentService = InvestmentService();