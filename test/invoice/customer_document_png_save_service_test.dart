import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/services/customer_document_image_service.dart';
import 'package:material_quote_pro/features/invoice/services/customer_document_png_save_service.dart';

void main() {
  final document = InvoiceDocument(
    invoiceNumber: 'QT-20260910-001',
    issuedAt: DateTime(2026, 9, 10),
    lines: const [],
  );

  test('saves the rendered 4K PNG at the user-selected location', () async {
    String? requestedFileName;
    Uint8List? savedBytes;
    String? savedPath;
    final imageService = CustomerDocumentImageService(
      buildPdf: (_) async => Uint8List.fromList('%PDF-test'.codeUnits),
      rasterize: (_) async => Uint8List.fromList([137, 80, 78, 71]),
      canRasterize: () async => true,
    );
    final service = CustomerDocumentPngSaveService(
      imageService: imageService,
      pickLocation: ({required suggestedName}) async {
        requestedFileName = suggestedName;
        return r'C:\Invoices\quote';
      },
      writeFile: (bytes, path) async {
        savedBytes = bytes;
        savedPath = path;
      },
    );

    final result = await service.save4kPng(document);

    expect(requestedFileName, 'QT-20260910-001-4K.png');
    expect(result, r'C:\Invoices\quote.png');
    expect(savedPath, r'C:\Invoices\quote.png');
    expect(savedBytes, orderedEquals([137, 80, 78, 71]));
    expect(CustomerDocumentImageService.renderedWidthPixels, 3840);
  });

  test('does not render or write when the user cancels Save As', () async {
    var rendered = false;
    var wroteFile = false;
    final imageService = CustomerDocumentImageService(
      buildPdf: (_) async {
        rendered = true;
        return Uint8List(0);
      },
      canRasterize: () async => true,
    );
    final service = CustomerDocumentPngSaveService(
      imageService: imageService,
      pickLocation: ({required suggestedName}) async => null,
      writeFile: (pngBytes, destinationPath) async => wroteFile = true,
    );

    final result = await service.save4kPng(document);

    expect(result, isNull);
    expect(rendered, isFalse);
    expect(wroteFile, isFalse);
  });

  test('does not open Save As when 4K rendering is unsupported', () async {
    var openedPicker = false;
    final imageService = CustomerDocumentImageService(
      buildPdf: (_) async => Uint8List(0),
      canRasterize: () async => false,
    );
    final service = CustomerDocumentPngSaveService(
      imageService: imageService,
      pickLocation: ({required suggestedName}) async {
        openedPicker = true;
        return r'C:\Invoices\quote.png';
      },
    );

    await expectLater(service.save4kPng(document), throwsStateError);

    expect(openedPicker, isFalse);
  });
}
