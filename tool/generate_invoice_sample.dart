import 'dart:io';
import 'dart:typed_data';

import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/services/invoice_pdf_service.dart';
import 'package:pdf/pdf.dart';

Future<void> main() async {
  final assets = InvoicePdfAssets(
    logo: _bytes('assets/brand/logo.png'),
    regularFont: _bytes('assets/fonts/NotoSansKhmer-Regular.ttf'),
    boldFont: _bytes('assets/fonts/NotoSansKhmer-Bold.ttf'),
    latinFont: _bytes('assets/fonts/Roboto-Regular.ttf'),
  );
  final invoice = InvoiceDocument(
    invoiceNumber: 'INV-20260905-001',
    issuedAt: DateTime(2026, 9, 5),
    customerName: 'លោក សុខ ដារ៉ា',
    customerPhone: '012 345 678',
    customerAddress: 'សែនសុខ រាជធានីភ្នំពេញ',
    note: 'ទំនិញដែលបានទិញ សូមពិនិត្យចំនួនមុនពេលទទួល។',
    lines: const [
      InvoiceLine(
        description: 'ពិដាន 4ជ្រុង',
        specification: 'ពិដាន PVC • 0.36 × 4.20m',
        quantity: 70,
        unit: 'សន្លឹក',
        unitPrice: 2.5,
        lineTotal: 175,
        packageBreakdown: '5 កេស + 10 សន្លឹក',
      ),
      InvoiceLine(
        description: 'Tវែង 3m',
        specification: 'គ្រោងពិដាន • 3m',
        quantity: 14,
        unit: 'ដើម',
        unitPrice: 3,
        lineTotal: 42,
      ),
      InvoiceLine(
        description: 'Tខ្លី 0.6m',
        specification: 'គ្រោងពិដាន • 0.6m',
        quantity: 68,
        unit: 'ដើម',
        unitPrice: 0.8,
        lineTotal: 54.4,
      ),
      InvoiceLine(
        description: 'ជ្រី V 2.95m',
        specification: 'សម្ភារៈពិដាន • 2.95m',
        quantity: 8,
        unit: 'ដើម',
        unitPrice: 1.75,
        lineTotal: 14,
      ),
      InvoiceLine(
        description: 'K 3m',
        specification: 'PVC Panel • 400 × 10 × 3000mm',
        quantity: 22,
        unit: 'សន្លឹក',
        unitPrice: 4,
        lineTotal: 88,
      ),
      InvoiceLine(
        description: '៤ភ្លីធំ',
        specification: 'PVC Panel • 160 × 22 × 3000mm',
        quantity: 23,
        unit: 'សន្លឹក',
        unitPrice: 3.25,
        lineTotal: 74.75,
      ),
    ],
  );

  final bytes = await InvoicePdfService(
    assets: assets,
  ).build(invoice, pageFormat: PdfPageFormat.a4);
  final output = File('output/pdf/professional_invoice_sample.pdf');
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(bytes, flush: true);
  stdout.writeln(output.absolute.path);
}

Uint8List _bytes(String path) =>
    Uint8List.fromList(File(path).readAsBytesSync());
