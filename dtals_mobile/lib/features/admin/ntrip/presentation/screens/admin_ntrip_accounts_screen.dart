import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pagination_bar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_ntrip_account_repository.dart';
import '../../../../../core/widgets/app_toast.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final adminNtripAccountsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final page = int.tryParse(parts[0]) ?? 1;
  final search = parts.length > 1 && parts[1] != 'null' && parts[1].isNotEmpty ? parts[1] : null;
  final status = parts.length > 2 && parts[2] != 'null' && parts[2].isNotEmpty ? parts[2] : null;
  final repository = AdminNtripAccountRepository();
  return repository.listAccounts(page: page, search: search, status: status);
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

class AdminNtripAccountsScreen extends ConsumerStatefulWidget {
  const AdminNtripAccountsScreen({super.key});

  @override
  ConsumerState<AdminNtripAccountsScreen> createState() => _AdminNtripAccountsScreenState();
}

class _AdminNtripAccountsScreenState extends ConsumerState<AdminNtripAccountsScreen> {
  String _search = '';
  String? _status;
  int _page = 1;
  final _searchController = TextEditingController();

  String get _providerKey => '$_page|$_search|$_status';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final accountsAsync = ref.watch(adminNtripAccountsProvider(_providerKey));

    return Container(
      color: c.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────
            _SearchRow(
              c: c,
              controller: _searchController,
              onSearch: (v) => setState(() { _search = v.trim(); _page = 1; }),
              onAdd: () => _showAddEditDialog(),
            ),

            // ── Filter Chips ────────────────────────────────────────────
            _buildFilterChips(c),

            // ── Subtitle Label ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DANH SÁCH TÀI KHOẢN NTRIP',
                  style: TextStyle(
                    color: c.sub,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // ── List view ───────────────────────────────────────────────
            Expanded(
              child: accountsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.accent),
                ),
                error: (err, stack) => Center(
                  child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
                ),
                data: (data) {
                  final List<dynamic> items = data['records'] ?? data['data'] ?? data['items'] ?? [];
                  final int total = int.tryParse((data['total'] ?? data['meta']?['total'])?.toString() ?? '') ?? items.length;
                  
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Không có tài khoản NTRIP nào',
                        style: TextStyle(color: c.sub),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildAccountCard(c, items[index]);
                          },
                        ),
                      ),
                      PaginationBar(
                        currentPage: _page,
                        totalItems: total,
                        onPageChanged: (p) => setState(() => _page = p),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips custom view ───────────────────────────────────────────────

  Widget _buildFilterChips(_C c) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Row(
        children: [
          _Chip(
            c: c,
            label: 'Tất cả',
            selected: _status == null,
            onTap: () => setState(() { _status = null; _page = 1; }),
            color: c.accent,
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c,
            label: 'Đang bật',
            selected: _status == '1',
            onTap: () => setState(() { _status = '1'; _page = 1; }),
            color: const Color(0xFF22D37E),
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c,
            label: 'Đã tắt',
            selected: _status == '0',
            onTap: () => setState(() { _status = '0'; _page = 1; }),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  // ── Account Card custom view ───────────────────────────────────────────────

  Widget _buildAccountCard(_C c, dynamic account) {
    final bool isEnabled = (account['enabled'] == 1 || account['enabled'] == true);
    final startTime = account['startTime'] != null ? DateTime.fromMillisecondsSinceEpoch(account['startTime'] is int ? account['startTime'] : 0) : null;
    final endTime = account['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(account['endTime'] is int ? account['endTime'] : 0) : null;
    final isExpired = endTime != null && endTime.isBefore(DateTime.now());

    Color statusColor = isEnabled ? const Color(0xFF22D37E) : const Color(0xFF9CA3AF);
    String statusLabel = isEnabled ? 'ĐANG BẬT' : 'ĐÃ TẮT';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon đại diện tài khoản
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isEnabled ? const Color(0xFF22D37E) : Colors.grey).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_tethering_rounded,
              color: isEnabled ? const Color(0xFF22D37E) : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Chi tiết tài khoản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        account['name']?.toString() ?? 'N/A',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(color: statusColor, label: statusLabel),
                    if (isExpired) ...[
                      const SizedBox(width: 4),
                      const _StatusBadge(color: Color(0xFFFF8C42), label: 'HẾT HẠN'),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (startTime != null) ...[
                      Icon(Icons.date_range_outlined, color: c.sub, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Từ: ${DateFormat('dd/MM/yyyy').format(startTime)}',
                        style: TextStyle(color: c.sub, fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (endTime != null) ...[
                      Icon(Icons.event_busy_outlined, color: c.sub, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        'Đến: ${DateFormat('dd/MM/yyyy').format(endTime)}',
                        style: TextStyle(color: c.sub, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Menu hành động
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: c.sub, size: 20),
            color: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.border),
            ),
            onSelected: (action) => _handleAction(action, account),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: c.sub, size: 16),
                    const SizedBox(width: 8),
                    Text('Chỉnh sửa', style: TextStyle(color: c.text, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(isEnabled ? Icons.toggle_off_outlined : Icons.toggle_on_outlined, color: c.sub, size: 16),
                    const SizedBox(width: 8),
                    Text(isEnabled ? 'Tắt tài khoản' : 'Bật tài khoản', style: TextStyle(color: c.text, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5C5C), size: 16),
                    const SizedBox(width: 8),
                    const Text('Xóa tài khoản', style: TextStyle(color: Color(0xFFFF5C5C), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Handle actions logic ───────────────────────────────────────────────────

  void _handleAction(String action, dynamic account) async {
    final id = account['id'].toString();
    switch (action) {
      case 'edit':
        _showAddEditDialog(account: account);
        break;
      case 'toggle':
        final isEnabled = (account['enabled'] == 1 || account['enabled'] == true);
        try {
          await AdminNtripAccountRepository().toggleEnabled(id, !isEnabled);
          ref.invalidate(adminNtripAccountsProvider(_providerKey));
          if (mounted) {
            AppToast.show(
              context,
              !isEnabled ? 'Đã bật tài khoản' : 'Đã tắt tài khoản',
              type: AppToastType.success,
            );
          }
        } catch (e) {
          if (mounted) AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) {
            final colors = _C(c);
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.border),
              ),
              title: Text('Xác nhận xóa', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800)),
              content: Text(
                'Bạn chắc chắn muốn xóa tài khoản "${account['name']}"?',
                style: TextStyle(color: colors.sub, fontSize: 13.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => c.pop(false),
                  style: TextButton.styleFrom(foregroundColor: colors.sub),
                  child: const Text('Hủy bỏ'),
                ),
                TextButton(
                  onPressed: () => c.pop(true),
                  child: const Text('Xóa ngay', style: TextStyle(color: Color(0xFFFF5C5C), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
        if (confirmed == true) {
          try {
            await AdminNtripAccountRepository().deleteAccount(id);
            ref.invalidate(adminNtripAccountsProvider(_providerKey));
            if (mounted) AppToast.show(context, 'Đã xóa tài khoản', type: AppToastType.success);
          } catch (e) {
            if (mounted) AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
          }
        }
        break;
    }
  }

  // ── Add / Edit dialog custom view ──────────────────────────────────────────

  void _showAddEditDialog({dynamic account}) {
    final isEditing = account != null;
    final nameCtrl = TextEditingController(text: account?['name']?.toString() ?? '');
    final pwdCtrl = TextEditingController();
    int numOnline = account?['numOnline'] ?? 1;
    int enabled = (account?['enabled'] == 1 || account?['enabled'] == true) ? 1 : 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) {
          final c = _C(ctx2);
          final formKey = GlobalKey<FormState>();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Dialog title ────────────────────────────────
                      Text(
                        isEditing ? 'Sửa tài khoản NTRIP' : 'Thêm tài khoản NTRIP mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: c.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),

                      // ── Card wrapper ───────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: c.accent.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.wifi_tethering_rounded,
                                  color: c.accent, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Cấu hình thông tin tài khoản',
                              style: TextStyle(
                                  color: c.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Định cấu hình tài khoản cấp phát kết nối\nNTRIP cho các thiết bị đo đạc ngoài thực địa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: c.sub, fontSize: 12),
                            ),
                            const SizedBox(height: 16),

                            // ── ID (nếu sửa) ──
                            if (isEditing) ...[
                              _dialogLabel(c, 'Mã tài khoản (ID)'),
                              _dialogInput(
                                c: c,
                                controller: TextEditingController(text: account['id'].toString()),
                                hint: 'ID',
                                icon: Icons.fingerprint_rounded,
                                enabled: false,
                              ),
                              const SizedBox(height: 10),
                            ],

                            // ── Tên tài khoản ──
                            _dialogLabel(c, 'Tên tài khoản (Mountpoint)'),
                            _dialogInput(
                              c: c,
                              controller: nameCtrl,
                              hint: 'Ví dụ: account_01',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Bắt buộc'
                                  : null,
                            ),
                            const SizedBox(height: 10),

                            // ── Mật khẩu ──
                            _dialogLabel(c, 'Mật khẩu truy cập'),
                            _dialogInput(
                              c: c,
                              controller: pwdCtrl,
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              validator: (v) => !isEditing && (v == null || v.isEmpty)
                                  ? 'Bắt buộc'
                                  : null,
                            ),
                            if (isEditing) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '  * Để trống nếu không muốn đổi mật khẩu',
                                  style: TextStyle(color: c.sub, fontSize: 11),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),

                            // ── Số kết nối đồng thời & Trạng thái ──
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _dialogLabel(c, 'Kết nối đồng thời'),
                                      DropdownButtonFormField<int>(
                                        value: numOnline,
                                        dropdownColor: c.card,
                                        style: TextStyle(color: c.text, fontSize: 14),
                                        decoration: _dropdownDeco(c),
                                        items: [1, 2, 3, 5, 10]
                                            .map((n) => DropdownMenuItem(value: n, child: Text('$n thiết bị')))
                                            .toList(),
                                        onChanged: (v) => setDialogState(() => numOnline = v!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Trạng thái Choice row ──
                            _dialogLabel(c, 'Trạng thái tài khoản'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: c.input,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() => enabled = 1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: enabled == 1 ? const Color(0xFF22D37E).withValues(alpha: 0.15) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: enabled == 1 ? const Color(0xFF22D37E) : Colors.transparent,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'KÍCH HOẠT (ON)',
                                            style: TextStyle(
                                              color: enabled == 1 ? const Color(0xFF22D37E) : c.sub,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setDialogState(() => enabled = 0),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: enabled == 0 ? const Color(0xFFFF5C5C).withValues(alpha: 0.15) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: enabled == 0 ? const Color(0xFFFF5C5C) : Colors.transparent,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'VÔ HIỆU HÓA (OFF)',
                                            style: TextStyle(
                                              color: enabled == 0 ? const Color(0xFFFF5C5C) : c.sub,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Actions ──────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ctx.pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: c.border),
                                foregroundColor: c.text,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Hủy bỏ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;
                                final data = <String, dynamic>{
                                  'name': nameCtrl.text.trim(),
                                  'numOnline': numOnline,
                                  'enabled': enabled,
                                };
                                if (pwdCtrl.text.isNotEmpty) data['userPwd'] = pwdCtrl.text;
                                try {
                                  if (isEditing) {
                                    await AdminNtripAccountRepository().updateAccount(account['id'].toString(), data);
                                  } else {
                                    await AdminNtripAccountRepository().createAccount(data);
                                  }
                                  if (ctx.mounted) ctx.pop();
                                  ref.invalidate(adminNtripAccountsProvider(_providerKey));
                                  if (mounted) {
                                    AppToast.show(
                                      context,
                                      isEditing ? 'Cập nhật thành công' : 'Tạo thành công',
                                      type: AppToastType.success,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: c.accent,
                                foregroundColor: c.onAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              child: Text(isEditing ? 'Cập nhật' : 'Tạo mới'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dialog Helpers ─────────────────────────────────────────────────────────

  Widget _dialogLabel(_C c, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          text,
          style: TextStyle(color: c.sub, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  InputDecoration _dropdownDeco(_C c) {
    return InputDecoration(
      filled: true,
      fillColor: c.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    );
  }

  Widget _dialogInput({
    required _C c,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: c.text, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: c.input,
        hintText: hint,
        hintStyle: TextStyle(color: c.sub.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: Icon(icon, color: c.sub, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─── _SearchRow ──────────────────────────────────────────────────────────────

class _SearchRow extends StatefulWidget {
  final _C c;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;

  const _SearchRow({
    required this.c,
    required this.controller,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  State<_SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<_SearchRow> {
  final FocusNode _focusNode = FocusNode();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
    _showClear = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onTextChanged() {
    final show = widget.controller.text.isNotEmpty;
    if (show != _showClear) {
      setState(() {
        _showClear = show;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final hasFocus = _focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: c.input,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasFocus ? c.accent : c.border.withValues(alpha: 0.8),
                  width: hasFocus ? 1.2 : 1.0,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: c.accent.withValues(alpha: 0.12),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        )
                      ]
                    : null,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: TextStyle(color: c.text, fontSize: 14),
                onChanged: widget.onSearch,
                decoration: InputDecoration(
                  filled: false,
                  hintText: 'Tìm tài khoản NTRIP...',
                  hintStyle: TextStyle(
                    color: c.sub.withValues(alpha: 0.6),
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: hasFocus ? c.accent : c.sub.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  suffixIcon: _showClear
                      ? GestureDetector(
                          onTap: () {
                            widget.controller.clear();
                            widget.onSearch('');
                          },
                          child: Icon(
                            Icons.cancel_rounded,
                            color: c.sub.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onAdd,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: c.onAccent, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Thêm',
                    style: TextStyle(
                      color: c.onAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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

// ─── _Chip ───────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final _C c;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _Chip({
    required this.c,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final unselBg = c.card;
    final unselBorder = c.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : unselBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : unselBorder.withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_circle_rounded, size: 13, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? color : c.sub.withOpacity(0.85),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _StatusBadge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
