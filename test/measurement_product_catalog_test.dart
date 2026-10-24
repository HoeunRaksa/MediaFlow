import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/data/measurement_product_catalog.dart';

void main() {
  test('PVC measurement catalog groups priced lengths by product family', () {
    final now = DateTime.utc(2026, 8, 8);
    final families = const MeasurementProductCatalog().build(
      materials: DefaultMaterialSeed.materials(now),
      prices: DefaultMaterialSeed.prices(now),
      at: now,
    );
    final k = families.singleWhere((family) => family.id == 'pvc_k');
    final p = families.singleWhere((family) => family.id == 'pvc_p');

    expect(k.code, 'K');
    expect(k.widthMm, 400);
    expect(k.thicknessMm, 10);
    expect(k.variants.map((variant) => variant.lengthMm), [3000, 4000]);
    expect(k.variants.map((variant) => variant.unitPrice), [6.70, 8.60]);
    expect(k.variants.map((variant) => variant.materialId), [
      'pvc_k_3000',
      'pvc_k_4000',
    ]);
    expect(p.variants.map((variant) => variant.unitPrice), [6.90, 8.85]);
    expect(
      families.any((family) => family.id == 'pvc_factory_160x22'),
      isFalse,
      reason: 'Cost-only products must not appear in the selling calculator.',
    );
  });
}
