import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ntrip_accounts_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MyNtripAccounts extends ConsumerWidget {
  const MyNtripAccounts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(ntripAccountsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Tài khoản NTRIP',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [SizedBox(width: 4)],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _EmptyStateWidget(
              onAdd: () => context.push('/user/packages'),
              onRefresh: () => ref.refresh(ntripAccountsProvider.future),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(ntripAccountsProvider.future),
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderSection(
                    count: accounts.length,
                    onRefresh: () => ref.refresh(ntripAccountsProvider.future),
                  ),
                ),
                SliverList.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AccountCard(account: accounts[index]),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: _FooterAddSection(
                    onAdd: () => context.push('/user/packages'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/user/packages'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: isDark ? const Color(0xFF0B0F14) : Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Thêm tài khoản',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  const _EmptyStateWidget({required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: _HeaderSection(
              count: 0,
              onRefresh: onRefresh,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
                  ),
                  child: Icon(Icons.person_off_rounded, size: 56, color: mutedText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bạn chưa có tài khoản NTRIP nào',
                  style: TextStyle(color: mutedText, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tạo tài khoản'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: isDark ? const Color(0xFF0B0F14) : Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int count;
  final VoidCallback onRefresh;

  const _HeaderSection({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách thiết bị',
                  style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count Tài khoản',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.8)),
              ),
              child: Icon(Icons.refresh_rounded, color: mutedText, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final dynamic account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF14181F) : colorScheme.surface;
    final cardBorder = isDark ? const Color(0xFF1F2937) : colorScheme.outlineVariant;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    final isActive = account.isActive == true;
    final statusColor = isActive ? const Color(0xFF22C55E) : colorScheme.error;
    final statusLabel = isActive ? 'Đang chạy' : 'Tạm dừng';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.username,
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C2B2F) : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF164E63) : colorScheme.primaryContainer),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sell_rounded,
                  size: 16,
                  color: isDark ? AppTheme.primaryLight : colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gói cước: ${account.packageName}',
                  style: TextStyle(
                    color: isDark ? AppTheme.primaryLight : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TechInfoTile(
                  icon: Icons.vpn_key_rounded,
                  label: 'MẬT KHẨU',
                  value: account.password,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TechInfoTile(
                  icon: Icons.cell_tower_rounded,
                  label: 'MOUNTPOINT',
                  value: account.mountpoint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NGÀY HẾT HẠN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.expiryDate != null ? dateFormat.format(account.expiryDate!) : 'Không giới hạn',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _AccountActionButton(
                label: 'Chi tiết',
                isPrimary: false,
                isDark: isDark,
                colorScheme: colorScheme,
                onPressed: () => _showDetailsDialog(context, dateFormat),
              ),
              const SizedBox(width: 8),
              _AccountActionButton(
                label: 'Gia hạn',
                isPrimary: true,
                isDark: isDark,
                colorScheme: colorScheme,
                onPressed: () => context.push('/user/packages'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, DateFormat dateFormat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết tài khoản: ${account.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(icon: Icons.person, label: 'Tên ĐN:', value: account.username),
            _DetailRow(icon: Icons.vpn_key, label: 'Mật khẩu:', value: account.password),
            _DetailRow(icon: Icons.cell_tower, label: 'Mountpoint:', value: account.mountpoint),
            _DetailRow(icon: Icons.sell, label: 'Gói cước:', value: account.packageName),
            _DetailRow(
              icon: Icons.event, 
              label: 'Hết hạn:', 
              value: account.expiryDate != null ? dateFormat.format(account.expiryDate!) : 'Không giới hạn'
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;

  const _AccountActionButton({
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.colorScheme,
    required this.onPressed,
  });

  static const _height = 36.0;
  static const _radius = 10.0;
  static const _textStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
    final accentFg = isDark ? const Color(0xFF0B0F14) : Colors.white;

    if (isPrimary) {
      return SizedBox(
        height: _height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: accentFg,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(84, _height),
            shape: shape,
            textStyle: _textStyle,
          ),
          child: Text(label),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          backgroundColor: isDark ? const Color(0xFF0F172A) : colorScheme.surface,
          side: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.45 : 0.35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(76, _height),
          shape: shape,
          textStyle: _textStyle,
        ),
        child: Text(label),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseTextColor = colorScheme.onSurface;
    final labelColor = baseTextColor.withOpacity(0.65);
    final valueColor = isHighlight ? colorScheme.primary : baseTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
          const Spacer(),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF1F2937) : colorScheme.outlineVariant;
    final tileColor = isDark ? const Color(0xFF0F131A) : colorScheme.surfaceVariant;
    final labelColor = colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterAddSection extends StatelessWidget {
  final VoidCallback onAdd;

  const _FooterAddSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          CustomPaint(
            painter: _DashedRectPainter(
              color: colorScheme.outlineVariant.withOpacity(isDark ? 0.5 : 0.8),
              radius: 14,
              strokeWidth: 1,
              dashLength: 6,
              gapLength: 6,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                children: [
                  Text(
                    'Bạn đã xem hết danh sách',
                    style: TextStyle(color: mutedText, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thêm tài khoản mới để tiếp tục kết nối',
                    style: TextStyle(color: mutedText.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
