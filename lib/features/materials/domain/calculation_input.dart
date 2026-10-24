class CalculationInput {
  const CalculationInput({
    required this.area,
    required this.pricingTierId,
    this.selectedOptionalMaterialIds = const [],
    this.manualQuantities = const {},
    this.discountAmount = 0,
    this.discountPercent = 0,
  });

  final double area;
  final String pricingTierId;
  final List<String> selectedOptionalMaterialIds;
  final Map<String, double> manualQuantities;
  final double discountAmount;
  final double discountPercent;
}
