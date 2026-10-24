import 'dart:convert';
import 'dart:io';

import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';

void main() {
  final seed = DefaultMaterialSeed.json(DateTime(2026));
  final dir = Directory('assets/seed')..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');

  void write(String fileName, Object? value) {
    File('${dir.path}/$fileName').writeAsStringSync(encoder.convert(value));
  }

  write('materials.json', seed['materials']);
  write('prices.json', seed['prices']);
  write(
    'material_quantity_price_tiers.json',
    seed['materialQuantityPriceTiers'],
  );
  write('packaging.json', seed['packagingRules']);
  write('product_kinds.json', seed['productTypeTemplates']);
  write('settings.json', {
    'settings': seed['settings'],
    'pricingTiers': seed['pricingTiers'],
    'formulaRules': seed['formulaRules'],
    'units': seed['units'],
    'categories': seed['categories'],
    'sellModes': seed['sellModes'],
  });
}
