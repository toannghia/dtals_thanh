import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future<void> initMapCaching() async {
  await FMTCObjectBoxBackend().initialise();
}
