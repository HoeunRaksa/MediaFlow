// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../storage/app_data_bootstrapper.dart';

typedef GetOpenFileNameC = Uint8 Function(Pointer<OPENFILENAMEW> lpofn);
typedef GetOpenFileNameDart = int Function(Pointer<OPENFILENAMEW> lpofn);

final class OPENFILENAMEW extends Struct {
  @Uint32()
  external int lStructSize;
  external Pointer<Void> hwndOwner;
  external Pointer<Void> hInstance;
  external Pointer<Utf16> lpstrFilter;
  external Pointer<Utf16> lpstrCustomFilter;
  @Uint32()
  external int nMaxCustFilter;
  @Uint32()
  external int nFilterIndex;
  external Pointer<Utf16> lpstrFile;
  @Uint32()
  external int nMaxFile;
  external Pointer<Utf16> lpstrFileTitle;
  @Uint32()
  external int nMaxFileTitle;
  external Pointer<Utf16> lpstrInitialDir;
  external Pointer<Utf16> lpstrTitle;
  @Uint32()
  external int Flags;
  @Uint16()
  external int nFileOffset;
  @Uint16()
  external int nFileExtension;
  external Pointer<Utf16> lpstrDefExt;
  @IntPtr()
  external int lCustData;
  external Pointer<Void> lpfnHook;
  external Pointer<Utf16> lpTemplateName;
  external Pointer<Void> pvReserved;
  @Uint32()
  external int dwReserved;
  @Uint32()
  external int FlagsEx;
}

class ProductImageService {
  const ProductImageService();

  static Future<String?> pickImageFile() async {
    if (Platform.isWindows) return pickImageFileWindows();
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
          uniformTypeIdentifiers: ['public.image'],
        ),
      ],
    );
    return file?.path;
  }

  static const supportedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  /// Gets the persistent product images directory inside the app data folder.
  static Future<Directory> getImagesDirectory({Directory? baseDataDir}) async {
    final baseDir =
        baseDataDir ?? await AppDataBootstrapper.defaultDataDirectory();
    final imagesDir = Directory(p.join(baseDir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Validates whether a file path has an allowed image extension.
  static bool isValidImageFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Copies an external image file into app-managed persistent storage.
  /// Returns the managed file path.
  static Future<String?> importImage(
    String sourceFilePath, {
    required String productId,
    Directory? baseDataDir,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return null;
      if (!isValidImageFile(sourceFilePath)) return null;

      final imagesDir = await getImagesDirectory(baseDataDir: baseDataDir);
      final ext = p.extension(sourceFilePath).toLowerCase();
      final safeId = productId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = '${safeId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(imagesDir.path, fileName);

      final copiedFile = await sourceFile.copy(targetPath);
      return copiedFile.path;
    } catch (e) {
      debugPrint('Failed to import product image: $e');
      return null;
    }
  }

  /// Deletes a managed image file safely if it exists.
  static Future<void> deleteManagedImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete managed product image $imagePath: $e');
    }
  }

  /// Replaces an existing image reference with a newly imported image, cleaning up old file.
  static Future<String?> replaceImage({
    required String? oldImagePath,
    required String newSourceFilePath,
    required String productId,
    Directory? baseDataDir,
  }) async {
    final newPath = await importImage(
      newSourceFilePath,
      productId: productId,
      baseDataDir: baseDataDir,
    );
    if (newPath != null && oldImagePath != null && oldImagePath != newPath) {
      await deleteManagedImage(oldImagePath);
    }
    return newPath;
  }

  /// Opens native Windows file picker dialog filtered to image files (*.png, *.jpg, *.jpeg, *.webp).
  static String? pickImageFileWindows() {
    if (!Platform.isWindows) return null;
    try {
      final comdlg32 = DynamicLibrary.open('comdlg32.dll');
      final getOpenFileName = comdlg32
          .lookupFunction<GetOpenFileNameC, GetOpenFileNameDart>(
            'GetOpenFileNameW',
          );

      const filterStr =
          'Image Files (*.png;*.jpg;*.jpeg;*.webp)\x00*.png;*.jpg;*.jpeg;*.webp\x00PNG Files (*.png)\x00*.png\x00JPEG Files (*.jpg;*.jpeg)\x00*.jpg;*.jpeg\x00WEBP Files (*.webp)\x00*.webp\x00All Files (*.*)\x00*.*\x00\x00';

      final filterPtr = filterStr.toNativeUtf16();
      final fileBuffer = calloc<Uint16>(512 * 2);
      final titlePtr = 'Select Product Image'.toNativeUtf16();

      final ofn = calloc<OPENFILENAMEW>();
      ofn.ref.lStructSize = sizeOf<OPENFILENAMEW>();
      ofn.ref.lpstrFilter = filterPtr;
      ofn.ref.nFilterIndex = 1;
      ofn.ref.lpstrFile = fileBuffer.cast<Utf16>();
      ofn.ref.nMaxFile = 512;
      ofn.ref.lpstrTitle = titlePtr;
      ofn.ref.Flags =
          0x00000800 | 0x00000008; // OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST

      final result = getOpenFileName(ofn);
      String? selectedPath;
      if (result != 0) {
        selectedPath = fileBuffer.cast<Utf16>().toDartString();
      }

      calloc.free(filterPtr);
      calloc.free(fileBuffer);
      calloc.free(titlePtr);
      calloc.free(ofn);

      return selectedPath;
    } catch (e) {
      debugPrint('Error invoking Windows file dialog: $e');
      return null;
    }
  }
}
