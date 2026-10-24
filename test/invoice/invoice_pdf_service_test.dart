import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/services/invoice_pdf_service.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lines = [
    InvoiceLine(
      description: 'ពិដាន 6លី',
      specification: '0.36m',
      quantity: 70,
      unit: 'សន្លឹក',
      unitPrice: 2.5,
      lineTotal: 175,
      packageBreakdown: '5 ប្រអប់ + 10 សន្លឹក',
    ),
    InvoiceLine(
      description: 'Tវែង 3m',
      specification: '3m',
      quantity: 14,
      unit: 'ដើម',
      unitPrice: 3,
      lineTotal: 42,
    ),
  ];

  test('invoice totals only customer-facing sale values', () {
    final invoice = InvoiceDocument(
      invoiceNumber: 'INV-20260905-001',
      issuedAt: DateTime(2026, 9, 5),
      customerName: 'អតិថិជនសាកល្បង',
      customerPhone: '012 345 678',
      customerAddress: 'ភ្នំពេញ',
      note: 'សូមអរគុណ',
      lines: lines,
    );

    expect(invoice.subtotal, 217);
    expect(invoice.grandTotal, 217);
    expect(invoice.totalQuantity, 84);
  });

  test(
    'builds a non-empty A4 PDF with embedded logo and Khmer fonts',
    () async {
      final assets = InvoicePdfAssets(
        logo: Uint8List.fromList(
          File('assets/brand/logo.png').readAsBytesSync(),
        ),
        regularFont: Uint8List.fromList(
          File('assets/fonts/NotoSansKhmer-Regular.ttf').readAsBytesSync(),
        ),
        boldFont: Uint8List.fromList(
          File('assets/fonts/NotoSansKhmer-Bold.ttf').readAsBytesSync(),
        ),
        latinFont: Uint8List.fromList(
          File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync(),
        ),
      );
      final invoice = InvoiceDocument(
        invoiceNumber: 'INV-20260905-001',
        issuedAt: DateTime(2026, 9, 5),
        customerName: 'អតិថិជនសាកល្បង',
        customerPhone: '012 345 678',
        customerAddress: 'ភ្នំពេញ',
        note: 'សូមអរគុណ',
        lines: lines,
      );

      final bytes = await InvoicePdfService(
        assets: assets,
      ).build(invoice, pageFormat: PdfPageFormat.a4);

      expect(bytes.length, greaterThan(50000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );

  test('builds a single-page 4K-width quotation source PDF', () async {
    final assets = InvoicePdfAssets(
      logo: Uint8List.fromList(File('assets/brand/logo.png').readAsBytesSync()),
      regularFont: Uint8List.fromList(
        File('assets/fonts/NotoSansKhmer-Regular.ttf').readAsBytesSync(),
      ),
      boldFont: Uint8List.fromList(
        File('assets/fonts/NotoSansKhmer-Bold.ttf').readAsBytesSync(),
      ),
      latinFont: Uint8List.fromList(
        File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync(),
      ),
    );
    final quotation = InvoiceDocument(
      invoiceNumber: 'QT-20260905-001',
      issuedAt: DateTime(2026, 9, 5),
      documentType: CustomerDocumentType.quotation,
      lines: lines,
    );

    final bytes = await InvoicePdfService(
      assets: assets,
    ).buildShareImagePdf(quotation);

    expect(InvoicePdfService.shareImageWidthPoints, 1080);
    expect(bytes.length, greaterThan(50000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
