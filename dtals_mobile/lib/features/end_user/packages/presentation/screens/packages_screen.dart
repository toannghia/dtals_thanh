import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/packages_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../admin/ntrip/data/models/ntrip_package.dart';
import '../../../ntrip_accounts/data/ntrip_account_repository.dart';
import '../../../orders/data/order_repository.dart';

class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói cước NTRIP'),
      ),
      backgroundColor: colorScheme.background,
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (packages) {
          if (packages.isEmpty) {
            return const Center(child: Text('Không có gói cước nào.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(packagesProvider.notifier).refresh(),
            color: AppTheme.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final pkg = packages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0) const _PackagesHeader(),
                    _PackageCard(
                      pkg: pkg,
                      isFeatured: index == 1,
                      onBuy: () => _openCreateAccount(context, pkg),
                    ),
                    if (index == packages.length - 1) const _ImportantNote(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _openCreateAccount(BuildContext context, NtripPackage pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _PurchaseBottomSheet(package: pkg),
      ),
    );
  }
}

class _PackagesHeader extends StatelessWidget {
  const _PackagesHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn gói dịch vụ',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Các gói dịch vụ tiện lợi và bảo đảm độ chính xác cao\n'
            'và kết nối ổn định 24/7.',
            style: TextStyle(color: mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final NtripPackage pkg;
  final bool isFeatured;
  final VoidCallback onBuy;

  const _PackageCard({
    required this.pkg,
    required this.isFeatured,
    required this.onBuy,
  });

  List<String> _featureLines() {
    final raw = (pkg.description ?? '').toString().trim();
    if (raw.isEmpty) {
      return [
        'Kết nối ổn định',
        'Độ chính xác cao',
        'Hỗ trợ kỹ thuật 24/7',
      ];
    }
    final split = raw
        .split(RegExp(r'\r?\n|;|\.|\u2022|-'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return split.isEmpty ? ['Kết nối ổn định', 'Độ chính xác cao', 'Hỗ trợ kỹ thuật 24/7'] : split.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    final softText = colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.5);
    final price = PackagesScreen._formatPrice(pkg.price);
    final cardColor = isDark
        ? (isFeatured ? const Color(0xFF0F172A) : const Color(0xFF11161D))
        : (isFeatured ? colorScheme.surface : colorScheme.surface);
    final borderColor = isFeatured ? colorScheme.primary : colorScheme.outlineVariant;
    final buttonColor = isFeatured ? colorScheme.primary : colorScheme.surfaceVariant;
    final buttonTextColor = isFeatured ? colorScheme.onPrimary : colorScheme.onSurface;
    final chipBg = isDark ? const Color(0xFF0C2B2F) : colorScheme.primaryContainer;
    final chipFg = isDark ? AppTheme.primaryLight : colorScheme.onPrimaryContainer;
    final chipBorder = isDark ? const Color(0xFF164E63) : colorScheme.primaryContainer;
    final checkColor = isDark ? AppTheme.primaryLight : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isFeatured ? 1.4 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pkg.name,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'NỔI BẬT',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: isFeatured ? colorScheme.primary : colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('VND', style: TextStyle(color: softText, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chipBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sell_rounded, size: 14, color: chipFg),
                const SizedBox(width: 6),
                Text(
                  'Gói cước: ${pkg.displayNameWithDuration}',
                  style: TextStyle(color: chipFg, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._featureLines().map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: checkColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                elevation: 0,
                side: isFeatured ? null : BorderSide(color: colorScheme.outlineVariant, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              child: const Text('Mua ngay'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantNote extends StatelessWidget {
  const _ImportantNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F131A) : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: mutedText, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lưu ý quan trọng', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Vui lòng cập nhật thông tin của bạn để tránh\n'
                    'ảnh hưởng đến quá trình kích hoạt và sử dụng dịch vụ.',
                    style: TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màu form mua NTRIP — tự đổi theo chế độ sáng / tối của app.
class _PurchaseSheetColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color accent;
  final Color label;
  final Color muted;
  final Color onSurface;
  final Color badgeBg;
  final Color badgeBorder;
  final Color boltCircleFill;
  final Color boltIcon;
  final Color buttonForeground;

  const _PurchaseSheetColors._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.accent,
    required this.label,
    required this.muted,
    required this.onSurface,
    required this.badgeBg,
    required this.badgeBorder,
    required this.boltCircleFill,
    required this.boltIcon,
    required this.buttonForeground,
  });

  factory _PurchaseSheetColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (isDark) {
      return const _PurchaseSheetColors._(
        background: Color(0xFF121212),
        surface: Color(0xFF1A1F26),
        surfaceElevated: Color(0xFF11161D),
        border: Color(0xFF2A3340),
        accent: AppTheme.primaryColor,
        label: Color(0xFF94A3B8),
        muted: Color(0xFF64748B),
        onSurface: Color(0xFFFFFFFF),
        badgeBg: Color(0xFF0C2B2F),
        badgeBorder: Color(0xFF164E63),
        boltCircleFill: Color(0xFFFFFFFF),
        boltIcon: Color(0xFF121212),
        buttonForeground: Color(0xFF0B0F14),
      );
    }

    return _PurchaseSheetColors._(
      background: AppTheme.surfaceColor,
      surface: AppTheme.backgroundColor,
      surfaceElevated: Colors.white,
      border: const Color(0xFFE2E8F0),
      accent: scheme.primary,
      label: AppTheme.textSecondary,
      muted: AppTheme.textSecondary.withValues(alpha: 0.85),
      onSurface: AppTheme.textPrimary,
      badgeBg: scheme.primary.withValues(alpha: 0.12),
      badgeBorder: scheme.primary.withValues(alpha: 0.35),
      boltCircleFill: scheme.primary,
      boltIcon: Colors.white,
      buttonForeground: Colors.white,
    );
  }
}

/// Form tạo tài khoản NTRIP — hiển thị trong bottom sheet (Mua ngay).
class _PurchaseBottomSheet extends StatefulWidget {
  final NtripPackage package;

  const _PurchaseBottomSheet({super.key, required this.package});

  @override
  State<_PurchaseBottomSheet> createState() => _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends State<_PurchaseBottomSheet> {
  final _accountNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  int _quantity = 1;
  DateTime _startTime = DateTime.now();

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price == 0) return '0';
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _durationUnitLabel(String unit, {bool capitalize = false}) {
    final label = switch (unit) {
      'year' => 'năm',
      'day' => 'ngày',
      _ => 'tháng',
    };
    if (!capitalize) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  String _packageDisplayName() => widget.package.displayNameWithDuration;

  String _usageDurationLabel() {
    final total = (widget.package.duration) * _quantity;
    return '$total ${_durationUnitLabel(widget.package.durationUnit)}';
  }

  DateTime _computeEndDate() {
    final totalDur = widget.package.duration * _quantity;
    final unit = widget.package.durationUnit;
    if (unit == 'day') {
      return _startTime.add(Duration(days: totalDur));
    }
    if (unit == 'year') {
      return DateTime(_startTime.year + totalDur, _startTime.month, _startTime.day);
    }
    return DateTime(_startTime.year, _startTime.month + totalDur, _startTime.day);
  }

  double get _totalPrice => widget.package.price * _quantity;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickQuantity() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final pickerColors = _PurchaseSheetColors.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chọn số lượng',
                  style: TextStyle(
                    color: pickerColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: 24,
                  itemBuilder: (_, i) {
                    final qty = i + 1;
                    return ListTile(
                      title: Text(
                        qty.toString(),
                        style: TextStyle(color: pickerColors.onSurface),
                      ),
                      trailing: qty == _quantity
                          ? Icon(Icons.check_rounded, color: pickerColors.accent)
                          : null,
                      onTap: () => Navigator.pop(ctx, qty),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) setState(() => _quantity = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final accountName = _accountNameCtrl.text.trim();
      if (accountName.isNotEmpty) {
        final existingAccounts = await NtripAccountRepository().getMyAccounts();
        final isDuplicate = existingAccounts.any(
          (a) => a.username.toLowerCase() == accountName.toLowerCase(),
        );
        if (isDuplicate) {
          if (mounted) {
            AppToast.show(
              context,
              'Tên tài khoản NTRIP đã tồn tại. Vui lòng chọn tên khác.',
              type: AppToastType.warning,
            );
          }
          return;
        }
      }

      final orderRepo = OrderRepository();
      final packageId = int.tryParse(widget.package.id);
      if (packageId == null) {
        throw Exception('Invalid packageId: ${widget.package.id}');
      }

      final order = await orderRepo.createOrder(
        ntripAccountName: accountName,
        ntripPassword: _passwordCtrl.text,
        packageId: packageId,
        quantity: _quantity,
        startTime: _startTime.millisecondsSinceEpoch,
      );

      final checkoutRes = await orderRepo.createCheckout(order.id);

      if (!mounted) return;
      if (checkoutRes['checkoutUrl'] != null) {
        final url = Uri.encodeComponent(checkoutRes['checkoutUrl']);
        Navigator.pop(context);
        context.push('/user/checkout?url=$url');
      } else {
        AppToast.show(context, 'Không thể lấy link thanh toán', type: AppToastType.error);
      }
    } catch (e) {
      if (!mounted) return;
      String message = 'Lỗi: $e';
      if (e is DioException && e.response?.data != null) {
        final rawMessage = e.response?.data['message']?.toString() ?? '';
        if (rawMessage.toLowerCase().contains('user name exist')) {
          message = 'Tên tài khoản NTRIP đã tồn tại. Vui lòng chọn tên khác.';
        } else if (rawMessage.isNotEmpty) {
          message = rawMessage;
        }
      }
      AppToast.show(context, message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tạo tài khoản NTRIP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: c.label),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: c.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ServiceBanner(),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      icon: Icons.person_outline_rounded,
                      label: 'THÔNG TIN TRUY CẬP',
                    ),
                    const SizedBox(height: 10),
                    _AccessInfoCard(
                      accountController: _accountNameCtrl,
                      passwordController: _passwordCtrl,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      icon: Icons.layers_outlined,
                      label: 'CẤU HÌNH GÓI CƯỚC',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ConfigField(
                            label: 'SỐ LƯỢNG',
                            value: _quantity.toString(),
                            trailingIcon: Icons.layers_outlined,
                            onTap: _pickQuantity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ConfigField(
                            label: 'NGÀY BẮT ĐẦU',
                            value: _formatDate(_startTime),
                            trailingIcon: Icons.calendar_today_outlined,
                            onTap: _pickStartDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      icon: Icons.shopping_cart_outlined,
                      label: 'TÓM TẮT ĐƠN HÀNG',
                    ),
                    const SizedBox(height: 10),
                    _OrderSummaryCard(
                      packageLabel: _packageDisplayName(),
                      quantity: _quantity,
                      usageDuration: _usageDurationLabel(),
                      endDate: _formatDate(_computeEndDate()),
                      totalPrice: '${_formatPrice(_totalPrice)} VNĐ',
                    ),
                    const SizedBox(height: 16),
                    const _ActivationNotice(),
                  ],
                ),
              ),
            ),
            _CheckoutBar(
              isSubmitting: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceBanner extends StatelessWidget {
  const _ServiceBanner();

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.boltCircleFill,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, color: c.boltIcon, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dịch vụ NTRIP PRO',
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Độ chính xác milimet 24/7',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.badgeBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.badgeBorder),
            ),
            child: Text(
              'Chính chủ',
              style: TextStyle(
                color: c.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: c.accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: c.accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _AccessInfoCard extends StatelessWidget {
  final TextEditingController accountController;
  final TextEditingController passwordController;

  const _AccessInfoCard({
    required this.accountController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tên tài khoản',
            style: TextStyle(
              color: c.label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _DarkInputField(
            controller: accountController,
            hint: 'Nhập tên đăng nhập NTRIP...',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên tài khoản' : null,
          ),
          const SizedBox(height: 14),
          Text(
            'Mật khẩu',
            style: TextStyle(
              color: c.label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _DarkInputField(
            controller: passwordController,
            hint: 'Thiết lập mật khẩu bảo mật...',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
          ),
        ],
      ),
    );
  }
}

class _DarkInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _DarkInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: c.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: c.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: c.muted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, color: c.muted, size: 20),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final String label;
  final String value;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _ConfigField({
    required this.label,
    required this.value,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.label,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(trailingIcon, size: 18, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String packageLabel;
  final int quantity;
  final String usageDuration;
  final String endDate;
  final String totalPrice;

  const _OrderSummaryCard({
    required this.packageLabel,
    required this.quantity,
    required this.usageDuration,
    required this.endDate,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          _summaryRow(c, 'Gói cước:', packageLabel),
          _summaryRow(c, 'Số lượng:', 'x$quantity'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thời gian sử dụng:',
                  style: TextStyle(color: c.label, fontSize: 13),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: c.accent),
                    const SizedBox(width: 4),
                    Text(
                      usageDuration,
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _summaryRow(c, 'Ngày kết thúc:', endDate, valueColor: c.accent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: c.border),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG THANH TOÁN',
                      style: TextStyle(
                        color: c.label,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 13, color: c.muted),
                        const SizedBox(width: 4),
                        Text(
                          'Miễn phí phí khởi tạo',
                          style: TextStyle(
                            color: c.muted.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                totalPrice,
                style: TextStyle(
                  color: c.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(_PurchaseSheetColors c, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.label, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationNotice extends StatelessWidget {
  const _ActivationNotice();

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: c.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tài khoản sẽ được kích hoạt ngay sau khi thanh toán thành công. '
              'Thông tin đăng nhập sẽ được gửi vào Email cá nhân của bạn.',
              style: TextStyle(
                color: c.label,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _CheckoutBar({required this.isSubmitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = _PurchaseSheetColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.buttonForeground,
              disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isSubmitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.buttonForeground),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tiếp tục & Thanh toán',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.buttonForeground),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 22, color: c.buttonForeground),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

