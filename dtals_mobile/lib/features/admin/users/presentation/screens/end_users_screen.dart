import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_end_user_repository.dart';
import '../../data/models/admin_user_models.dart';
import '../../../../../core/widgets/app_toast.dart';
import 'package:intl/intl.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final endUsersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final page = int.tryParse(parts[0]) ?? 1;
  final search =
      parts.length > 1 && parts[1] != 'null' && parts[1].isNotEmpty
          ? parts[1]
          : null;
  final status =
      parts.length > 2 && parts[2] != 'null' && parts[2].isNotEmpty
          ? parts[2]
          : null;
  return AdminEndUserRepository().listUsers(
      page: page, search: search, status: status);
});

// ─── Constants (non-color) ───────────────────────────────────────────────────

const _pageSize = 20;

// ─── Theme-aware color helper ────────────────────────────────────────────────
//
// All colors are resolved at build-time from the active ColorScheme so that
// switching between light and dark mode works automatically.

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

// ─── Main screen ─────────────────────────────────────────────────────────────

class EndUsersScreen extends ConsumerStatefulWidget {
  const EndUsersScreen({super.key});

  @override
  ConsumerState<EndUsersScreen> createState() => _EndUsersScreenState();
}

class _EndUsersScreenState extends ConsumerState<EndUsersScreen> {
  String  _search = '';
  String? _status;
  int     _page   = 1;
  final   _searchCtrl = TextEditingController();

  String get _key => '$_page|$_search|$_status';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final async = ref.watch(endUsersProvider(_key));

    return Container(
      color: c.bg,
      child: Column(
        children: [
          _SearchRow(
            c: c,
            controller: _searchCtrl,
            onSearch: (v) => setState(() { _search = v; _page = 1; }),
            onAdd: _showAddDialog,
          ),
          _Filters(
            c: c,
            status: _status,
            onTap: (v) => setState(() { _status = v; _page = 1; }),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: c.accent)),
              error: (e, _) => Center(
                child: Text('Lỗi: $e',
                    style: TextStyle(color: c.sub))),
              data: (data) {
                final users = (data['items'] as List<AdminEndUser>?) ?? [];
                final total = (data['total'] as int?) ?? 0;
                if (users.isEmpty) {
                  return Center(
                    child: Text('Không có dữ liệu',
                        style: TextStyle(color: c.sub)));
                }
                final totalPages =
                    (total / _pageSize).ceil().clamp(1, 9999);
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                        itemCount: users.length,
                        itemBuilder: (_, i) => _UserRow(
                          c: c,
                          user: users[i],
                          onEdit:   () => _showDetail(users[i]),
                          onDelete: () => _doDelete(users[i]),
                        ),
                      ),
                    ),
                    _Footer(
                      c: c,
                      page: _page,
                      total: total,
                      totalPages: totalPages,
                      onPrev: _page > 1          ? () => setState(() => _page--) : null,
                      onNext: _page < totalPages ? () => setState(() => _page++) : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── delete ────────────────────────────────────────────────────────────────

  Future<void> _doDelete(AdminEndUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title:   'Xóa tài khoản',
        body:    'Bạn có chắc muốn xóa tài khoản "${user.username}"?\nHành động này không thể hoàn tác.',
        confirm: 'Xóa',
        danger:  true,
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AdminEndUserRepository().deleteUser(user.id);
      ref.invalidate(endUsersProvider(_key));
      if (mounted) {
        AppToast.show(context, 'Đã xóa tài khoản',
            type: AppToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
      }
    }
  }

  // ── detail sheet ──────────────────────────────────────────────────────────

  void _showDetail(AdminEndUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C(context).surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.60,
        minChildSize: 0.35,
        maxChildSize: 0.90,
        expand: false,
        builder: (_, sc) => _DetailSheet(
          user: user, scroll: sc,
          onToggle: () async {
            final ns =
                user.status == 'ACTIVE' ? 'BLOCKED' : 'ACTIVE';
            try {
              await AdminEndUserRepository()
                  .updateStatus(user.id, ns);
              ref.invalidate(endUsersProvider(_key));
              if (ctx.mounted) { Navigator.pop(ctx); }
              if (mounted) {
                AppToast.show(
                  context,
                  ns == 'BLOCKED'
                      ? 'Đã khóa tài khoản'
                      : 'Đã mở khóa',
                  type: AppToastType.success,
                );
              }
            } catch (e) {
              if (mounted) {
                AppToast.show(context, 'Lỗi: $e',
                    type: AppToastType.error);
              }
            }
          },
        ),
      ),
    );
  }

  // ── add dialog ────────────────────────────────────────────────────────────

