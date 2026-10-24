import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/core/storage/app_data_bootstrapper.dart';
import 'package:material_quote_pro/core/storage/local_json_storage.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/repositories/material_price_repository.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_engine.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_models.dart';

void main() {
  late Directory tempDir;
  late Map<String, String> seedAssets;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mqp_price_storage_');
    seedAssets = _seedAssetText();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  AppDataBootstrapper bootstrapper() {
    return AppDataBootstrapper(
      dataDirectory: tempDir,
      assetLoader: (assetPath) async => seedAssets[assetPath]!,
    );
  }

  test('first launch creates local prices.json from built-in seed', () async {
    await bootstrapper().ensureSeedDataInstalled();

    final pricesFile = File('${tempDir.path}/prices.json');
    expect(await pricesFile.exists(), isTrue);

    final prices = (jsonDecode(await pricesFile.readAsString()) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    for (final materialId in _defaultMaterialIds) {
      final typeIds = prices
          .where((price) => price['materialId'] == materialId)
          .map((price) => price['priceTypeId'])
          .toSet();
      expect(typeIds, contains(PriceTypeIds.saleUnitPrice));
      expect(typeIds, contains(PriceTypeIds.saleBoxPrice));
      expect(typeIds, contains(PriceTypeIds.costUnitPrice));
      expect(typeIds, contains(PriceTypeIds.costBoxPrice));
    }

    final ledSaleUnit = prices.firstWhere(
      (price) =>
          price['materialId'] == 'led_60w' &&
          price['priceTypeId'] == PriceTypeIds.saleUnitPrice,
    );
    final ledCostUnit = prices.firstWhere(
      (price) =>
          price['materialId'] == 'led_60w' &&
          price['priceTypeId'] == PriceTypeIds.costUnitPrice,
    );
    final fullSetAreaPrice = prices.firstWhere(
      (price) =>
          price['materialId'] == 'ceiling_full_set' &&
          price['priceTypeId'] == PriceTypeIds.areaM2SalePrice,
    );
    final materialsOnlyAreaPrice = prices.firstWhere(
      (price) =>
          price['materialId'] == 'ceiling_material_only' &&
          price['priceTypeId'] == PriceTypeIds.areaM2SalePrice,
    );
    expect(ledSaleUnit['price'], 13.0);
    expect(ledCostUnit['price'], 0.0);
    expect(fullSetAreaPrice['price'], 4.2);
    expect(materialsOnlyAreaPrice['price'], 1.2);
  });

  test('existing prices.json is not overwritten', () async {
    final existing = [
      {
        'id': 'led_60w_cost_unit_price',
        'materialId': 'led_60w',
        'priceTypeId': PriceTypeIds.costUnitPrice,
        'price': 7.5,
        'currencyCode': 'USD',
        'effectiveFrom': DateTime(2020).toIso8601String(),
        'effectiveTo': null,
        'active': true,
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      },
    ];
    await File(
      '${tempDir.path}/prices.json',
    ).writeAsString(jsonEncode(existing));

    await bootstrapper().ensureSeedDataInstalled();

    final decoded =
        jsonDecode(await File('${tempDir.path}/prices.json').readAsString())
            as List;
    expect(decoded.length, 1);
    expect(decoded.first['price'], 7.5);
  });

  test('saved cost price loads after app restart', () async {
    await bootstrapper().ensureSeedDataInstalled();
    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    await repo.savePrice(_price('led_60w', PriceTypeIds.costUnitPrice, 4.25));

    final restartedRepo = LocalMaterialPriceRepository(
      LocalJsonStorage(baseDirectory: tempDir),
    );
    final prices = await restartedRepo.getPrices();
    final saved = prices.firstWhere(
      (price) => price.id == 'led_60w_cost_unit_price',
    );

    expect(saved.price, 4.25);
  });

  test('old zero sale prices are repaired from built-in seed', () async {
    await File('${tempDir.path}/prices.json').writeAsString(
      jsonEncode([
        _price('ceiling_6mm', PriceTypeIds.saleUnitPrice, 0).toJson(),
        _price('ceiling_6mm', PriceTypeIds.saleBoxPrice, 0).toJson(),
      ]),
    );

    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    final prices = await repo.getPrices();
    final saleUnit = prices.firstWhere(
      (price) =>
          price.materialId == 'ceiling_6mm' &&
          price.priceTypeId == PriceTypeIds.saleUnitPrice,
    );
    final saleBox = prices.firstWhere(
      (price) =>
          price.materialId == 'ceiling_6mm' &&
          price.priceTypeId == PriceTypeIds.saleBoxPrice,
    );

    expect(saleUnit.price, 1.20);
    expect(saleBox.price, 13.00);
  });

  test('nonzero local sale price is not overwritten by seed repair', () async {
    await File('${tempDir.path}/prices.json').writeAsString(
      jsonEncode([
        _price('ceiling_6mm', PriceTypeIds.saleBoxPrice, 14).toJson(),
      ]),
    );

    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    final saved = (await repo.getPrices()).firstWhere(
      (price) =>
          price.materialId == 'ceiling_6mm' &&
          price.priceTypeId == PriceTypeIds.saleBoxPrice,
    );

    expect(saved.price, 14);
  });

  test('missing local sale price is appended from built-in seed', () async {
    await File('${tempDir.path}/prices.json').writeAsString(
      jsonEncode([
        _price('ceiling_6mm', PriceTypeIds.saleUnitPrice, 1.20).toJson(),
      ]),
    );

    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    final saved = (await repo.getPrices()).firstWhere(
      (price) =>
          price.materialId == 'ceiling_6mm' &&
          price.priceTypeId == PriceTypeIds.saleBoxPrice,
    );

    expect(saved.price, 13.00);
  });

  test(
    'calculator temporary override does not overwrite local saved price',
    () async {
      await bootstrapper().ensureSeedDataInstalled();
      final storage = LocalJsonStorage(baseDirectory: tempDir);
      await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
      final repo = LocalMaterialPriceRepository(storage);
      await repo.savePrice(_price('led_60w', PriceTypeIds.saleUnitPrice, 5));

      final seed = DefaultMaterialSeed.json(DateTime(2026));
      final result = const ProductSaleEngine().calculate(
        input: const ProductSaleInput(
          productKindId: 'led_only',
          materialId: 'led_60w',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 10,
          saleUnitPrice: 2,
          costUnitPrice: 1,
          useSavedPriceAsDefault: false,
        ),
        productKinds: DefaultMaterialSeed.productTypeTemplates(),
        materials: DefaultMaterialSeed.materials(DateTime(2026)),
        prices: (seed['prices'] as List)
            .map(
              (item) => MaterialPrice.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        packagingRules: DefaultMaterialSeed.packagingRules(DateTime(2026)),
      );

      final saved = (await repo.getPrices()).firstWhere(
        (price) => price.id == 'led_60w_sale_unit_price',
      );
      expect(result.customerPayTotal, 20);
      expect(saved.price, 5);
    },
  );

  test('save price updates local prices.json', () async {
    await bootstrapper().ensureSeedDataInstalled();
    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    await repo.savePrice(_price('led_60w', PriceTypeIds.costBoxPrice, 42));

    final rows =
        jsonDecode(await File('${tempDir.path}/prices.json').readAsString())
            as List;
    final saved = rows.firstWhere(
      (row) => row['id'] == 'led_60w_cost_box_price',
    );

    expect(saved['price'], 42);
  });

  test('saved edited sale price reloads as calculator default', () async {
    await bootstrapper().ensureSeedDataInstalled();
    final storage = LocalJsonStorage(baseDirectory: tempDir);
    await storage.ensureSeeded(DefaultMaterialSeed.json(DateTime(2026)));
    final repo = LocalMaterialPriceRepository(storage);
    await repo.savePrice(_price('ceiling_6mm', PriceTypeIds.saleBoxPrice, 14));

    final restartedStorage = LocalJsonStorage(baseDirectory: tempDir);
    await restartedStorage.ensureSeeded(
      DefaultMaterialSeed.json(DateTime(2026)),
    );
    final restartedRepo = LocalMaterialPriceRepository(restartedStorage);
    final saved = (await restartedRepo.getPrices()).firstWhere(
      (price) =>
          price.materialId == 'ceiling_6mm' &&
          price.priceTypeId == PriceTypeIds.saleBoxPrice,
    );

    expect(saved.price, 14);
  });

  test(
    'temporary sale snapshot keeps old price after saved price changes',
    () async {
      final snapshot = const ProductSaleEngine().calculate(
        input: const ProductSaleInput(
          productKindId: 'led_only',
          materialId: 'led_60w',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 10,
          saleUnitPrice: 2,
          costUnitPrice: 1,
          useSavedPriceAsDefault: false,
        ),
        productKinds: DefaultMaterialSeed.productTypeTemplates(),
        materials: DefaultMaterialSeed.materials(DateTime(2026)),
        prices: DefaultMaterialSeed.prices(DateTime(2026)),
        packagingRules: DefaultMaterialSeed.packagingRules(DateTime(2026)),
      );
      final summary = TemporarySaleSummary.fromItems([snapshot]);

      await bootstrapper().ensureSeedDataInstalled();
      final repo = LocalMaterialPriceRepository(
        LocalJsonStorage(baseDirectory: tempDir),
      );
      await repo.savePrice(_price('led_60w', PriceTypeIds.saleUnitPrice, 99));

      expect(summary.customerPayTotal, 20);
      expect(summary.ownerCostTotal, 10);
      expect(summary.ownerProfit, 10);
    },
  );
}

Map<String, String> _seedAssetText() {
  final seed = DefaultMaterialSeed.json(DateTime(2026));
  const encoder = JsonEncoder.withIndent('  ');
  return {
    'assets/seed/materials.json': encoder.convert(seed['materials']),
    'assets/seed/prices.json': encoder.convert(seed['prices']),
    'assets/seed/material_quantity_price_tiers.json': encoder.convert(
      seed['materialQuantityPriceTiers'],
    ),
    'assets/seed/packaging.json': encoder.convert(seed['packagingRules']),
    'assets/seed/product_kinds.json': encoder.convert(
      seed['productTypeTemplates'],
    ),
    'assets/seed/settings.json': encoder.convert({
      'settings': seed['settings'],
      'pricingTiers': seed['pricingTiers'],
      'formulaRules': seed['formulaRules'],
      'units': seed['units'],
      'categories': seed['categories'],
      'sellModes': seed['sellModes'],
    }),
  };
}

MaterialPrice _price(String materialId, String priceTypeId, double price) {
  return MaterialPrice(
    id: '${materialId}_$priceTypeId',
    materialId: materialId,
    priceTypeId: priceTypeId,
    price: price,
    currencyCode: 'USD',
    effectiveFrom: DateTime(2020),
    effectiveTo: null,
    active: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

const _defaultMaterialIds = [
  'ceiling_6mm',
  'long_t_3m',
  'short_t_06m',
  'v_iron_295m',
  'v_iron_usk_3m',
  'led_60w',
  'wire_2000m_11kg',
  'dk01',
  'dk03',
  'insulation_indonesia_13kg',
  'insulation_2n_15kg',
  'insulation_2n_17kg',
];
