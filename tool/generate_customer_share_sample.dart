import 'dart:io';
import 'dart:typed_data';

import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/services/invoice_pdf_service.dart';

Future<void> main() async {
  final assets = InvoicePdfAssets(
    logo: _bytes('assets/brand/logo.png'),
    regularFont: _bytes('assets/fonts/NotoSansKhmer-Regular.ttf'),
    boldFont: _bytes('assets/fonts/NotoSansKhmer-Bold.ttf'),
    latinFont: _bytes('assets/fonts/Roboto-Regular.ttf'),
  );
  final document = InvoiceDocument(
    invoiceNumber: 'QT-20260906-001',
    issuedAt: DateTime(2026, 9, 6),
    documentType: CustomerDocumentType.quotation,
    customerName: 'លោក សុខ ដារ៉ា',
    customerPhone: '012 345 678',
    customerAddress: 'សែនសុខ រាជធានីភ្នំពេញ',
    note: 'សូមពិនិត្យបរិមាណ និងតម្លៃមុនពេលបញ្ជាទិញ។',
    lines: const [
      InvoiceLine(
        description: 'ពិដាន 4ជ្រុង',
        specification: 'ពិដាន PVC • 0.36 × 4.20m',
        quantity: 70,
        unit: 'សន្លឹក',
        unitPrice: 2.5,
        salePriceLabel: r'$2.50 / សន្លឹក',
        lineTotal: 175,
        packageBreakdown: '5 កេស + 10 សន្លឹក',
      ),
      InvoiceLine(
        description: 'Tវែង 3m',
        specification: 'គ្រោងពិដាន • 3m',
        quantity: 14,
        unit: 'ដើម',
        unitPrice: 3,
        salePriceLabel: r'$3.00 / ដើម',
        lineTotal: 42,
      ),
      InvoiceLine(
        description: 'K 3m',
        specification: 'PVC Panel • 400 × 10 × 3000mm',
        quantity: 22,
        unit: 'សន្លឹក',
        unitPrice: 4,
        salePriceLabel: r'$4.00 / សន្លឹក',
        lineTotal: 88,
      ),
    ],
  );

  final bytes = await InvoicePdfService(
    assets: assets,
  ).buildShareImagePdf(document);
  final output = File('tmp/customer_share_sample.pdf');
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(bytes, flush: true);
  stdout.writeln(output.absolute.path);
}

Uint8List _bytes(String path) =>
    Uint8List.fromList(File(path).readAsBytesSync());
