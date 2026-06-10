import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_repository.dart';
import '../../../../core/widgets/app_toast.dart';

class _ProfilePageColors {
  final Color background;
  final Color card;
  final Color border;
  final Color accent;
  final Color onSurface;
  final Color label;
  final Color muted;
  final Color roleChipBg;
  final Color roleChipFg;
  final Color editButtonFg;
  final Color logout;

  const _ProfilePageColors._({
    required this.background,
    required this.card,
    required this.border,
    required this.accent,
    required this.onSurface,
    required this.label,
    required this.muted,
    required this.roleChipBg,
    required this.roleChipFg,
    required this.editButtonFg,
    required this.logout,
  });

  factory _ProfilePageColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (isDark) {
      return const _ProfilePageColors._(
        background: Color(0xFF121212),
        card: Color(0xFF1E1E1E),
        border: Color(0xFF2A3340),
        accent: Color(0xFF4FC3F7),
        onSurface: Color(0xFFFFFFFF),
        label: Color(0xFF94A3B8),
        muted: Color(0xFF64748B),
        roleChipBg: Color(0xFF0C2B2F),
        roleChipFg: Color(0xFF4FC3F7),
        editButtonFg: Color(0xFF0B0F14),
        logout: Color(0xFFEF4444),
      );
    }

    return _ProfilePageColors._(
      background: AppTheme.backgroundColor,
      card: AppTheme.surfaceColor,
      border: const Color(0xFFE2E8F0),
      accent: scheme.primary,
      onSurface: AppTheme.textPrimary,
      label: AppTheme.textSecondary,
      muted: AppTheme.textSecondary.withValues(alpha: 0.85),
      roleChipBg: scheme.primary.withValues(alpha: 0.12),
      roleChipFg: scheme.primary,
      editButtonFg: Colors.white,
      logout: AppTheme.errorColor,
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _formatRoleLabel(String role) {
    final normalized = role.trim();
    if (normalized.isEmpty) return 'Thành viên';
    final upper = normalized.toUpperCase();
    return switch (upper) {
      'END_USER' || 'USER' => 'Người dùng',
      'TECH' => 'Kỹ Thuật Viên Cấp Cao',
      'ADMIN' || 'SUPER_ADMIN' || 'SUPERADMIN' => 'Quản trị viên',
      'ACCOUNTANT' => 'Kế toán',
      'GOV' || 'AUTHORITY' => 'Cơ quan nhà nước',
      _ => normalized,
    };
  }

  static String _themeSubtitle(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => 'Chế độ Tối (Mặc định)',
      ThemeMode.light => 'Chế độ Sáng',
      ThemeMode.system => 'Theo hệ thống',
    };
  }

  /// Tránh bị BottomAppBar + FAB giữa che nội dung cuối trang.
  static double _bottomContentInset(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    const bottomBarHeight = 72.0;
    const fabOverlap = 44.0;
    return viewPadding.bottom + bottomBarHeight + fabOverlap;
  }

