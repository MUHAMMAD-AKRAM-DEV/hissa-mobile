// ============================================================
//  lib/services/property_service.dart  —  Data layer.
//  Goes in:  hissa_mobile/lib/services/property_service.dart  (replace all)
//
//  Real mode: loads /properties, then fetches each property's
//  images from /properties/:id/images and builds full URLs.
// ============================================================

import '../config.dart';
import '../models/property.dart';
import 'api_client.dart';

// turn "uploads\properties\123.jpg" into a full URL the app can load
String imageUrl(String path) => '$apiBaseUrl/${path.replaceAll(r'\', '/')}';

class PropertyService {
  Future<List<Property>> getProperties() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return mockProperties;
    }

    final data = await apiClient.getJson('/properties') as List;
    final props = data.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();

    // fetch images for every property in parallel, then attach
    await Future.wait(props.map((p) async {
      try {
        final imgs = await apiClient.getJson('/properties/${p.id}/images') as List;
        final urls = imgs
            .map((e) => imageUrl((e as Map)['imagePath'].toString()))
            .toList()
            .cast<String>();
        if (urls.isNotEmpty) p.images
          ..clear()
          ..addAll(urls);
      } catch (_) {
        // keep the placeholder if this call fails
      }
    }));

    return props;
  }

  Future<Property> getProperty(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return mockProperties.firstWhere((p) => p.id == id);
    }
    final data = await apiClient.getJson('/properties/$id') as Map<String, dynamic>;
    final p = Property.fromJson(data);
    try {
      final imgs = await apiClient.getJson('/properties/$id/images') as List;
      final urls = imgs.map((e) => imageUrl((e as Map)['imagePath'].toString())).toList().cast<String>();
      if (urls.isNotEmpty) p.images..clear()..addAll(urls);
    } catch (_) {}
    return p;
  }
}

String _photo(String seed) => 'https://picsum.photos/seed/$seed/800/520';

final List<Property> mockProperties = [
  Property(
    id: 'p1', title: '2-Bed Apartment, DHA Phase 6', city: 'Karachi', area: 'DHA Phase 6',
    type: 'Residential', status: 'funding',
    images: [_photo('hissa-dha-1'), _photo('hissa-dha-2'), _photo('hissa-dha-3')],
    totalValue: 52750000, sharePrice: 10000, totalShares: 5275, sharesSold: 3890,
    investors: 412, occupancy: 100, expectedYield: 7.6, projectedAppreciation: 5.0,
    fundingDeadline: '2026-08-15', holdingPeriod: '5 years', distribution: 'Monthly', shariah: true,
    fees: {'acquisition': 1.5, 'management': 0.7, 'exit': 1.5},
    description: 'A tenanted two-bedroom apartment in DHA Phase 6.',
    highlights: ['Prime location', 'Already tenanted'], documents: ['Valuation report'],
  ),
];