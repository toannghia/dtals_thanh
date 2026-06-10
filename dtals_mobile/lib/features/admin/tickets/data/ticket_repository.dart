import '../../../../../core/network/api_client.dart';
import 'models/ticket.dart';

class TicketRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Ticket>> listTickets() async {
    final response = await _apiClient.dio.get('/tickets');
    final List data = response.data ?? [];
    return data.map((e) => Ticket.fromJson(e)).toList();
  }

  Future<Ticket> getDetail(String id) async {
    final response = await _apiClient.dio.get('/tickets/$id');
    return Ticket.fromJson(response.data);
  }

  Future<void> updateStatus(String id, String status, String note) async {
    await _apiClient.dio.patch('/tickets/$id/status', data: {
      'status': status,
      'adminNote': note,
    });
  }

  Future<void> createTicket(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/tickets', data: data);
  }
}
