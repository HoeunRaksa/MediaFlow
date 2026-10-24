class ProductKindCalculationInput {
  const ProductKindCalculationInput({
    required this.productKindId,
    required this.areaM2,
    this.manualQuantities = const {},
    this.sellModeOverrides = const {},
    this.discountAmount = 0,
    this.discountPercent = 0,
  });

  final String productKindId;
  final double? areaM2;
  final Map<String, double> manualQuantities;
  final Map<String, String> sellModeOverrides;
  final double discountAmount;
  final double discountPercent;
}

class ProductKindCalculationLine {
  const ProductKindCalculationLine({
    required this.materialId,
    required this.khmerName,
    required this.englishName,
    required this.spec,
    required this.formulaText,
    required this.rawQuantity,
    required this.roundedQuantity,
    required this.unitKhmer,
    required this.unitEnglish,
    required this.itemsPerBox,
    required this.packagingFullBoxes,
    required this.packagingLooseItems,
    required this.sellModeId,
    required this.unitPrice,
    required this.boxPrice,
    required this.chargedBoxes,
    required this.lineTotal,
  });

  final String materialId;
  final String khmerName;
  final String englishName;
  final String spec;
  final String formulaText;
  final double rawQuantity;
  final int roundedQuantity;
  final String unitKhmer;
  final String unitEnglish;
  final int? itemsPerBox;
  final int packagingFullBoxes;
  final int packagingLooseItems;
  final String sellModeId;
  final double? unitPrice;
  final double? boxPrice;
  final int? chargedBoxes;
  final double lineTotal;
}

class ProductKindCalculationResult {
  const ProductKindCalculationResult({
    required this.productKindId,
    required this.productKindNameKhmer,
    required this.productKindNameEnglish,
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.validationErrors,
  });

  final String productKindId;
  final String productKindNameKhmer;
  final String productKindNameEnglish;
  final List<ProductKindCalculationLine> lines;
  final double subtotal;
  final double discountTotal;
  final double grandTotal;
  final List<String> validationErrors;
}
