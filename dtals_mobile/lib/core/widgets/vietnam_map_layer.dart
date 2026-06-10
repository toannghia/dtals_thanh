import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VietnamMapLayer extends StatefulWidget {
  final String? selectedProvince;
  final Function(String)? onProvinceTap;

  const VietnamMapLayer({
    super.key,
    this.selectedProvince,
    this.onProvinceTap,
  });

  @override
  State<VietnamMapLayer> createState() => _VietnamMapLayerState();
}

class _VietnamMapLayerState extends State<VietnamMapLayer> {
  List<Polygon> _polygons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String geoString = await rootBundle.loadString('assets/geo/vietnam_provinces.geojson');
      final data = json.decode(geoString);

      List<Polygon> parsedPolygons = [];

      for (var feature in data['features']) {
        final props = feature['properties'];
        final geometry = feature['geometry'];
        
        if (geometry == null) continue;

        String name = props['adm1_name1'] ?? props['adm1_name'] ?? '';
        bool isSelected = name == widget.selectedProvince && widget.selectedProvince != null;

        if (geometry['type'] == 'Polygon') {
          parsedPolygons.add(_buildPolygon(geometry['coordinates'][0], name, isSelected));
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var coords in geometry['coordinates']) {
            parsedPolygons.add(_buildPolygon(coords[0], name, isSelected));
          }
        }
      }

      setState(() {
        _polygons = parsedPolygons;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading geojson: $e');
      setState(() => _isLoading = false);
    }
  }

  Polygon _buildPolygon(List coords, String name, bool isSelected) {
    List<LatLng> points = coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();

    return Polygon(
      points: points,
      color: isSelected ? const Color(0xFFF39C12).withOpacity(0.3) : const Color(0xFF3498DB).withOpacity(0.1),
      borderColor: isSelected ? const Color(0xFFD35400) : Colors.white,
      borderStrokeWidth: isSelected ? 3 : 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    return PolygonLayer(polygons: _polygons);
  }
}
