import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/services/map_tile_provider.dart';
import '../../data/models/station.dart';
import './station_list_screen.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/widgets/vietnam_map_layer.dart';

class AdminStationsMapScreen extends ConsumerStatefulWidget {
  const AdminStationsMapScreen({super.key});

  @override
  ConsumerState<AdminStationsMapScreen> createState() => _AdminStationsMapScreenState();
}

class _AdminStationsMapScreenState extends ConsumerState<AdminStationsMapScreen> {
  bool _isSatellite = true;

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      // No app bar here, since AppShell provides the main AppBar.
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (stations) {
          final String mapStyle = _isSatellite ? 'satellite-streets-v12' : 'dark-v11';
          
          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(16.0, 108.5),
                  initialZoom: 5.5,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/$mapStyle/tiles/{z}/{x}/{y}?access_token=${AppConfig.mapboxToken}',
                    userAgentPackageName: 'com.dtals.app',
                    tileProvider: getDefaultTileProvider(),
                  ),
                  const VietnamMapLayer(),
                  MarkerLayer(
                    markers: _buildIslandLabels(),
                  ),
                  MarkerLayer(
                    markers: stations.map((s) {
                      final isActive = s.status.toUpperCase() == 'RUNNING';
                      final color = isActive ? Colors.green : Colors.red;
                      return Marker(
                        point: LatLng(s.latitude ?? 0, s.longitude ?? 0),
                        width: 16,
                        height: 16,
                        child: GestureDetector(
                          onTap: () => _showStationDetail(context, s),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(
                top: topInset + 8,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_layer_toggle',
                      onPressed: () => setState(() => _isSatellite = !_isSatellite),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(_isSatellite ? Icons.dark_mode : Icons.satellite_alt),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_list_view',
                      onPressed: () => context.push('/admin/stations/list'),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.format_list_bulleted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildIslandLabels() {
    final labels = [
      {'pos': const LatLng(10.823111, 106.629647), 'text': 'TP. Hồ Chí Minh'},
      {'pos': const LatLng(21.027812, 105.834535), 'text': 'Hà Nội'},
      {'pos': const LatLng(16.5839161, 112.4743021), 'text': 'Quần đảo\nHoàng Sa'},
      {'pos': const LatLng(10.6921803, 115.7505101), 'text': 'Quần đảo\nTrường Sa'},
    ];

    return labels.map((l) {
      return Marker(
        point: l['pos'] as LatLng,
        width: 120,
        height: 48,
        child: IgnorePointer(
          child: Center(
            child: Text(
              l['text'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFF04D), // Light yellow matching web
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.2,
                shadows: [
                  Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1, 1)),
                  Shadow(blurRadius: 3, color: Colors.black, offset: Offset(-1, -1)),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return Colors.green;
      case 'STOPPED': return Colors.orange;
      case 'OFFLINE': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showStationDetail(BuildContext context, Station station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(station.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                _buildStatusChip(station.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.code, 'Mã trạm', station.code),
            _buildDetailRow(Icons.place, 'Khu vực', station.province ?? 'Unknown'),
            _buildDetailRow(Icons.lan, 'Địa chỉ mạng', '${station.ipAddress}:${station.port}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
     final color = _getStatusColor(status);
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
       child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
     );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
