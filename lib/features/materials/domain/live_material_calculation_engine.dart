import 'dart:math' as math;

import '../../../core/constants/business_ids.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/quantity_rounding.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/packaging_rule.dart';
import '../data/models/product_type_template.dart';
import '../data/models/sell_mode.dart';
import '../../../core/utils/packaging_breakdown.dart';
import 'live_calculation_models.dart';

class LiveMaterialCalculationEngine {
  const LiveMaterialCalculationEngine({DateTime Function()? clock})
    : _clock = clock;

  final DateTime Function()? _clock;

  LiveCalculationResult calculate({
    required LiveCalculationInput input,
    required ProductTypeTemplate productType,
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    required List<SellMode> sellModes,
    List<PackagingRule> packagingRules = const [],
  }) {
    final errors = <String>[];
    final lines = <LiveCalculationLineResult>[];
    final now = _clock?.call() ?? DateTime.now();
    final materialById = {
      for (final material in materials) material.id: material,
    };
    final packagingByMaterialId = {
      for (final rule in packagingRules.where((rule) => rule.active))
        rule.materialId: rule,
    };
    final selectedIds = input.selectedOptionalMaterialIds.toSet();
    final activeSellModeIds = sellModes
        .where((mode) => mode.active)
        .map((mode) => mode.id)
        .toSet();

    if (input.productTypeTemplateId.trim().isEmpty || !productType.active) {
      errors.add('Product type must be selected and active.');
    }

    final needsArea =
        productType.inputModeId == InputModeIds.areaM2 ||
        productType.inputModeId == InputModeIds.mixedAreaAndManual;
    if (needsArea && (input.areaM2 == null || input.areaM2! <= 0)) {
      errors.add('Area (m² / ការ៉េ) must be greater than 0.');
    }

    if (productType.defaultMaterialRules.isEmpty && selectedIds.isEmpty) {
      errors.add('No material is configured for this product type.');
    }

    final rules = <ProductTemplateMaterialRule>[];
    for (final rule in productType.defaultMaterialRules) {
      if (rule.includedByDefault || selectedIds.contains(rule.materialId)) {
        rules.add(rule);
      }
    }

    final templateMaterialIds = productType.defaultMaterialRules
        .map((rule) => rule.materialId)
        .toSet();
    for (final selectedId in selectedIds) {
      if (!templateMaterialIds.contains(selectedId)) {
        final material = materialById[selectedId];
        if (material != null) {
          rules.add(
            ProductTemplateMaterialRule(
              materialId: selectedId,
              includedByDefault: true,
              allowManualOverride: true,
              formulaTypeOverrideId: material.formulaTypeId,
              coverageValueOverride: null,
              multiplierValueOverride: null,
              fixedQuantityOverride: null,
              defaultSellModeId: material.isServiceOnly
                  ? SellModeIds.areaService
                  : SellModeIds.unitOnly,
            ),
          );
        }
      }
    }

    if (rules.isEmpty) {
      errors.add('Select at least one material for this product type.');
    }

    for (final rule in rules) {
      final material = materialById[rule.materialId];
      if (material == null) {
        errors.add('Configured material is missing: ${rule.materialId}.');
        continue;
      }
      if (!material.active) {
        errors.add('Inactive material selected: ${material.englishName}.');
        continue;
      }

      final sellModeId =
          input.sellModeOverrides[material.id] ?? rule.defaultSellModeId;
      if (!activeSellModeIds.contains(sellModeId)) {
        errors.add(
          'Invalid sell mode for ${material.englishName}: $sellModeId.',
        );
        continue;
      }

      final raw = _rawQuantity(
        input: input,
        productType: productType,
        material: material,
        itemsPerBox:
            packagingByMaterialId[material.id]?.itemsPerBox ??
            material.itemsPerBox,
        rule: rule,
        sellModeId: sellModeId,
        errors: errors,
      );
      if (raw == null) {
        continue;
      }

      final rounded = QuantityRounding.customerCeil(raw);
      final itemsPerBox =
          packagingByMaterialId[material.id]?.itemsPerBox ??
          material.itemsPerBox;
      final usesBox =
          sellModeId == SellModeIds.boxOnlyRoundUp ||
          sellModeId == SellModeIds.boxPlusLoose;
      if (usesBox && (itemsPerBox == null || itemsPerBox <= 0)) {
        errors.add(
          'Missing or invalid items per box for ${material.englishName}.',
        );
        continue;
      }

      final breakdown = breakdownFromTotalQuantity(
        totalQuantity: rounded,
        itemsPerBox: itemsPerBox ?? 0,
      );
      final fullBoxes = breakdown.fullBoxes;
      final looseItems = breakdown.looseItems;

      final unitPrice = _activePrice(
        material.id,
        _unitPriceTypeForSellMode(sellModeId),
        prices,
        now,
      );
      final boxPrice = _activePrice(
        material.id,
        PriceTypeIds.boxPrice,
        prices,
        now,
      );

      if (_requiresUnitPrice(sellModeId) && unitPrice == null) {
        errors.add('Missing unit price for ${material.englishName}.');
        continue;
      }
      if (_requiresBoxPrice(sellModeId) && boxPrice == null) {
        errors.add('Missing box price for ${material.englishName}.');
        continue;
      }

      final chargedBoxes = sellModeId == SellModeIds.boxOnlyRoundUp
          ? (rounded / itemsPerBox!).ceil()
          : null;
      final lineTotal = _lineTotal(
        sellModeId: sellModeId,
        areaM2: input.areaM2,
        roundedQuantity: rounded,
        fullBoxes: fullBoxes,
        looseItems: looseItems,
        chargedBoxes: chargedBoxes,
        unitPrice: unitPrice?.price,
        boxPrice: boxPrice?.price,
      );

      lines.add(
        LiveCalculationLineResult(
          materialId: material.id,
          khmerName: material.khmerName,
          englishName: material.englishName,
          spec: material.spec,
          formulaText: _formulaText(input, material, rule, sellModeId),
          rawQuantity: raw,
          roundedQuantity: rounded,
          unitKhmer: material.unitKhmer,
          unitEnglish: material.unitEnglish,
          itemsPerBox: itemsPerBox,
          packagingFullBoxes: fullBoxes,
          packagingLooseItems: looseItems,
          sellModeId: sellModeId,
          unitPrice: unitPrice?.price,
          boxPrice: boxPrice?.price,
          chargedBoxes: chargedBoxes,
          lineTotal: lineTotal,
          showInPickList:
              material.showInPickList &&
              !material.isServiceOnly &&
              itemsPerBox != null &&
              itemsPerBox > 0,
        ),
      );
    }

    final subtotal = MoneyFormatter.roundMoney(
      lines.fold<double>(0, (sum, line) => sum + line.lineTotal),
    );
    final discountTotal = MoneyFormatter.roundMoney(
      math.min(
        subtotal,
        math.max(0.0, input.discountAmount) +
            subtotal * (math.max(0.0, input.discountPercent) / 100),
      ),
    );
    final grandTotal = MoneyFormatter.roundMoney(subtotal - discountTotal);

    return LiveCalculationResult(
      productTypeTemplateId: productType.id,
      productTypeNameKhmer: productType.nameKhmer,
      productTypeNameEnglish: productType.nameEnglish,
      lines: errors.isEmpty ? lines : const [],
      subtotal: errors.isEmpty ? subtotal : 0,
      discountTotal: errors.isEmpty ? discountTotal : 0,
      grandTotal: errors.isEmpty ? grandTotal : 0,
      validationErrors: errors,
    );
  }

