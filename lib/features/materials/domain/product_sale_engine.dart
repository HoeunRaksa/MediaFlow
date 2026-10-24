import 'dart:math' as math;

import '../../../core/constants/business_ids.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/quantity_rounding.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/packaging_rule.dart';
import '../data/models/product_type_template.dart';
import '../../../core/utils/packaging_breakdown.dart';
import 'delivery_calculation_engine.dart';
import 'product_sale_models.dart';

class ProductSaleEngine {
  const ProductSaleEngine({DateTime Function()? clock}) : _clock = clock;

  static const _ceilingMaterialId = 'ceiling_6mm';
  static const _defaultCeilingCoverageM2 = 0.36;
  static const _defaultCeilingItemsPerBox = 12;

  final DateTime Function()? _clock;

  ProductSaleResult calculate({
    required ProductSaleInput input,
    required List<ProductTypeTemplate> productKinds,
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    required List<PackagingRule> packagingRules,
    List<BuyMode> buyModes = BuyModeCatalog.defaults,
    List<ChargeMethod> chargeMethods = ChargeMethodCatalog.defaults,
    QuantityRounder? automaticQuantityRounder,
  }) {
    final roundAutomaticQuantity =
        automaticQuantityRounder ?? QuantityRounding.customerCeil;
    final now = _clock?.call() ?? DateTime.now();
    final errors = <String>[];
    final productKind = productKinds
        .where((kind) => kind.id == input.productKindId)
        .firstOrNull;
    final material = materials
        .where((item) => item.id == input.materialId)
        .firstOrNull;
    final inputMethod = buyModes
        .where((mode) => mode.id == input.inputMethodId && mode.active)
        .firstOrNull;

    if (inputMethod == null) {
      errors.add('សូមជ្រើសរើសរបៀបបញ្ចូលត្រឹមត្រូវ។');
    }
    if (material == null) {
      errors.add('សូមជ្រើសរើសផលិតផលត្រឹមត្រូវ។');
    } else if (!material.active) {
      errors.add('ផលិតផលនេះមិនសកម្មទេ។');
    }

    final effectiveInputMethod =
        inputMethod ?? InputMethodCatalog.byId(InputMethodIds.manualQuantity);
    final effectiveChargeMethod = _chargeMethod(
      input.chargeMethodId,
      effectiveInputMethod.id,
      chargeMethods,
    );
    final effectiveMaterial = material;
    final productKindName = productKind?.nameKhmer ?? input.productKindId;

    if (effectiveMaterial == null) {
      return _emptyResult(
        input: input,
        productKindNameKhmer: productKindName,
        inputMethodNameKhmer: effectiveInputMethod.nameKhmer,
        chargeMethodNameKhmer: effectiveChargeMethod.nameKhmer,
        errors: errors,
      );
    }

    final rule = productKind?.defaultMaterialRules
        .where((item) => item.materialId == effectiveMaterial.id)
        .firstOrNull;
    final itemsPerBox = _itemsPerBox(effectiveMaterial, packagingRules);
    final ceilingMaterial = materials
        .where((item) => item.id == _ceilingMaterialId)
        .firstOrNull;
    final ceilingItemsPerBox = ceilingMaterial == null
        ? _defaultCeilingItemsPerBox
        : _itemsPerBox(ceilingMaterial, packagingRules);
    final ceilingCoverageM2 = _ceilingCoverageM2(
      productKind: productKind,
      ceilingMaterial: ceilingMaterial,
    );

    var areaM2 = input.areaM2;
    if (effectiveInputMethod.requiresWidthLength) {
      final width = input.widthM ?? 0;
      final length = input.lengthM ?? 0;
      if (width <= 0 || length <= 0) {
        errors.add('សូមបញ្ចូលទទឹង និងបណ្ដោយឱ្យធំជាង 0។');
      } else {
        areaM2 = width * length;
      }
    }
    if (effectiveInputMethod.requiresArea && (areaM2 == null || areaM2 <= 0)) {
      errors.add('សូមបញ្ចូលការ៉េឱ្យធំជាង 0។');
    }

    final saleUnitPrice = _effectivePrice(
      override: input.saleUnitPrice,
      materialId: effectiveMaterial.id,
      primaryTypeId: PriceTypeIds.saleUnitPrice,
      fallbackTypeIds: const [PriceTypeIds.unitPrice],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final saleBoxPrice = _effectivePrice(
      override: input.saleBoxPrice,
      materialId: effectiveMaterial.id,
      primaryTypeId: PriceTypeIds.saleBoxPrice,
      fallbackTypeIds: const [PriceTypeIds.boxPrice],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final salePricePerM2 = _effectivePrice(
      override: input.salePricePerM2,
      materialId: input.productKindId,
      primaryTypeId: PriceTypeIds.areaM2SalePrice,
      fallbackTypeIds: const [PriceTypeIds.servicePrice],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final costPricePerM2 = _effectivePrice(
      override: input.costPricePerM2,
      materialId: input.productKindId,
      primaryTypeId: PriceTypeIds.areaM2CostPrice,
      fallbackTypeIds: const [],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final costUnitPrice = _effectivePrice(
      override: input.costUnitPrice,
      materialId: effectiveMaterial.id,
      primaryTypeId: PriceTypeIds.costUnitPrice,
      fallbackTypeIds: const [],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final costBoxPrice = _effectivePrice(
      override: input.costBoxPrice,
      materialId: effectiveMaterial.id,
      primaryTypeId: PriceTypeIds.costBoxPrice,
      fallbackTypeIds: const [],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );
    final servicePrice = _effectivePrice(
      override: input.serviceAmount,
      materialId: effectiveMaterial.id,
      primaryTypeId: PriceTypeIds.servicePrice,
      fallbackTypeIds: const [PriceTypeIds.manualPrice],
      useSavedPriceAsDefault: input.useSavedPriceAsDefault,
      prices: prices,
      now: now,
    );

    var rawQuantity = 0.0;
    var sellQuantity = 0;
    var fullBoxes = 0;
    var looseItems = 0;
    var formulaText = '';

    if (errors.isEmpty) {
      switch (effectiveInputMethod.id) {
        case InputMethodIds.areaM2:
        case InputMethodIds.widthLength:
          rawQuantity = _rawFormulaQuantity(
            areaM2: areaM2 ?? 0,
            material: effectiveMaterial,
            rule: rule,
          );
          sellQuantity = roundAutomaticQuantity(rawQuantity);
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = _formulaText(
            inputMethodId: effectiveInputMethod.id,
            areaM2: areaM2,
            widthM: input.widthM,
            lengthM: input.lengthM,
            material: effectiveMaterial,
            rule: rule,
          );
          break;
        case InputMethodIds.looseQuantity:
          sellQuantity = _positiveInt(
            input.looseQuantity,
            'សូមបញ្ចូលចំនួនរាយឱ្យធំជាង 0។',
            errors,
          );
          rawQuantity = sellQuantity.toDouble();
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = 'រាយ $sellQuantity';
          break;
        case InputMethodIds.boxQuantity:
          final boxes = _positiveInt(
            input.boxQuantity,
            'សូមបញ្ចូលចំនួនកេសឱ្យធំជាង 0។',
            errors,
          );
          final breakdown = breakdownFromBoxQuantity(
            boxQuantity: boxes,
            itemsPerBox: itemsPerBox,
          );
          sellQuantity = breakdown.totalQuantity;
          rawQuantity = sellQuantity.toDouble();
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = '$fullBoxes កេស × $itemsPerBox';
          break;
        case InputMethodIds.boxPlusLoose:
          final boxes = _positiveInt(
            input.boxQuantity,
            'សូមបញ្ចូលចំនួនកេសឱ្យធំជាង 0។',
            errors,
          );
          final loose = _zeroOrPositiveInt(
            input.looseQuantity,
            'ចំនួនរាយមិនអាចតូចជាង 0 បានទេ។',
            errors,
          );
          final breakdown = breakdownFromBoxPlusLoose(
            boxQuantity: boxes,
            looseQuantity: loose,
            itemsPerBox: itemsPerBox,
          );
          sellQuantity = breakdown.totalQuantity;
          rawQuantity = sellQuantity.toDouble();
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = '$fullBoxes កេស + $looseItems រាយ';
          break;
        case InputMethodIds.ceilingLooseSheets:
          final ceilingSheets = _positiveInt(
            input.looseQuantity,
            'សូមបញ្ចូលចំនួនពិដានរាយឱ្យធំជាង 0។',
            errors,
          );
          areaM2 = ceilingSheets * ceilingCoverageM2;
          rawQuantity = _ceilingBasedRawQuantity(
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          sellQuantity = roundAutomaticQuantity(rawQuantity);
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = _ceilingQuantityFormulaText(
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          break;
        case InputMethodIds.ceilingBoxQuantity:
          final ceilingBoxes = _positiveInt(
            input.boxQuantity,
            'សូមបញ្ចូលចំនួនកេសពិដានឱ្យធំជាង 0។',
            errors,
          );
          final ceilingSheets = ceilingBoxes * ceilingItemsPerBox;
          areaM2 = ceilingSheets * ceilingCoverageM2;
          rawQuantity = _ceilingBasedRawQuantity(
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          sellQuantity = roundAutomaticQuantity(rawQuantity);
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = _ceilingQuantityFormulaText(
            ceilingBoxes: ceilingBoxes,
            ceilingItemsPerBox: ceilingItemsPerBox,
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          break;
        case InputMethodIds.ceilingBoxPlusLoose:
          final ceilingBoxes = _positiveInt(
            input.boxQuantity,
            'សូមបញ្ចូលចំនួនកេសពិដានឱ្យធំជាង 0។',
            errors,
          );
          final looseSheets = _zeroOrPositiveInt(
            input.looseQuantity,
            'ចំនួនពិដានរាយមិនអាចតូចជាង 0 បានទេ។',
            errors,
          );
          final ceilingSheets = ceilingBoxes * ceilingItemsPerBox + looseSheets;
          areaM2 = ceilingSheets * ceilingCoverageM2;
          rawQuantity = _ceilingBasedRawQuantity(
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          sellQuantity = roundAutomaticQuantity(rawQuantity);
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = _ceilingQuantityFormulaText(
            ceilingBoxes: ceilingBoxes,
            ceilingItemsPerBox: ceilingItemsPerBox,
            looseSheets: looseSheets,
            ceilingSheets: ceilingSheets,
            areaM2: areaM2,
            material: effectiveMaterial,
            rule: rule,
          );
          break;
        case InputMethodIds.manualPerProduct:
        case InputMethodIds.manualQuantity:
          sellQuantity = _positiveInt(
            input.manualQuantity,
            'សូមបញ្ចូលចំនួនឱ្យធំជាង 0។',
            errors,
          );
          rawQuantity = sellQuantity.toDouble();
          final breakdown = breakdownFromTotalQuantity(
            totalQuantity: sellQuantity,
            itemsPerBox: itemsPerBox,
          );
          fullBoxes = breakdown.fullBoxes;
          looseItems = breakdown.looseItems;
          formulaText = 'ចំនួនផ្ទាល់ $sellQuantity';
          break;
        case InputMethodIds.serviceOnly:
          rawQuantity = 1;
          sellQuantity = 1;
          fullBoxes = 0;
          looseItems = 0;
          formulaText = 'សេវាកម្ម';
          break;
      }
    }

    if (effectiveChargeMethod.id == ChargeMethodIds.areaM2Price &&
        (areaM2 == null || areaM2 <= 0)) {
      errors.add('សូមបញ្ចូលការ៉េសម្រាប់គិតតម្លៃតាមការ៉េ។');
    }

    final chargedBoxes = _chargedBoxes(
      chargeMethodId: effectiveChargeMethod.id,
      sellQuantity: sellQuantity,
      fullBoxes: fullBoxes,
      itemsPerBox: itemsPerBox,
    );
    final defaultCost = costBoxPrice > 0
        ? fullBoxes * costBoxPrice + looseItems * costUnitPrice
        : sellQuantity * costUnitPrice;
    final productRevenue = MoneyFormatter.roundMoney(
      _productRevenue(
        chargeMethodId: effectiveChargeMethod.id,
        sellQuantity: sellQuantity,
        fullBoxes: fullBoxes,
        looseItems: looseItems,
        chargedBoxes: chargedBoxes,
        saleUnitPrice: saleUnitPrice,
        saleBoxPrice: saleBoxPrice,
        salePricePerM2: salePricePerM2,
        areaM2: areaM2 ?? 0,
        includeAreaRevenue: input.includeAreaRevenue,
        manualTotalPrice:
            input.manualTotalPrice ??
            (effectiveInputMethod.id == InputMethodIds.serviceOnly
                ? servicePrice
                : null),
      ),
    );
    final productCost = MoneyFormatter.roundMoney(
      _productCost(
        chargeMethodId: effectiveChargeMethod.id,
        sellQuantity: sellQuantity,
        fullBoxes: fullBoxes,
        looseItems: looseItems,
        chargedBoxes: chargedBoxes,
        costUnitPrice: costUnitPrice,
        costBoxPrice: costBoxPrice,
        defaultCost: defaultCost,
        costPricePerM2: costPricePerM2,
        areaM2: areaM2 ?? 0,
      ),
    );

    final belowCost = _belowCost(
      chargeMethodId: effectiveChargeMethod.id,
      saleUnitPrice: saleUnitPrice,
      saleBoxPrice: saleBoxPrice,
      costUnitPrice: costUnitPrice,
      costBoxPrice: costBoxPrice,
      productRevenue: productRevenue,
      productCost: productCost,
      includeAreaRevenue: input.includeAreaRevenue,
    );
    final costZeroWarning = _costZeroWarning(
      chargeMethodId: effectiveChargeMethod.id,
      costUnitPrice: costUnitPrice,
      costBoxPrice: costBoxPrice,
      sellQuantity: sellQuantity,
      productCost: productCost,
      costPricePerM2: costPricePerM2,
    );

    final deliveryResult = input.includeDelivery
        ? calculateDelivery(
            deliveryModeId: input.deliveryModeId,
            deliveryPayerId: input.deliveryPayerId,
            deliveryRate: input.deliveryRate,
            lines: [
              DeliveryLineData(
                packagingFullBoxes: fullBoxes,
                packagingLooseItems: looseItems,
              ),
            ],
          )
        : DeliveryCalculationResult(
            deliveryModeId: input.deliveryModeId,
            deliveryPayerId: DeliveryPayerIds.noDelivery,
            deliveryRate: input.deliveryRate,
            totalFullBoxes: 0,
            totalLooseItems: 0,
            deliveryFeeTotal: 0,
          );

    final deliveryFeeTotal = MoneyFormatter.roundMoney(
      deliveryResult.deliveryFeeTotal,
    );
    final deliveryRevenue =
        deliveryResult.deliveryPayerId == DeliveryPayerIds.customerPays
        ? deliveryFeeTotal
        : 0.0;
    final deliveryCostToOwner =
        deliveryResult.deliveryPayerId == DeliveryPayerIds.ownerPays
        ? deliveryFeeTotal
        : 0.0;
    final customerPayTotal = MoneyFormatter.roundMoney(
      productRevenue + deliveryRevenue,
    );
    final ownerCostTotal = MoneyFormatter.roundMoney(
      productCost + deliveryCostToOwner,
    );
    final ownerProfit = MoneyFormatter.roundMoney(
      customerPayTotal - ownerCostTotal,
    );
    final canAddToTemporarySale =
        errors.isEmpty && (!belowCost || input.allowSaleBelowCost);

    return ProductSaleResult(
      productKindId: input.productKindId,
      productKindNameKhmer: productKindName,
      materialId: effectiveMaterial.id,
      materialNameKhmer: effectiveMaterial.khmerName,
      askModeId: input.askModeId,
      offerId: input.offerId,
      spec: input.displaySpec ?? effectiveMaterial.spec,
      unitKhmer: effectiveMaterial.unitKhmer,
      inputMethodId: effectiveInputMethod.id,
      inputMethodNameKhmer: effectiveInputMethod.nameKhmer,
      chargeMethodId: effectiveChargeMethod.id,
      chargeMethodNameKhmer: effectiveChargeMethod.nameKhmer,
      formulaText: formulaText,
      areaM2: areaM2,
      widthM: input.widthM,
      lengthM: input.lengthM,
      rawQuantity: rawQuantity,
      sellQuantity: sellQuantity,
      itemsPerBox: itemsPerBox,
      packagingFullBoxes: fullBoxes,
      packagingLooseItems: looseItems,
      chargedBoxes: chargedBoxes,
      saleUnitPrice: saleUnitPrice,
      saleBoxPrice: saleBoxPrice,
      salePricePerM2: salePricePerM2,
      includeAreaRevenue: input.includeAreaRevenue,
      costPricePerM2: costPricePerM2,
      costUnitPrice: costUnitPrice,
      costBoxPrice: costBoxPrice,
      manualTotalPrice: input.manualTotalPrice,
      productRevenue: productRevenue,
      productCost: productCost,
      includeDelivery: input.includeDelivery,
      deliveryModeId: deliveryResult.deliveryModeId,
      deliveryPayerId: deliveryResult.deliveryPayerId,
      deliveryRate: deliveryResult.deliveryRate,
      totalFullBoxes: deliveryResult.totalFullBoxes,
      totalLooseItems: deliveryResult.totalLooseItems,
      deliveryFeeTotal: deliveryFeeTotal,
      deliveryRevenue: deliveryRevenue,
      deliveryCostToOwner: deliveryCostToOwner,
      customerPayTotal: customerPayTotal,
      ownerCostTotal: ownerCostTotal,
      ownerProfit: ownerProfit,
      costZeroWarning: costZeroWarning,
      belowCost: belowCost,
      canAddToTemporarySale: canAddToTemporarySale,
      validationErrors: errors,
    );
  }

  ProductSaleResult _emptyResult({
    required ProductSaleInput input,
    required String productKindNameKhmer,
    required String inputMethodNameKhmer,
    required String chargeMethodNameKhmer,
    required List<String> errors,
  }) {
    return ProductSaleResult(
      productKindId: input.productKindId,
      productKindNameKhmer: productKindNameKhmer,
      materialId: input.materialId,
      materialNameKhmer: '',
      askModeId: input.askModeId,
      offerId: input.offerId,
      spec: '',
      unitKhmer: '',
      inputMethodId: input.inputMethodId,
      inputMethodNameKhmer: inputMethodNameKhmer,
      chargeMethodId: input.chargeMethodId,
      chargeMethodNameKhmer: chargeMethodNameKhmer,
      formulaText: '',
      areaM2: input.areaM2,
      widthM: input.widthM,
      lengthM: input.lengthM,
      rawQuantity: 0,
      sellQuantity: 0,
      itemsPerBox: 1,
      packagingFullBoxes: 0,
      packagingLooseItems: 0,
      chargedBoxes: 0,
      saleUnitPrice: 0,
      saleBoxPrice: 0,
      salePricePerM2: 0,
      includeAreaRevenue: input.includeAreaRevenue,
      costPricePerM2: 0,
      costUnitPrice: 0,
      costBoxPrice: 0,
      manualTotalPrice: input.manualTotalPrice,
      productRevenue: 0,
      productCost: 0,
      includeDelivery: input.includeDelivery,
      deliveryModeId: input.deliveryModeId,
      deliveryPayerId: input.deliveryPayerId,
      deliveryRate: input.deliveryRate,
      totalFullBoxes: 0,
      totalLooseItems: 0,
      deliveryFeeTotal: 0,
      deliveryRevenue: 0,
      deliveryCostToOwner: 0,
      customerPayTotal: 0,
      ownerCostTotal: 0,
      ownerProfit: 0,
      costZeroWarning: false,
      belowCost: false,
      canAddToTemporarySale: false,
      validationErrors: errors,
    );
  }

  ChargeMethod _chargeMethod(
    String id,
    String inputMethodId,
    List<ChargeMethod> chargeMethods,
  ) {
    final direct = chargeMethods
        .where((mode) => mode.id == id && mode.active)
        .firstOrNull;
    if (direct != null) {
      return direct;
    }
    return ChargeMethodCatalog.byId(
      _defaultChargeMethodForInput(inputMethodId),
    );
  }

  String _defaultChargeMethodForInput(String inputMethodId) {
    return switch (inputMethodId) {
      InputMethodIds.looseQuantity ||
      InputMethodIds.manualQuantity ||
      InputMethodIds.manualPerProduct => ChargeMethodIds.unitOnly,
      InputMethodIds.boxQuantity ||
      InputMethodIds.ceilingBoxQuantity => ChargeMethodIds.boxOnly,
      _ => ChargeMethodIds.boxPlusLoose,
    };
  }

  int _itemsPerBox(MaterialItem material, List<PackagingRule> packagingRules) {
    final packaging = packagingRules
        .where((rule) => rule.materialId == material.id && rule.active)
        .firstOrNull;
    final value = packaging?.itemsPerBox ?? material.itemsPerBox ?? 1;
    return value <= 0 ? 1 : value;
  }

  double _effectivePrice({
    required double? override,
    required String materialId,
    required String primaryTypeId,
    required List<String> fallbackTypeIds,
    required bool useSavedPriceAsDefault,
    required List<MaterialPrice> prices,
    required DateTime now,
  }) {
    if (override != null) {
      return override;
    }
    if (!useSavedPriceAsDefault) {
      return 0;
    }
    return _savedPrice(
      materialId: materialId,
      primaryTypeId: primaryTypeId,
      fallbackTypeIds: fallbackTypeIds,
      prices: prices,
      now: now,
    );
  }

  double _savedPrice({
    required String materialId,
    required String primaryTypeId,
    required List<String> fallbackTypeIds,
    required List<MaterialPrice> prices,
    required DateTime now,
  }) {
    final salePriceCanFallbackFromZero =
        primaryTypeId == PriceTypeIds.saleUnitPrice ||
        primaryTypeId == PriceTypeIds.saleBoxPrice;
    for (final typeId in [primaryTypeId, ...fallbackTypeIds]) {
      final matches =
          prices
              .where(
                (price) =>
                    price.materialId == materialId &&
                    price.priceTypeId == typeId &&
                    price.isEffectiveAt(now),
              )
              .toList()
            ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
      if (matches.isNotEmpty) {
        final price = matches.first.price;
        if (typeId == primaryTypeId &&
            price == 0 &&
            salePriceCanFallbackFromZero &&
            fallbackTypeIds.isNotEmpty) {
          continue;
        }
        return price;
      }
    }
    return 0;
  }

  double _rawFormulaQuantity({
    required double areaM2,
    required MaterialItem material,
    required ProductTemplateMaterialRule? rule,
  }) {
    final formulaType = rule?.formulaTypeOverrideId ?? material.formulaTypeId;
    return switch (formulaType) {
      FormulaTypeIds.areaDividedByCoverage =>
        areaM2 / ((rule?.coverageValueOverride ?? material.coverageValue) ?? 1),
      FormulaTypeIds.areaTimesMultiplier =>
        areaM2 *
            ((rule?.multiplierValueOverride ?? material.multiplierValue) ?? 1),
      FormulaTypeIds.fixedQuantity =>
        (rule?.fixedQuantityOverride ?? material.fixedQuantity) ?? 0,
      _ => areaM2,
    };
  }

  double _ceilingCoverageM2({
    required ProductTypeTemplate? productKind,
    required MaterialItem? ceilingMaterial,
  }) {
    final rule = productKind?.defaultMaterialRules
        .where((item) => item.materialId == _ceilingMaterialId)
        .firstOrNull;
    final value = rule?.coverageValueOverride ?? ceilingMaterial?.coverageValue;
    if (value == null || value <= 0) {
      return _defaultCeilingCoverageM2;
    }
    return value;
  }

  double _ceilingBasedRawQuantity({
    required int ceilingSheets,
    required double? areaM2,
    required MaterialItem material,
    required ProductTemplateMaterialRule? rule,
  }) {
    if (material.id == _ceilingMaterialId) {
      return ceilingSheets.toDouble();
    }
    return _rawFormulaQuantity(
      areaM2: areaM2 ?? 0,
      material: material,
      rule: rule,
    );
  }

  int _chargedBoxes({
    required String chargeMethodId,
    required int sellQuantity,
    required int fullBoxes,
    required int itemsPerBox,
  }) {
    if (chargeMethodId != ChargeMethodIds.boxOnly) {
      return fullBoxes;
    }
    if (sellQuantity <= 0) {
      return 0;
    }
    return math.max(1, (sellQuantity / itemsPerBox).ceil());
  }

  double _productRevenue({
    required String chargeMethodId,
    required int sellQuantity,
    required int fullBoxes,
    required int looseItems,
    required int chargedBoxes,
    required double saleUnitPrice,
    required double saleBoxPrice,
    required double salePricePerM2,
    required double areaM2,
    required bool includeAreaRevenue,
    required double? manualTotalPrice,
  }) {
    return switch (chargeMethodId) {
      ChargeMethodIds.unitOnly => sellQuantity * saleUnitPrice,
      ChargeMethodIds.boxOnly => chargedBoxes * saleBoxPrice,
      ChargeMethodIds.boxPlusLoose =>
        fullBoxes * saleBoxPrice + looseItems * saleUnitPrice,
      ChargeMethodIds.areaM2Price =>
        includeAreaRevenue ? areaM2 * salePricePerM2 : 0,
      ChargeMethodIds.manualTotal => manualTotalPrice ?? 0,
      ChargeMethodIds.quantityOnly => 0,
      _ => 0,
    };
  }

  double _productCost({
    required String chargeMethodId,
    required int sellQuantity,
    required int fullBoxes,
    required int looseItems,
    required int chargedBoxes,
    required double costUnitPrice,
    required double costBoxPrice,
    required double defaultCost,
    required double costPricePerM2,
    required double areaM2,
  }) {
    return switch (chargeMethodId) {
      ChargeMethodIds.unitOnly => sellQuantity * costUnitPrice,
      ChargeMethodIds.boxOnly => chargedBoxes * costBoxPrice,
      ChargeMethodIds.boxPlusLoose => defaultCost,
      ChargeMethodIds.areaM2Price =>
        costPricePerM2 > 0 ? areaM2 * costPricePerM2 : defaultCost,
      ChargeMethodIds.manualTotal => defaultCost,
      ChargeMethodIds.quantityOnly => defaultCost,
      _ => 0,
    };
  }

  bool _belowCost({
    required String chargeMethodId,
    required double saleUnitPrice,
    required double saleBoxPrice,
    required double costUnitPrice,
    required double costBoxPrice,
    required double productRevenue,
    required double productCost,
    required bool includeAreaRevenue,
  }) {
    return switch (chargeMethodId) {
      ChargeMethodIds.unitOnly =>
        costUnitPrice > 0 && saleUnitPrice < costUnitPrice,
      ChargeMethodIds.boxOnly =>
        costBoxPrice > 0 && saleBoxPrice < costBoxPrice,
      ChargeMethodIds.boxPlusLoose =>
        (costUnitPrice > 0 && saleUnitPrice < costUnitPrice) ||
            (costBoxPrice > 0 && saleBoxPrice < costBoxPrice),
      ChargeMethodIds.areaM2Price =>
        includeAreaRevenue && productCost > 0 && productRevenue < productCost,
      ChargeMethodIds.manualTotal =>
        productCost > 0 && productRevenue < productCost,
      ChargeMethodIds.quantityOnly => false,
      _ => false,
    };
  }

  bool _costZeroWarning({
    required String chargeMethodId,
    required double costUnitPrice,
    required double costBoxPrice,
    required int sellQuantity,
    required double productCost,
    required double costPricePerM2,
  }) {
    return switch (chargeMethodId) {
      ChargeMethodIds.unitOnly => costUnitPrice == 0,
      ChargeMethodIds.boxOnly => costBoxPrice == 0,
      ChargeMethodIds.boxPlusLoose => costUnitPrice == 0 && costBoxPrice == 0,
      ChargeMethodIds.areaM2Price =>
        costPricePerM2 > 0
            ? productCost == 0
            : (sellQuantity > 0 && productCost == 0),
      ChargeMethodIds.manualTotal => productCost == 0,
      ChargeMethodIds.quantityOnly => false,
      _ => false,
    };
  }

  String _formulaText({
    required String inputMethodId,
    required double? areaM2,
    required double? widthM,
    required double? lengthM,
    required MaterialItem material,
    required ProductTemplateMaterialRule? rule,
  }) {
    final areaText = MoneyFormatter.decimal(areaM2 ?? 0);
    if (inputMethodId == InputMethodIds.widthLength) {
      final widthText = MoneyFormatter.decimal(widthM ?? 0);
      final lengthText = MoneyFormatter.decimal(lengthM ?? 0);
      return 'ទទឹង ${widthText}m × បណ្ដោយ ${lengthText}m = $areaText ការ៉េ';
    }
    final formulaType = rule?.formulaTypeOverrideId ?? material.formulaTypeId;
    return switch (formulaType) {
      FormulaTypeIds.areaDividedByCoverage =>
        '$areaText ការ៉េ / ${MoneyFormatter.decimal((rule?.coverageValueOverride ?? material.coverageValue) ?? 1)}',
      FormulaTypeIds.areaTimesMultiplier =>
        '$areaText ការ៉េ × ${MoneyFormatter.decimal((rule?.multiplierValueOverride ?? material.multiplierValue) ?? 1)}',
      FormulaTypeIds.fixedQuantity => MoneyFormatter.decimal(
        (rule?.fixedQuantityOverride ?? material.fixedQuantity) ?? 0,
      ),
      _ => '$areaText ការ៉េ',
    };
  }

  String _ceilingQuantityFormulaText({
    int? ceilingBoxes,
    int? ceilingItemsPerBox,
    int? looseSheets,
    required int ceilingSheets,
    required double? areaM2,
    required MaterialItem material,
    required ProductTemplateMaterialRule? rule,
  }) {
    final areaText = MoneyFormatter.decimal(areaM2 ?? 0);
    final source = ceilingBoxes == null
        ? '$ceilingSheets ពិដានរាយ'
        : looseSheets == null
        ? '$ceilingBoxes កេសពិដាន × ${ceilingItemsPerBox ?? _defaultCeilingItemsPerBox}'
        : '$ceilingBoxes កេសពិដាន × ${ceilingItemsPerBox ?? _defaultCeilingItemsPerBox} + $looseSheets រាយ';
    if (material.id == _ceilingMaterialId) {
      return '$source = $ceilingSheets សន្លឹក | ការ៉េប៉ាន់ស្មាន $areaText';
    }
    return '$source = $ceilingSheets សន្លឹក | ${_formulaText(inputMethodId: InputMethodIds.areaM2, areaM2: areaM2, widthM: null, lengthM: null, material: material, rule: rule)}';
  }

  int _positiveInt(int? value, String error, List<String> errors) {
    final next = value ?? 0;
    if (next <= 0) {
      errors.add(error);
      return 0;
    }
    return next;
  }

  int _zeroOrPositiveInt(int? value, String error, List<String> errors) {
    final next = value ?? 0;
    if (next < 0) {
      errors.add(error);
      return 0;
    }
    return next;
  }
}
