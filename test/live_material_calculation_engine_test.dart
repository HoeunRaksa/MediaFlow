import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/models/packaging_rule.dart';
import 'package:material_quote_pro/features/materials/data/models/product_type_template.dart';
import 'package:material_quote_pro/features/materials/data/models/sell_mode.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/materials/domain/product_kind_calculation_engine.dart';
import 'package:material_quote_pro/features/materials/domain/product_kind_calculation_models.dart';

void main() {
  final now = DateTime(2026, 6, 30);
  final engine = ProductKindCalculationEngine(clock: () => now);

  late List<MaterialItem> materials;
  late List<MaterialPrice> prices;
  late List<SellMode> sellModes;
  late List<PackagingRule> packagingRules;
  late List<ProductTypeTemplate> templates;

  setUp(() {
    materials = DefaultMaterialSeed.materials(now);
    prices = DefaultMaterialSeed.prices(now);
    sellModes = DefaultMaterialSeed.sellModes();
    packagingRules = DefaultMaterialSeed.packagingRules(now);
    templates = DefaultMaterialSeed.productTypeTemplates();
  });

  test('100 m2 ceiling full set returns expected packaging', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'ceiling_full_set',
        areaM2: 100,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(_line(result, 'ceiling_6mm').roundedQuantity, 278);
    expect(_line(result, 'ceiling_6mm').packagingFullBoxes, 23);
    expect(_line(result, 'ceiling_6mm').packagingLooseItems, 2);
    expect(_line(result, 'long_t_3m').roundedQuantity, 54);
    expect(_line(result, 'long_t_3m').packagingFullBoxes, 1);
    expect(_line(result, 'long_t_3m').packagingLooseItems, 0);
    expect(_line(result, 'short_t_06m').roundedQuantity, 270);
    expect(_line(result, 'short_t_06m').packagingFullBoxes, 3);
    expect(_line(result, 'short_t_06m').packagingLooseItems, 0);
    expect(_line(result, 'v_iron_295m').roundedQuantity, 20);
    expect(_line(result, 'v_iron_295m').packagingFullBoxes, 0);
    expect(_line(result, 'v_iron_295m').packagingLooseItems, 20);
  });

  test('box only round up charges ceiling as 24 boxes', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'ceiling_full_set',
        areaM2: 100,
        sellModeOverrides: {'ceiling_6mm': SellModeIds.boxOnlyRoundUp},
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(_line(result, 'ceiling_6mm').chargedBoxes, 24);
  });

  test('box plus loose charges full boxes and loose pieces', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'ceiling_full_set',
        areaM2: 100,
        sellModeOverrides: {'ceiling_6mm': SellModeIds.boxPlusLoose},
      ),
    );
    final ceiling = _line(result, 'ceiling_6mm');

    expect(result.validationErrors, isEmpty);
    expect(ceiling.packagingFullBoxes, 23);
    expect(ceiling.packagingLooseItems, 2);
    expect(ceiling.lineTotal, 301.40);
  });

  test('unit only charges every rounded item', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'ceiling_full_set',
        areaM2: 100,
        sellModeOverrides: {'ceiling_6mm': SellModeIds.unitOnly},
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(_line(result, 'ceiling_6mm').lineTotal, 333.60);
  });

  test('insulation manual quantity works and is not area based', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'insulation_only',
        areaM2: null,
        manualQuantities: {'insulation_indonesia_13kg': 2},
        sellModeOverrides: {'insulation_indonesia_13kg': SellModeIds.unitOnly},
      ),
    );
    final line = _line(result, 'insulation_indonesia_13kg');

    expect(result.validationErrors, isEmpty);
    expect(line.roundedQuantity, 2);
    expect(line.lineTotal, 70);
  });

  test('LED manual quantity can sell two boxes plus five loose pieces', () {
    final result = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'led_only',
        areaM2: null,
        manualQuantities: {'led_60w': 25},
        sellModeOverrides: {'led_60w': SellModeIds.boxPlusLoose},
      ),
    );
    final line = _line(result, 'led_60w');

    expect(result.validationErrors, isEmpty);
    expect(line.roundedQuantity, 25);
    expect(line.packagingFullBoxes, 2);
    expect(line.packagingLooseItems, 5);
    expect(line.lineTotal, 335);
  });

  test('product kinds keep area and manual calculators separated', () {
    final ceiling = _template(templates, 'ceiling_full_set');
    final insulation = _template(templates, 'insulation_only');
    final led = _template(templates, 'led_only');
    final wire = _template(templates, 'wire_only');

    expect(ceiling.inputModeId, InputModeIds.areaM2);
    expect(insulation.inputModeId, InputModeIds.manualQuantity);
    expect(led.inputModeId, InputModeIds.manualQuantity);
    expect(wire.inputModeId, InputModeIds.manualQuantity);

    final missingArea = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'ceiling_full_set',
        areaM2: null,
      ),
    );
    final manualOnly = _calculate(
      engine,
      templates,
      materials,
      prices,
      packagingRules,
      sellModes,
      const ProductKindCalculationInput(
        productKindId: 'wire_only',
        areaM2: null,
        manualQuantities: {'wire_2000m_11kg': 3},
        sellModeOverrides: {'wire_2000m_11kg': SellModeIds.unitOnly},
      ),
    );

    expect(missingArea.validationErrors, isNotEmpty);
    expect(manualOnly.validationErrors, isEmpty);
  });
}

ProductKindCalculationResult _calculate(
  ProductKindCalculationEngine engine,
  List<ProductTypeTemplate> templates,
  List<MaterialItem> materials,
  List<MaterialPrice> prices,
  List<PackagingRule> packagingRules,
  List<SellMode> sellModes,
  ProductKindCalculationInput input,
) {
  final template = _template(templates, input.productKindId);
  return engine.calculate(
    input: input,
    productKind: template,
    rules: template.defaultMaterialRules,
    materials: materials,
    prices: prices,
    packagingRules: packagingRules,
    sellModes: sellModes,
  );
}

ProductTypeTemplate _template(List<ProductTypeTemplate> templates, String id) {
  return templates.firstWhere((item) => item.id == id);
}

ProductKindCalculationLine _line(
  ProductKindCalculationResult result,
  String materialId,
) {
  return result.lines.firstWhere((line) => line.materialId == materialId);
}
