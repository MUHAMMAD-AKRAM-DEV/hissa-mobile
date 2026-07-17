// ============================================================
//  lib/models/property.dart  —  Property model + money helpers.
//  Goes in:  hissa_mobile/lib/models/property.dart   (replace all)
//
//  fromJson is tolerant: it reads the real backend field names
//  (sharePricePkr, expectedYieldPct, address, string numbers…)
//  AND the ideal names, and defaults anything not sent yet.
// ============================================================

String _grp(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

String grp(int n) => _grp(n);
String pkr(num n) => 'PKR ${_grp(n.round())}';
String pkrShort(num n) {
  if (n >= 1e7) return 'PKR ${(n / 1e7).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} Cr';
  if (n >= 1e5) return 'PKR ${(n / 1e5).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} Lac';
  return pkr(n);
}
String kpkr(int n) => n >= 1000 ? 'PKR ${(n / 1000).toStringAsFixed(0)}k' : pkr(n);

// ---- parsing helpers (backend sends some numbers as strings) ----
int _int(dynamic v, [int d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first) ?? d;
}

double _dbl(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

String _str(dynamic v, [String d = '']) => v?.toString() ?? d;

List<String> _strList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Property {
  final String id, title, city, area, type, status, description;
  final List<String> images; // mutable so the service can attach real image URLs
  final int totalValue, sharePrice, totalShares, sharesSold, investors, occupancy;
  final double expectedYield, projectedAppreciation;
  final String fundingDeadline, holdingPeriod, distribution;
  final bool shariah;
  final double? latitude, longitude;
  final Map<String, double> fees;
  final List<String> highlights, documents;

  Property({
    required this.id, required this.title, required this.city, required this.area,
    required this.type, required this.status, required this.description, required this.images,
    required this.totalValue, required this.sharePrice, required this.totalShares,
    required this.sharesSold, required this.investors, required this.occupancy,
    required this.expectedYield, required this.projectedAppreciation,
    required this.fundingDeadline, required this.holdingPeriod, required this.distribution,
    required this.shariah, this.latitude, this.longitude, required this.fees, required this.highlights, required this.documents,
  });

  int get fundedPct => totalShares == 0 ? 0 : ((sharesSold / totalShares) * 100).round();
  int get sharesLeft => totalShares - sharesSold;
  bool get funded => status == 'funded' || sharesLeft <= 0;
  double get annualised => expectedYield + projectedAppreciation;

  factory Property.fromJson(Map<String, dynamic> j) {
    // images: flat list of urls, list of {url}/{path}, else placeholder
    List<String> images = [];
    final rawImg = j['images'];
    if (rawImg is List) {
      images = rawImg
          .map((e) => e is String ? e : (e is Map ? (e['url'] ?? e['path'] ?? '').toString() : e.toString()))
          .where((s) => s.toString().isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (images.isEmpty) {
      final seed = _str(j['id'], _str(j['title'], 'hissa')).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      images = ['https://picsum.photos/seed/${seed.isEmpty ? 'hissa' : seed}/800/520'];
    }

    // fees: nested object or platform defaults
    Map<String, double> fees = {'acquisition': 1.5, 'management': 0.7, 'exit': 1.5};
    final rawFees = j['fees'];
    if (rawFees is Map) {
      fees = {
        'acquisition': _dbl(rawFees['acquisition'], 1.5),
        'management': _dbl(rawFees['management'], 0.7),
        'exit': _dbl(rawFees['exit'], 1.5),
      };
    }

    return Property(
      id: _str(j['id']),
      title: _str(j['title'], 'Untitled'),
      city: _str(j['city']),
      area: _str(j['area'] ?? j['address']),
      type: _str(j['type'], 'Residential'),
      status: _str(j['status'], 'funding'),
      description: _str(j['description']),
      images: images,
      totalValue: _int(j['totalValue'] ?? j['totalValuePkr']),
      sharePrice: _int(j['sharePrice'] ?? j['sharePricePkr'], 1),
      totalShares: _int(j['totalShares'], 1),
      sharesSold: _int(j['sharesSold']),
      investors: _int(j['investors']),
      occupancy: _int(j['occupancy'], 100),
      expectedYield: _dbl(j['expectedYield'] ?? j['expectedYieldPct']),
      projectedAppreciation: _dbl(j['projectedAppreciation']),
      fundingDeadline: _str(j['fundingDeadline'], '—'),
      holdingPeriod: _str(j['holdingPeriod'], '5 years'),
      distribution: _str(j['distribution'], 'Monthly'),
      shariah: j['shariah'] is bool ? j['shariah'] as bool : true,
      latitude: j['latitude'] == null ? null : _dbl(j['latitude']),
      longitude: j['longitude'] == null ? null : _dbl(j['longitude']),
      fees: fees,
      highlights: _strList(j['highlights']),
      documents: _strList(j['documents']),
    );
  }
}