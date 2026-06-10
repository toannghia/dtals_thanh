import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/support_repository.dart';
import '../../data/models/support_ticket.dart';

final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final repository = SupportRepository();
  return repository.getMyTickets();
});

final supportMessagesProvider = FutureProvider.family<List<SupportMessage>, String>((ref, ticketId) async {
  final repository = SupportRepository();
  return repository.getMessages(ticketId);
});
