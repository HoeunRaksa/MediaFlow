import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/invoice/domain/invoice_document.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_models.dart';

void main() {
  group('customer document projection', () {
    test('uses the selected document type in its customer number', () {
      final quotation = InvoiceDocument.fromSaleItems(
        const [],
        issuedAt: DateTime(2026, 9, 6, 10, 30),
        documentType: CustomerDocumentType.quotation,
      );

      expect(quotation.invoiceNumber, 'QT-20260906-103000');
      expect(quotation.documentTitleKhmer, 'សម្រង់តម្លៃ');
      expect(quotation.documentTitleEnglish, 'QUOTATION');
    });

    test('changes an ephemeral document from invoice to quotation', () {
      final document = InvoiceDocument(
        invoiceNumber: 'INV-20260906-001',
        issuedAt: DateTime(2026, 9, 6),
        lines: const [],
      ).copyWithCustomer(documentType: CustomerDocumentType.quotation);

      expect(document.invoiceNumber, 'QT-20260906-001');
      expect(document.documentType, CustomerDocumentType.quotation);
    });

    test(
      'projects each pricing method with customer sale information only',
      () {
        final cases = <({String id, String expected})>[
          (id: ChargeMethodIds.unitOnly, expected: r'$4.00 / សន្លឹក'),
          (id: ChargeMethodIds.boxOnly, expected: r'$30.00 / កេស'),
          (
            id: ChargeMethodIds.boxPlusLoose,
            expected: r'$30.00 / កេស + $4.00 / សន្លឹក',
          ),
          (id: ChargeMethodIds.areaM2Price, expected: r'$3.50 / m²'),
          (id: ChargeMethodIds.manualTotal, expected: 'កំណត់តម្លៃសរុប'),
          (id: ChargeMethodIds.quantityOnly, expected: ''),
        ];

        for (final testCase in cases) {
          final line = InvoiceLine.fromSaleResult(
            _saleResult(chargeMethodId: testCase.id),
          );

          expect(line.salePriceLabel, testCase.expected);
          expect(line.lineTotal, 88);
          expect(line.quantity, 22);
        }
      },
    );
  });
}

ProductSaleResult _saleResult({required String chargeMethodId}) {
  return ProductSaleResult(
    productKindId: 'pvc',
    productKindNameKhmer: 'PVC',
    materialId: 'k3',
    materialNameKhmer: 'K 3m',
    askModeId: CustomerAskModeIds.looseProductSale,
    offerId: null,
    spec: '400 × 10 × 3000 mm',
    unitKhmer: 'សន្លឹក',
    inputMethodId: InputMethodIds.looseQuantity,
    inputMethodNameKhmer: 'បញ្ចូលចំនួនរាយ',
    chargeMethodId: chargeMethodId,
    chargeMethodNameKhmer: 'គិតតម្លៃ',
    formulaText: '',
    areaM2: 8.8,
    widthM: null,
    lengthM: null,
    rawQuantity: 22,
    sellQuantity: 22,
    itemsPerBox: 12,
    packagingFullBoxes: 1,
    packagingLooseItems: 10,
    chargedBoxes: 1,
    saleUnitPrice: 4,
    saleBoxPrice: 30,
    salePricePerM2: 3.5,
    includeAreaRevenue: true,
    costPricePerM2: 1.25,
    costUnitPrice: 2,
    costBoxPrice: 20,
    manualTotalPrice: 88,
    productRevenue: 88,
    productCost: 44,
    includeDelivery: false,
    deliveryModeId: 'flat_delivery',
    deliveryPayerId: 'no_delivery',
    deliveryRate: 0,
    totalFullBoxes: 1,
    totalLooseItems: 10,
    deliveryFeeTotal: 0,
    deliveryRevenue: 0,
    deliveryCostToOwner: 0,
    customerPayTotal: 88,
    ownerCostTotal: 44,
    ownerProfit: 44,
    costZeroWarning: false,
    belowCost: false,
    canAddToTemporarySale: true,
    validationErrors: const [],
  );
}
