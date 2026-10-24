import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/invoice_document.dart';
import 'customer_document_image_service.dart';

typedef CustomerDocumentSaveLocationPicker =
    Future<String?> Function({required String suggestedName});
typedef CustomerDocumentPngWriter =
    Future<void> Function(Uint8List pngBytes, String destinationPath);

/// Saves the same customer-safe 4K PNG used for copying, but only after the
/// user explicitly selects a destination in the native platform save dialog.
class CustomerDocumentPngSaveService {
  CustomerDocumentPngSaveService({
    required CustomerDocumentImageService imageService,
    CustomerDocumentSaveLocationPicker? pickLocation,
    CustomerDocumentPngWriter? writeFile,
  }) : _imageService = imageService,
       _pickLocation = pickLocation ?? _pickPngSaveLocation,
       _writeFile = writeFile ?? _writePngFile;

  final CustomerDocumentImageService _imageService;
  final CustomerDocumentSaveLocationPicker _pickLocation;
  final CustomerDocumentPngWriter _writeFile;

  Future<String?> save4kPng(InvoiceDocument document) async {
    await _imageService.ensure4kRenderingAvailable();

    final selectedPath = await _pickLocation(
      suggestedName: suggestedFileName(document),
    );
    if (selectedPath == null || selectedPath.trim().isEmpty) return null;

    final destinationPath = _withPngExtension(selectedPath.trim());
    final pngBytes = await _imageService.render4kImage(document);
    await _writeFile(pngBytes, destinationPath);
    return destinationPath;
  }

  static String suggestedFileName(InvoiceDocument document) =>
      '${document.invoiceNumber}-4K.png';

  static Future<String?> _pickPngSaveLocation({
    required String suggestedName,
  }) async {
    // iOS file_selector has no save dialog. Files exposes this app's Documents
    // folder; use a unique name so repeated exports never overwrite a file.
    if (kIsWeb) return suggestedName;
    if (Platform.isIOS) {
      final documents = await getApplicationDocumentsDirectory();
      final name = p.basenameWithoutExtension(suggestedName);
      return p.join(
        documents.path,
        '$name-${DateTime.now().microsecondsSinceEpoch}.png',
      );
    }
    const acceptedTypes = [
      XTypeGroup(label: 'PNG image', extensions: ['png']),
    ];
    final location = await getSaveLocation(
      acceptedTypeGroups: acceptedTypes,
      suggestedName: suggestedName,
      confirmButtonText: 'រក្សាទុក PNG',
    );
    return location?.path;
  }

  static Future<void> _writePngFile(
    Uint8List pngBytes,
    String destinationPath,
  ) {
    return XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: destinationPath,
    ).saveTo(destinationPath);
  }

  static String _withPngExtension(String path) =>
      path.toLowerCase().endsWith('.png') ? path : '$path.png';
}
