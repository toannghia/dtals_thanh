import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/government_repository.dart';
import '../../../admin/tickets/data/models/ticket.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_toast.dart';

final govTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = GovernmentRepository();
  return repository.getTicketHistory();
});

class GovTicketsScreen extends ConsumerWidget {
  const GovTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(govTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu điều khiển')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (tickets) {
          return Column(
            children: [
              _buildActionCard(context, ref),
              const Divider(),
              Expanded(
                child: tickets.isEmpty 
                  ? const Center(child: Text('Chưa có yêu cầu nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) => _buildTicketItem(tickets[index]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () => _showCreateTicketDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tạo yêu cầu mới', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryColor)),
                    SizedBox(height: 4),
                    Text('Gửi phản ánh hoặc thao tác kỹ thuật', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(Ticket ticket) {
    final dateStr = DateFormat('dd/MM/yyyy').format(ticket.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Trạng thái: ${ticket.status} • $dateStr'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tạo yêu cầu điều khiển'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController, 
                      decoration: const InputDecoration(hintText: 'Tiêu đề'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController, 
                      decoration: const InputDecoration(hintText: 'Nội dung chi tiết'), 
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context), 
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (titleController.text.trim().isEmpty) {
                      AppToast.show(context, 'Vui lòng nhập tiêu đề', type: AppToastType.warning);
                      return;
                    }
                    
                    setState(() => isLoading = true);
                    final repository = GovernmentRepository();
                    try {
                      await repository.submitControlTicket({
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'type': 'CONTROL',
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(govTicketsProvider);
                        AppToast.show(context, 'Gửi yêu cầu thành công', type: AppToastType.success);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isLoading = false);
                        AppToast.show(context, 'Lỗi: $e', type: AppToastType.error);
                      }
                    }
                  },
                  child: isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gửi yêu cầu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
