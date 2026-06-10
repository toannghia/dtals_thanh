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
    if (!isKycVerified) return 1;
    if (pendingOrdersCount > 0) return 3;
    if (ntripCount == 0) return 2;
    return 4;
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
