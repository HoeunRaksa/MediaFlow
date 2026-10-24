import 'package:intl/intl.dart';

import '../../materials/domain/product_sale_models.dart';

enum CustomerDocumentType {
  invoice,
  quotation;

  String get khmerTitle => switch (this) {
    CustomerDocumentType.invoice => 'វិក្កយបត្រ',
    CustomerDocumentType.quotation => 'សម្រង់តម្លៃ',
  };

  String get englishTitle => switch (this) {
    CustomerDocumentType.invoice => 'INVOICE',
    CustomerDocumentType.quotation => 'QUOTATION',
  };

  String get numberPrefix => switch (this) {
    CustomerDocumentType.invoice => 'INV',
    CustomerDocumentType.quotation => 'QT',
  };
}

class InvoiceLine {
  const InvoiceLine({
    required this.description,
    required this.specification,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
    this.salePriceLabel = '',
    this.packageBreakdown,
  });

  final String description;
  final String specification;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;
  final String salePriceLabel;
  final String? packageBreakdown;

  factory InvoiceLine.fromSaleResult(ProductSaleResult result) {
    final salePrice = _salePrice(result);
    return InvoiceLine(
      description: result.materialNameKhmer,
      specification: [
        result.productKindNameKhmer,
        result.spec,
      ].where((value) => value.trim().isNotEmpty).join(' • '),
      quantity: result.sellQuantity,
      unit: result.unitKhmer,
      unitPrice: salePrice.value,
      lineTotal: result.customerPayTotal,
      salePriceLabel: salePrice.label,
      packageBreakdown: _packageBreakdown(result),
    );
  }

  static _SalePrice _salePrice(ProductSaleResult result) {
    final unit = result.unitKhmer;
    return switch (result.chargeMethodId) {
      ChargeMethodIds.unitOnly => _SalePrice(
        result.saleUnitPrice,
        '\$${result.saleUnitPrice.toStringAsFixed(2)} / $unit',
      ),
      ChargeMethodIds.boxOnly => _SalePrice(
        result.saleBoxPrice,
        '\$${result.saleBoxPrice.toStringAsFixed(2)} / កេស',
      ),
      ChargeMethodIds.boxPlusLoose => _SalePrice(
        result.saleUnitPrice,
        '\$${result.saleBoxPrice.toStringAsFixed(2)} / កេស + '
        '\$${result.saleUnitPrice.toStringAsFixed(2)} / $unit',
      ),
      ChargeMethodIds.areaM2Price => _SalePrice(
        result.salePricePerM2,
        '\$${result.salePricePerM2.toStringAsFixed(2)} / m²',
      ),
      ChargeMethodIds.manualTotal => const _SalePrice(0, 'កំណត់តម្លៃសរុប'),
      ChargeMethodIds.quantityOnly => const _SalePrice(0, ''),
      _ => const _SalePrice(0, ''),
    };
  }

  static String? _packageBreakdown(ProductSaleResult result) {
    if (result.itemsPerBox <= 0) return null;
    final parts = <String>[];
    if (result.packagingFullBoxes > 0) {
      parts.add('${result.packagingFullBoxes} កេស');
    }
    if (result.packagingLooseItems > 0) {
      parts.add('${result.packagingLooseItems} ${result.unitKhmer}');
    }
    return parts.isEmpty ? null : parts.join(' + ');
  }
}

class _SalePrice {
  const _SalePrice(this.value, this.label);

  final double value;
  final String label;
}

class InvoiceDocument {
  const InvoiceDocument({
    required this.invoiceNumber,
    required this.issuedAt,
    required this.lines,
    this.documentType = CustomerDocumentType.invoice,
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.note = '',
  });

  factory InvoiceDocument.fromSaleItems(
    List<ProductSaleResult> items, {
    DateTime? issuedAt,
    String? invoiceNumber,
    CustomerDocumentType documentType = CustomerDocumentType.invoice,
  }) {
    final date = issuedAt ?? DateTime.now();
    return InvoiceDocument(
      invoiceNumber:
          invoiceNumber ??
          '${documentType.numberPrefix}-${DateFormat('yyyyMMdd-HHmmss').format(date)}',
      issuedAt: date,
      lines: [for (final item in items) InvoiceLine.fromSaleResult(item)],
      documentType: documentType,
    );
  }

  final String invoiceNumber;
  final DateTime issuedAt;
  final CustomerDocumentType documentType;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String note;
  final List<InvoiceLine> lines;

  double get subtotal => lines.fold(0, (total, line) => total + line.lineTotal);
  double get grandTotal => subtotal;
  int get totalQuantity =>
      lines.fold(0, (total, line) => total + line.quantity);

  String get documentTitleKhmer => documentType.khmerTitle;
  String get documentTitleEnglish => documentType.englishTitle;

  InvoiceDocument copyWithCustomer({
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? note,
    CustomerDocumentType? documentType,
  }) {
    final selectedDocumentType = documentType ?? this.documentType;
    return InvoiceDocument(
      invoiceNumber: documentType == null
          ? invoiceNumber
          : _numberFor(selectedDocumentType, invoiceNumber),
      issuedAt: issuedAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      note: note ?? this.note,
      lines: lines,
      documentType: selectedDocumentType,
    );
  }

  static String _numberFor(CustomerDocumentType type, String number) {
    return number.replaceFirst(RegExp(r'^(INV|QT)-'), '${type.numberPrefix}-');
  }
}
