import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../data/admin_support_repository.dart';
import '../../../../end_user/support/data/models/support_ticket.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../../core/widgets/app_toast.dart';
import 'admin_support_list_screen.dart';

// Provider cho tin nhắn
final adminSupportMessagesProvider = FutureProvider.family<List<SupportMessage>, String>((ref, id) async {
  final repository = AdminSupportRepository();
  return repository.getRequestMessages(id);
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

class AdminSupportDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const AdminSupportDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<AdminSupportDetailScreen> createState() => _AdminSupportDetailScreenState();
}

class _AdminSupportDetailScreenState extends ConsumerState<AdminSupportDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  XFile? _attachmentFile;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom on initial frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });

    // Set up periodic 3-second refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.invalidate(adminSupportMessagesProvider(widget.requestId));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _attachmentFile = pickedFile;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentFile = null;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _attachmentFile == null) return;
    
    String content = _messageController.text.trim();
    if (content.isEmpty && _attachmentFile != null) {
      content = " ";
    }
    
    setState(() => _isSending = true);
    
    try {
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

      await AdminSupportRepository().sendAdminMessage(
        widget.requestId, 
        content,
        attachmentPath: path,
        attachmentBytes: bytes,
        attachmentName: filename,
      );

      // Auto update status to IN_PROGRESS when replying
      try {
        await AdminSupportRepository().updateStatus(widget.requestId, 'IN_PROGRESS');
      } catch (_) {}
      
      _messageController.clear();
      _attachmentFile = null;
      ref.invalidate(adminSupportMessagesProvider(widget.requestId));
      ref.invalidate(adminSupportRequestsProvider);
      
      // Scroll to bottom immediately on sending
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        String errMsg = 'Lỗi: $e';
        if (e is DioException && e.response?.data != null) {
          errMsg = e.response!.data['message'] ?? e.response!.data.toString();
        }
        AppToast.show(context, errMsg, type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _C(context);
    final messagesAsync = ref.watch(adminSupportMessagesProvider(widget.requestId));
    final profileAsync = ref.watch(profileProvider);

    // Riverpod listener to automatically scroll down when new message data arrives
    ref.listen<AsyncValue<List<SupportMessage>>>(
      adminSupportMessagesProvider(widget.requestId),
      (prev, next) {
        if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
    );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(
          'Chi tiết hỗ trợ',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: c.text),
            color: c.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (status) async {
              try {
                await AdminSupportRepository().updateStatus(widget.requestId, status);
                ref.invalidate(adminSupportRequestsProvider);
                ref.invalidate(adminSupportMessagesProvider(widget.requestId));
                if (context.mounted) {
                  AppToast.show(
                    context, 
                    status == 'CLOSED' ? 'Đã chuyển thành Đã giải quyết' : 'Đã chuyển thành Đang xử lý',
                    type: AppToastType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(context, 'Lỗi cập nhật trạng thái: $e', type: AppToastType.error);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'IN_PROGRESS',
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Text('Đang xử lý', style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'CLOSED',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22D37E), size: 18),
                    const SizedBox(width: 8),
                    Text('Đã giải quyết', style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: c.accent),
              ),
              error: (err, stack) => Center(
                child: Text('Lỗi: $err', style: TextStyle(color: c.sub)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Chưa có tin nhắn', style: TextStyle(color: c.sub)),
                  );
                }
                if (profileAsync.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accent),
                  );
                }
                final currentUserId = profileAsync.value?.id.toString();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageDate = DateUtils.dateOnly(message.createdAt);
                    
                    DateTime? previousDate;
                    if (index > 0) {
                      previousDate = DateUtils.dateOnly(messages[index - 1].createdAt);
                    }
                    final showHeader = index == 0 || previousDate != messageDate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHeader) _buildDateHeader(messageDate, dividerColor: c.border.withOpacity(0.5), c: c),
                        _buildMessageBubble(c, message, currentUserId),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(c),
        ],
      ),
    );
  }

  // ── Date Header Helper ─────────────────────────────────────────────────────

  Widget _buildDateHeader(DateTime date, {required Color dividerColor, required _C c}) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = date == today;
    final headerTextColor = c.sub.withOpacity(0.7);

    final day = DateFormat('dd').format(date);
    final month = date.month;
    final year = DateFormat('yyyy').format(date);

    final text = isToday
        ? 'HÔM NAY, $day TH$month $year'
        : '$day TH$month $year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: dividerColor,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: headerTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: dividerColor,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble custom view ─────────────────────────────────────────────

  Widget _buildMessageBubble(_C c, SupportMessage message, String? currentUserId) {
    final bool isMe = currentUserId != null && message.senderId == currentUserId;
    final timeFormat = DateFormat('HH:mm');

    final bubbleColor = isMe ? c.accent : c.card;
    final textColor = isMe ? c.onAccent : c.text;
    final timeColor = isMe ? c.onAccent.withOpacity(0.8) : c.sub.withOpacity(0.65);

    final avatar = Container(
      width: 32,
      height: 32,
      margin: isMe ? const EdgeInsets.only(left: 8) : const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe ? c.accent.withOpacity(0.12) : c.card,
        border: Border.all(color: c.border.withOpacity(0.6), width: 1),
      ),
      child: Icon(
        isMe ? Icons.support_agent_rounded : Icons.person_rounded,
        color: isMe ? c.accent : c.text,
        size: 16,
      ),
    );

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 16),
        ),
        border: isMe ? null : Border.all(color: c.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            Text(
              message.content,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (message.attachmentUrl != null) ...[
            if (message.content.isNotEmpty) const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(context, message.attachmentUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.attachmentUrl!.startsWith('http')
                      ? message.attachmentUrl!
                      : '${AppConfig.baseUrl}${message.attachmentUrl!.startsWith('/') ? '' : '/'}${message.attachmentUrl}',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: c.input,
                    child: Icon(Icons.broken_image_rounded, color: c.sub, size: 28),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            timeFormat.format(message.createdAt),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isMe
          ? [
              Flexible(child: bubble),
              avatar,
            ]
          : [
              avatar,
              Flexible(child: bubble),
            ],
    );
  }

  // ── Input Area custom view ─────────────────────────────────────────────────

  Widget _buildInputArea(_C c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.border.withOpacity(0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_attachmentFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Chip(
                  label: const Text(
                    'Đã đính kèm 1 ảnh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: _removeAttachment,
                  backgroundColor: c.accent.withOpacity(0.15),
                  side: BorderSide(color: c.accent.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image_rounded, 
                    color: _attachmentFile != null ? c.accent : c.sub,
                    size: 26,
                  ),
                  onPressed: _isSending ? null : _pickImage,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: c.input,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: c.text, fontSize: 14),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: 'Nhập phản hồi chăm sóc...',
                        hintStyle: TextStyle(color: c.sub.withOpacity(0.55), fontSize: 13.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        isDense: true,
                      ),
                      maxLines: null,
                      enabled: !_isSending,
                      cursorColor: c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: c.accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Icon(Icons.send_rounded, color: c.onAccent, size: 18),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    final fullUrl = url.startsWith('http')
        ? url
        : '${AppConfig.baseUrl}${url.startsWith('/') ? '' : '/'}$url';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
