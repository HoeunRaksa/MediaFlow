import 'dart:convert';

import 'package:file_selector/file_selector.dart';

class ProductImageService {
  const ProductImageService();

  static const supportedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  static Future<String?> pickImageFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'webp']),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 2 * 1024 * 1024) {
      throw StateError(
        'Choose an image smaller than 2 MB for browser storage.',
      );
    }
    final type = file.name.toLowerCase().endsWith('.png')
        ? 'image/png'
        : file.name.toLowerCase().endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    return 'data:$type;base64,${base64Encode(await file.readAsBytes())}';
  }

  static bool isValidImageFile(String path) => path.startsWith('data:image/');

  static Future<String?> importImage(
    String path, {
    required String productId,
  }) async => isValidImageFile(path) ? path : null;

  static Future<String?> replaceImage({
    required String? oldImagePath,
    required String newSourceFilePath,
    required String productId,
  }) => importImage(newSourceFilePath, productId: productId);

  static Future<void> deleteManagedImage(String? path) async {}
}
