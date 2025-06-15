import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class DatabaseHelper {
  static late Box box;

  static Future<void> init() async {
    await Hive.initFlutter();
    box = await Hive.openBox('instaDemoBox');
  }

  static T? readData<T>(String key) {
    return box.get(key) as T?;
  }

  static Future<void> updateData(String key, dynamic value) async {
    await box.put(key, value);
  }

  static Future<void> deleteData(String key) async {
    await box.delete(key);
  }

  static Future<String?> imageToBase64(XFile image) async {
    try {
      late Uint8List bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      } else {
        bytes = await File(image.path).readAsBytes();
      }
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }
}