  double? _rawQuantity({
    required LiveCalculationInput input,
    required ProductTypeTemplate productType,
    required MaterialItem material,
    required int? itemsPerBox,
    required ProductTemplateMaterialRule rule,
    required String sellModeId,
    required List<String> errors,
  }) {
    if (sellModeId == SellModeIds.areaService) {
      if (input.areaM2 == null || input.areaM2! <= 0) {
        errors.add(
          'Area (m² / ការ៉េ) is required for ${material.englishName}.',
        );
        return null;
      }
      return input.areaM2!;
    }

    if (productType.inputModeId == InputModeIds.boxQuantity) {
      final manual = input.manualQuantities[material.id];
      if (manual == null || manual <= 0) {
        errors.add('Box quantity is required for ${material.englishName}.');
        return null;
      }
      if (itemsPerBox == null || itemsPerBox <= 0) {
        errors.add('Items per box is required for ${material.englishName}.');
        return null;
      }
      return manual * itemsPerBox;
    }

    final formulaType = rule.formulaTypeOverrideId ?? material.formulaTypeId;
    switch (formulaType) {
      case FormulaTypeIds.areaDividedByCoverage:
        if (input.areaM2 == null || input.areaM2! <= 0) {
          errors.add(
            'Area (m² / ការ៉េ) is required for ${material.englishName}.',
          );
          return null;
        }
        final coverage = rule.coverageValueOverride ?? material.coverageValue;
        if (coverage == null || coverage <= 0) {
          errors.add('Coverage value is required for ${material.englishName}.');
          return null;
        }
        return input.areaM2! / coverage;
      case FormulaTypeIds.areaTimesMultiplier:
        if (input.areaM2 == null || input.areaM2! <= 0) {
          errors.add(
            'Area (m² / ការ៉េ) is required for ${material.englishName}.',
          );
          return null;
        }
        final multiplier =
            rule.multiplierValueOverride ?? material.multiplierValue;
        if (multiplier == null) {
          errors.add(
            'Multiplier value is required for ${material.englishName}.',
          );
          return null;
        }
        return input.areaM2! * multiplier;
      case FormulaTypeIds.fixedQuantity:
        final fixed = rule.fixedQuantityOverride ?? material.fixedQuantity;
        if (fixed == null) {
          errors.add('Fixed quantity is required for ${material.englishName}.');
          return null;
        }
        return fixed;
      case FormulaTypeIds.manualQuantity:
        final manual = input.manualQuantities[material.id];
        if (manual == null) {
          errors.add(
            'Manual quantity is required for ${material.englishName}.',
          );
          return null;
        }
        if (manual <= 0) {
          errors.add(
            'Manual quantity must be greater than 0 for ${material.englishName}.',
          );
          return null;
        }
        return manual;
      default:
        errors.add(
          'Invalid formula for ${material.englishName}: $formulaType.',
        );
        return null;
    }
  }

