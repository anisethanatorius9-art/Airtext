import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CacheManagerService {
  static Future<String> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appDocDir = await getApplicationDocumentsDirectory();

      var totalSize = 0;
      if (tempDir.existsSync()) {
        totalSize += _dirSize(tempDir);
      }
      if (appDocDir.existsSync()) {
        totalSize += _dirSize(appDocDir);
      }

      final sizeInMb = totalSize / (1024 * 1024);
      return '${sizeInMb.toStringAsFixed(2)} MB';
    } on Exception {
      return '0.00 MB';
    }
  }

  static int _dirSize(Directory dir) {
    var totalSize = 0;
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      }
    } on Exception {
      return totalSize;
    }

    return totalSize;
  }

  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        await tempDir.create(recursive: true);
      }
    } on Exception {
      // Gracefully ignore cache clear failures in production.
    }
  }
}
