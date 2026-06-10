import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/support_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/support_repository.dart';
import '../../data/models/support_ticket.dart';
import '../../../../../core/widgets/app_toast.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  Timer? _refreshTimer;
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.invalidate(supportTicketsProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0F14) : colorScheme.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Hỗ trợ & Khiếu nại'),
        backgroundColor: bgColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: const [SizedBox(width: 4)],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (tickets) {
          final filteredTickets = _filterTickets(tickets, _searchQuery);
          if (filteredTickets.isEmpty) {
            return const _EmptyStateWidget();
          }
          final stats = _SupportStats.fromTickets(filteredTickets);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(supportTicketsProvider.future),
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _StatsRow(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _searchCtrl,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(count: filteredTickets.length),
                ),
                SliverList.separated(
                  itemCount: filteredTickets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _TicketCard(ticket: filteredTickets[index]),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                child: const _CreateTicketBottomSheet(),
              );
            },
          ).then((value) {
            if (value == true) {
              ref.refresh(supportTicketsProvider.future);
            }
          });
        },
        label: const Text('Tạo yêu cầu', style: TextStyle(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: isDark ? const Color(0xFF0B0F14) : Colors.white,
      ),
    );
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets, String? query) {
    final trimmed = (query ?? '').trim().toLowerCase();
    if (trimmed.isEmpty) return tickets;
    return tickets.where((ticket) {
      final title = ticket.title.toLowerCase();
      final id = ticket.id.toLowerCase();
      final preview = ticket.requestPreview.toLowerCase();
      return title.contains(trimmed) ||
          id.contains(trimmed) ||
          preview.contains(trimmed);
    }).toList();
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : colorScheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
            ),
            child: Icon(Icons.support_agent_rounded, size: 64, color: mutedText),
          ),
          const SizedBox(height: 24),
          Text(
            'Bạn chưa có yêu cầu hỗ trợ nào', 
            style: TextStyle(color: mutedText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

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

class _StatsRow extends StatelessWidget {
  final _SupportStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF11161D) : colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF1F2937) : colorScheme.outlineVariant;
    final labelColor = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);

    Widget statBox(String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          statBox(stats.open.toString().padLeft(2, '0'), 'ĐANG MỞ'),
          const SizedBox(width: 10),
          statBox(stats.inProgress.toString().padLeft(2, '0'), 'CẦN PHẢN HỒI'),
          const SizedBox(width: 10),
          statBox(stats.closed.toString().padLeft(2, '0'), 'ĐÃ ĐÓNG'),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF10161E) : colorScheme.surfaceVariant;
    final border = isDark ? const Color(0xFF1F2937) : colorScheme.outlineVariant;
    final hint = colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm yêu cầu hoặc ID...',
          hintStyle: TextStyle(color: hint),
          prefixIcon: Icon(Icons.search_rounded, color: hint),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Text('DANH SÁCH YÊU CẦU', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$count bản ghi', style: TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  String _getBadgeLabel(String status) {
    switch (status) {
      case 'IN_PROGRESS': return 'Đang xử lý';
      case 'RESOLVED':
      case 'CLOSED': return 'Đã giải quyết';
      case 'OPEN':
      case 'PENDING': return 'Đang chờ';
      default: return status;
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFF22D3EE);
      case 'RESOLVED':
      case 'CLOSED':
        return const Color(0xFF22C55E);
      case 'OPEN':
      case 'PENDING':
        return scheme.primary;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF11161D) : theme.cardColor;
    final borderColor = isDark ? const Color(0xFF1F2937) : colorScheme.outlineVariant;
    final subtitleColor = colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6);
    final metaColor = colorScheme.onSurface.withOpacity(isDark ? 0.6 : 0.5);
    final statusColor = _statusColor(ticket.status, colorScheme);
    final code = ticket.id;
    final codeLabel = code.length > 5 ? 'TK-${code.substring(0, 5)}' : 'TK-$code';
    final requestPreview = ticket.requestPreview;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/user/support/${ticket.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withOpacity(isDark ? 0.6 : 0.4)),
                      ),
                      child: Text(
                        _getBadgeLabel(ticket.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (requestPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    requestPreview,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 14, color: metaColor),
                    const SizedBox(width: 6),
                    Text(
                      codeLabel,
                      style: TextStyle(fontSize: 12, color: metaColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.event_outlined, size: 14, color: metaColor),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(ticket.createdAt),
                      style: TextStyle(fontSize: 12, color: metaColor, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTicketColors {
  final Color background;
  final Color card;
  final Color border;
  final Color accent;
  final Color onSurface;
  final Color muted;
  final Color hint;
  final Color noteBg;
  final Color badgeBg;
  final Color submitFg;
  final Color dashedBorder;

  const _CreateTicketColors._({
    required this.background,
    required this.card,
    required this.border,
    required this.accent,
    required this.onSurface,
    required this.muted,
    required this.hint,
    required this.noteBg,
    required this.badgeBg,
    required this.submitFg,
    required this.dashedBorder,
  });

  factory _CreateTicketColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (isDark) {
      return const _CreateTicketColors._(
        background: Color(0xFF000000),
        card: Color(0xFF1A1A1A),
        border: Color(0xFF3A3F47),
        accent: Color(0xFF4FC3F7),
        onSurface: Color(0xFFFFFFFF),
        muted: Color(0xFF94A3B8),
        hint: Color(0xFF64748B),
        noteBg: Color(0xFF0C2B2F),
        badgeBg: Color(0xFF2A2F36),
        submitFg: Color(0xFF0B0F14),
        dashedBorder: Color(0xFF3A4550),
      );
    }

    return _CreateTicketColors._(
      background: AppTheme.backgroundColor,
      card: AppTheme.surfaceColor,
      border: const Color(0xFFE2E8F0),
      accent: scheme.primary,
      onSurface: AppTheme.textPrimary,
      muted: AppTheme.textSecondary,
      hint: AppTheme.textSecondary.withValues(alpha: 0.75),
      noteBg: scheme.primary.withValues(alpha: 0.08),
      badgeBg: const Color(0xFFE2E8F0),
      submitFg: Colors.white,
      dashedBorder: const Color(0xFFCBD5E1),
    );
  }
}

class _CreateTicketBottomSheet extends StatefulWidget {
  const _CreateTicketBottomSheet();

  @override
  State<_CreateTicketBottomSheet> createState() => _CreateTicketBottomSheetState();
}

class _CreateTicketBottomSheetState extends State<_CreateTicketBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  XFile? _attachmentFile;

  static const _technicalNote =
      'Vui lòng cung cấp mã ID trạm hoặc thông số log kết nối nếu bạn đang gặp sự cố về tín hiệu NTRIP để chúng tôi xử lý nhanh nhất.';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 2048,
    );
    if (pickedFile != null && mounted) {
      setState(() => _attachmentFile = pickedFile);
    }
  }

  void _showTechnicalInfo(_CreateTicketColors c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: c.accent, size: 22),
            const SizedBox(width: 8),
            Text('Lưu ý kỹ thuật', style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(_technicalNote, style: TextStyle(color: c.muted, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đã hiểu', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = SupportRepository();
      String? path;
      List<int>? bytes;
      String? filename;

      if (_attachmentFile != null) {
        filename = _attachmentFile!.name;
        if (kIsWeb) {
          bytes = await _attachmentFile!.readAsBytes();
        } else {
          path = _attachmentFile!.path;
        }
      }

      await repo.createTicket(
        _titleCtrl.text.trim(),
        _contentCtrl.text.trim(),
        attachmentPath: path,
        attachmentBytes: bytes,
        attachmentName: filename,
      );

      if (mounted) {
        Navigator.pop(context, true);
        AppToast.show(context, 'Đã gửi yêu cầu hỗ trợ thành công!', type: AppToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Lỗi khi gửi yêu cầu: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(_CreateTicketColors c, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.hint, fontSize: 14, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: c.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _CreateTicketColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: c.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _CreateTicketHeader(
              colors: c,
              onClose: () => Navigator.pop(context),
            ),
            Divider(height: 1, thickness: 1, color: c.border),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                  children: [
                    _TechnicalNoteBox(colors: c, text: _technicalNote),
                    const SizedBox(height: 22),
                    _CreateFieldLabel(
                      colors: c,
                      icon: Icons.description_outlined,
                      label: 'Tiêu đề yêu cầu',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Bắt buộc',
                          style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleCtrl,
                      style: TextStyle(color: c.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                      cursorColor: c.accent,
                      decoration: _fieldDecoration(
                        c,
                        'Ví dụ: Lỗi không kết nối được trạm HCM01',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined, size: 14, color: c.muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Súc tích, rõ ràng để kỹ thuật viên dễ nhận diện.',
                            style: TextStyle(color: c.muted, fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _CreateFieldLabel(
                      colors: c,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Nội dung chi tiết',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _contentCtrl,
                      maxLines: 6,
                      minLines: 5,
                      style: TextStyle(color: c.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                      cursorColor: c.accent,
                      decoration: _fieldDecoration(
                        c,
                        'Mô tả chi tiết tình trạng lỗi, thời gian xảy ra và các bước đã thực hiện xử lý...',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
                    ),
                    const SizedBox(height: 22),
                    _CreateFieldLabel(
                      colors: c,
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Đính kèm hình ảnh minh họa',
                    ),
                    const SizedBox(height: 10),
                    _ImageUploadZone(
                      colors: c,
                      file: _attachmentFile,
                      onTap: _pickImage,
                      onRemove: () => setState(() => _attachmentFile = null),
                    ),
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
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.submitFg),
                        )
                      : Icon(Icons.send_rounded, color: c.submitFg, size: 20),
                  label: Text(
                    'Gửi yêu cầu hỗ trợ',
                    style: TextStyle(
                      color: c.submitFg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.submitFg,
                    disabledBackgroundColor: c.accent.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _CreateTicketHeader extends StatelessWidget {
  final _CreateTicketColors colors;
  final VoidCallback onClose;

  const _CreateTicketHeader({
    required this.colors,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tạo yêu cầu hỗ trợ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.muted),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TechnicalNoteBox extends StatelessWidget {
  final _CreateTicketColors colors;
  final String text;

  const _TechnicalNoteBox({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.noteBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'LƯU Ý KỸ THUẬT',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: colors.onSurface, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CreateFieldLabel extends StatelessWidget {
  final _CreateTicketColors colors;
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _CreateFieldLabel({
    required this.colors,
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: colors.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ImageUploadZone extends StatelessWidget {
  final _CreateTicketColors colors;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageUploadZone({
    required this.colors,
    required this.file,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colors.dashedBorder,
          radius: 12,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: file == null ? _emptyContent() : _previewContent(context),
        ),
      ),
    );
  }

  Widget _emptyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_photo_alternate_outlined, color: colors.accent, size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          'Nhấn để tải ảnh hoặc kéo thả',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hỗ trợ JPG, PNG (Tối đa 5MB)',
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _previewContent(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: file!.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: colors.accent, strokeWidth: 2)),
                );
              }
              return Image.memory(
                snapshot.data!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: colors.accent, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                file!.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, color: colors.muted, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
