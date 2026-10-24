import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/core/utils/quantity_rounding.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/models/packaging_rule.dart';
import 'package:material_quote_pro/features/materials/data/models/product_type_template.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_engine.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_models.dart';

void main() {
  final now = DateTime(2026, 6, 30);
  final engine = ProductSaleEngine(clock: () => now);

  late List<MaterialItem> materials;
  late List<MaterialPrice> prices;
  late List<PackagingRule> packagingRules;
  late List<ProductTypeTemplate> productKinds;

  setUp(() {
    materials = DefaultMaterialSeed.materials(now);
    prices = DefaultMaterialSeed.prices(now);
    packagingRules = DefaultMaterialSeed.packagingRules(now);
    productKinds = DefaultMaterialSeed.productTypeTemplates();
  });

  ProductSaleResult calculate(
    ProductSaleInput input, {
    int Function(double)? automaticQuantityRounder,
  }) {
    return engine.calculate(
      input: input,
      productKinds: productKinds,
      materials: materials,
      prices: prices,
      packagingRules: packagingRules,
      automaticQuantityRounder: automaticQuantityRounder,
    );
  }

  test('full ceiling by area uses input method and box plus loose charge', () {
    final ceiling = calculate(_areaInput('ceiling_6mm'));
    final longT = calculate(_areaInput('long_t_3m'));
    final shortT = calculate(_areaInput('short_t_06m'));
    final vIron = calculate(_areaInput('v_iron_295m'));

    expect(ceiling.validationErrors, isEmpty);
    expect(ceiling.inputMethodId, InputMethodIds.areaM2);
    expect(ceiling.chargeMethodId, ChargeMethodIds.boxPlusLoose);
    expect(ceiling.sellQuantity, 278);
    expect(longT.sellQuantity, 54);
    expect(shortT.sellQuantity, 270);
    expect(vIron.sellQuantity, 20);
  });

  test('ceiling half-up rounder is applied after the existing formulas', () {
    final cases = <({String materialId, double area, double raw, int rounded})>[
      (materialId: 'ceiling_6mm', area: 1.224, raw: 3.4, rounded: 3),
      (materialId: 'ceiling_6mm', area: 1.26, raw: 3.5, rounded: 4),
      (materialId: 'long_t_3m', area: 8.4 / 0.54, raw: 8.4, rounded: 8),
      (materialId: 'long_t_3m', area: 8.5 / 0.54, raw: 8.5, rounded: 9),
      (materialId: 'short_t_06m', area: 14.4 / 2.7, raw: 14.4, rounded: 14),
      (materialId: 'short_t_06m', area: 14.5 / 2.7, raw: 14.5, rounded: 15),
      (materialId: 'v_iron_295m', area: 5.4 / 0.2, raw: 5.4, rounded: 5),
      (materialId: 'v_iron_295m', area: 5.5 / 0.2, raw: 5.5, rounded: 6),
    ];

    for (final testCase in cases) {
      final result = calculate(
        ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: testCase.materialId,
          inputMethodId: InputMethodIds.areaM2,
          chargeMethodId: ChargeMethodIds.boxPlusLoose,
          areaM2: testCase.area,
        ),
        automaticQuantityRounder: roundCeilingQuantity,
      );

      expect(result.rawQuantity, closeTo(testCase.raw, 1e-9));
      expect(result.sellQuantity, testCase.rounded);
    }
  });

  test('shared sales calculations keep customer ceil by default', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 1.224,
      ),
    );

    expect(result.rawQuantity, closeTo(3.4, 1e-9));
    expect(result.sellQuantity, 4);
  });

  test('ceiling default sale prices load from seed', () {
    final ceiling = calculate(_areaInput('ceiling_6mm'));
    final longT = calculate(_areaInput('long_t_3m'));
    final shortT = calculate(_areaInput('short_t_06m'));
    final vIron = calculate(_areaInput('v_iron_295m'));

    expect(ceiling.saleUnitPrice, 1.20);
    expect(ceiling.saleBoxPrice, 13.00);
    expect(longT.saleUnitPrice, 1.00);
    expect(longT.saleBoxPrice, 52.00);
    expect(shortT.saleUnitPrice, 0.50);
    expect(shortT.saleBoxPrice, 25.00);
    expect(vIron.saleUnitPrice, 1.00);
    expect(vIron.saleBoxPrice, 50.00);
  });

  test('ceiling default sale prices calculate expected customer totals', () {
    final ceiling = calculate(_areaInput('ceiling_6mm'));
    final longT = calculate(_areaInput('long_t_3m'));
    final shortT = calculate(_areaInput('short_t_06m'));
    final vIron = calculate(_areaInput('v_iron_295m'));

    expect(ceiling.packagingFullBoxes, 23);
    expect(ceiling.packagingLooseItems, 2);
    expect(ceiling.customerPayTotal, 301.40);
    expect(longT.packagingFullBoxes, 1);
    expect(longT.packagingLooseItems, 0);
    expect(longT.customerPayTotal, 52);
    expect(shortT.packagingFullBoxes, 3);
    expect(shortT.packagingLooseItems, 0);
    expect(shortT.customerPayTotal, 75);
    expect(vIron.packagingFullBoxes, 0);
    expect(vIron.packagingLooseItems, 20);
    expect(vIron.customerPayTotal, 20);
  });

  test(
    'calculator temporary sale price edit recalculates without saving seed',
    () {
      final defaultResult = calculate(_areaInput('ceiling_6mm'));
      final edited = calculate(
        const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.areaM2,
          chargeMethodId: ChargeMethodIds.boxPlusLoose,
          areaM2: 100,
          saleBoxPrice: 14,
        ),
      );
      final seedSaleBox = prices.firstWhere(
        (price) =>
            price.materialId == 'ceiling_6mm' &&
            price.priceTypeId == PriceTypeIds.saleBoxPrice,
      );

      expect(defaultResult.customerPayTotal, 301.40);
      expect(edited.customerPayTotal, 324.40);
      expect(seedSaleBox.price, 13);
    },
  );

  test('old zero sale price rows fallback to legacy seed sale prices', () {
    prices = [
      for (final price in prices)
        if (price.materialId == 'ceiling_6mm' &&
            (price.priceTypeId == PriceTypeIds.saleUnitPrice ||
                price.priceTypeId == PriceTypeIds.saleBoxPrice))
          price.copyWith(price: 0)
        else
          price,
    ];

    final result = calculate(_areaInput('ceiling_6mm'));

    expect(result.saleUnitPrice, 1.20);
    expect(result.saleBoxPrice, 13.00);
    expect(result.customerPayTotal, 301.40);
  });

  test('full ceiling by width length calculates area', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.widthLength,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        widthM: 5,
        lengthM: 6,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.areaM2, 30);
  });

  test('customer ask modes keep input and charge method separated', () {
    final priceByArea = CustomerAskModeCatalog.ceilingById(
      CustomerAskModeIds.priceByArea,
    );
    final materialsByWidth = CustomerAskModeCatalog.ceilingById(
      CustomerAskModeIds.materialsByWidthLength,
    );
    final boxSale = CustomerAskModeCatalog.ceilingById(
      CustomerAskModeIds.boxProductSale,
    );

    expect(priceByArea.allowedInputMethods, [InputMethodIds.areaM2]);
    expect(priceByArea.allowedChargeMethods, [ChargeMethodIds.areaM2Price]);
    expect(priceByArea.requiresOffer, isTrue);
    expect(materialsByWidth.allowedInputMethods, [InputMethodIds.widthLength]);
    expect(materialsByWidth.allowedChargeMethods, [
      ChargeMethodIds.quantityOnly,
    ]);
    expect(materialsByWidth.isQuantityOnly, isTrue);
    expect(boxSale.allowedInputMethods, [InputMethodIds.boxQuantity]);
    expect(boxSale.allowedChargeMethods, [ChargeMethodIds.boxOnly]);
    expect(boxSale.requiresProduct, isTrue);
  });

  test('area price sale charges customer by square meter', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.priceByArea,
        offerId: 'ceiling_full_set',
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        areaM2: 100,
        salePricePerM2: 4.20,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.areaM2, 100);
    expect(result.salePricePerM2, 4.20);
    expect(result.customerPayTotal, 420.00);
  });

  test('default full ceiling area sale price loads from seed', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        areaM2: 100,
      ),
    );

    expect(result.salePricePerM2, 4.20);
    expect(result.customerPayTotal, 420.00);
  });

  test('default ceiling materials only area sale price loads from seed', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_material_only',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        areaM2: 100,
      ),
    );

    expect(result.salePricePerM2, 1.20);
    expect(result.customerPayTotal, 120.00);
  });

  test('width length with area price charges customer by calculated area', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.priceByWidthLength,
        offerId: 'ceiling_full_set',
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.widthLength,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        widthM: 5,
        lengthM: 6,
        salePricePerM2: 4.20,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.areaM2, 30);
    expect(result.customerPayTotal, 126.00);
  });

  test(
    'boxes by width length returns required ceiling set quantities only',
    () {
      final ceiling = calculate(_quantityWidthLengthInput('ceiling_6mm'));
      final longT = calculate(_quantityWidthLengthInput('long_t_3m'));
      final shortT = calculate(_quantityWidthLengthInput('short_t_06m'));
      final vIron = calculate(_quantityWidthLengthInput('v_iron_295m'));

      expect(ceiling.validationErrors, isEmpty);
      expect(ceiling.areaM2, 30);
      expect(ceiling.chargeMethodId, ChargeMethodIds.quantityOnly);
      expect(ceiling.customerPayTotal, 0);
      expect(ceiling.sellQuantity, 84);
      expect(ceiling.packagingFullBoxes, 7);
      expect(ceiling.packagingLooseItems, 0);
      expect(longT.sellQuantity, 17);
      expect(longT.packagingFullBoxes, 0);
      expect(longT.packagingLooseItems, 17);
      expect(shortT.sellQuantity, 81);
      expect(shortT.packagingFullBoxes, 0);
      expect(shortT.packagingLooseItems, 81);
      expect(vIron.sellQuantity, 6);
      expect(vIron.packagingFullBoxes, 0);
      expect(vIron.packagingLooseItems, 6);
    },
  );

  test('ceiling sheets only by width length returns ceiling count only', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.ceilingSheetsByWidthLength,
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.widthLength,
        chargeMethodId: ChargeMethodIds.quantityOnly,
        widthM: 5,
        lengthM: 6,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.areaM2, 30);
    expect(result.sellQuantity, 84);
    expect(result.packagingFullBoxes, 7);
    expect(result.packagingLooseItems, 0);
    expect(result.customerPayTotal, 0);
  });

  test('full ceiling by loose ceiling sheets estimates area', () {
    final ceiling = calculate(_ceilingLooseInput('ceiling_6mm', 278));
    final longT = calculate(_ceilingLooseInput('long_t_3m', 278));
    final shortT = calculate(_ceilingLooseInput('short_t_06m', 278));
    final vIron = calculate(_ceilingLooseInput('v_iron_295m', 278));

    expect(ceiling.validationErrors, isEmpty);
    expect(ceiling.areaM2, closeTo(100.08, 0.001));
    expect(ceiling.sellQuantity, 278);
    expect(longT.sellQuantity, (100.08 * 0.54).ceil());
    expect(shortT.sellQuantity, (100.08 * 2.7).ceil());
    expect(vIron.sellQuantity, (100.08 * 0.2).ceil());
  });

  test(
    'ceiling sheet input with area price estimates area before charging',
    () {
      final result = calculate(
        const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.ceilingLooseSheets,
          chargeMethodId: ChargeMethodIds.areaM2Price,
          looseQuantity: 278,
          salePricePerM2: 4.20,
        ),
      );

      expect(result.validationErrors, isEmpty);
      expect(result.areaM2, closeTo(100.08, 0.001));
      expect(result.customerPayTotal, closeTo(420.34, 0.001));
    },
  );

  test('area price sale still calculates owner cost from material lines', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        areaM2: 100,
        salePricePerM2: 4.20,
        costUnitPrice: 0.25,
        costBoxPrice: 3,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 278);
    expect(result.packagingFullBoxes, 23);
    expect(result.packagingLooseItems, 2);
    expect(result.productCost, 69.50);
    expect(result.ownerCostTotal, 69.50);
    expect(result.ownerProfit, 350.50);
  });

  test('full ceiling by ceiling boxes estimates sheets and area', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.ceilingBoxQuantity,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        boxQuantity: 10,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 120);
    expect(result.areaM2, closeTo(43.2, 0.001));
    expect(result.packagingFullBoxes, 10);
    expect(result.packagingLooseItems, 0);
  });

  test(
    'full ceiling by ceiling boxes plus loose estimates sheets and area',
    () {
      final result = calculate(
        const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.ceilingBoxPlusLoose,
          chargeMethodId: ChargeMethodIds.boxPlusLoose,
          boxQuantity: 10,
          looseQuantity: 5,
        ),
      );

      expect(result.validationErrors, isEmpty);
      expect(result.sellQuantity, 125);
      expect(result.areaM2, closeTo(45, 0.001));
      expect(result.packagingFullBoxes, 10);
      expect(result.packagingLooseItems, 5);
    },
  );

  test('manual per product input uses exact quantities without formula', () {
    const quantities = {
      'ceiling_6mm': 100,
      'long_t_3m': 20,
      'short_t_06m': 50,
      'v_iron_295m': 10,
    };

    for (final entry in quantities.entries) {
      final result = calculate(
        ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: entry.key,
          inputMethodId: InputMethodIds.manualPerProduct,
          chargeMethodId: ChargeMethodIds.unitOnly,
          manualQuantity: entry.value,
        ),
      );

      expect(result.validationErrors, isEmpty);
      expect(result.sellQuantity, entry.value);
      expect(result.rawQuantity, entry.value);
    }
  });

  test('one product box buy calculates quantity and packaging', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.boxQuantity,
        chargeMethodId: ChargeMethodIds.boxOnly,
        boxQuantity: 3,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 30);
    expect(result.packagingFullBoxes, 3);
    expect(result.packagingLooseItems, 0);
  });

  test('loose product sale answers unit customer sale', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.looseProductSale,
        productKindId: 'ceiling_material_only',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 20,
        saleUnitPrice: 1.20,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 20);
    expect(result.packagingFullBoxes, 1);
    expect(result.packagingLooseItems, 8);
    expect(result.customerPayTotal, 24);
  });

  test('box product sale answers box customer sale', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.boxProductSale,
        productKindId: 'ceiling_material_only',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.boxQuantity,
        chargeMethodId: ChargeMethodIds.boxOnly,
        boxQuantity: 3,
        saleBoxPrice: 13,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 36);
    expect(result.packagingFullBoxes, 3);
    expect(result.packagingLooseItems, 0);
    expect(result.customerPayTotal, 39);
  });

  test('box plus loose sale answers mixed customer sale', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.boxPlusLooseSale,
        productKindId: 'ceiling_material_only',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.boxPlusLoose,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        boxQuantity: 3,
        looseQuantity: 5,
        saleBoxPrice: 13,
        saleUnitPrice: 1.20,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.sellQuantity, 41);
    expect(result.packagingFullBoxes, 3);
    expect(result.packagingLooseItems, 5);
    expect(result.customerPayTotal, 45);
  });

  test('DK01 keeps packaging but does not invent a box sale price', () {
    final dk01 = materials.firstWhere((material) => material.id == 'dk01');
    final packaging = packagingRules.firstWhere(
      (rule) => rule.materialId == 'dk01',
    );
    final boxSalePrice = prices.firstWhere(
      (price) =>
          price.materialId == 'dk01' &&
          price.priceTypeId == PriceTypeIds.saleBoxPrice,
    );
    final legacyBoxPrice = prices.firstWhere(
      (price) =>
          price.materialId == 'dk01' &&
          price.priceTypeId == PriceTypeIds.boxPrice,
    );
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.boxProductSale,
        productKindId: 'decoration_only',
        materialId: 'dk01',
        inputMethodId: InputMethodIds.boxQuantity,
        chargeMethodId: ChargeMethodIds.boxOnly,
        boxQuantity: 1,
      ),
    );

    expect(dk01.itemsPerBox, 10);
    expect(packaging.itemsPerBox, 10);
    expect(boxSalePrice.price, 0);
    expect(legacyBoxPrice.price, 0);
    expect(result.sellQuantity, 10);
    expect(result.saleBoxPrice, 0);
    expect(result.customerPayTotal, 0);
  });

  test('price override recalculates revenue cost and profit', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 10,
        saleUnitPrice: 2,
        costUnitPrice: 1,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.customerPayTotal, 20);
    expect(result.ownerCostTotal, 10);
    expect(result.ownerProfit, 10);
  });

  test('cost zero warning still allows temporary sale', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 10,
        saleUnitPrice: 2,
        costUnitPrice: 0,
        useSavedPriceAsDefault: false,
        allowSaleBelowCost: false,
      ),
    );

    expect(result.costZeroWarning, isTrue);
    expect(result.belowCost, isFalse);
    expect(result.canAddToTemporarySale, isTrue);
    expect(result.canSellStatusId, 'unknown_cost');
  });

  test('sale override uses saved cost price in the background', () {
    prices = [
      for (final price in prices)
        if (price.materialId == 'led_60w' &&
            price.priceTypeId == PriceTypeIds.costUnitPrice)
          price.copyWith(price: 4)
        else
          price,
    ];

    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 10,
        saleUnitPrice: 5,
        useSavedPriceAsDefault: true,
      ),
    );

    expect(result.validationErrors, isEmpty);
    expect(result.customerPayTotal, 50);
    expect(result.ownerCostTotal, 40);
    expect(result.ownerProfit, 10);
  });

  test('below cost blocks add when sale below cost is not allowed', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 10,
        saleUnitPrice: 1,
        costUnitPrice: 2,
        useSavedPriceAsDefault: false,
        allowSaleBelowCost: false,
      ),
    );

    expect(result.belowCost, isTrue);
    expect(result.canAddToTemporarySale, isFalse);
  });

  test(
    'temporary sale snapshot keeps override after default price changes',
    () {
      final snapshot = calculate(
        const ProductSaleInput(
          productKindId: 'led_only',
          materialId: 'led_60w',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 10,
          saleUnitPrice: 2,
          costUnitPrice: 1,
          useSavedPriceAsDefault: false,
        ),
      );
      prices = [
        for (final price in prices)
          if (price.materialId == 'led_60w' &&
              price.priceTypeId == PriceTypeIds.saleUnitPrice)
            price.copyWith(price: 99)
          else
            price,
      ];
      final recalculated = calculate(
        const ProductSaleInput(
          productKindId: 'led_only',
          materialId: 'led_60w',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 10,
          useSavedPriceAsDefault: true,
        ),
      );
      final summary = TemporarySaleSummary.fromItems([snapshot]);

      expect(recalculated.customerPayTotal, isNot(snapshot.customerPayTotal));
      expect(summary.customerPayTotal, 20);
      expect(summary.ownerProfit, 10);
    },
  );

  test(
    'temporary area sale snapshot stores area price and calculated area',
    () {
      final snapshot = calculate(
        const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.widthLength,
          chargeMethodId: ChargeMethodIds.areaM2Price,
          widthM: 5,
          lengthM: 6,
          salePricePerM2: 4.20,
          costUnitPrice: 0.25,
          costBoxPrice: 3,
          useSavedPriceAsDefault: false,
          includeDelivery: true,
          deliveryPayerId: DeliveryPayerIds.customerPays,
          deliveryRate: 5,
        ),
      );

      prices = [
        for (final price in prices)
          if (price.materialId == 'ceiling_full_set' &&
              price.priceTypeId == PriceTypeIds.areaM2SalePrice)
            price.copyWith(price: 9.99)
          else
            price,
      ];
      final recalculated = calculate(
        const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.widthLength,
          chargeMethodId: ChargeMethodIds.areaM2Price,
          widthM: 5,
          lengthM: 6,
        ),
      );
      final summary = TemporarySaleSummary.fromItems([snapshot]);

      expect(snapshot.chargeMethodId, ChargeMethodIds.areaM2Price);
      expect(snapshot.areaM2, 30);
      expect(snapshot.salePricePerM2, 4.20);
      expect(snapshot.customerPayTotal, 131);
      expect(snapshot.ownerCostTotal, 21);
      expect(snapshot.ownerProfit, 110);
      expect(snapshot.deliveryRate, 5);
      expect(snapshot.deliveryPayerId, DeliveryPayerIds.customerPays);
      expect(recalculated.customerPayTotal, 299.70);
      expect(summary.customerPayTotal, 131);
      expect(summary.ownerProfit, 110);
    },
  );

  test(
    'temporary sale snapshot stores sale inputs delivery totals and status',
    () {
      final snapshot = calculate(
        const ProductSaleInput(
          productKindId: 'led_only',
          materialId: 'led_60w',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 10,
          saleUnitPrice: 2,
          costUnitPrice: 1,
          useSavedPriceAsDefault: false,
          includeDelivery: true,
          deliveryPayerId: DeliveryPayerIds.customerPays,
          deliveryRate: 7,
        ),
      );

      expect(snapshot.inputMethodId, InputMethodIds.looseQuantity);
      expect(snapshot.chargeMethodId, ChargeMethodIds.unitOnly);
      expect(snapshot.saleUnitPrice, 2);
      expect(snapshot.includeDelivery, isTrue);
      expect(snapshot.deliveryPayerId, DeliveryPayerIds.customerPays);
      expect(snapshot.deliveryRate, 7);
      expect(snapshot.customerPayTotal, 27);
      expect(snapshot.ownerCostTotal, 10);
      expect(snapshot.ownerProfit, 17);
      expect(snapshot.canSellStatusId, 'can_sell');
    },
  );

  test('delivery customer pays adds delivery to customer total only', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 1,
        includeDelivery: true,
        deliveryPayerId: DeliveryPayerIds.customerPays,
        deliveryRate: 7,
      ),
    );

    expect(result.customerPayTotal, result.productRevenue + 7);
    expect(result.ownerCostTotal, result.productCost);
  });

  test('delivery owner pays adds delivery to owner cost only', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 1,
        includeDelivery: true,
        deliveryPayerId: DeliveryPayerIds.ownerPays,
        deliveryRate: 7,
      ),
    );

    expect(result.customerPayTotal, result.productRevenue);
    expect(result.ownerCostTotal, result.productCost + 7);
  });

  test('no delivery does not affect totals', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'led_only',
        materialId: 'led_60w',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 1,
        includeDelivery: false,
        deliveryPayerId: DeliveryPayerIds.customerPays,
        deliveryRate: 7,
      ),
    );

    expect(result.deliveryFeeTotal, 0);
    expect(result.customerPayTotal, result.productRevenue);
    expect(result.ownerCostTotal, result.productCost);
  });

  test('material cost fallback ignores full boxes if box cost is 0', () {
    final ceiling = calculate(
      ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 100,
        costUnitPrice: 0.77,
        costBoxPrice: 0,
        useSavedPriceAsDefault: false,
      ),
    );
    final longT = calculate(
      ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'long_t_3m',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 100,
        costUnitPrice: 0.74,
        costBoxPrice: 0,
        useSavedPriceAsDefault: false,
      ),
    );
    final shortT = calculate(
      ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'short_t_06m',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 100,
        costUnitPrice: 0.11,
        costBoxPrice: 0,
        useSavedPriceAsDefault: false,
      ),
    );
    final vIron = calculate(
      ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'v_iron_295m',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 100,
        costUnitPrice: 0.80,
        costBoxPrice: 0,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(ceiling.sellQuantity, 278);
    expect(ceiling.productCost, 214.06);
    expect(longT.sellQuantity, 54);
    expect(longT.productCost, 39.96);
    expect(shortT.sellQuantity, 270);
    expect(shortT.productCost, 29.70);
    expect(vIron.sellQuantity, 20);
    expect(vIron.productCost, 16.00);

    final summary = TemporarySaleSummary.fromItems([
      ceiling,
      longT,
      shortT,
      vIron,
    ]);
    expect(summary.ownerCostTotal, 299.72);
  });

  test('material cost uses full boxes when box cost exists', () {
    final ceiling = calculate(
      ProductSaleInput(
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        areaM2: 100,
        costUnitPrice: 0.77,
        costBoxPrice: 9.00,
        useSavedPriceAsDefault: false,
      ),
    );

    // 278 items -> 23 boxes + 2 loose. 23 * 9.00 + 2 * 0.77 = 207 + 1.54 = 208.54
    expect(ceiling.sellQuantity, 278);
    expect(ceiling.packagingFullBoxes, 23);
    expect(ceiling.packagingLooseItems, 2);
    expect(ceiling.productCost, 208.54);
  });

  test('area offer with cost_area_price sets owner cost accurately', () {
    final result = calculate(
      const ProductSaleInput(
        askModeId: CustomerAskModeIds.priceByArea,
        offerId: 'ceiling_full_set',
        productKindId: 'ceiling_full_set',
        materialId: 'ceiling_6mm',
        inputMethodId: InputMethodIds.areaM2,
        chargeMethodId: ChargeMethodIds.areaM2Price,
        areaM2: 100,
        salePricePerM2: 4.20,
        costPricePerM2: 2.89,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.areaM2, 100);
    expect(result.customerPayTotal, 420.00);
    expect(result.productCost, 289.00);
    expect(result.ownerCostTotal, 289.00);
  });

  test(
    'DK01 loose quantity calculates fullBoxes and looseItems from itemsPerBox',
    () {
      final result = calculate(
        const ProductSaleInput(
          productKindId: 'decoration_only',
          materialId: 'dk01',
          inputMethodId: InputMethodIds.looseQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          looseQuantity: 25,
          saleUnitPrice: 2.50,
          costUnitPrice: 1.30,
          useSavedPriceAsDefault: false,
        ),
      );

      expect(result.sellQuantity, 25);
      expect(result.packagingFullBoxes, 2);
      expect(result.packagingLooseItems, 5);
      expect(result.customerPayTotal, 62.50);
      expect(result.ownerCostTotal, 32.50);
      expect(result.ownerProfit, 30.00);
    },
  );

  test('DK01 manual quantity breaks down into boxes and loose correctly', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'decoration_only',
        materialId: 'dk01',
        inputMethodId: InputMethodIds.manualQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        manualQuantity: 25,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.packagingFullBoxes, 2);
    expect(result.packagingLooseItems, 5);
  });

  test('DK01 box quantity calculates totalQuantity correctly', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'decoration_only',
        materialId: 'dk01',
        inputMethodId: InputMethodIds.boxQuantity,
        chargeMethodId: ChargeMethodIds.boxOnly,
        boxQuantity: 25,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.sellQuantity, 250);
    expect(result.packagingFullBoxes, 25);
    expect(result.packagingLooseItems, 0);
  });

  test('DK01 box plus loose calculates total correctly', () {
    final result = calculate(
      const ProductSaleInput(
        productKindId: 'decoration_only',
        materialId: 'dk01',
        inputMethodId: InputMethodIds.boxPlusLoose,
        chargeMethodId: ChargeMethodIds.boxPlusLoose,
        boxQuantity: 2,
        looseQuantity: 5,
        useSavedPriceAsDefault: false,
      ),
    );

    expect(result.sellQuantity, 25);
    expect(result.packagingFullBoxes, 2);
    expect(result.packagingLooseItems, 5);
  });

  test('DK01 packaging still works without a box price', () {
    prices = [
      for (final price in prices)
        if (price.materialId == 'dk01' &&
            price.priceTypeId == PriceTypeIds.saleBoxPrice)
          price.copyWith(price: 0)
        else
          price,
    ];

    final result = calculate(
      const ProductSaleInput(
        productKindId: 'decoration_only',
        materialId: 'dk01',
        inputMethodId: InputMethodIds.looseQuantity,
        chargeMethodId: ChargeMethodIds.unitOnly,
        looseQuantity: 25,
        saleUnitPrice: 2.50,
        useSavedPriceAsDefault: true,
      ),
    );

    expect(result.sellQuantity, 25);
    expect(result.packagingFullBoxes, 2);
    expect(result.packagingLooseItems, 5);
    // 25 * 2.50 = 62.50
    expect(result.customerPayTotal, 62.50);
  });
}

ProductSaleInput _areaInput(String materialId) {
  return ProductSaleInput(
    productKindId: 'ceiling_full_set',
    materialId: materialId,
    inputMethodId: InputMethodIds.areaM2,
    chargeMethodId: ChargeMethodIds.boxPlusLoose,
    areaM2: 100,
  );
}

ProductSaleInput _ceilingLooseInput(String materialId, int sheets) {
  return ProductSaleInput(
    productKindId: 'ceiling_full_set',
    materialId: materialId,
    inputMethodId: InputMethodIds.ceilingLooseSheets,
    chargeMethodId: ChargeMethodIds.boxPlusLoose,
    looseQuantity: sheets,
  );
}

ProductSaleInput _quantityWidthLengthInput(String materialId) {
  return ProductSaleInput(
    askModeId: CustomerAskModeIds.materialsByWidthLength,
    productKindId: 'ceiling_full_set',
    materialId: materialId,
    inputMethodId: InputMethodIds.widthLength,
    chargeMethodId: ChargeMethodIds.quantityOnly,
    widthM: 5,
    lengthM: 6,
  );
}