  void _showAddDialog() {
    final uc = TextEditingController();
    final fc = TextEditingController();
    final ec = TextEditingController();
    final pc = TextEditingController();
    final fk = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _AddDialog(
        formKey: fk,
        username: uc, fullName: fc, email: ec, phone: pc,
        onSubmit: () async {
          if (!(fk.currentState?.validate() ?? false)) return;
          try {
            await AdminEndUserRepository().createUser({
              'username':    uc.text.trim(),
              'fullName':    fc.text.trim(),
              'email':       ec.text.trim(),
              'phoneNumber': pc.text.trim(),
            });
            if (ctx.mounted) { Navigator.of(ctx).pop(); }
            ref.invalidate(endUsersProvider(_key));
            if (mounted) {
              AppToast.show(context, 'Tạo người dùng thành công',
                  type: AppToastType.success);
            }
          } catch (e) {
            if (mounted) {
              AppToast.show(context, 'Lỗi: $e',
                  type: AppToastType.error);
            }
          }
        },
      ),
    );
  }
}


// ─── _SearchRow ──────────────────────────────────────────────────────────────

class _SearchRow extends StatefulWidget {
  final _C c;
  final TextEditingController controller;
  final ValueChanged<String>  onSearch;
  final VoidCallback          onAdd;

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
                  hintText: 'Tìm theo tên, email, SĐT...',
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

// ─── _Filters ────────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  final _C c;
  final String? status;
  final void Function(String?) onTap;

  const _Filters({required this.c, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          _Chip(
            c: c, 
            label: 'Tất cả', 
            selected: status == null, 
            onTap: () => onTap(null),
            color: c.accent,
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c, 
            label: 'Hoạt động', 
            selected: status == 'ACTIVE', 
            onTap: () => onTap('ACTIVE'),
            color: const Color(0xFF22D37E),
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c, 
            label: 'Đã khóa', 
            selected: status == 'BLOCKED', 
            onTap: () => onTap('BLOCKED'),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final _C c;
  final String   label;
  final bool     selected;
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
    final unselBg  = c.card;
    final unselBorder = c.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const SizedBox(width: 4),
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

// ─── _Footer ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final _C c;
  final int page, total, totalPages;
  final VoidCallback? onPrev, onNext;

  const _Footer({
    required this.c,
    required this.page,
    required this.total,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tổng số: $total  •  Trang $page trên $totalPages',
              style: TextStyle(color: c.sub, fontSize: 12),
            ),
          ),
          _PgBtn(c: c, icon: Icons.chevron_left,  enabled: onPrev != null, onTap: onPrev),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          _PgBtn(c: c, icon: Icons.chevron_right, enabled: onNext != null, onTap: onNext),
        ],
      ),
    );
  }
}

class _PgBtn extends StatelessWidget {
  final _C c;
  final IconData icon;
  final bool     enabled;
  final VoidCallback? onTap;
  const _PgBtn({
    required this.c,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18,
            color: enabled ? c.sub : c.border),
      ),
    );
  }
}

// ─── _UserRow ────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final _C c;
  final AdminEndUser user;
  final VoidCallback onEdit, onDelete;

  const _UserRow({
    required this.c,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: c.border.withValues(alpha: 0.6))),
        ),
        child: Row(
          children: [
            _AvatarWidget(name: user.fullName ?? user.username),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName ?? user.username,
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(user.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? user.phoneNumber ?? user.username,
                    style: TextStyle(color: c.sub, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text('KYC: ',
                        style: TextStyle(color: c.sub, fontSize: 11)),
                    _KycText(user.kycStatus),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _ActionBtn(c: c, icon: Icons.edit_outlined,  onTap: onEdit),
            const SizedBox(width: 4),
            _ActionBtn(c: c, icon: Icons.delete_outline, onTap: onDelete,
                danger: true),
          ],
        ),
      ),
    );
  }
}

// ─── _AvatarWidget ───────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String name;
  final double radius;
  const _AvatarWidget({required this.name, this.radius = 22});

  static const _colors = [
    Color(0xFF3A6FD8), Color(0xFF6C5CE7), Color(0xFF00B894),
    Color(0xFFE17055), Color(0xFF0984E3), Color(0xFFFD79A8),
  ];

  @override
  Widget build(BuildContext context) {
    final ch    = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final color = _colors[ch.codeUnitAt(0) % _colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.22),
      child: Text(
        ch,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

// ─── _StatusBadge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      ),
    );
  }

  String _label() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':   return 'HOẠT ĐỘNG';
      case 'BLOCKED':  return 'ĐÃ KHÓA';
      case 'INACTIVE': return 'VÔ HIỆU';
      default: return status;
    }
  }

  Color _color() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':   return const Color(0xFF22D37E);
      case 'BLOCKED':  return const Color(0xFFFF5C5C);
      case 'INACTIVE': return const Color(0xFFFF8C42);
      default: return Colors.grey;
    }
  }
}

