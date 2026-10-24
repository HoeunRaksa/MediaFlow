import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/packaging_rule.dart';
import '../data/models/product_type_template.dart';
import '../data/models/sell_mode.dart';
import 'live_calculation_models.dart';
import 'live_material_calculation_engine.dart';
import 'product_kind_calculation_models.dart';

typedef ProductKindTemplate = ProductTypeTemplate;
typedef ProductKindMaterialRule = ProductTemplateMaterialRule;

class ProductKindCalculationEngine {
  ProductKindCalculationEngine({DateTime Function()? clock})
    : _liveEngine = LiveMaterialCalculationEngine(clock: clock);

  final LiveMaterialCalculationEngine _liveEngine;

  ProductKindCalculationResult calculate({
    required ProductKindCalculationInput input,
    required ProductKindTemplate productKind,
    required List<ProductKindMaterialRule> rules,
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    required List<PackagingRule> packagingRules,
    required List<SellMode> sellModes,
  }) {
    final liveResult = _liveEngine.calculate(
      input: LiveCalculationInput(
        productTypeTemplateId: input.productKindId,
        areaM2: input.areaM2,
        selectedOptionalMaterialIds: rules
            .where((rule) => !rule.includedByDefault)
            .map((rule) => rule.materialId)
            .where((id) => input.manualQuantities.containsKey(id))
            .toList(),
        manualQuantities: input.manualQuantities,
        sellModeOverrides: input.sellModeOverrides,
        discountAmount: input.discountAmount,
        discountPercent: input.discountPercent,
      ),
      productType: productKind.copyWith(defaultMaterialRules: rules),
      materials: materials,
      prices: prices,
      sellModes: sellModes,
      packagingRules: packagingRules,
    );

    return ProductKindCalculationResult(
      productKindId: liveResult.productTypeTemplateId,
      productKindNameKhmer: liveResult.productTypeNameKhmer,
      productKindNameEnglish: liveResult.productTypeNameEnglish,
      lines: liveResult.lines
          .map(
            (line) => ProductKindCalculationLine(
              materialId: line.materialId,
              khmerName: line.khmerName,
              englishName: line.englishName,
              spec: line.spec,
              formulaText: line.formulaText,
              rawQuantity: line.rawQuantity,
              roundedQuantity: line.roundedQuantity,
              unitKhmer: line.unitKhmer,
              unitEnglish: line.unitEnglish,
              itemsPerBox: line.itemsPerBox,
              packagingFullBoxes: line.packagingFullBoxes,
              packagingLooseItems: line.packagingLooseItems,
              sellModeId: line.sellModeId,
              unitPrice: line.unitPrice,
              boxPrice: line.boxPrice,
              chargedBoxes: line.chargedBoxes,
              lineTotal: line.lineTotal,
            ),
          )
          .toList(growable: false),
      subtotal: liveResult.subtotal,
      discountTotal: liveResult.discountTotal,
      grandTotal: liveResult.grandTotal,
      validationErrors: liveResult.validationErrors,
    );
  }
}