  static String _formatPhoneDisplay(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'Chưa cập nhật';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  Future<void> _copyValue(BuildContext context, String value) async {
    if (value.trim().isEmpty || value == 'Chưa cập nhật') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      AppToast.show(context, 'Đã sao chép', type: AppToastType.success);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (shouldLogout == true) {
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final c = _ProfilePageColors.of(context);
    final current = ref.read(themeProvider);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget tile(ThemeMode mode, String label) {
          final selected = current == mode;
          return ListTile(
            title: Text(label, style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w600)),
            trailing: selected ? Icon(Icons.check_rounded, color: c.accent) : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Giao diện hiển thị',
                  style: TextStyle(color: c.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              tile(ThemeMode.dark, 'Chế độ Tối (Mặc định)'),
              tile(ThemeMode.light, 'Chế độ Sáng'),
              tile(ThemeMode.system, 'Theo hệ thống'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);
    final c = _ProfilePageColors.of(context);

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
          // Cân bằng với actions để tiêu đề nằm giữa thanh app bar.
          leadingWidth: 56,
          leading: const SizedBox(width: 56),
          title: Text(
            'Hồ sơ cá nhân',
            style: TextStyle(
              color: c.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout_rounded, color: c.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
        body: profileAsync.when(
          loading: () => _ProfileSkeleton(colors: c),
          error: (err, stack) => Center(
            child: Text('Lỗi: $err', style: TextStyle(color: c.muted)),
          ),
          data: (UserModel user) {
            final displayName = (user.fullName?.trim().isNotEmpty == true)
                ? user.fullName!.trim()
                : user.username;
            final email = user.email?.trim().isNotEmpty == true
                ? user.email!.trim()
                : 'Chưa cập nhật';
            final phone = _formatPhoneDisplay(user.phoneNumber);

            final bottomInset = _bottomContentInset(context);

            return ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              children: [
                _ProfileSummary(
                  colors: c,
                  name: displayName,
                  roleLabel: _formatRoleLabel(user.role),
                  userId: user.id,
                ),
                const SizedBox(height: 24),
                _SectionLabel(text: 'THÔNG TIN TÀI KHOẢN', colors: c),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      _AccountInfoRow(
                        colors: c,
                        icon: Icons.person_outline_rounded,
                        label: 'TÊN ĐĂNG NHẬP',
                        value: user.username,
                        onCopy: () => _copyValue(context, user.username),
                      ),
                      Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
                      _AccountInfoRow(
                        colors: c,
                        icon: Icons.email_outlined,
                        label: 'ĐỊA CHỈ EMAIL',
                        value: email,
                        onCopy: user.email?.isNotEmpty == true
                            ? () => _copyValue(context, email)
                            : null,
                      ),
                      Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
                      _AccountInfoRow(
                        colors: c,
                        icon: Icons.phone_outlined,
                        label: 'SỐ ĐIỆN THOẠI',
                        value: phone,
                        onCopy: user.phoneNumber?.isNotEmpty == true
                            ? () => _copyValue(context, user.phoneNumber!)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel(text: 'TÙY CHỌN ỨNG DỤNG', colors: c),
                const SizedBox(height: 10),
                _OptionCard(
                  colors: c,
                  icon: Icons.history_rounded,
                  title: 'Lịch sử mua hàng',
                  subtitle: 'Xem lại các gói dịch vụ đã đăng ký',
                  onTap: () => context.push('/user/orders'),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  colors: c,
                  icon: Icons.dark_mode_outlined,
                  title: 'Giao diện hiển thị',
                  subtitle: _themeSubtitle(themeMode),
                  onTap: () => _showThemePicker(context, ref),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: false,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) {
                          final height = MediaQuery.sizeOf(ctx).height;
                          return SizedBox(
                            height: height,
                            child: _EditProfileBottomSheet(user: user),
                          );
                        },
                      ).then((value) {
                        if (value == true) {
                          ref.invalidate(profileProvider);
                        }
                      });
                    },
                    icon: Icon(Icons.edit_outlined, color: c.editButtonFg, size: 20),
                    label: Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(
                        color: c.editButtonFg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.editButtonFg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Phiên bản ứng dụng v1.0.0 (Stable)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final _ProfilePageColors colors;

  const _SectionLabel({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.label,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final _ProfilePageColors colors;
  final String name;
  final String roleLabel;
  final String userId;

  const _ProfileSummary({
    required this.colors,
    required this.name,
    required this.roleLabel,
    required this.userId,
  });

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.roleChipBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.roleChipFg.withValues(alpha: 0.35)),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: colors.roleChipFg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  final _ProfilePageColors colors;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _AccountInfoRow({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.label,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.copy_rounded, size: 18, color: colors.muted),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final _ProfilePageColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: colors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  final _ProfilePageColors colors;

  const _ProfileSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: block(96, width: 96)),
        const SizedBox(height: 16),
        Center(child: block(14, width: 180)),
        const SizedBox(height: 24),
        block(12, width: 140),
        const SizedBox(height: 10),
        block(180),
        const SizedBox(height: 24),
        block(12, width: 120),
        const SizedBox(height: 10),
        block(72),
        const SizedBox(height: 10),
        block(72),
        const SizedBox(height: 10),
        block(72),
      ],
    );
  }
}

class _EditProfileColors {
  final Color background;
  final Color fieldBg;
  final Color onSurface;
  final Color label;
  final Color muted;
  final Color accent;
  final Color noteCard;
  final Color submitFg;

  const _EditProfileColors._({
    required this.background,
    required this.fieldBg,
    required this.onSurface,
    required this.label,
    required this.muted,
    required this.accent,
    required this.noteCard,
    required this.submitFg,
  });

  factory _EditProfileColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (isDark) {
      return const _EditProfileColors._(
        background: Color(0xFF000000),
        fieldBg: Color(0xFF1C1C1E),
        onSurface: Color(0xFFFFFFFF),
        label: Color(0xFF94A3B8),
        muted: Color(0xFF64748B),
        accent: Color(0xFF4FC3F7),
        noteCard: Color(0xFF14181F),
        submitFg: Color(0xFF0B0F14),
      );
    }

    return _EditProfileColors._(
      background: AppTheme.backgroundColor,
      fieldBg: AppTheme.surfaceColor,
      onSurface: AppTheme.textPrimary,
      label: AppTheme.textSecondary,
      muted: AppTheme.textSecondary.withValues(alpha: 0.85),
      accent: scheme.primary,
      noteCard: const Color(0xFFF1F5F9),
      submitFg: Colors.white,
    );
  }
}

class _EditProfileBottomSheet extends StatefulWidget {
  final UserModel user;
  const _EditProfileBottomSheet({required this.user});

  @override
  State<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSubmitting = false;
  bool _isDirty = false;
  final _formKey = GlobalKey<FormState>();

  static const _securityNote =
      'Việc thay đổi Email sẽ yêu cầu xác thực lại tài khoản qua mã OTP được gửi về hòm thư mới. '
      'Hãy đảm bảo thông tin liên lạc luôn chính xác để nhận thông báo từ hệ thống NTRIP Pro.';

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.user.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    for (final ctrl in [_fullNameCtrl, _emailCtrl, _phoneCtrl]) {
      ctrl.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    for (final ctrl in [_fullNameCtrl, _emailCtrl, _phoneCtrl]) {
      ctrl.removeListener(_markDirty);
    }
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _displayName {
    final full = widget.user.fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    return widget.user.username;
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.last.isNotEmpty ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_isDirty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ProfileRepository();
      await repo.updateProfile({
        'fullName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        AppToast.show(context, 'Cập nhật thông tin thành công!', type: AppToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _EditProfileColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: c.background,
      child: SafeArea(
        child: Column(
          children: [
            _EditProfileHeader(
              colors: c,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                  children: [
                    _EditProfileAvatarHeader(
                      colors: c,
                      displayName: _displayName,
                      initials: _initials(_displayName),
                    ),
                    const SizedBox(height: 28),
                    _EditProfileField(
                      colors: c,
                      label: 'HỌ VÀ TÊN',
                      icon: Icons.person_outline_rounded,
                      controller: _fullNameCtrl,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _EditProfileField(
                      colors: c,
                      label: 'ĐỊA CHỈ EMAIL',
                      icon: Icons.email_outlined,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return null;
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(email)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _EditProfileField(
                      colors: c,
                      label: 'SỐ ĐIỆN THOẠI',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (phone.isEmpty) return null;
                        final phoneRegex = RegExp(r'^[0-9+\-()\s]{8,}$');
                        if (!phoneRegex.hasMatch(phone)) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _EditSecurityNote(colors: c, text: _securityNote),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_isDirty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.submitFg,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.submitFg),
                        )
                      : Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: c.submitFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  final _EditProfileColors colors;
  final VoidCallback onClose;

  const _EditProfileHeader({required this.colors, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chỉnh sửa thông tin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: colors.onSurface, size: 26),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileAvatarHeader extends StatelessWidget {
  final _EditProfileColors colors;
  final String displayName;
  final String initials;

  const _EditProfileAvatarHeader({
    required this.colors,
    required this.displayName,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: colors.muted),
            const SizedBox(width: 6),
            Text(
              'Tài khoản đã xác thực',
              style: TextStyle(color: colors.muted, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditProfileField extends StatelessWidget {
  final _EditProfileColors colors;
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _EditProfileField({
    required this.colors,
    required this.label,
    required this.icon,
    required this.controller,
    required this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.fieldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurface.withValues(alpha: 0.9), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: colors.accent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditSecurityNote extends StatelessWidget {
  final _EditProfileColors colors;
  final String text;

  const _EditSecurityNote({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.noteCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lưu ý bảo mật',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}
