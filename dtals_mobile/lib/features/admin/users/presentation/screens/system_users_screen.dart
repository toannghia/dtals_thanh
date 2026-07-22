import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/system_user_repository.dart';
import '../../data/models/admin_user_models.dart';
import '../../../../../core/widgets/app_toast.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

class SystemUsersState {
  final List<SystemUser> users;
  final bool hasMore;
  final bool isLoadingMore;
  final int page;
  final String search;

  SystemUsersState({
    this.users = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.page = 1,
    this.search = '',
  });

  SystemUsersState copyWith({
    List<SystemUser>? users,
    bool? hasMore,
    bool? isLoadingMore,
    int? page,
    String? search,
  }) {
    return SystemUsersState(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      search: search ?? this.search,
    );
  }
}

class SystemUsersNotifier extends AsyncNotifier<SystemUsersState> {
  @override
  FutureOr<SystemUsersState> build() async {
    final users = await SystemUserRepository().listSystemUsers(page: 1, limit: 20);
    return SystemUsersState(
      users: users,
      hasMore: users.length == 20,
      page: 1,
    );
  }

  Future<void> loadMore() async {
    final curr = state.value;
    if (curr == null || !curr.hasMore || curr.isLoadingMore) return;

    state = AsyncValue.data(curr.copyWith(isLoadingMore: true));
    try {
      final nextPage = curr.page + 1;
      final newUsers = await SystemUserRepository().listSystemUsers(
        page: nextPage,
        limit: 20,
        search: curr.search,
      );
      
      state = AsyncValue.data(curr.copyWith(
        users: [...curr.users, ...newUsers],
        hasMore: newUsers.length == 20,
        isLoadingMore: false,
        page: nextPage,
      ));
    } catch (e) {
      state = AsyncValue.data(curr.copyWith(isLoadingMore: false));
    }
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final users = await SystemUserRepository().listSystemUsers(page: 1, limit: 20, search: query);
      state = AsyncValue.data(SystemUsersState(
        users: users,
        hasMore: users.length == 20,
        page: 1,
        search: query,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }

  void removeUser(String id) {
    final curr = state.value;
    if (curr == null) return;
    state = AsyncValue.data(curr.copyWith(
      users: curr.users.where((u) => u.id != id).toList(),
    ));
  }
}

final systemUsersProvider = AsyncNotifierProvider<SystemUsersNotifier, SystemUsersState>(() {
  return SystemUsersNotifier();
});

// ─── Theme-aware color helper ────────────────────────────────────────────────

class _C {
  final ColorScheme cs;
  final bool dark;

  _C(BuildContext ctx)
      : cs = Theme.of(ctx).colorScheme,
        dark = Theme.of(ctx).brightness == Brightness.dark;

  // Backgrounds
  Color get bg      => dark ? const Color(0xFF15202B) : cs.surface;
  Color get surface => dark ? const Color(0xFF192734) : cs.surfaceContainerLow;
  Color get card    => dark ? const Color(0xFF22303C) : cs.surfaceContainerHighest;
  Color get input   => dark ? const Color(0xFF192734) : cs.surfaceContainer;

  // Borders / dividers
  Color get border  => dark ? const Color(0xFF38444D) : cs.outlineVariant;

  // Text
  Color get text    => cs.onSurface;
  Color get sub     => cs.onSurfaceVariant;

  // Accent (primary)
  Color get accent  => cs.primary;
  Color get onAccent => cs.onPrimary;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SystemUsersScreen extends ConsumerStatefulWidget {
  const SystemUsersScreen({super.key});

  @override
  ConsumerState<SystemUsersScreen> createState() => _SystemUsersScreenState();
}

class _SystemUsersScreenState extends ConsumerState<SystemUsersScreen> {
  List<String> _fetchedRoles = [
    'ACCOUNTANT',
    'AUTHORITY',
    'CSKH',
    'DRIVER',
    'END_USER',
    'GOV',
    'RETAILER',
    'SUPER_ADMIN',
  ];

  Future<void> _loadRoles() async {
    try {
      final roles = await SystemUserRepository().listRoles();
      if (roles.isNotEmpty && mounted) {
        setState(() {
          _fetchedRoles = roles;
        });
      }
    } catch (e) {
      debugPrint('Failed to load roles: ');
    }
  }

  bool _hideEndUser = true; // Mặc định ẩn End User cho gọn màn hình giống Web
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadRoles();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemUsersProvider.notifier).refresh();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(systemUsersProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final usersAsync = ref.watch(systemUsersProvider);

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
              onSearch: (v) {
                ref.read(systemUsersProvider.notifier).search(v.trim());
              },
              onAdd: () => _showAddEditDialog(),
            ),

            // ── Section label ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DANH SÁCH NHÂN VIÊN',
                    style: TextStyle(
                      color: c.sub,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text('Ẩn End User', style: TextStyle(color: c.sub, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 24,
                        child: Switch(
                          value: _hideEndUser,
                          onChanged: (v) => setState(() => _hideEndUser = v),
                          activeColor: c.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: usersAsync.when(
                loading: () => Center(
                    child: CircularProgressIndicator(color: c.accent)),
                error: (err, _) => Center(
                  child: Text('Lỗi: $err',
                      style: TextStyle(color: c.sub)),
                ),
                data: (state) {
                  Iterable<SystemUser> filtered = state.users;
                  if (_hideEndUser) {
                    filtered = filtered.where((u) => !u.roles.contains('END_USER'));
                  }
                  
                  final displayList = filtered.toList();

                  if (displayList.isEmpty && !state.isLoadingMore) {
                    return Center(
                      child: Text('Chưa có nhân viên nào',
                          style: TextStyle(color: c.sub)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.read(systemUsersProvider.notifier).refresh();
                      await ref.read(systemUsersProvider.future);
                    },
                    color: c.accent,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      itemCount: displayList.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == displayList.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: c.accent),
                            ),
                          );
                        }
                        return _buildUserCard(c, displayList[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── User card ─────────────────────────────────────────────────────────────

  Widget _buildUserCard(_C c, SystemUser user) {
    final role = user.roles.isNotEmpty ? user.roles.first : 'N/A';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: c.border,
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: c.text, fontWeight: FontWeight.w700),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? const Color(0xFF22D37E)
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: c.card, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildRoleChip(role),
                    const SizedBox(width: 4),
                    _StatusBadge(status: user.status),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: c.sub, size: 18),
            onPressed: () => _showAddEditDialog(user: user),
            tooltip: 'Sửa',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: c.sub, size: 18),
            onPressed: () => _confirmDelete(user),
            tooltip: 'Xóa',
          ),
        ],
      ),
    );
  }

  // ── Role chip ─────────────────────────────────────────────────────────────

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':  color = Colors.red;         break;
      case 'AUTHORITY':    color = Colors.orange;      break;
      case 'GOV':          color = Colors.indigo;      break;
      case 'CSKH':         color = Colors.blue;        break;
      case 'ACCOUNTANT':   color = Colors.teal;        break;
      case 'RETAILER':     color = Colors.purple;      break;
      case 'DRIVER':       color = Colors.brown;       break;
      case 'END_USER':     color = Colors.blueGrey;    break;
      default:             color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────

  void _showAddEditDialog({SystemUser? user}) {
    final isEditing = user != null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();

    String selectedRole = user?.roles.isNotEmpty == true ? user!.roles.first : 'END_USER';
    final Map<String, String> availableRoles = {
      for (var r in _fetchedRoles) r: r
    };
    if (!availableRoles.containsKey(selectedRole)) {
      selectedRole = 'END_USER';
    }
    String selectedStatus = user?.status ?? 'ACTIVE';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final c = _C(ctx);
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
                      Text(
                        isEditing ? 'Sửa Nhân Viên' : 'Thêm Nhân Viên',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      if (isEditing) ...[
                        _dialogLabel(c, 'ID Hệ thống'),
                        _dialogInput(
                          c: c,
                          controller: TextEditingController(text: user!.id),
                          hint: '',
                          icon: Icons.tag,
                          enabled: false,
                        ),
                        const SizedBox(height: 10),
                      ],

                      _dialogLabel(c, 'Phân quyền'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedRole,
                        dropdownColor: c.card,
                        style: TextStyle(color: c.text),
                        decoration: _dropdownDeco(c),
                        items: availableRoles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (v) => setDialogState(() => selectedRole = v!),
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Tên đăng nhập'),
                      _dialogInput(
                        c: c,
                        controller: usernameCtrl,
                        hint: 'Ví dụ: thanhdtals',
                        icon: Icons.person_outline,
                        enabled: !isEditing,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Họ và tên'),
                      _dialogInput(
                        c: c,
                        controller: fullNameCtrl,
                        hint: 'Nguyễn Văn A',
                        icon: Icons.badge_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 10),

                      if (!isEditing) ...[
                        _dialogLabel(c, 'Email công việc'),
                        _dialogInput(
                          c: c,
                          controller: emailCtrl,
                          hint: 'name@company.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 10),
                      ],

                      _dialogLabel(c, 'Mật khẩu tạm thời'),
                      _dialogInput(
                        c: c,
                        controller: passwordCtrl,
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) => !isEditing && (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 10),

                      _dialogLabel(c, 'Trạng thái'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedStatus,
                        dropdownColor: c.card,
                        style: TextStyle(color: c.text),
                        decoration: _dropdownDeco(c),
                        items: [
                          const DropdownMenuItem(value: 'ACTIVE', child: Text('Hoạt động')),
                          const DropdownMenuItem(value: 'INACTIVE', child: Text('Khóa')),
                          if (selectedStatus == 'DELETED')
                            const DropdownMenuItem(value: 'DELETED', child: Text('Đã xóa')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedStatus = v!),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c.text,
                                side: BorderSide(color: c.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Hủy bỏ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  try {
                                    final data = <String, dynamic>{
                                      'username': usernameCtrl.text.trim(),
                                      'fullName': fullNameCtrl.text.trim(),
                                      'roleName': selectedRole,
                                    };
                                    if (passwordCtrl.text.isNotEmpty) {
                                      data['password'] = passwordCtrl.text;
                                    }
                                    if (!isEditing) {
                                      data['email'] = emailCtrl.text.trim();
                                    }
                                    if (isEditing) {
                                      data['status'] = selectedStatus;
                                    }
                                    if (isEditing) {
                                      await SystemUserRepository().updateSystemUser(user.id, data);
                                    } else {
                                      await SystemUserRepository().createSystemUser(data);
                                    }
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                    ref.invalidate(systemUsersProvider);
                                    if (mounted) {
                                      AppToast.show(context, isEditing ? 'Cập nhật thành công' : 'Tạo nhân viên thành công', type: AppToastType.success);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.accent,
                                foregroundColor: c.onAccent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
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

  InputDecoration _dropdownDeco(_C c) {
    return InputDecoration(
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

  // ── Delete confirm ────────────────────────────────────────────────────────

  void _confirmDelete(SystemUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) {
        final colors = _C(c);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Xác nhận xóa',
              style: TextStyle(color: colors.text)),
          content: Text(
              'Bạn chắc chắn muốn xóa nhân viên "${user.username}"?',
              style: TextStyle(color: colors.sub)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              style: TextButton.styleFrom(foregroundColor: colors.sub),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Xóa',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        await SystemUserRepository().deleteSystemUser(user.id);
        ref.read(systemUsersProvider.notifier).removeUser(user.id);
        if (mounted) {
          AppToast.show(context, 'Đã xóa nhân viên',
              type: AppToastType.success);
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, 'Lỗi: $e',
              type: AppToastType.error);
        }
      }
    }
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
                  hintText: 'Tìm nhân viên...',
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

// ── Status badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  String _label() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'HOẠT ĐỘNG';
      case 'INACTIVE':
      case 'BLOCKED':
      case 'DELETED':
        return 'ĐÃ KHÓA';
      default:
        return status;
    }
  }

  Color _color() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF22D37E);
      case 'INACTIVE':
      case 'BLOCKED':
      case 'DELETED':
        return const Color(0xFFFF5C5C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(),
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

