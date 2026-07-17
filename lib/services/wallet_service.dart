// ============================================================
//  lib/services/wallet_service.dart  —  Wallet + transactions.
//  Goes in:  hissa_mobile/lib/services/wallet_service.dart  (NEW file)
//
//  Backend shapes (confirmed):
//    GET  /wallet               -> {"balance": 0, "currency": "PKR"}   (rupees, number)
//    GET  /wallet/transactions  -> [{id, userId, type, amountPkr(String), description, createdAt}]
//    POST /wallet/deposit       -> {"balance": 5000, "currency": "PKR"}
// ============================================================

import '../models/property.dart' show grp; // number formatting helper
import 'api_client.dart';

class WalletTxn {
  final String id, type, description, createdAt;
  final double amountPkr;
  WalletTxn({required this.id, required this.type, required this.description, required this.createdAt, required this.amountPkr});

  factory WalletTxn.fromJson(Map<String, dynamic> j) {
    final raw = j['amountPkr'];
    final amt = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '0') ?? 0;
    return WalletTxn(
      id: (j['id'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),          // deposit | withdrawal
      description: (j['description'] ?? '').toString(),
      createdAt: (j['createdAt'] ?? '').toString(),
      amountPkr: amt,
    );
  }

  bool get isCredit => type == 'deposit';
  // "2026-07-13T03:22:26.365Z" -> "13 Jul 2026"
  String get dateLabel {
    final d = DateTime.tryParse(createdAt);
    if (d == null) return '';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class WalletService {
  Future<double> getBalance() async {
    final res = await apiClient.getJson('/wallet') as Map<String, dynamic>;
    final b = res['balance'];
    return b is num ? b.toDouble() : double.tryParse(b?.toString() ?? '0') ?? 0;
  }

  Future<List<WalletTxn>> getTransactions() async {
    final res = await apiClient.getJson('/wallet/transactions') as List;
    return res.map((e) => WalletTxn.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Withdraw funds — returns the new balance.
  // Throws with "Insufficient wallet balance" if too much.
  Future<double> withdraw(double amountPkr) async {
    final res = await apiClient.postJson('/wallet/withdraw', {'amountPkr': amountPkr});
    if (res is Map && res['balance'] != null) {
      final b = res['balance'];
      return b is num ? b.toDouble() : double.tryParse(b.toString()) ?? 0;
    }
    return getBalance();
  }

  // Test/manual deposit — returns the new balance.
  Future<double> deposit(double amountPkr) async {
    final res = await apiClient.postJson('/wallet/deposit', {'amountPkr': amountPkr});
    if (res is Map && res['balance'] != null) {
      final b = res['balance'];
      return b is num ? b.toDouble() : double.tryParse(b.toString()) ?? 0;
    }
    return getBalance();
  }
}

final walletService = WalletService();

String money(double v) => 'PKR ${grp(v.round())}';