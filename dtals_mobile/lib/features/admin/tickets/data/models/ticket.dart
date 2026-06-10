// lib/features/admin/tickets/data/models/ticket.dart

class Ticket {
  final String id;
  final String type; // SHUTDOWN, RESTART, etc.
  final String title;
  final String description;
  final String status; // PENDING, APPROVED, REJECTED
  final String? adminNote;
  final dynamic user;
  final dynamic station;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.adminNote,
    this.user,
    this.station,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminNote: json['adminNote'],
      user: json['user'],
      station: json['station'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
