// ============================================================
//  lib/services/marketplace_service.dart  —  Secondary market.
//  Goes in:  hissa_mobile/lib/services/marketplace_service.dart  (NEW file)
//
//  Backend:
//    POST   /marketplace/listings            {propertyId, shares, pricePerShare}
//    GET    /marketplace/listings[?propertyId=]
//    GET    /marketplace/my-listings
//    DELETE /marketplace/listings/:id
//    POST   /marketplace/listings/:id/buy
//
//  Note: numeric fields come back as strings (pricePerShare, totalPrice).
// ============================================================

import 'api_client.dart';

enum ListingStatus { open, sold, cancelled, unknown }

class Listing {
  final String id, sellerId, propertyId, createdAt;
  final String? buyerId;
  final int shares;
  final double pricePerShare, totalPrice;
  final ListingStatus status;

  Listing({
    required this.id, required this.sellerId, required this.propertyId,
    required this.createdAt, required this.shares, required this.pricePerShare,
    required this.totalPrice, required this.status, this.buyerId,
  });

  static double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
    id: (j['id'] ?? '').toString(),
    sellerId: (j['sellerId'] ?? '').toString(),
    propertyId: (j['propertyId'] ?? '').toString(),
    buyerId: j['buyerId'] as String?,
    createdAt: (j['createdAt'] ?? '').toString(),
    shares: j['shares'] is num ? (j['shares'] as num).toInt() : int.tryParse(j['shares']?.toString() ?? '0') ?? 0,
    pricePerShare: _num(j['pricePerShare']),
    totalPrice: _num(j['totalPrice']),
    status: switch ((j['status'] ?? '').toString()) {
      'open' => ListingStatus.open,
      'sold' => ListingStatus.sold,
      'cancelled' => ListingStatus.cancelled,
      _ => ListingStatus.unknown,
    },
  );

  bool get isOpen => status == ListingStatus.open;

  String get statusLabel => switch (status) {
    ListingStatus.open => 'Listed',
    ListingStatus.sold => 'Sold',
    ListingStatus.cancelled => 'Cancelled',
    ListingStatus.unknown => '—',
  };
}

class MarketplaceService {
  Future<Listing> createListing({
    required String propertyId,
    required int shares,
    required double pricePerShare,
  }) async {
    final res = await apiClient.postJson('/marketplace/listings', {
      'propertyId': propertyId,
      'shares': shares,
      'pricePerShare': pricePerShare,
    }) as Map<String, dynamic>;
    return Listing.fromJson(res);
  }

  // All open listings, optionally for one property.
  Future<List<Listing>> getListings({String? propertyId}) async {
    final path = propertyId == null ? '/marketplace/listings' : '/marketplace/listings?propertyId=$propertyId';
    final res = await apiClient.getJson(path) as List;
    return res.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  // The current user's listings (all statuses).
  Future<List<Listing>> getMyListings() async {
    final res = await apiClient.getJson('/marketplace/my-listings') as List;
    return res.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelListing(String id) async {
    await apiClient.deleteJson('/marketplace/listings/$id');
  }

  // Buy someone else's listing. Returns {exitFee, sellerReceives, totalPaid}.
  Future<Map<String, dynamic>> buyListing(String id) async {
    final res = await apiClient.postJson('/marketplace/listings/$id/buy', {});
    return (res is Map) ? Map<String, dynamic>.from(res) : {};
  }
}

final marketplaceService = MarketplaceService();