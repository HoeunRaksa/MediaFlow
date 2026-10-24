class QuotationLineResult {
  const QuotationLineResult({
    required this.materialId,
    required this.khmerName,
    required this.englishName,
    required this.spec,
    required this.categoryId,
    required this.unitKhmer,
    required this.unitEnglish,
    required this.formulaTypeId,
    required this.rawQuantity,
    required this.roundedQuantity,
    required this.pricingTierId,
    required this.pricingBehaviorId,
    required this.appliedUnitPrice,
    required this.chargedBoxes,
    required this.lineTotal,
    required this.showInCustomerQuote,
    required this.showInPickList,
    required this.isServiceOnly,
    required this.snapshot,
  });

  final String materialId;
  final String khmerName;
  final String englishName;
  final String spec;
  final String categoryId;
  final String unitKhmer;
  final String unitEnglish;
  final String formulaTypeId;
  final double rawQuantity;
  final int roundedQuantity;
  final String pricingTierId;
  final String pricingBehaviorId;
  final double appliedUnitPrice;
  final int? chargedBoxes;
  final double lineTotal;
  final bool showInCustomerQuote;
  final bool showInPickList;
  final bool isServiceOnly;
  final Map<String, dynamic> snapshot;
}

class PickListLineResult {
  const PickListLineResult({
    required this.materialId,
    required this.khmerName,
    required this.englishName,
    required this.spec,
    required this.totalQuantity,
    required this.unitKhmer,
    required this.unitEnglish,
    required this.itemsPerBox,
    required this.packagingFullBoxes,
    required this.packagingLooseItems,
  });

  final String materialId;
  final String khmerName;
  final String englishName;
  final String spec;
  final int totalQuantity;
  final String unitKhmer;
  final String unitEnglish;
  final int itemsPerBox;
  final int? packagingFullBoxes;
  final int? packagingLooseItems;
}

class QuotationCalculationResult {
  const QuotationCalculationResult({
    required this.area,
    required this.pricingTierId,
    required this.pricingTierNameKhmer,
    required this.pricingTierNameEnglish,
    required this.quoteLines,
    required this.pickListLines,
    required this.subtotal,
    required this.discountAmount,
    required this.discountPercent,
    required this.discountTotal,
    required this.grandTotal,
    required this.calculatedAt,
  });

  final double area;
  final String pricingTierId;
  final String pricingTierNameKhmer;
  final String pricingTierNameEnglish;
  final List<QuotationLineResult> quoteLines;
  final List<PickListLineResult> pickListLines;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double discountTotal;
  final double grandTotal;
  final DateTime calculatedAt;
}
