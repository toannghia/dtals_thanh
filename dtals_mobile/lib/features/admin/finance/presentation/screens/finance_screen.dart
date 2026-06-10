import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/finance_repository.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Use a String key for stable equality to prevent infinite re-fetches
final revenueSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final start = DateTime.parse(parts[0]);
  final end = DateTime.parse(parts[1]);
  final repository = FinanceRepository();
  return repository.getRevenueSummary(start: start, end: end);
});

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();

  String get _providerKey => '${_start.toIso8601String()}|${_end.toIso8601String()}';

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(revenueSummaryProvider(_providerKey));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildRevenueCard(summary['totalRevenue'] ?? 0, currencyFormat),
              const SizedBox(height: 24),
              _buildStatsRow(summary),
              const SizedBox(height: 24),
              const Text('Biểu đồ tăng trưởng (30 ngày)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSimpleLineChart(),
            ],
          );
      },
    );
  }

  Widget _buildRevenueCard(num amount, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng doanh thu', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            format.format(amount),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(child: _buildSmallStat('Đơn hàng', '${summary['totalOrders'] ?? 0}', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildSmallStat('Thanh toán', '${summary['paidOrders'] ?? 0}', Colors.green)),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleLineChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 1),
                FlSpot(1, 2),
                FlSpot(2, 1.5),
                FlSpot(3, 3),
                FlSpot(4, 2.5),
                FlSpot(5, 4),
              ],
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }
}
