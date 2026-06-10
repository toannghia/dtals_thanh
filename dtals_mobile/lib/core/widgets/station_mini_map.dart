import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_tile_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../../features/admin/stations/data/models/station.dart';
import './vietnam_map_layer.dart';

class StationMiniMap extends StatelessWidget {
  final List<Station> stations;
  final VoidCallback? onTap;
  final double height;

  const StationMiniMap({
    super.key,
    required this.stations,
    this.onTap,
    this.height = 430,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IgnorePointer(
              ignoring: true, // Prevent map interaction from consuming scroll
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(16.0, 108.5),
                  initialZoom: 5.0,
                  interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/{z}/{x}/{y}?access_token=${AppConfig.mapboxToken}',
                    userAgentPackageName: 'com.dtals.app',
                    tileProvider: getDefaultTileProvider(),
                  ),
                  const VietnamMapLayer(),
                  MarkerLayer(
                    markers: _buildIslandLabels(),
                  ),
                  MarkerLayer(
                    markers: stations
                        .where((s) => s.latitude != null && s.longitude != null)
                        .map((s) => Marker(
                              point: LatLng(s.latitude!, s.longitude!),
                              width: 12,
                              height: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getStatusColor(s.status),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          if (onTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
      case 'RUNNING':
        return AppTheme.successColor;
      case 'STOPPED':
        return AppTheme.warningColor;
      case 'OFFLINE':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}
