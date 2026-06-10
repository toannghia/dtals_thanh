import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../providers/support_providers.dart';
import '../../data/models/support_ticket.dart';
import '../../data/support_repository.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../../core/widgets/app_toast.dart';

class SupportDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const SupportDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportDetailScreen> createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends ConsumerState<SupportDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  XFile? _attachmentFile;
  bool _isSending = false;
  late final Ticker _ticker;
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastRefresh).inSeconds >= 3) {
      _lastRefresh = now;
      ref.invalidate(supportMessagesProvider(widget.ticketId));
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
      content = " "; // Send a space if text is empty but image is present
    }
    
    setState(() => _isSending = true);
    
    try {
      final repository = SupportRepository();
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

      await repository.sendMessage(
        widget.ticketId, 
        content,
        attachmentPath: path,
        attachmentBytes: bytes,
        attachmentName: filename,
      );
      
      _messageController.clear();
      _attachmentFile = null;
      ref.invalidate(supportMessagesProvider(widget.ticketId));
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
    final messagesAsync = ref.watch(supportMessagesProvider(widget.ticketId));
    final profileAsync = ref.watch(profileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatBackgroundColor = isDark ? const Color(0xFF050B14) : const Color(0xFFF4F6FA);
    final chatForegroundColor = isDark ? Colors.white : Colors.black87;
    final chatDividerColor = isDark ? const Color(0xFF2C3A4C) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: chatBackgroundColor,
      appBar: AppBar(
        backgroundColor: chatBackgroundColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: chatForegroundColor,
        title: Text(
          'Chi tiết hỗ trợ',
          style: TextStyle(
            color: chatForegroundColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có tin nhắn',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black45),
                    ),
                  );
                }
                if (profileAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                        if (showHeader) _buildDateHeader(messageDate, dividerColor: chatDividerColor),
                        _buildMessageBubble(context, message, currentUserId),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(chatBackgroundColor, isDark: isDark),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildDateHeader(DateTime date, {required Color dividerColor}) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = date == today;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white70 : Colors.black45;

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
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

  Widget _buildMessageBubble(BuildContext context, SupportMessage message, String? currentUserId) {
    final bool isMe = currentUserId != null && message.senderId == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final timeFormat = DateFormat('HH:mm');

    final bubbleColor = isMe
        ? AppTheme.primaryColor
        : (isDark ? const Color(0xFF202938) : const Color(0xFFE5E7EB));
    final textColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final timeColor = isMe
        ? Colors.white.withOpacity(0.85)
        : (isDark ? Colors.white.withOpacity(0.75) : Colors.black45);

    final avatarColor = isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB);
    final avatarIconColor = isDark ? Colors.white : Colors.black87;

    final avatar = Container(
      width: 28,
      height: 28,
      margin: isMe ? const EdgeInsets.only(left: 8) : const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
      ),
      child: Icon(
        Icons.person,
        color: avatarIconColor,
        size: 16,
      ),
    );

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            Text(
              message.content,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
            ),
          if (message.attachmentUrl != null) ...[
            if (message.content.isNotEmpty) const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImagePreview(context, message.attachmentUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.attachmentUrl!.startsWith('http')
                      ? message.attachmentUrl!
                      : '${AppConfig.baseUrl}${message.attachmentUrl!.startsWith('/') ? '' : '/'}${message.attachmentUrl}',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            timeFormat.format(message.createdAt),
            style: TextStyle(
              fontSize: 10,
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

  Widget _buildInputArea(Color chatBackgroundColor, {required bool isDark}) {
    final inputFieldBg = isDark ? const Color(0xFF111827) : Colors.white;
    final inputFieldBorder = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final inputHintColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
    final inputShadowColor = isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: chatBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: inputShadowColor,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
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
                  label: Text(
                    'Đã đính kèm 1 ảnh',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: _removeAttachment,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: _attachmentFile != null ? AppTheme.primaryColor : Colors.grey),
                  onPressed: _isSending ? null : _pickImage,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: inputFieldBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: inputFieldBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: inputHintColor, fontSize: 14),
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: TextStyle(color: inputTextColor, fontSize: 14),
                      maxLines: null,
                      enabled: !_isSending,
                      cursorColor: inputTextColor,
                    ),
                  ),
                ),
                _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Container(
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: (_messageController.text.trim().isEmpty && _attachmentFile == null)
                            ? null
                            : _sendMessage,
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
