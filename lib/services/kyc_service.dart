// ============================================================
//  lib/services/kyc_service.dart  —  Verification status.
//  Goes in:  hissa_mobile/lib/services/kyc_service.dart  (NEW file)
//
//  Backend:
//    GET /kyc/status -> {"status":"not_started"}                  (never submitted)
//                    -> {"id":..,"status":"pending"|"approved"|"rejected", ...}
// ============================================================

import 'api_client.dart';

enum KycState { notStarted, pending, approved, rejected, unknown }

class KycStatus {
  final KycState state;
  final String? rejectionReason;
  const KycStatus(this.state, {this.rejectionReason});

  bool get canInvest => state == KycState.approved;

  String get label => switch (state) {
    KycState.notStarted => 'Not verified',
    KycState.pending => 'Under review',
    KycState.approved => 'Verified',
    KycState.rejected => 'Verification rejected',
    KycState.unknown => 'Unknown',
  };

  String get blurb => switch (state) {
    KycState.notStarted => 'Verify your identity to start investing.',
    KycState.pending => 'We’re reviewing your documents. You can browse meanwhile.',
    KycState.approved => 'Your identity is verified.',
    KycState.rejected => rejectionReason ?? 'Your verification was rejected. Please submit again.',
    KycState.unknown => '',
  };
}

class KycService {
  KycStatus? cached;

  // Submit KYC. Backend expects multipart:
  //   cnicNumber, fullNameOnCnic, cnicImage (file), selfieImage (file)
  Future<void> submit({
    required String cnicNumber,
    required String fullNameOnCnic,
    required List<int> cnicBytes,
    required String cnicFilename,
    required List<int> selfieBytes,
    required String selfieFilename,
  }) async {
    await apiClient.postMultipart(
      '/kyc/submit',
      {'cnicNumber': cnicNumber.trim(), 'fullNameOnCnic': fullNameOnCnic.trim()},
      {
        'cnicImage': (bytes: cnicBytes, filename: cnicFilename),
        'selfieImage': (bytes: selfieBytes, filename: selfieFilename),
      },
    );
    cached = null; // force a refresh next time
  }

  Future<KycStatus> getStatus({bool refresh = false}) async {
    if (cached != null && !refresh) return cached!;
    try {
      final res = await apiClient.getJson('/kyc/status') as Map<String, dynamic>;
      final s = (res['status'] ?? '').toString();
      final state = switch (s) {
        'approved' => KycState.approved,
        'pending' => KycState.pending,
        'rejected' => KycState.rejected,
        'not_started' => KycState.notStarted,
        _ => KycState.unknown,
      };
      cached = KycStatus(state, rejectionReason: res['rejectionReason'] as String?);
      return cached!;
    } catch (_) {
      return const KycStatus(KycState.unknown);
    }
  }

  void clear() => cached = null;
}

final kycService = KycService();