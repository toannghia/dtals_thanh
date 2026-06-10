import 'package:flutter_map/flutter_map.dart';
import 'map_tile_provider_native.dart' if (dart.library.html) 'map_tile_provider_web.dart';

TileProvider getDefaultTileProvider() {
  return getMapTileProvider();
}
