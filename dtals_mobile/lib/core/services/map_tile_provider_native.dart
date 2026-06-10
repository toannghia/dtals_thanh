import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

TileProvider getMapTileProvider() {
  return const FMTCStore('OSMTiles').getTileProvider();
}
