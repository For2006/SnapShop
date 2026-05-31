import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;

class ImageCompress {
  static Future<List<int>> compress(List<int> imageBytes, {int quality = 60}) async {
    final result = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(imageBytes),
      quality: quality,
      minWidth: 512,
      minHeight: 512,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  static Future<bool> shouldCompress(List<int> imageBytes) async {
    return imageBytes.length > 200 * 1024; // 超过200KB就压缩
  }
}
