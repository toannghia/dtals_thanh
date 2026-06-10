import '../../../../../core/network/api_client.dart';
import 'models/admin_stats.dart';

class AdminDashboardRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AdminStats> getStationStats() async {
    final response = await _apiClient.dio.get('/dtals-dashboard/stations');
    return AdminStats.fromJson(response.data);
  }

  Future<AdminStats> getUserStats() async {
    final response = await _apiClient.dio.get('/dtals-dashboard/users');
    return AdminStats.fromJson(response.data);
  }

  Future<SystemOverview> getOverview() async {
    final response = await _apiClient.dio.get('/dtals-dashboard/overview');
    return SystemOverview.fromJson(response.data);
  }
}
