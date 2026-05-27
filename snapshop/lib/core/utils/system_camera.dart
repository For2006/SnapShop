import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class SystemCamera {
  static Future<String?> takePicture() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      return photo?.path;
    } catch (e) {
      debugPrint('SystemCamera error: $e');
      return null;
    }
  }
}
