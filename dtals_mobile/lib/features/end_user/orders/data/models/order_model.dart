// lib/features/end_user/orders/data/models/order_model.dart

class OrderModel {
  final String id;
  final String orderCode;
  final double amount;
  final String status; // PENDING, COMPLETED, CANCELLED
  final String packageName;
  final String? ntripAccountName;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.packageName,
    this.ntripAccountName,
    required this.createdAt,
  });

  /// Mã hiển thị trên UI (vd: #NTRIP-88291).
  String get displayOrderCode {
    final raw = orderCode.trim();
    if (raw.isEmpty) return _formatAsNtripCode(id);
    return _formatAsNtripCode(raw);
  }

  static String _formatAsNtripCode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '#NTRIP-—';
    if (trimmed.startsWith('#')) return trimmed;
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('NTRIP-') || upper.startsWith('NTRIP')) return '#$trimmed';
    return '#NTRIP-$trimmed';
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _parseOrderCode(Map<String, dynamic> json, String id) {
    for (final key in [
      'orderCode',
      'order_code',
      'code',
      'payosOrderCode',
      'payos_order_code',
      'referenceCode',
      'reference',
    ]) {
      final value = _readString(json[key]);
      if (value != null) return value;
    }
    return id;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final package = json['package'];
    final packageName = json['packageName'] ??
        (package is Map ? package['name']?.toString() : null) ??
        '';

    final id = json['id'].toString();

    return OrderModel(
      id: id,
      orderCode: _parseOrderCode(json, id),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: (json['status'] ?? 'PENDING').toString(),
      packageName: packageName,
      ntripAccountName: _readString(
        json['ntripAccountName'] ??
            json['ntrip_account_name'] ??
            json['ntripAccountId'] ??
            json['ntrip_account_id'],
      ),
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']).toString()).toLocal(),
    );
  }
}
