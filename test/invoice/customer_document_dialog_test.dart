import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/theme/sakura_theme.dart';
import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/invoice/presentation/customer_document_dialog.dart';

void main() {
  testWidgets('collects customer details and copies a 4K quotation', (
    tester,
  ) async {
    InvoiceDocument? submitted;
    InvoiceDocument? saved;
    final invoice = InvoiceDocument(
      invoiceNumber: 'INV-20260905-001',
      issuedAt: DateTime(2026, 9, 5),
      lines: const [
        InvoiceLine(
          description: 'K 3m',
          specification: '400 x 10 x 3000 mm',
          quantity: 22,
          unit: 'សន្លឹក',
          unitPrice: 4,
          lineTotal: 88,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(fontFamily: 'NotoSansKhmer'),
        home: Scaffold(
          body: CustomerDocumentDialog(
            initialDocument: invoice,
            onCopy: (document) async => submitted = document,
            onSave: (document) async {
              saved = document;
              return r'C:\Invoices\quotation-4k.png';
            },
          ),
        ),
      ),
    );

    expect(find.text('សំណង់ទំនើប'), findsWidgets);
    expect(
      find.byKey(const ValueKey('customer-document-preview')),
      findsOneWidget,
    );
    expect(find.text('ពិនិត្យមើលលម្អិត'), findsOneWidget);
    expect(find.text('ចម្លង PNG 4K'), findsOneWidget);
    expect(find.text('រក្សាទុក PNG 4K'), findsOneWidget);
    expect(find.text('បោះពុម្ពវិក្កយបត្រ'), findsNothing);
    expect(find.textContaining('Owner cost'), findsNothing);
    expect(find.textContaining('Profit'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('customer-document-name')),
      'សុខ ដារ៉ា',
    );
    await tester.enterText(
      find.byKey(const ValueKey('customer-document-phone')),
      '012 345 678',
    );
    await tester.tap(find.text('សម្រង់តម្លៃ'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('customer-document-copy-4k')));
    await tester.pump();

    expect(submitted?.customerName, 'សុខ ដារ៉ា');
    expect(submitted?.customerPhone, '012 345 678');
    expect(submitted?.documentType, CustomerDocumentType.quotation);
    expect(submitted?.invoiceNumber, 'QT-20260905-001');
    expect(submitted?.grandTotal, 88);
    expect(
      find.byKey(const ValueKey('customer-document-preview')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('customer-document-save-4k')));
    await tester.pump();

    expect(saved?.customerName, 'សុខ ដារ៉ា');
    expect(saved?.documentType, CustomerDocumentType.quotation);
    expect(saved?.grandTotal, 88);
  });
}
