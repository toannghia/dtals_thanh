import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import 'models/dashboard_overview.dart';

class DashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardOverview> getDashboardData() async {
    String ekycStatus = 'NONE';
    int ntripCount = 0;
    int pendingOrdersCount = 0;
    List<PendingNtrip> pendingNtrips = [];

    // 1. Fetch eKYC Status
    try {
      final ekycRes = await _apiClient.dio.get('/ekyc/status');
      ekycStatus = ekycRes.data['kycStatus'] ?? ekycRes.data['status'] ?? 'NONE';
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        debugPrint('Error fetching eKYC status: $e');
      }
      ekycStatus = 'NONE';
    } catch (e) {
      debugPrint('Unexpected error fetching eKYC status: $e');
      ekycStatus = 'NONE';
    }

    // 2. Fetch NTRIP Count
    try {
      final ntripRes = await _apiClient.dio.get('/ntrip-users', queryParameters: {'page': 1, 'size': 1});
      final resData = ntripRes.data;
      ntripCount = (resData is Map) ? (resData['total'] ?? 0) : 0;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        debugPrint('Error fetching NTRIP count: $e');
      }
      ntripCount = 0;
    } catch (e) {
      debugPrint('Unexpected error fetching NTRIP count: $e');
      ntripCount = 0;
    }

    // 3. Fetch Pending Orders
    if (ekycStatus == 'APPROVED' || ekycStatus == 'VERIFIED') {
      try {
        final orderRes = await _apiClient.dio.get('/orders', queryParameters: {'status': 'PENDING'});
        final resData = orderRes.data;
        final List orders = (resData is Map) ? (resData['items'] ?? resData['data'] ?? []) : (resData as List? ?? []);
        pendingOrdersCount = orders.length;
        pendingNtrips = orders
            .where((o) => o['ntripAccountName'] != null)
            .map((o) => PendingNtrip(
                  id: o['id'].toString(),
                  accountName: o['ntripAccountName'],
                  packageName: o['packageName'] ?? '',
                ))
            .toList();
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
             debugPrint('Error fetching pending orders: $e');
        }
        pendingOrdersCount = 0;
      } catch (e) {
        debugPrint('Unexpected error fetching pending orders: $e');
        pendingOrdersCount = 0;
      }
    }

    return DashboardOverview(
      ekycStatus: ekycStatus,
      ntripCount: ntripCount,
      pendingOrdersCount: pendingOrdersCount,
      pendingNtrips: pendingNtrips,
    );
  }
}
