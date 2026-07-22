import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

// Web implementation using XFile bytes (dart:io not available on Web)
Future<MultipartFile> buildMultipartFile(String path, String filename) async {
  final xFile = XFile(path);
  final bytes = await xFile.readAsBytes();
  return MultipartFile.fromBytes(bytes, filename: filename);
}
