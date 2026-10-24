class LiveCalculationInput {
  const LiveCalculationInput({
    required this.productTypeTemplateId,
    required this.areaM2,
    this.selectedOptionalMaterialIds = const [],
    this.manualQuantities = const {},
    this.sellModeOverrides = const {},
    this.discountAmount = 0,
    this.discountPercent = 0,
  });

  final String productTypeTemplateId;
  final double? areaM2;
  final List<String> selectedOptionalMaterialIds;
  final Map<String, double> manualQuantities;
  final Map<String, String> sellModeOverrides;
  final double discountAmount;
  final double discountPercent;
}

class LiveCalculationLineResult {
  const LiveCalculationLineResult({
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
    required this.showInPickList,
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
  final bool showInPickList;
}

class LiveCalculationResult {
  const LiveCalculationResult({
    required this.productTypeTemplateId,
    required this.productTypeNameKhmer,
    required this.productTypeNameEnglish,
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.validationErrors,
  });

  final String productTypeTemplateId;
  final String productTypeNameKhmer;
  final String productTypeNameEnglish;
  final List<LiveCalculationLineResult> lines;
  final double subtotal;
  final double discountTotal;
  final double grandTotal;
  final List<String> validationErrors;

  bool get hasErrors => validationErrors.isNotEmpty;
}