  MaterialPrice? _activePrice(
    String materialId,
    String priceTypeId,
    List<MaterialPrice> prices,
    DateTime now,
  ) {
    final matches =
        prices
            .where(
              (price) =>
                  price.materialId == materialId &&
                  price.priceTypeId == priceTypeId &&
                  price.isEffectiveAt(now),
            )
            .toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return matches.isEmpty ? null : matches.first;
  }

  String _unitPriceTypeForSellMode(String sellModeId) {
    return switch (sellModeId) {
      SellModeIds.areaService => PriceTypeIds.servicePrice,
      SellModeIds.manualTotal => PriceTypeIds.manualPrice,
      _ => PriceTypeIds.unitPrice,
    };
  }

  bool _requiresUnitPrice(String sellModeId) {
    return sellModeId == SellModeIds.unitOnly ||
        sellModeId == SellModeIds.boxPlusLoose ||
        sellModeId == SellModeIds.manualTotal ||
        sellModeId == SellModeIds.areaService;
  }

  bool _requiresBoxPrice(String sellModeId) {
    return sellModeId == SellModeIds.boxOnlyRoundUp ||
        sellModeId == SellModeIds.boxPlusLoose;
  }

  double _lineTotal({
    required String sellModeId,
    required double? areaM2,
    required int roundedQuantity,
    required int fullBoxes,
    required int looseItems,
    required int? chargedBoxes,
    required double? unitPrice,
    required double? boxPrice,
  }) {
    final total = switch (sellModeId) {
      SellModeIds.unitOnly => roundedQuantity * (unitPrice ?? 0),
      SellModeIds.boxOnlyRoundUp => (chargedBoxes ?? 0) * (boxPrice ?? 0),
      SellModeIds.boxPlusLoose =>
        (fullBoxes * (boxPrice ?? 0)) + (looseItems * (unitPrice ?? 0)),
      SellModeIds.manualTotal => roundedQuantity * (unitPrice ?? 0),
      SellModeIds.areaService => (areaM2 ?? 0) * (unitPrice ?? 0),
      _ => 0,
    };
    return MoneyFormatter.roundMoney(total);
  }

  String _formulaText(
    LiveCalculationInput input,
    MaterialItem material,
    ProductTemplateMaterialRule rule,
    String sellModeId,
  ) {
    if (sellModeId == SellModeIds.areaService) {
      return '${_fmt(input.areaM2)} m² service';
    }
    final formulaType = rule.formulaTypeOverrideId ?? material.formulaTypeId;
    return switch (formulaType) {
      FormulaTypeIds.areaDividedByCoverage =>
        '${_fmt(input.areaM2)} / ${_fmt(rule.coverageValueOverride ?? material.coverageValue)}',
      FormulaTypeIds.areaTimesMultiplier =>
        '${_fmt(input.areaM2)} × ${_fmt(rule.multiplierValueOverride ?? material.multiplierValue)}',
      FormulaTypeIds.fixedQuantity =>
        '${_fmt(rule.fixedQuantityOverride ?? material.fixedQuantity)} fixed',
      FormulaTypeIds.manualQuantity => 'manual quantity',
      _ => formulaType,
    };
  }

  String _fmt(num? value) {
    if (value == null) {
      return '-';
    }
    return MoneyFormatter.decimal(value);
  }
}
