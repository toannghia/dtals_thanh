import '../../../../../core/network/api_client.dart';
import '../../admin/stations/data/models/station.dart';
import '../../admin/tickets/data/models/ticket.dart';

class GovernmentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.dio.get('/government/dashboard');
    return response.data;
  }

  Future<List<Station>> getStations() async {
    final response = await _apiClient.dio.get(
      '/government/stations',
      queryParameters: {'size': 1000},
    );
    final List data = response.data ?? [];
    return data.map((e) => Station.fromJson(e)).toList();
  }

  Future<List<Ticket>> getTicketHistory() async {
    final response = await _apiClient.dio.get('/government/tickets');
    final List data = response.data ?? [];
    return data.map((e) => Ticket.fromJson(e)).toList();
  }

  Future<void> submitControlTicket(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/government/tickets', data: data);
  }
}
