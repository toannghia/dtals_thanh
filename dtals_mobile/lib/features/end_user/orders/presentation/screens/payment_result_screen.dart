import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentResultScreen extends StatelessWidget {
  final String status;
  const PaymentResultScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  isSuccess 
                      ? 'Đơn hàng của bạn đã được thanh toán. Hệ thống sẽ kích hoạt tài khoản trong giây lát.' 
                      : 'Giao dịch không thành công hoặc đã bị hủy. Vui lòng thử lại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => context.go('/user'),
                  child: const Text('Về bảng điều khiển'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
