import 'dart:io';
import 'package:dio/dio.dart';

// Mobile implementation using dart:io File
Future<MultipartFile> buildMultipartFile(String path, String filename) async {
  return MultipartFile.fromFile(path, filename: filename);
}
