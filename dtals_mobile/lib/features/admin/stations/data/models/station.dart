// lib/features/admin/stations/data/models/station.dart

class Station {
  final String id;
  final String code;
  final String name;
  final String? ipAddress;
  final int? port;
  final String status; // RUNNING, STOPPED, OFFLINE
  final double? latitude;
  final double? longitude;
  final String? province;

  Station({
    required this.id,
    required this.code,
    required this.name,
    this.ipAddress,
    this.port,
    required this.status,
    this.latitude,
    this.longitude,
    this.province,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    String parseStatus() {
      if (json['connectStatus'] != null) {
        final st = json['connectStatus'].toString();
        if (st == '1') return 'RUNNING';
        if (st == '2') return 'STOPPED';
        if (st == '3') return 'OFFLINE';
      }
      if (json['status'] != null) {
        final st = json['status'].toString();
        if (st == '1' || st.toUpperCase() == 'RUNNING') return 'RUNNING';
        if (st == '0' || st.toUpperCase() == 'STOPPED') return 'STOPPED';
        return st.toUpperCase();
      }
      return 'OFFLINE';
    }

    return Station(
      id: json['id']?.toString() ?? '',
      code: json['stationCode']?.toString() ?? json['code']?.toString() ?? '',
      name: json['stationName']?.toString() ?? json['name']?.toString() ?? '',
      ipAddress: json['ip']?.toString() ?? json['ipAddress']?.toString(),
      port: json['port'] is String ? int.tryParse(json['port']) : json['port'],
      status: parseStatus(),
      latitude: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      province: json['province']?.toString(),
    );
  }
}
