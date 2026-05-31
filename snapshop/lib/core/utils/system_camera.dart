import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SystemCamera {
  static Future<String?> takePicture() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      
      if (photo == null) return null;
      
      final originalFile = File(photo.path);
      final originalSize = await originalFile.length();
      
      debugPrint('📸 原图大小: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // 快速压缩：目标 500KB 以内，70%质量，1280px最大宽度
      final dir = await originalFile.parent;
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        rotate: 0,
        autoCorrectionAngle: true,
      );
      
      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        debugPrint('✅ 压缩后大小: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        return compressedFile.path;
      }
      
      return photo.path;
    } catch (e) {
      debugPrint('SystemCamera error: $e');
      return null;
    }
  }
  
  static Future<String?> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
      
      if (photo == null) return null;
      
      final originalFile = File(photo.path);
      final originalSize = await originalFile.length();
      
      debugPrint('🖼️  原图大小: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // 快速压缩
      final dir = await originalFile.parent;
      final targetPath = '${dir.path}/compressed_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        rotate: 0,
        autoCorrectionAngle: true,
      );
      
      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        debugPrint('✅ 压缩后大小: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        return compressedFile.path;
      }
      
      return photo.path;
    } catch (e) {
      debugPrint('SystemCamera gallery error: $e');
      return null;
    }
  }
}
