class ImageCompress {
  static Future<List<int>> compress(List<int> imageBytes, {int quality = 80}) async {
    return imageBytes;
  }

  static bool shouldCompress(int byteLength) {
    return byteLength > 2 * 1024 * 1024;
  }
}
