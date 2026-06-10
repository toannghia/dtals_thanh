class NtripPackage {
  final String id;
  final String name;
  final double price;
  final int duration;
  final String durationUnit;
  final String? description;
  final bool active;

  NtripPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.durationUnit,
    this.description,
    this.active = true,
  });

  factory NtripPackage.fromJson(Map<String, dynamic> json) {
    return NtripPackage(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      duration: json['duration'] ?? 1,
      durationUnit: json['durationUnit'] ?? 'month',
      description: json['description'],
      active: json['active'] ?? true,
    );
  }

  static final _embeddedDurationPattern = RegExp(
    r'\(\s*\d+\s*(tháng|năm|ngày|month|months|year|years|day|days)\s*\)',
    caseSensitive: false,
  );

  String durationLabel({bool capitalizeUnit = false}) {
    final unit = switch (durationUnit) {
      'year' => capitalizeUnit ? 'Năm' : 'năm',
      'day' => capitalizeUnit ? 'Ngày' : 'ngày',
      _ => capitalizeUnit ? 'Tháng' : 'tháng',
    };
    return '$duration $unit';
  }

  /// Tên gói kèm thời hạn — không ghép thêm nếu API đã có sẵn trong `name`.
  String get displayNameWithDuration {
    final trimmed = name.trim();
    if (_embeddedDurationPattern.hasMatch(trimmed)) return trimmed;
    return '$trimmed (${durationLabel(capitalizeUnit: true)})';
  }
}
