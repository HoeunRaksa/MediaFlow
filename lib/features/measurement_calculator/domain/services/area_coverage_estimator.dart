import '../models/measurement_models.dart';

class AreaCoverageEstimator {
  const AreaCoverageEstimator();

  AreaCoverageResult estimate({
    required double areaM2,
    required List<MeasurementProductVariant> variants,
    required MeasurementOptimizationOptions options,
  }) {
    if (!areaM2.isFinite || areaM2 <= 0 || variants.isEmpty) {
      throw const FormatException('Area and product variants must be valid.');
    }
    final candidates = <AreaCoverageCandidate>[];
    for (final variant in variants) {
      final base = (areaM2 / variant.areaM2).ceil();
      final reserve = options.sparePercent <= 0
          ? 0
          : (base * options.sparePercent / 100).ceil();
      final purchase = base + reserve;
      final purchasedArea = purchase * variant.areaM2;
      final waste = purchasedArea - areaM2;
      candidates.add(
        AreaCoverageCandidate(
          variantId: variant.variantId,
          baseQuantity: base,
          reserveQuantity: reserve,
          purchaseQuantity: purchase,
          requiredAreaM2: areaM2,
          purchasedAreaM2: purchasedArea,
          wasteAreaM2: waste,
          wastePercent: waste / purchasedArea * 100,
          totalCost: purchase * variant.unitPrice,
        ),
      );
    }
    var selected = 0;
    for (var i = 1; i < candidates.length; i++) {
      if (_better(candidates[i], candidates[selected], options.optimizeFor)) {
        selected = i;
      }
    }
    return AreaCoverageResult(
      candidates: List.unmodifiable(candidates),
      selectedCandidateIndex: selected,
    );
  }

  bool _better(
    AreaCoverageCandidate left,
    AreaCoverageCandidate right,
    MeasurementOptimizeFor optimizeFor,
  ) {
    const epsilon = 1e-7;
    int compare(double a, double b) =>
        (a - b).abs() <= epsilon ? 0 : (a < b ? -1 : 1);
    final values = switch (optimizeFor) {
      MeasurementOptimizeFor.lowestCost => [
        compare(left.totalCost, right.totalCost),
        compare(left.wasteAreaM2, right.wasteAreaM2),
        left.purchaseQuantity.compareTo(right.purchaseQuantity),
      ],
      MeasurementOptimizeFor.lowestWaste ||
      MeasurementOptimizeFor.fewestJoints => [
        compare(left.wasteAreaM2, right.wasteAreaM2),
        compare(left.totalCost, right.totalCost),
        left.purchaseQuantity.compareTo(right.purchaseQuantity),
      ],
    };
    return values.firstWhere((value) => value != 0, orElse: () => 0) < 0;
  }
}
