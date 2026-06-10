import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../finance/data/finance_repository.dart';

// Provider cho summary
final revenueReportSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final start = DateTime.parse(parts[0]);
  final end = DateTime.parse(parts[1]);
  return FinanceRepository().getRevenueSummary(start: start, end: end);
});

// Provider cho chart data
final revenueChartProvider =
    FutureProvider.family<List<dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final start = DateTime.parse(parts[0]);
  final end = DateTime.parse(parts[1]);
  return FinanceRepository().getRevenueChart(start: start, end: end);
});

// ─── Theme-aware color helper ────────────────────────────────────────────────

class _C {
  final ColorScheme cs;
  final bool dark;

  _C(BuildContext ctx)
      : cs = Theme.of(ctx).colorScheme,
        dark = Theme.of(ctx).brightness == Brightness.dark;

  // Backgrounds
  Color get bg      => dark ? const Color(0xFF0D1B2A) : cs.surface;
  Color get surface => dark ? const Color(0xFF16263B) : cs.surfaceContainerLow;
  Color get card    => dark ? const Color(0xFF1A2D42) : cs.surfaceContainerHighest;
  Color get input   => dark ? const Color(0xFF1A2B3E) : cs.surfaceContainer;

  // Borders / dividers
  Color get border  => dark ? const Color(0xFF243B55) : cs.outlineVariant;

  // Text
  Color get text    => cs.onSurface;
  Color get sub     => cs.onSurfaceVariant;

  // Accent (primary)
  Color get accent  => cs.primary;
  Color get onAccent => cs.onPrimary;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class RevenueReportScreen extends ConsumerStatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  ConsumerState<RevenueReportScreen> createState() =>
      _RevenueReportScreenState();
}

