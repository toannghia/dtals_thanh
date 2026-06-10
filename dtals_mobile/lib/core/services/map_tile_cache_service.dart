import 'package:flutter_map/flutter_map.dart';
import 'map_tile_provider.dart';

class MapTileCacheService {
  static const String storeName = 'OSMTiles';

  static Future<void> preCacheRegion() async {
    // Optionally pre-cache certain zoom levels for the whole country
    // In a real app, this might be triggered by a "Download for Offline" button
  }

  static TileProvider getTileProvider() {
    return getDefaultTileProvider();
  }
}
