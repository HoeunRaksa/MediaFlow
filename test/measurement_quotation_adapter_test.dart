import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/data/measurement_quotation_adapter.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';

void main() {
  test('measurement quantities hand off through existing sale engine', () {
    final now = DateTime(2026, 1, 1);
    final state = AppState()
      ..materials = DefaultMaterialSeed.materials(now)
      ..prices = DefaultMaterialSeed.prices(now)
      ..packagingRules = DefaultMaterialSeed.packagingRules(now)
      ..productTemplates = DefaultMaterialSeed.productTypeTemplates();
    const variants = [
      MeasurementProductVariant(
        variantId: 3000,
        label: '400 × 10 × 3000 mm',
        widthMm: 400,
        lengthMm: 3000,
        thicknessMm: 10,
        unitPrice: 9,
      ),
      MeasurementProductVariant(
        variantId: 4000,
        label: '400 × 10 × 4000 mm',
        widthMm: 400,
        lengthMm: 4000,
        thicknessMm: 10,
        unitPrice: 12,
      ),
    ];
    const candidate = MeasurementCandidate(
      candidateId: 1,
      valid: true,
      stockMode: MeasurementStockMode.mixed,
      singleVariantId: null,
      quantities: [
        MeasurementVariantQuantity(
          variantId: 3000,
          baseQuantity: 2,
          reserveQuantity: 0,
          purchaseQuantity: 2,
        ),
        MeasurementVariantQuantity(
          variantId: 4000,
          baseQuantity: 3,
          reserveQuantity: 1,
          purchaseQuantity: 4,
        ),
      ],
      cuts: [],
      roomLayouts: [],
      basePieceCount: 5,
      reservePieceCount: 1,
      purchasePieceCount: 6,
      jointCount: 2,
      requiredAreaM2: 10,
      purchasedAreaM2: 10,
      wasteAreaM2: 0,
      wastePercent: 0,
      totalCost: 66,
      score: 0,
    );

    final lines = const MeasurementQuotationAdapter().createLines(
      state: state,
      candidate: candidate,
      variants: variants,
    );
    expect(lines, hasLength(2));
    expect(lines[0].sellQuantity, 2);
    expect(lines[1].sellQuantity, 4);
    expect(lines[0].spec, '400 × 10 × 3000 mm');
    expect(lines[1].customerPayTotal, 48);
    expect(lines.every((line) => line.canAddToTemporarySale), isTrue);

    state.addTemporarySaleResults(lines);
    expect(state.currentSaleItems, hasLength(2));
    expect(state.temporarySaleSummary.customerPayTotal, 66);

    final estimated = const MeasurementQuotationAdapter().createAreaLines(
      state: state,
      candidate: const AreaCoverageCandidate(
        variantId: 3000,
        baseQuantity: 3,
        reserveQuantity: 1,
        purchaseQuantity: 4,
        requiredAreaM2: 3,
        purchasedAreaM2: 4.8,
        wasteAreaM2: 1.8,
        wastePercent: 37.5,
        totalCost: 36,
      ),
      variants: variants,
    );
    expect(estimated.single.sellQuantity, 4);
    expect(estimated.single.spec, contains('ប៉ាន់ស្មានតាម m²'));
  });
}