class _RevenueReportScreenState extends ConsumerState<RevenueReportScreen> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();
  String _period = '30d'; // '7d', '30d', '90d', 'custom'

  String get _providerKey =>
      '${_start.toIso8601String()}|${_end.toIso8601String()}';

  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  void _setPeriod(String period) {
    DateTime now = DateTime.now();
    DateTime start;
    switch (period) {
      case '7d':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        start = now.subtract(const Duration(days: 30));
        break;
      case '90d':
        start = now.subtract(const Duration(days: 90));
        break;
      default:
        return;
    }
    setState(() {
      _period = period;
      _start = start;
      _end = now;
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      builder: (context, child) {
        final colors = _C(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colors.dark
                ? ColorScheme.dark(
                    primary: colors.accent,
                    surface: colors.surface,
                    onSurface: colors.text,
                  )
                : ColorScheme.light(
                    primary: colors.accent,
                    surface: colors.surface,
                    onSurface: colors.text,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _period = 'custom';
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final summaryAsync = ref.watch(revenueReportSummaryProvider(_providerKey));
    final chartAsync = ref.watch(revenueChartProvider(_providerKey));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(revenueReportSummaryProvider(_providerKey));
            ref.invalidate(revenueChartProvider(_providerKey));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            children: [
              // Period Selector Row
              _buildPeriodSelector(c),
              const SizedBox(height: 10),
              
              // Date range label
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range_rounded, color: c.accent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${_dateFormat.format(_start)}  →  ${_dateFormat.format(_end)}',
                        style: TextStyle(
                            color: c.sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Summary cards
              summaryAsync.when(
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: c.accent),
                  ),
                ),
                error: (err, _) => _buildError(c, 'Lỗi tải tổng quan: $err'),
                data: (summary) => _buildSummarySection(c, summary),
              ),

              const SizedBox(height: 20),

              // Chart header
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10),
                child: Text(
                  'BIỂU ĐỒ DOANH THU',
                  style: TextStyle(
                    color: c.sub,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              
              // Chart area
              chartAsync.when(
                loading: () => SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator(color: c.accent)),
                ),
                error: (err, _) => _buildError(c, 'Lỗi tải biểu đồ: $err'),
                data: (data) => _buildBarChart(c, data),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Period selector custom view ───────────────────────────────────────────

  Widget _buildPeriodSelector(_C c) {
    final options = [
      ('7d', '7 ngày'),
      ('30d', '30 ngày'),
      ('90d', '90 ngày'),
      ('custom', 'Tùy chọn'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = _period == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PeriodChip(
              c: c,
              label: opt.$2,
              selected: isSelected,
              onTap: () {
                if (opt.$1 == 'custom') {
                  _pickCustomRange();
                } else {
                  _setPeriod(opt.$1);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary Cards custom view ─────────────────────────────────────────────

  Widget _buildSummarySection(_C c, Map<String, dynamic> summary) {
    final totalRevenue = (summary['totalRevenue'] ?? 0) as num;
    final totalOrders = summary['totalOrders'] ?? 0;
    final paidOrders = summary['paidOrders'] ?? 0;
    final pendingOrders = (totalOrders is num && paidOrders is num)
        ? totalOrders - paidOrders
        : 0;

    return Column(
      children: [
        // Big revenue card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tổng doanh thu thực tế',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currencyFormat.format(totalRevenue),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        
        // Stat cards row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                c,
                'Tổng đơn',
                '$totalOrders',
                Icons.receipt_long_rounded,
                const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                c,
                'Đã thanh toán',
                '$paidOrders',
                Icons.check_circle_rounded,
                const Color(0xFF22D37E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                c,
                'Chờ xử lý',
                '$pendingOrders',
                Icons.hourglass_top_rounded,
                const Color(0xFFFF8C42),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Stat Card builder ──────────────────────────────────────────────────────

  Widget _buildStatCard(
      _C c, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: c.sub, fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Bar Chart custom view ──────────────────────────────────────────────────

  Widget _buildBarChart(_C c, List<dynamic> data) {
    if (data.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text(
            'Không có dữ liệu biểu đồ',
            style: TextStyle(color: c.sub),
          ),
        ),
      );
    }

    // Parse data from API: [{date, revenue}]
    final spots = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final revenue = (item['revenue'] ?? item['totalRevenue'] ?? 0) as num;
      final y = revenue.toDouble();
      if (y > maxY) maxY = y;
      spots.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: y,
            color: c.accent,
            width: data.length > 20 ? 4 : 10,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY == 0 ? 100 : maxY * 1.2,
              color: c.accent.withValues(alpha: 0.05),
            ),
          ),
        ],
      ));
    }

    // Build x-axis label from first/last date
    String firstDate = '';
    String lastDate = '';
    if (data.isNotEmpty) {
      final rawFirst = data.first['date'] ?? '';
      final rawLast = data.last['date'] ?? '';
      try {
        firstDate = DateFormat('dd/MM').format(DateTime.parse(rawFirst));
        lastDate = DateFormat('dd/MM').format(DateTime.parse(rawLast));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 100 : maxY * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                      color: c.border.withValues(alpha: 0.4), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          _shortMoney(value),
                          style: TextStyle(fontSize: 10, color: c.sub, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i == 0 && firstDate.isNotEmpty) {
                          return Text(firstDate,
                              style: TextStyle(fontSize: 10, color: c.sub, fontWeight: FontWeight.bold));
                        }
                        if (i == data.length - 1 && lastDate.isNotEmpty) {
                          return Text(lastDate,
                              style: TextStyle(fontSize: 10, color: c.sub, fontWeight: FontWeight.bold));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: spots,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.surface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x];
                      String dateLabel = '';
                      try {
                        dateLabel = DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(item['date'] ?? ''));
                      } catch (_) {}
                      return BarTooltipItem(
                        '$dateLabel\n${_currencyFormat.format(rod.toY)}',
                        TextStyle(
                            color: c.text,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (firstDate.isNotEmpty && lastDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.sub, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '$firstDate – $lastDate  •  ${data.length} điểm dữ liệu',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.sub),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _shortMoney(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildError(_C c, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C5C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5C5C).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5C5C)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(msg, style: const TextStyle(color: Color(0xFFFF5C5C), fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// ─── _PeriodChip ─────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final _C c;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.c,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selColor = Color(0xFF22D3EE); // Cyan
    const selBg = Color(0xFF11374A); // Harmonized slate cyan bg
    final unselBg = c.card;
    final unselBorder = c.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selBg : unselBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selColor : unselBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selColor : c.sub,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
