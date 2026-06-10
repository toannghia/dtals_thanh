import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/modern_card.dart';

class EndUserDashboard extends ConsumerWidget {
  const EndUserDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: _buildTopAppBar(context, isDark),
      body: SafeArea(
        child: dashboardState.isLoading
            ? _buildLoading()
            : RefreshIndicator(
                onRefresh: () => ref.read(dashboardProvider.notifier).loadData(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildHeroCard(context, dashboardState.data, isDark),
                    const SizedBox(height: 14),
                    _buildQuickActions(context),
                    const SizedBox(height: 14),
                    _buildStatusSection(context, dashboardState.data, isDark),
                    const SizedBox(height: 14),
                    _buildPendingNtrip(context, dashboardState.data),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.background.withOpacity(isDark ? 0.0 : 0.0),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
            ),
            child: Icon(Icons.satellite_alt_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DTALS',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.3)),
              Text('Trải nghiệm thao tác nhanh',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      )),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _skeletonHero(),
        const SizedBox(height: 14),
        _skeletonQuickActions(),
        const SizedBox(height: 14),
        _skeletonSection(),
        const SizedBox(height: 14),
        _skeletonSection(height: 170),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, dynamic data, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    final int step = data.activeStep;
    final String stepTitle = switch (step) {
      1 => 'Hoàn tất eKYC để bắt đầu',
      2 => 'Tạo tài khoản NTRIP của bạn',
      3 => 'Kích hoạt gói cước',
      _ => 'Sẵn sàng sử dụng dịch vụ',
    };

    final String stepSubtitle = switch (step) {
      1 => 'Chỉ mất vài phút • dễ thao tác',
      2 => 'Chọn gói phù hợp • thanh toán nhanh',
      3 => 'Kiểm tra thông tin • thanh toán 1 lần',
      _ => 'Mọi thứ đã sẵn sàng • bạn có thể quản lý ngay',
    };

    final Color accent = switch (step) {
      1 => AppTheme.primaryColor,
      2 => AppTheme.primaryColor,
      3 => AppTheme.warningColor,
      _ => AppTheme.successColor,
    };

    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Container(
            height: 176,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(isDark ? 0.22 : 0.10),
                  cs.surface.withOpacity(isDark ? 0.22 : 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(isDark ? 0.12 : 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.white),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Text('Trạng thái',
                              style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  stepTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  stepSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (step == 1) {
                              context.push('/user/ekyc');
                              return;
                            }
                            if (step == 2) {
                              context.push('/user/ntrip-accounts');
                              return;
                            }
                            if (step == 3) {
                              context.push('/user/orders');
                              return;
                            }
                            context.push('/user/ntrip-accounts');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            switch (step) {
                              1 => 'Bắt đầu eKYC',
                              2 => 'Tạo tài khoản NTRIP',
                              3 => 'Thanh toán & kích hoạt',
                              _ => 'Quản lý dịch vụ',
                            },
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget action({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? accent,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            height: 92,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.75)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: accent ?? cs.primary),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Thao tác nhanh',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        ),
        Row(
          children: [
            Expanded(
              child: action(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Tài khoản NTRIP',
                onTap: () => context.push('/user/ntrip-accounts'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: action(
                icon: Icons.inventory_2_rounded,
                title: 'Gói cước',
                onTap: () => context.push('/user/packages'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: action(
                icon: Icons.map_outlined,
                title: 'Bản đồ trạm',
                onTap: () => context.push('/user/map'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: action(
                icon: Icons.support_agent_rounded,
                title: 'Hỗ trợ',
                onTap: () => context.push('/user/support'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: action(
                icon: Icons.person_rounded,
                title: 'Hồ sơ cá nhân',
                onTap: () => context.push('/user/profile'),
                accent: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: action(
                icon: Icons.receipt_long_rounded,
                title: 'Đơn hàng / thanh toán',
                onTap: () => context.push('/user/orders'),
                accent: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, dynamic data, bool isDark) {
    final cs = Theme.of(context).colorScheme;

    final String kycText = data.ekycStatus == 'APPROVED' || data.ekycStatus == 'VERIFIED'
        ? 'Đã xác thực'
        : (data.ekycStatus == 'REJECTED' ? 'Bị từ chối' : 'Chờ xử lý');

    final Color kycAccent = data.ekycStatus == 'APPROVED' || data.ekycStatus == 'VERIFIED'
        ? AppTheme.successColor
        : (data.ekycStatus == 'REJECTED' ? AppTheme.errorColor : AppTheme.warningColor);

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Text('Trạng thái tổng quan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statusChip(
                  title: 'Tài khoản NTRIP',
                  value: '${data.ntripCount}',
                  accent: AppTheme.primaryColor,
                  icon: Icons.cell_tower_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statusChip(
                  title: 'eKYC',
                  value: kycText,
                  accent: kycAccent,
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.pendingOrdersCount > 0)
            _statusBar(
              label: 'Đơn hàng chờ thanh toán',
              value: '${data.pendingOrdersCount} đơn',
              accent: AppTheme.warningColor,
              icon: Icons.pending_actions_rounded,
              onTap: () => context.push('/user/orders'),
            )
          else
            _statusBar(
              label: 'Đang ổn định',
              value: 'Không có đơn chờ',
              accent: AppTheme.successColor,
              icon: Icons.check_circle_rounded,
              onTap: () => context.push('/user/packages'),
            ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String title,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNtrip(BuildContext context, dynamic data) {
    final pending = (data.pendingNtrips ?? []) as List? ?? [];
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse_rounded, color: AppTheme.warningColor, size: 22),
              const SizedBox(width: 10),
              Text('Tài khoản NTRIP chờ kích hoạt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.take(3).map((p) {
            final name = p.accountName?.toString() ?? p['accountName']?.toString() ?? 'Tài khoản';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text('Chờ', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
          if (pending.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/user/ntrip-accounts'),
                child: const Text('Xem tất cả'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _skeletonHero() {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _skeletonQuickActions() {
    return Row(
      children: [
        Expanded(child: _skeletonSection(height: 92)),
        const SizedBox(width: 12),
        Expanded(child: _skeletonSection(height: 92)),
      ],
    );
  }

  Widget _skeletonSection({double height = 120}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
