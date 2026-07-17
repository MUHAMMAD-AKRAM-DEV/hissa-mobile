// ============================================================
//  lib/store.dart  —  Shared app state (holdings, wallet).
//  Goes in:  hissa_mobile/lib/store.dart   (new file)
//
//  A ChangeNotifier singleton. Screens listen with
//  ListenableBuilder. Later, these methods call your NestJS API.
// ============================================================

import 'package:flutter/foundation.dart';
import 'models/property.dart';
import 'services/property_service.dart';

class Holding {
  final Property property;
  int shares;
  int invested;
  final String date;
  Holding({required this.property, required this.shares, required this.invested, required this.date});
}

class Txn {
  final String id, type, label;
  final int amount;
  final String date;
  Txn({required this.id, required this.type, required this.label, required this.amount, required this.date});
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);
String _tid() => 't${DateTime.now().microsecondsSinceEpoch}';

class AppStore extends ChangeNotifier {
  final List<Holding> holdings = [
    Holding(property: mockProperties[0], shares: 12, invested: 120000, date: '2026-05-10'),
  ];
  int balance = 18450;
  final List<Txn> txns = [
    Txn(id: 't1', type: 'payout', label: 'Rent · DHA Phase 6', amount: 760, date: '2026-06-01'),
    Txn(id: 't4', type: 'deposit', label: 'Deposit · Bank transfer', amount: 100000, date: '2026-04-01'),
  ];

  void addInvestment(Property property, int shares, int total) {
    final equity = shares * property.sharePrice;
    final idx = holdings.indexWhere((h) => h.property.id == property.id);
    if (idx >= 0) {
      holdings[idx].shares += shares;
      holdings[idx].invested += equity;
    } else {
      holdings.add(Holding(property: property, shares: shares, invested: equity, date: _today()));
    }
    txns.insert(0, Txn(id: _tid(), type: 'invest', label: 'Invested · ${property.area}', amount: -total, date: _today()));
    notifyListeners();
  }

  void deposit(int amount) {
    balance += amount;
    txns.insert(0, Txn(id: _tid(), type: 'deposit', label: 'Deposit · Bank transfer', amount: amount, date: _today()));
    notifyListeners();
  }

  void withdraw(int amount) {
    balance = (balance - amount) < 0 ? 0 : balance - amount;
    txns.insert(0, Txn(id: _tid(), type: 'withdraw', label: 'Withdrawal · Bank', amount: -amount, date: _today()));
    notifyListeners();
  }

  void sellShares(Property property, int shares, int price) {
    final gross = shares * price;
    final fee = (gross * (property.fees['exit']! / 100)).round();
    final net = gross - fee;
    final idx = holdings.indexWhere((h) => h.property.id == property.id);
    if (idx >= 0) {
      final h = holdings[idx];
      final remaining = h.shares - shares;
      if (remaining <= 0) {
        holdings.removeAt(idx);
      } else {
        h.invested = (h.invested * remaining / h.shares).round();
        h.shares = remaining;
      }
    }
    balance += net;
    txns.insert(0, Txn(id: _tid(), type: 'sale', label: 'Sold · ${property.area}', amount: net, date: _today()));
    notifyListeners();
  }
}

final store = AppStore();