// ─── _KycText ────────────────────────────────────────────────────────────────

class _KycText extends StatelessWidget {
  final String status;
  const _KycText(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'VERIFIED': color = const Color(0xFF22D37E); break;
      case 'PENDING':  color = const Color(0xFFFBC02D); break;
      default:         color = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    return Text(status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600));
  }
}

// ─── _ActionBtn ──────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final _C c;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _ActionBtn({
    required this.c,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF5C5C) : c.sub;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFFF5C5C).withValues(alpha: 0.08)
              : c.input,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16,
            color: color.withValues(alpha: danger ? 0.85 : 1.0)),
      ),
    );
  }
}

// ─── _AddDialog ──────────────────────────────────────────────────────────────

class _AddDialog extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController username, fullName, email, phone;
  final VoidCallback          onSubmit;

  const _AddDialog({
    required this.formKey,
    required this.username, required this.fullName,
    required this.email,    required this.phone,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
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
                  'Thêm người dùng mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // ── Info card ───────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: c.accent.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.person_add_outlined,
                            color: c.accent, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thông tin khách hàng',
                        style: TextStyle(
                            color: c.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Điền đầy đủ các thông tin bên dưới để\nkhởi tạo tài khoản mới trong hệ thống.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: c.sub, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // ── Fields ──────────────────────────────
                      _dialogLabel(c, 'Tên đăng nhập'),
                      _dialogInput(
                        c: c,
                        controller: username,
                        hint: 'Ví dụ: thanhdtals',
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Bắt buộc'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Họ và tên'),
                      _dialogInput(
                        c: c,
                        controller: fullName,
                        hint: 'Ví dụ: Nguyễn Văn A',
                        icon: Icons.badge_outlined,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Bắt buộc'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Email'),
                      _dialogInput(
                        c: c,
                        controller: email,
                        hint: 'example@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Bắt buộc'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Số điện thoại'),
                      _dialogInput(
                        c: c,
                        controller: phone,
                        hint: '086xxxxxxx',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action buttons ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: c.border),
                          foregroundColor: c.text,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy bỏ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSubmit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: c.accent,
                          foregroundColor: c.onAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tạo mới'),
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
  }

  // ── Dialog helpers ────────────────────────────────────────────────────────

  Widget _dialogLabel(_C c, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
              color: c.sub, fontSize: 13, fontWeight: FontWeight.w600),
        ),
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
      style: TextStyle(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.sub),
        prefixIcon: Icon(icon, color: c.sub, size: 18),
        filled: true,
        fillColor: c.input,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: c.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}


// ─── _ConfirmDialog ──────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title, body, confirm;
  final bool   danger;
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirm,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    return Dialog(
      backgroundColor: c.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: c.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(body, style: TextStyle(color: c.sub, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style:
                      TextButton.styleFrom(foregroundColor: c.sub),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: danger
                        ? const Color(0xFFFF5C5C)
                        : c.accent,
                    foregroundColor:
                        danger ? Colors.white : c.onAccent,
                    elevation: 0,
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _DetailSheet ────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final AdminEndUser     user;
  final ScrollController scroll;
  final VoidCallback     onToggle;

  const _DetailSheet({
    required this.user,
    required this.scroll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c      = _C(context);
    final active = user.status == 'ACTIVE';

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Row(children: [
          _AvatarWidget(name: user.fullName ?? user.username, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    _StatusBadge(user.status),
                    const SizedBox(width: 8),
                    _KycText(user.kycStatus),
                  ]),
                ]),
          ),
        ]),
        const SizedBox(height: 20),
        Divider(color: c.border),
        const SizedBox(height: 12),
        _detailRow(c, 'Username',    user.username),
        _detailRow(c, 'Email',       user.email       ?? 'N/A'),
        _detailRow(c, 'Số điện thoại', user.phoneNumber ?? 'N/A'),
        _detailRow(c, 'KYC',         user.kycStatus),
        _detailRow(c, 'Ngày tạo',
            DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)),
        _detailRow(c, 'Đăng nhập cuối',
            user.lastLogin != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                : 'Chưa đăng nhập'),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onToggle,
          icon: Icon(
              active
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              size: 18),
          label: Text(
              active ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
          style: ElevatedButton.styleFrom(
            backgroundColor: active
                ? const Color(0xFFFF5C5C)
                : const Color(0xFF22D37E),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(_C c, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: TextStyle(color: c.sub, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: c.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
        ]),
      );
}
