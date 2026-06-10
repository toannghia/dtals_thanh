import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../end_user/support/data/models/support_ticket.dart';
import '../../data/admin_support_repository.dart';

// Provider cho danh sách yêu cầu
final adminSupportRequestsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final repository = AdminSupportRepository();
  return repository.getAllRequests();
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

// ─── Support Stats ──────────────────────────────────────────────────────────

class _SupportStats {
  final int open;
  final int inProgress;
  final int closed;

  const _SupportStats({required this.open, required this.inProgress, required this.closed});

  factory _SupportStats.fromTickets(List<SupportTicket> tickets) {
    int open = 0;
    int inProgress = 0;
    int closed = 0;
    for (final t in tickets) {
      final status = (t.status ?? '').toString().toUpperCase();
      if (status == 'CLOSED' || status == 'RESOLVED') {
        closed++;
      } else if (status == 'IN_PROGRESS') {
        inProgress++;
      } else {
        open++;
      }
    }
    return _SupportStats(open: open, inProgress: inProgress, closed: closed);
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminSupportListScreen extends ConsumerStatefulWidget {
  const AdminSupportListScreen({super.key});

  @override
  ConsumerState<AdminSupportListScreen> createState() => _AdminSupportListScreenState();
}

class _AdminSupportListScreenState extends ConsumerState<AdminSupportListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return tickets;
    return tickets.where((ticket) {
      final title = ticket.title.toLowerCase();
      final id = ticket.id.toLowerCase();
      final preview = ticket.requestPreview.toLowerCase();
      return title.contains(trimmed) || id.contains(trimmed) || preview.contains(trimmed);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final requestsAsync = ref.watch(adminSupportRequestsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(adminSupportRequestsProvider.future),
          color: c.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Subtitle Label ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'YÊU CẦU HỖ TRỢ KHÁCH HÀNG',
                  style: TextStyle(
                    color: c.sub,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              // ── Data Content ──
              Expanded(
                child: requestsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: c.accent),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
                  ),
                  data: (requests) {
                    final stats = _SupportStats.fromTickets(requests);
                    final filteredRequests = _filterTickets(requests, _searchQuery);

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _StatsRow(stats: stats),
                        ),
                        SliverToBoxAdapter(
                          child: _SearchRow(controller: _searchCtrl),
                        ),
                        if (filteredRequests.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'Không tìm thấy yêu cầu nào',
                                style: TextStyle(color: c.sub, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          SliverList.separated(
                            itemCount: filteredRequests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final request = filteredRequests[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildRequestCard(context, c, request),
                              );
                            },
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Request Card custom view ───────────────────────────────────────────────

  Widget _buildRequestCard(BuildContext context, _C c, SupportTicket request) {
    Color statusColor;
    String statusLabel;
    
    switch (request.status.toUpperCase()) {
      case 'OPEN':
      case 'PENDING':
        statusColor = const Color(0xFFFF8C42);
        statusLabel = 'Mở / Mới';
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF38BDF8);
        statusLabel = 'Đang xử lý';
        break;
      default:
        statusColor = const Color(0xFF22D37E);
        statusLabel = 'Đã giải quyết';
    }

    final code = request.id;
    final codeLabel = code.length > 5 ? 'TK-${code.substring(0, 5)}' : 'TK-$code';

    return GestureDetector(
      onTap: () => context.push('/admin/support/${request.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Icon hỗ trợ khách hàng
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
              child: Icon(Icons.headset_mic_rounded, color: c.accent, size: 20),
            ),
            const SizedBox(width: 12),

            // Chi tiết nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
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
                        codeLabel,
                        style: TextStyle(color: c.accent.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: c.sub.withOpacity(0.5))),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM HH:mm').format(request.createdAt),
                        style: TextStyle(color: c.sub.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Nhãn trạng thái
            _StatusBadge(color: statusColor, label: statusLabel),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: c.sub.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _StatsRow ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final _SupportStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = _C(context);

    Widget statBox(String value, String label, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: c.sub.withOpacity(0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          statBox(stats.open.toString().padLeft(2, '0'), 'MỞ / MỚI', const Color(0xFFFF8C42)),
          const SizedBox(width: 10),
          statBox(stats.inProgress.toString().padLeft(2, '0'), 'ĐANG XỬ LÝ', const Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          statBox(stats.closed.toString().padLeft(2, '0'), 'ĐÃ GIẢI QUYẾT', const Color(0xFF22D37E)),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
            hintText: 'Tìm kiếm tiêu đề hoặc mã...',
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35), width: 1.0),
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
