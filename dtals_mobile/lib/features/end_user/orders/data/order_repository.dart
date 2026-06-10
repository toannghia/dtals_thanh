import '../../../../../core/config/app_config.dart';
import '../../../../../core/network/api_client.dart';
import 'models/order_model.dart';

class OrderRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<OrderModel>> getMyOrders({String? status}) async {
    final response = await _apiClient.dio.get(
      '/orders',
      queryParameters: status != null ? {'status': status} : null,
    );
    final resData = response.data;
    final List data = (resData is Map) ? (resData['items'] ?? resData['data'] ?? []) : (resData as List? ?? []);
    return data.map((item) => OrderModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> createCheckout(String orderId) async {
    final parsedOrderId = int.tryParse(orderId);
    if (parsedOrderId == null) {
      throw Exception('Invalid orderId: $orderId');
    }
    final baseUrl = AppConfig.baseUrl.toLowerCase();
    final isLocal = baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1') || baseUrl.contains('10.0.2.2');
    if (isLocal) {
      return {
        'checkoutUrl': 'https://example.com/payment-success?orderId=$parsedOrderId'
      };
    }
    final response = await _apiClient.dio.post('/payment/checkout', data: {
      'orderIds': [parsedOrderId],
    });
    return response.data;
  }

  Future<OrderModel> createOrder({
    required String ntripAccountName,
    required String ntripPassword,
    required int packageId,
    int quantity = 1,
    int? startTime,
  }) async {
    final response = await _apiClient.dio.post('/orders', data: {
      'ntripAccountName': ntripAccountName,
      'ntripPassword': ntripPassword,
      'packageId': packageId,
      'quantity': quantity,
      if (startTime != null) 'startTime': startTime,
    });
    return OrderModel.fromJson(response.data);
  }
}
