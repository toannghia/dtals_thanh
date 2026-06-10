import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ntrip_package_repository.dart';
import '../../data/models/ntrip_package.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_toast.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final packagesProvider = FutureProvider<List<NtripPackage>>((ref) async {
  final repository = NtripPackageRepository();
  return repository.listPackages();
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

class NtripPackagesScreen extends ConsumerStatefulWidget {
  const NtripPackagesScreen({super.key});

  @override
  ConsumerState<NtripPackagesScreen> createState() => _NtripPackagesScreenState();
}

class _NtripPackagesScreenState extends ConsumerState<NtripPackagesScreen> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final packagesAsync = ref.watch(packagesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
              onAdd: () => _showAddEditDialog(),
            ),

            // ── Subtitle label ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DANH SÁCH GÓI CƯỚC NTRIP',
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
              child: packagesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.accent),
                ),
                error: (err, stack) => Center(
                  child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
                ),
                data: (packages) {
                  final filtered = _search.isEmpty
                      ? packages
                      : packages
                          .where((p) => p.name
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Không có gói cước nào',
                        style: TextStyle(color: c.sub),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final package = filtered[index];
                      return _buildPackageCard(c, package, currencyFormat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Package Card custom view ───────────────────────────────────────────────

  Widget _buildPackageCard(_C c, NtripPackage package, NumberFormat currencyFormat) {
    Color statusColor = package.active ? const Color(0xFF22D37E) : const Color(0xFFFF5C5C);
    String statusLabel = package.active ? 'HOẠT ĐỘNG' : 'TẠM DỪNG';

    return GestureDetector(
      onTap: () => _showAddEditDialog(pkg: package),
      child: Container(
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
            // Icon đại diện
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sell_rounded, color: c.accent, size: 22),
            ),
            const SizedBox(width: 14),

            // Thông tin chi tiết
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.name,
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(color: statusColor, label: statusLabel),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    package.description ?? 'Không có mô tả',
                    style: TextStyle(color: c.sub, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Giá tiền & Thời hạn
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currencyFormat.format(package.price),
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${package.duration} ${package.durationUnit == 'month' ? 'tháng' : package.durationUnit == 'year' ? 'năm' : 'ngày'}',
                  style: TextStyle(color: c.sub, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit dialog custom view ──────────────────────────────────────────

  void _showAddEditDialog({NtripPackage? pkg}) {
    final isEditing = pkg != null;
    final nameCtrl = TextEditingController(text: pkg?.name ?? '');
    final descCtrl = TextEditingController(text: pkg?.description ?? '');
    final priceCtrl =
        TextEditingController(text: pkg?.price.toStringAsFixed(0) ?? '');
    final durationCtrl =
        TextEditingController(text: pkg?.duration.toString() ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        String selectedUnit = pkg?.durationUnit ?? 'month';
        bool isActive = pkg?.active ?? true;
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            final c = _C(ctx2);
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          isEditing ? 'Sửa thông tin gói' : 'Thêm gói cước mới',
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
                                child: Icon(Icons.sell_outlined,
                                    color: c.accent, size: 26),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Cấu hình giá & thời hạn',
                                style: TextStyle(
                                    color: c.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Điền đầy đủ thông tin để định cấu hình\ngói dịch vụ NTRIP trên toàn hệ thống.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: c.sub, fontSize: 12),
                              ),
                              const SizedBox(height: 16),

                              // ── Tên gói ──
                              _dialogLabel(c, 'Tên gói cước'),
                              _dialogInput(
                                c: c,
                                controller: nameCtrl,
                                hint: 'Ví dụ: Gói Cơ Bản 1 Tháng',
                                icon: Icons.badge_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Bắt buộc'
                                    : null,
                              ),
                              const SizedBox(height: 10),

                              // ── Mô tả ──
                              _dialogLabel(c, 'Mô tả chi tiết'),
                              _dialogInput(
                                c: c,
                                controller: descCtrl,
                                hint: 'Gói cước NTRIP tốc độ cao, hỗ trợ CORS...',
                                icon: Icons.description_outlined,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 10),

                              // ── Giá ──
                              _dialogLabel(c, 'Đơn giá (VND)'),
                              _dialogInput(
                                c: c,
                                controller: priceCtrl,
                                hint: 'Ví dụ: 500000',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Bắt buộc'
                                    : null,
                              ),
                              const SizedBox(height: 10),

                              // ── Thời hạn & Đơn vị ──
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _dialogLabel(c, 'Thời hạn'),
                                        _dialogInput(
                                          c: c,
                                          controller: durationCtrl,
                                          hint: 'Ví dụ: 1',
                                          icon: Icons.timer_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Bắt buộc'
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _dialogLabel(c, 'Đơn vị'),
                                        DropdownButtonFormField<String>(
                                          value: selectedUnit,
                                          dropdownColor: c.card,
                                          style: TextStyle(color: c.text, fontSize: 14),
                                          decoration: _dropdownDeco(c),
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'day', child: Text('Ngày')),
                                            DropdownMenuItem(
                                                value: 'month', child: Text('Tháng')),
                                            DropdownMenuItem(
                                                value: 'year', child: Text('Năm')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setStateDialog(
                                                  () => selectedUnit = val);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Trạng thái Switch ──
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.input,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: c.border),
                                ),
                                child: SwitchListTile(
                                  title: Text('Trạng thái hoạt động',
                                      style: TextStyle(
                                          color: c.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  value: isActive,
                                  activeColor: c.accent,
                                  onChanged: (val) =>
                                      setStateDialog(() => isActive = val),
                                  contentPadding: EdgeInsets.zero,
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
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                  textStyle:
                                      const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                child: const Text('Hủy bỏ'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) return;
                                  try {
                                    final data = {
                                      'name': nameCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'price':
                                          double.tryParse(priceCtrl.text) ?? 0,
                                      'duration':
                                          int.tryParse(durationCtrl.text) ?? 1,
                                      'durationUnit': selectedUnit,
                                      'active': isActive,
                                    };

                                    if (isEditing && pkg != null) {
                                      await NtripPackageRepository()
                                          .updatePackage(int.parse(pkg.id), data);
                                    } else {
                                      await NtripPackageRepository()
                                          .createPackage(data);
                                    }
                                    if (ctx.mounted) ctx.pop();
                                    ref.invalidate(packagesProvider);
                                    if (mounted) {
                                      AppToast.show(context, 'Thành công',
                                          type: AppToastType.success);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      AppToast.show(context, 'Lỗi: $e',
                                          type: AppToastType.error);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  backgroundColor: c.accent,
                                  foregroundColor: c.onAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                  textStyle:
                                      const TextStyle(fontWeight: FontWeight.w700),
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
        );
      },
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
          style: TextStyle(
              color: c.sub, fontSize: 12.5, fontWeight: FontWeight.w600),
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
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
                  hintText: 'Tìm gói cước...',
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
