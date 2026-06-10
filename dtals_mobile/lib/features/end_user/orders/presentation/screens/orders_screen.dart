import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../data/order_repository.dart';
import '../providers/orders_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_toast.dart';

class _OrdersPageColors {
  final Color background;
  final Color card;
  final Color cardInset;
  final Color border;
  final Color accent;
  final Color onSurface;
  final Color label;
  final Color muted;
  final Color payButtonFg;

  const _OrdersPageColors._({
    required this.background,
    required this.card,
    required this.cardInset,
    required this.border,
    required this.accent,
    required this.onSurface,
    required this.label,
    required this.muted,
    required this.payButtonFg,
  });

  factory _OrdersPageColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (isDark) {
      return const _OrdersPageColors._(
        background: Color(0xFF121212),
        card: Color(0xFF1E1E1E),
        cardInset: Color(0xFF161616),
        border: Color(0xFF2A3340),
        accent: Color(0xFF4FC3F7),
        onSurface: Color(0xFFFFFFFF),
        label: Color(0xFF94A3B8),
        muted: Color(0xFF64748B),
        payButtonFg: Color(0xFF0B0F14),
      );
    }

    return _OrdersPageColors._(
      background: AppTheme.backgroundColor,
      card: AppTheme.surfaceColor,
      cardInset: const Color(0xFFF1F5F9),
      border: const Color(0xFFE2E8F0),
      accent: scheme.primary,
      onSurface: AppTheme.textPrimary,
      label: AppTheme.textSecondary,
      muted: AppTheme.textSecondary.withValues(alpha: 0.85),
      payButtonFg: Colors.white,
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _statusFilter;

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    if (_statusFilter == null || _statusFilter!.isEmpty) return orders;
    final filter = _statusFilter!.toUpperCase();
    if (filter == 'PAID') {
      return orders.where((o) {
        final s = o.status.toUpperCase();
        return s == 'PAID' || s == 'COMPLETED';
      }).toList();
    }
    return orders.where((o) => o.status.toUpperCase() == filter).toList();
  }

  String _filterLabel() {
    return switch (_statusFilter?.toUpperCase()) {
      'PENDING' => 'Chờ thanh toán',
      'PAID' => 'Đã thanh toán',
      'COMPLETED' => 'Đã thanh toán',
      'CANCELLED' => 'Đã hủy',
      _ => 'Tất cả',
    };
  }

  Future<void> _showFilterSheet() async {
    final c = _OrdersPageColors.of(context);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget tile(String? value, String label) {
          final isSelected = _statusFilter == value ||
              (value == 'PAID' && _statusFilter == 'COMPLETED');
          return ListTile(
            title: Text(label, style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w600)),
            trailing: isSelected ? Icon(Icons.check_rounded, color: c.accent) : null,
            onTap: () => Navigator.pop(ctx, value),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lọc đơn hàng',
                  style: TextStyle(color: c.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              tile(null, 'Tất cả'),
              tile('PENDING', 'Chờ thanh toán'),
              tile('PAID', 'Đã thanh toán'),
              tile('CANCELLED', 'Đã hủy'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _statusFilter = selected);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final c = _OrdersPageColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'Lịch sử đơn hàng',
            style: TextStyle(
              color: c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.history_rounded, color: c.onSurface),
              onPressed: () => ref.refresh(ordersProvider.future),
              tooltip: 'Làm mới',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: c.border),
          ),
        ),
        body: ordersAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: c.accent)),
          error: (err, stack) => Center(
            child: Text('Lỗi: $err', style: TextStyle(color: c.muted)),
          ),
          data: (orders) {
            final filtered = _applyFilter(orders);
            if (orders.isEmpty) {
              return _EmptyStateWidget(colors: c);
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(ordersProvider.future),
              color: c.accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _OrdersSectionHeader(
                      count: filtered.length,
                      filterLabel: _filterLabel(),
                      onFilterTap: _showFilterSheet,
                      colors: c,
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Không có đơn phù hợp bộ lọc',
                          style: TextStyle(color: c.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _OrderCard(order: filtered[index], colors: c);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrdersSectionHeader extends StatelessWidget {
  final int count;
  final String filterLabel;
  final VoidCallback onFilterTap;
  final _OrdersPageColors colors;

  const _OrdersSectionHeader({
    required this.count,
    required this.filterLabel,
    required this.onFilterTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Text(
            'Đơn hàng gần đây',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: colors.payButtonFg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lọc theo',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final _OrdersPageColors colors;

  const _EmptyStateWidget({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardInset,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, size: 64, color: colors.muted),
          ),
          const SizedBox(height: 24),
          Text(
            'Bạn chưa có đơn hàng nào',
            style: TextStyle(color: colors.muted, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final _OrdersPageColors colors;

  const _OrderCard({required this.order, required this.colors});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isLoadingPayment = false;

  bool get _isPending {
    final s = widget.order.status.toUpperCase();
    return s == 'PENDING';
  }

  bool get _isPaid {
    final s = widget.order.status.toUpperCase();
    return s == 'PAID' || s == 'COMPLETED';
  }

  String get _statusLabel {
    if (_isPaid) return 'ĐÃ THANH TOÁN';
    if (widget.order.status.toUpperCase() == 'CANCELLED') return 'ĐÃ HỦY';
    return 'CHỜ THANH TOÁN';
  }

  IconData get _statusIcon {
    if (_isPaid) return Icons.check_circle_outline_rounded;
    if (widget.order.status.toUpperCase() == 'CANCELLED') return Icons.cancel_outlined;
    return Icons.access_time_rounded;
  }

  static String _formatPrice(double price) {
    if (price == 0) return '0';
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final orderCode = widget.order.displayOrderCode;
    final accountName = widget.order.ntripAccountName?.trim();

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MÃ ĐƠN HÀNG',
                        style: TextStyle(
                          color: c.label,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderCode,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 16, color: c.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.cardInset,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_offer_outlined, size: 20, color: c.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GÓI CƯỚC',
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.order.packageName.isNotEmpty
                              ? widget.order.packageName
                              : '—',
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (accountName != null && accountName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_circle_outlined, size: 18, color: c.muted),
                  const SizedBox(width: 8),
                  Text(
                    'Tài khoản:',
                    style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      accountName,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: c.border.withValues(alpha: 0.7)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NGÀY TẠO',
                        style: TextStyle(
                          color: c.label,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: c.muted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateFormat.format(widget.order.createdAt.toLocal()),
                              style: TextStyle(
                                color: c.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TỔNG TIỀN',
                      style: TextStyle(
                        color: c.label,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatPrice(widget.order.amount)} đ',
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingPayment
                      ? null
                      : () async {
                          setState(() => _isLoadingPayment = true);
                          try {
                            final orderRepo = OrderRepository();
                            final result = await orderRepo.createCheckout(widget.order.id);
                            if (!mounted) return;
                            if (result['checkoutUrl'] != null) {
                              context.push(
                                '/user/checkout?url=${Uri.encodeComponent(result['checkoutUrl'])}',
                              );
                            } else {
                              AppToast.show(
                                context,
                                'Không thể lấy link thanh toán',
                                type: AppToastType.error,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
                            }
                          } finally {
                            if (mounted) setState(() => _isLoadingPayment = false);
                          }
                        },
                  icon: _isLoadingPayment
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.payButtonFg,
                          ),
                        )
                      : Icon(Icons.account_balance_wallet_outlined, color: c.payButtonFg, size: 20),
                  label: Text(
                    'Thanh toán ngay',
                    style: TextStyle(
                      color: c.payButtonFg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.payButtonFg,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
