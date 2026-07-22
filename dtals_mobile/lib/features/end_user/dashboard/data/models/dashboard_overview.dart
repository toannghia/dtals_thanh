// lib/features/end_user/dashboard/data/models/dashboard_overview.dart

class DashboardOverview {
  final String ekycStatus;
  final int ntripCount;
  final int pendingOrdersCount;
  final List<PendingNtrip> pendingNtrips;

  DashboardOverview({
    required this.ekycStatus,
    required this.ntripCount,
    required this.pendingOrdersCount,
    required this.pendingNtrips,
  });

  factory DashboardOverview.initial() => DashboardOverview(
        ekycStatus: 'NONE',
        ntripCount: 0,
        pendingOrdersCount: 0,
        pendingNtrips: [],
      );

  bool get isKycVerified => ekycStatus == 'APPROVED' || ekycStatus == 'VERIFIED';

  int get activeStep {
    if (!isKycVerified) return 2; // Step 2: eKYC (Step 1 is Register, already done)
    if (pendingOrdersCount > 0) return 4; // Step 4: Payment
    if (ntripCount == 0) return 3; // Step 3: Create NTRIP
    return 5; // Step 5: Active
  }
}

class PendingNtrip {
  final String id;
  final String accountName;
  final String packageName;

  PendingNtrip({
    required this.id,
    required this.accountName,
    required this.packageName,
  });
}
