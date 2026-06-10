import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_ekyc_repository.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pagination_bar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_toast.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final adminEkycSubmissionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = AdminEkycRepository();
  return repository.listSubmissions();
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

// ─── Main Screen ─────────────────────────────────────────────────────────────

class EkycManagementScreen extends ConsumerStatefulWidget {
  const EkycManagementScreen({super.key});

  @override
  ConsumerState<EkycManagementScreen> createState() => _EkycManagementScreenState();
}

class _EkycManagementScreenState extends ConsumerState<EkycManagementScreen> {
  String _search = '';
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final submissionsAsync = ref.watch(adminEkycSubmissionsProvider);

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
              onSearch: (v) => setState(() => _search = v.trim()),
            ),

            // ── Filter Chips ────────────────────────────────────────────
            _buildFilterChips(c),

            // ── Subtitle label ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DANH SÁCH HỒ SƠ CHỜ DUYỆT',
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
              child: submissionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.accent),
                ),
                error: (err, stack) => Center(
                  child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
                ),
                data: (items) {
                  var filtered = items.where((item) {
                    final name = (item['user']?['fullName'] ??
                            item['user']?['username'] ??
                            '')
                        .toString()
                        .toLowerCase();
                    if (_search.isNotEmpty &&
                        !name.contains(_search.toLowerCase())) return false;
                    if (_statusFilter != null &&
                        item['status'] != _statusFilter) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Không có hồ sơ nào',
                        style: TextStyle(color: c.sub),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildKycCard(c, filtered[index]),
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
            selected: _statusFilter == null,
            onTap: () => setState(() => _statusFilter = null),
            color: c.accent,
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c,
            label: 'Chờ duyệt',
            selected: _statusFilter == 'PENDING',
            onTap: () => setState(() => _statusFilter = 'PENDING'),
            color: const Color(0xFFFF8C42),
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c,
            label: 'Đã duyệt',
            selected: _statusFilter == 'APPROVED',
            onTap: () => setState(() => _statusFilter = 'APPROVED'),
            color: const Color(0xFF22D37E),
          ),
          const SizedBox(width: 8),
          _Chip(
            c: c,
            label: 'Từ chối',
            selected: _statusFilter == 'REJECTED',
            onTap: () => setState(() => _statusFilter = 'REJECTED'),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  // ── Kyc card custom view ───────────────────────────────────────────────────

  Widget _buildKycCard(_C c, dynamic item) {
    final status = item['status']?.toString() ?? 'PENDING';
    final createdAt =
        DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final faceScore =
        double.tryParse(item['faceMatchScore']?.toString() ?? '0') ?? 0.0;
    final name =
        item['user']?['fullName'] ?? item['user']?['username'] ?? 'Unknown';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF22D37E);
        statusLabel = 'ĐÃ DUYỆT';
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFFF5C5C);
        statusLabel = 'TỪ CHỐI';
        break;
      default:
        statusColor = const Color(0xFFFF8C42);
        statusLabel = 'CHỜ DUYỆT';
    }

    // Color code based on face score
    Color scoreColor;
    if (faceScore >= 80) {
      scoreColor = const Color(0xFF22D37E);
    } else if (faceScore >= 50) {
      scoreColor = const Color(0xFFFFBC11);
    } else {
      scoreColor = const Color(0xFFFF5C5C);
    }

    return GestureDetector(
      onTap: () => _showReviewSheet(c, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AvatarWidget(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                        style: TextStyle(color: c.sub, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                    status: status, color: statusColor, label: statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 0.8, color: c.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Độ khớp khuôn mặt (Face Match)',
                            style: TextStyle(
                              color: c.sub,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${faceScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: faceScore / 100,
                          minHeight: 5,
                          backgroundColor: c.border.withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.chevron_right_rounded,
                  color: c.sub.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom review sheet ────────────────────────────────────────────────────

  void _showReviewSheet(_C c, dynamic item) {
    final noteController = TextEditingController();
    final ocrData = item['ocrData'];
    final status = item['status']?.toString() ?? 'PENDING';
    final name =
        item['user']?['fullName'] ?? item['user']?['username'] ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, color: c.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiết hồ sơ eKYC',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Dữ liệu sinh trắc học và trích xuất OCR',
                        style: TextStyle(color: c.sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Segment 1: Biometrics Info
            _buildSectionHeader(c, 'Dữ liệu xác thực sinh trắc',
                Icons.fingerprint_rounded),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  _detailRow(c, 'Người dùng', name, icon: Icons.person_outline),
                  Divider(height: 16, color: c.border),
                  _detailRow(c, 'Loại giấy tờ',
                      item['documentType']?.toString() ?? 'CCCD',
                      icon: Icons.credit_card_outlined),
                  Divider(height: 16, color: c.border),
                  _detailRow(c, 'Face Match Score',
                      '${item['faceMatchScore'] ?? 'N/A'}%',
                      icon: Icons.face_retouching_natural),
                  Divider(height: 16, color: c.border),
                  _detailRow(c, 'Liveness Score',
                      '${item['livenessScore'] ?? 'N/A'}',
                      icon: Icons.offline_bolt_outlined),
                  Divider(height: 16, color: c.border),
                  _detailRow(c, 'Trạng thái hiện tại', status,
                      icon: Icons.info_outline, isStatus: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Segment 2: OCR Info (if exists)
            if (ocrData != null) ...[
              _buildSectionHeader(c, 'Thông tin trích xuất OCR từ giấy tờ',
                  Icons.document_scanner_outlined),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    _detailRow(c, 'Họ tên', ocrData['name']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(c, 'Số CCCD', ocrData['id']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(
                        c, 'Ngày sinh', ocrData['birth_day']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(
                        c, 'Giới tính', ocrData['gender']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(c, 'Nguyên quán',
                        ocrData['origin_location']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(c, 'Nơi ở hiện tại',
                        ocrData['recent_location']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(
                        c, 'Ngày cấp', ocrData['issue_date']?.toString() ?? 'N/A'),
                    Divider(height: 16, color: c.border),
                    _detailRow(c, 'Hạn sử dụng',
                        ocrData['valid_date']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Segment 3: Rejection note & Action Buttons
            if (status == 'PENDING') ...[
              _buildSectionHeader(c, 'Quyết định phê duyệt hồ sơ', Icons.gavel_rounded),
              TextField(
                controller: noteController,
                maxLines: 2,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.input,
                  labelText: 'Lý do từ chối (nếu có)',
                  labelStyle: TextStyle(color: c.sub, fontSize: 13),
                  hintText: 'Nhập lý do từ chối phê duyệt hồ sơ eKYC...',
                  hintStyle: TextStyle(
                      color: c.sub.withValues(alpha: 0.6), fontSize: 13),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await AdminEkycRepository().reviewSubmission(
                              item['id'].toString(),
                              false,
                              noteController.text.trim());
                          if (ctx.mounted) ctx.pop();
                          ref.invalidate(adminEkycSubmissionsProvider);
                          if (mounted) {
                            AppToast.show(context, 'Đã từ chối hồ sơ',
                                type: AppToastType.success);
                          }
                        } catch (e) {
                          if (mounted) {
                            AppToast.show(context, 'Lỗi: $e',
                                type: AppToastType.error);
                          }
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: const Color(0xFFFF5C5C),
                        side: const BorderSide(color: Color(0xFFFF5C5C), width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await AdminEkycRepository().reviewSubmission(
                              item['id'].toString(),
                              true,
                              noteController.text.trim());
                          if (ctx.mounted) ctx.pop();
                          ref.invalidate(adminEkycSubmissionsProvider);
                          if (mounted) {
                            AppToast.show(context, 'Đã phê duyệt hồ sơ',
                                type: AppToastType.success);
                          }
                        } catch (e) {
                          if (mounted) {
                            AppToast.show(context, 'Lỗi: $e',
                                type: AppToastType.error);
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Phê duyệt'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: const Color(0xFF22D37E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: const Color(0xFF22D37E).withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Sheet helper widgets ───────────────────────────────────────────────────

  Widget _buildSectionHeader(_C c, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, top: 4),
      child: Row(
        children: [
          Icon(icon, color: c.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: c.accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(_C c, String label, String value,
      {IconData? icon, bool isStatus = false}) {
    Widget valueWidget;
    if (isStatus) {
      Color color;
      String text;
      switch (value.toUpperCase()) {
        case 'APPROVED':
          color = const Color(0xFF22D37E);
          text = 'ĐÃ DUYỆT';
          break;
        case 'REJECTED':
          color = const Color(0xFFFF5C5C);
          text = 'TỪ CHỐI';
          break;
        default:
          color = const Color(0xFFFF8C42);
          text = 'CHỜ DUYỆT';
      }
      valueWidget = _StatusBadge(status: value, color: color, label: text);
    } else {
      valueWidget = Text(
        value,
        style: TextStyle(
            color: c.text, fontWeight: FontWeight.w600, fontSize: 13.5),
        textAlign: TextAlign.end,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: c.sub.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
                color: c.sub, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _SearchRow ──────────────────────────────────────────────────────────────

class _SearchRow extends StatefulWidget {
  final _C c;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  const _SearchRow({
    required this.c,
    required this.controller,
    required this.onSearch,
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
            hintText: 'Tìm theo tên, username...',
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

// ─── _AvatarWidget ───────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String name;
  final double radius;
  const _AvatarWidget({required this.name, this.radius = 20});

  static const _colors = [
    Color(0xFF3A6FD8),
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFFD79A8),
  ];

  @override
  Widget build(BuildContext context) {
    final ch = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
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
  final Color color;
  final String label;

  const _StatusBadge({
    required this.status,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
