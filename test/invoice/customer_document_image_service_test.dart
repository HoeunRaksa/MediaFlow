import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/services/customer_document_image_service.dart';

void main() {
  test(
    'renders and copies a 3840-pixel customer document without storage',
    () async {
      final document = InvoiceDocument(
        invoiceNumber: 'INV-20260906-001',
        issuedAt: DateTime(2026, 9, 6),
        lines: const [],
      );
      Uint8List? rasterInput;
      Uint8List? clipboardImage;
      final service = CustomerDocumentImageService(
        buildPdf: (_) async => Uint8List.fromList('%PDF-test'.codeUnits),
        rasterize: (pdf) async {
          rasterInput = pdf;
          return Uint8List.fromList([137, 80, 78, 71]);
        },
        writeToClipboard: (png) async => clipboardImage = png,
        canRasterize: () async => true,
      );

      await service.copy4kImage(document);

      expect(String.fromCharCodes(rasterInput!), '%PDF-test');
      expect(clipboardImage, orderedEquals([137, 80, 78, 71]));
      expect(CustomerDocumentImageService.renderedWidthPixels, 3840);
    },
  );

  test('does not render or copy when rasterization is unavailable', () async {
    var built = false;
    var copied = false;
    final service = CustomerDocumentImageService(
      buildPdf: (_) async {
        built = true;
        return Uint8List(0);
      },
      writeToClipboard: (_) async => copied = true,
      canRasterize: () async => false,
    );
    final document = InvoiceDocument(
      invoiceNumber: 'INV-20260906-001',
      issuedAt: DateTime(2026, 9, 6),
      lines: const [],
    );

    await expectLater(service.copy4kImage(document), throwsStateError);

    expect(built, isFalse);
    expect(copied, isFalse);
  });
}
