import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ticket_repository.dart';
import '../../data/models/ticket.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_toast.dart';

final adminTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = TicketRepository();
  return repository.listTickets();
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

class AdminTicketsScreen extends ConsumerStatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  ConsumerState<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends ConsumerState<AdminTicketsScreen> {
  String _search = '';
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _search) return;
      setState(() => _search = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final ticketsAsync = ref.watch(adminTicketsProvider);

    return Container(
      color: c.bg,
      child: Column(
        children: [
          _SearchRow(controller: _searchController),
          _buildFilterChips(c),
          Expanded(
            child: ticketsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: c.accent),
              ),
              error: (err, stack) => Center(
                child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
              ),
              data: (tickets) {
                final filtered = tickets.where((t) {
                  final matchesSearch = _search.isEmpty || 
                      t.title.toLowerCase().contains(_search.toLowerCase()) || 
                      t.description.toLowerCase().contains(_search.toLowerCase()) ||
                      t.type.toLowerCase().contains(_search.toLowerCase());
                  if (!matchesSearch) return false;
                  if (_statusFilter != null && t.status != _statusFilter) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có phiếu nào',
                      style: TextStyle(color: c.sub, fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _TicketCard(
                    ticket: filtered[index],
                    c: c,
                    onUpdate: _updateTicket,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(_C c) {
    Widget chip(String label, String? value, Color selectedColor) {
      final isSelected = _statusFilter == value;
      return GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withOpacity(0.12) : c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? selectedColor : c.border.withOpacity(0.6),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle_rounded, size: 13, color: selectedColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : c.sub.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          chip('Tất cả', null, c.accent),
          const SizedBox(width: 8),
          chip('Chờ duyệt', 'PENDING', const Color(0xFFFF8C42)),
          const SizedBox(width: 8),
          chip('Đã duyệt', 'APPROVED', const Color(0xFF22D37E)),
          const SizedBox(width: 8),
          chip('Từ chối', 'REJECTED', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  void _updateTicket(String id, String status) async {
    final c = _C(context);
    final noteController = TextEditingController();

    final isApprove = status == 'APPROVED';
    final accentColor = isApprove ? const Color(0xFF22D37E) : const Color(0xFFEF4444);
    final iconData = isApprove ? Icons.assignment_turned_in_rounded : Icons.cancel_presentation_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(iconData, color: accentColor, size: 24),
            const SizedBox(width: 10),
            Text(
              isApprove ? 'Duyệt phiếu' : 'Từ chối phiếu',
              style: TextStyle(color: c.text, fontWeight: FontWeight.w800, fontSize: 16.5),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove 
                  ? 'Nhập ghi chú phản hồi duyệt cho người dùng (nếu có):' 
                  : 'Nhập lý do từ chối phiếu hỗ trợ này:',
              style: TextStyle(color: c.sub.withOpacity(0.85), fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: TextStyle(color: c.text, fontSize: 13.5),
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: c.input,
                hintText: 'Nhập phản hồi...',
                hintStyle: TextStyle(color: c.sub.withOpacity(0.5), fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 1.2),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () => ctx.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.sub,
                side: BorderSide(color: c.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Hủy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await TicketRepository().updateStatus(id, status, noteController.text.trim());
                    if (ctx.mounted) {
                      ctx.pop();
                      ref.invalidate(adminTicketsProvider);
                      AppToast.show(
                        context, 
                        isApprove ? 'Đã duyệt phiếu hỗ trợ thành công' : 'Đã từ chối phiếu hỗ trợ',
                        type: AppToastType.success,
                      );
                    }
                  } catch (e) {
                    if (mounted) AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Xác nhận', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _TicketCard ─────────────────────────────────────────────────────────────

class _TicketCard extends StatefulWidget {
  final Ticket ticket;
  final _C c;
  final Function(String id, String status) onUpdate;

  const _TicketCard({
    required this.ticket,
    required this.c,
    required this.onUpdate,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final c = widget.c;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt);

    Color statusColor;
    String statusLabel;
    switch (t.status.toUpperCase()) {
      case 'PENDING':
        statusColor = const Color(0xFFFF8C42);
        statusLabel = 'Chờ duyệt';
        break;
      case 'APPROVED':
        statusColor = const Color(0xFF22D37E);
        statusLabel = 'Đã duyệt';
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Từ chối';
    }

    IconData typeIcon;
    switch (t.type.toUpperCase()) {
      case 'SHUTDOWN':
        typeIcon = Icons.power_settings_new_rounded;
        break;
      case 'RESTART':
        typeIcon = Icons.restart_alt_rounded;
        break;
      default:
        typeIcon = Icons.assignment_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header of the card
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Circular Gradient Icon representation
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.accent.withOpacity(0.15), c.accent.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accent.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(typeIcon, color: c.accent, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Title & Meta details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              t.type,
                              style: TextStyle(color: c.accent.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: c.sub.withOpacity(0.5))),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(color: c.sub.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status Badge & Animated Chevron
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: statusColor.withOpacity(0.35), width: 1),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: c.sub.withOpacity(0.4),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content with SizeTransition or simple Conditional render with Animation
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      Divider(color: c.border.withOpacity(0.4), height: 1, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ticket Description
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: c.sub.withOpacity(0.6)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.description,
                                    style: TextStyle(
                                      color: c.text.withOpacity(0.9),
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Admin Notes (if present)
                            if (t.adminNote != null && t.adminNote!.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.input.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.border.withOpacity(0.4)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.rate_review_rounded, size: 16, color: c.accent.withOpacity(0.8)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ghi chú: ${t.adminNote}',
                                        style: TextStyle(
                                          color: c.text.withOpacity(0.8),
                                          fontSize: 12.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Action buttons for PENDING status
                            if (t.status.toUpperCase() == 'PENDING') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Reject button (Red Outline)
                                  SizedBox(
                                    height: 36,
                                    child: OutlinedButton(
                                      onPressed: () => widget.onUpdate(t.id, 'REJECTED'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: const Text('Từ chối', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Approve button (Green Filled with subtle glow)
                                  SizedBox(
                                    height: 36,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF22D37E).withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => widget.onUpdate(t.id, 'APPROVED'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF22D37E),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: const Text('Phê duyệt', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── _SearchRow ─────────────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;

  const _SearchRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = _C(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: c.input,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: c.text, fontSize: 13.5),
          decoration: InputDecoration(
            filled: false,
            hintText: 'Tìm kiếm phiếu theo tiêu đề...',
            hintStyle: TextStyle(color: c.sub.withOpacity(0.5), fontSize: 13.5),
            prefixIcon: Icon(
              Icons.search_rounded, 
              color: c.sub.withOpacity(0.55), 
              size: 20,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                    },
                    child: Icon(
                      Icons.close_rounded, 
                      color: c.sub.withOpacity(0.6), 
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }
}
