import '../../../../../core/network/api_client.dart';

class FinanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getRevenueSummary({required DateTime start, required DateTime end}) async {
    final response = await _apiClient.dio.get('/admin/revenue/summary', queryParameters: {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });
    return response.data;
  }

  Future<List<dynamic>> getRevenueChart({required DateTime start, required DateTime end}) async {
    final response = await _apiClient.dio.get('/admin/revenue/chart', queryParameters: {
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });
    return response.data;
  }
}
