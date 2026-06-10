import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/order_repository.dart';
import '../../data/models/order_model.dart';

final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repository = OrderRepository();
  return repository.getMyOrders();
});
