import 'dart:math' as math;

import '../../../core/constants/business_ids.dart';
import '../../../core/errors/calculation_error.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/quantity_rounding.dart';
import '../data/models/formula_rule.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/pricing_tier.dart';
import 'calculation_input.dart';
import 'calculation_result.dart';

class MaterialCalculationEngine {
  const MaterialCalculationEngine({DateTime Function()? clock})
    : _clock = clock;

  final DateTime Function()? _clock;

  QuotationCalculationResult calculate({
    required CalculationInput input,
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    required List<PricingTier> pricingTiers,
    required List<FormulaRule> formulaRules,
  }) {
    final errors = <CalculationValidationError>[];
    final now = _clock?.call() ?? DateTime.now();

    if (input.area <= 0) {
      errors.add(
        const CalculationValidationError(
          code: 'area_invalid',
          message: 'Area must be greater than 0.',
        ),
      );
    }

    final pricingTier = _findPricingTier(input.pricingTierId, pricingTiers);
    if (pricingTier == null) {
      errors.add(
        CalculationValidationError(
          code: 'pricing_tier_missing',
          message: 'Missing active pricing tier: ${input.pricingTierId}.',
        ),
      );
    } else if (!PricingBehaviorIds.supportedNow.contains(
      pricingTier.pricingBehaviorId,
    )) {
      errors.add(
        CalculationValidationError(
          code: 'pricing_behavior_unknown',
          message:
              'Unsupported pricing behavior: ${pricingTier.pricingBehaviorId}.',
        ),
      );
    }

    final rulesById = {
      for (final rule in formulaRules.where((rule) => rule.active))
        rule.formulaTypeId: rule,
    };

    final selectedOptionalIds = input.selectedOptionalMaterialIds.toSet();
    final selectedMaterials =
        materials
            .where(
              (material) =>
                  material.active &&
                  (material.includedByDefault ||
                      selectedOptionalIds.contains(material.id)),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final quoteLines = <QuotationLineResult>[];
    final pickListLines = <PickListLineResult>[];

    for (final material in selectedMaterials) {
      final formulaRule = rulesById[material.formulaTypeId];
      if (material.formulaTypeId.trim().isEmpty) {
        errors.add(
          CalculationValidationError(
            code: 'formula_missing',
            message: 'Missing formula type for ${material.englishName}.',
            materialId: material.id,
          ),
        );
        continue;
      }
      if (formulaRule == null) {
        errors.add(
          CalculationValidationError(
            code: 'formula_unknown',
            message:
                'Unknown or inactive formula type ${material.formulaTypeId} for ${material.englishName}.',
            materialId: material.id,
          ),
        );
        continue;
      }
      if (!FormulaTypeIds.supportedNow.contains(material.formulaTypeId)) {
        errors.add(
          CalculationValidationError(
            code: 'formula_not_implemented',
            message:
                'Formula type ${material.formulaTypeId} is seeded for future use but not implemented yet.',
            materialId: material.id,
          ),
        );
        continue;
      }

      final rawQuantity = _calculateRawQuantity(
        input: input,
        material: material,
        errors: errors,
      );
      if (rawQuantity == null) {
        continue;
      }
      final roundedQuantity = QuantityRounding.customerCeil(rawQuantity);

      if (material.showInPickList &&
          !material.isServiceOnly &&
          material.itemsPerBox != null &&
          material.itemsPerBox! <= 0) {
        errors.add(
          CalculationValidationError(
            code: 'items_per_box_invalid',
            message: 'Items per box must be greater than 0 for pick-list.',
            materialId: material.id,
          ),
        );
        continue;
      }

      if (pricingTier == null) {
        continue;
      }

      final activePrice = _findPrice(
        materialId: material.id,
        pricingTierId: pricingTier.id,
        prices: prices,
        now: now,
      );
      if (activePrice == null) {
        errors.add(
          CalculationValidationError(
            code: 'price_missing',
            message:
                'Missing active price for ${material.englishName} in tier ${pricingTier.id}.',
            materialId: material.id,
          ),
        );
        continue;
      }
      if (activePrice.price < 0) {
        errors.add(
          CalculationValidationError(
            code: 'price_invalid',
            message: 'Price cannot be negative for ${material.englishName}.',
            materialId: material.id,
          ),
        );
        continue;
      }

      final chargedBoxes = _chargedBoxes(
        material: material,
        roundedQuantity: roundedQuantity,
        behaviorId: pricingTier.pricingBehaviorId,
        errors: errors,
      );
      if (pricingTier.pricingBehaviorId == PricingBehaviorIds.boxPrice &&
          chargedBoxes == null) {
        continue;
      }

      final lineTotal = _lineTotal(
        behaviorId: pricingTier.pricingBehaviorId,
        roundedQuantity: roundedQuantity,
        chargedBoxes: chargedBoxes,
        appliedUnitPrice: activePrice.price,
      );

      final line = QuotationLineResult(
        materialId: material.id,
        khmerName: material.khmerName,
        englishName: material.englishName,
        spec: material.spec,
        categoryId: material.categoryId,
        unitKhmer: material.unitKhmer,
        unitEnglish: material.unitEnglish,
        formulaTypeId: material.formulaTypeId,
        rawQuantity: rawQuantity,
        roundedQuantity: roundedQuantity,
        pricingTierId: pricingTier.id,
        pricingBehaviorId: pricingTier.pricingBehaviorId,
        appliedUnitPrice: activePrice.price,
        chargedBoxes: chargedBoxes,
        lineTotal: lineTotal,
        showInCustomerQuote: material.showInCustomerQuote,
        showInPickList: material.showInPickList,
        isServiceOnly: material.isServiceOnly,
        snapshot: _snapshot(
          input: input,
          material: material,
          price: activePrice,
          pricingTier: pricingTier,
          rawQuantity: rawQuantity,
          roundedQuantity: roundedQuantity,
          chargedBoxes: chargedBoxes,
          lineTotal: lineTotal,
          calculatedAt: now,
        ),
      );

      if (material.showInCustomerQuote) {
        quoteLines.add(line);
      }

      final itemsPerBox = material.itemsPerBox;
      if (material.showInPickList &&
          !material.isServiceOnly &&
          itemsPerBox != null &&
          itemsPerBox > 0) {
        pickListLines.add(
          PickListLineResult(
            materialId: material.id,
            khmerName: material.khmerName,
            englishName: material.englishName,
            spec: material.spec,
            totalQuantity: roundedQuantity,
            unitKhmer: material.unitKhmer,
            unitEnglish: material.unitEnglish,
            itemsPerBox: itemsPerBox,
            packagingFullBoxes: roundedQuantity ~/ itemsPerBox,
            packagingLooseItems: roundedQuantity % itemsPerBox,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      throw CalculationException(errors);
    }

    final subtotal = MoneyFormatter.roundMoney(
      quoteLines.fold<double>(0, (sum, line) => sum + line.lineTotal),
    );
    final safeDiscountAmount = math.max(0.0, input.discountAmount);
    final safeDiscountPercent = math.max(0.0, input.discountPercent);
    final percentDiscount = subtotal * (safeDiscountPercent / 100);
    final discountTotal = MoneyFormatter.roundMoney(
      math.min(subtotal, safeDiscountAmount + percentDiscount),
    );
    final grandTotal = MoneyFormatter.roundMoney(subtotal - discountTotal);

    return QuotationCalculationResult(
      area: input.area,
      pricingTierId: pricingTier!.id,
      pricingTierNameKhmer: pricingTier.nameKhmer,
      pricingTierNameEnglish: pricingTier.nameEnglish,
      quoteLines: quoteLines,
      pickListLines: pickListLines,
      subtotal: subtotal,
      discountAmount: safeDiscountAmount,
      discountPercent: safeDiscountPercent,
      discountTotal: discountTotal,
      grandTotal: grandTotal,
      calculatedAt: now,
    );
  }

  PricingTier? _findPricingTier(String pricingTierId, List<PricingTier> tiers) {
    for (final tier in tiers) {
      if (tier.id == pricingTierId && tier.active) {
        return tier;
      }
    }
    return null;
  }

  MaterialPrice? _findPrice({
    required String materialId,
    required String pricingTierId,
    required List<MaterialPrice> prices,
    required DateTime now,
  }) {
    final matching =
        prices
            .where(
              (price) =>
                  price.materialId == materialId &&
                  price.pricingTierId == pricingTierId &&
                  price.isEffectiveAt(now),
            )
            .toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return matching.isEmpty ? null : matching.first;
  }

  double? _calculateRawQuantity({
    required CalculationInput input,
    required MaterialItem material,
    required List<CalculationValidationError> errors,
  }) {
    switch (material.formulaTypeId) {
      case FormulaTypeIds.areaDividedByCoverage:
        final coverage = material.coverageValue;
        if (coverage == null) {
          errors.add(
            CalculationValidationError(
              code: 'coverage_missing',
              message:
                  'Coverage value is required for ${material.englishName}.',
              materialId: material.id,
            ),
          );
          return null;
        }
        if (coverage <= 0) {
          errors.add(
            CalculationValidationError(
              code: 'coverage_invalid',
              message: 'Coverage value must be greater than 0.',
              materialId: material.id,
            ),
          );
          return null;
        }
        return input.area / coverage;
      case FormulaTypeIds.areaTimesMultiplier:
        final multiplier = material.multiplierValue;
        if (multiplier == null) {
          errors.add(
            CalculationValidationError(
              code: 'multiplier_missing',
              message:
                  'Multiplier value is required for ${material.englishName}.',
              materialId: material.id,
            ),
          );
          return null;
        }
        return input.area * multiplier;
      case FormulaTypeIds.fixedQuantity:
        final fixed = material.fixedQuantity;
        if (fixed == null) {
          errors.add(
            CalculationValidationError(
              code: 'fixed_quantity_missing',
              message:
                  'Fixed quantity is required for ${material.englishName}.',
              materialId: material.id,
            ),
          );
          return null;
        }
        return fixed;
      case FormulaTypeIds.manualQuantity:
        final manual = input.manualQuantities[material.id];
        if (manual == null) {
          errors.add(
            CalculationValidationError(
              code: 'manual_quantity_missing',
              message:
                  'Manual quantity is required for ${material.englishName}.',
              materialId: material.id,
            ),
          );
          return null;
        }
        if (manual <= 0) {
          errors.add(
            CalculationValidationError(
              code: 'manual_quantity_invalid',
              message: 'Manual quantity must be greater than 0.',
              materialId: material.id,
            ),
          );
          return null;
        }
        return manual;
      default:
        errors.add(
          CalculationValidationError(
            code: 'formula_unknown',
            message: 'Unknown formula type ${material.formulaTypeId}.',
            materialId: material.id,
          ),
        );
        return null;
    }
  }

  int? _chargedBoxes({
    required MaterialItem material,
    required int roundedQuantity,
    required String behaviorId,
    required List<CalculationValidationError> errors,
  }) {
    if (behaviorId != PricingBehaviorIds.boxPrice) {
      return null;
    }
    final itemsPerBox = material.itemsPerBox;
    if (itemsPerBox == null) {
      errors.add(
        CalculationValidationError(
          code: 'box_items_missing',
          message:
              'Box pricing selected but items per box is missing for ${material.englishName}.',
          materialId: material.id,
        ),
      );
      return null;
    }
    if (itemsPerBox <= 0) {
      errors.add(
        CalculationValidationError(
          code: 'box_items_invalid',
          message: 'Items per box must be greater than 0 for box pricing.',
          materialId: material.id,
        ),
      );
      return null;
    }
    return (roundedQuantity / itemsPerBox).ceil();
  }

  double _lineTotal({
    required String behaviorId,
    required int roundedQuantity,
    required int? chargedBoxes,
    required double appliedUnitPrice,
  }) {
    final total = switch (behaviorId) {
      PricingBehaviorIds.boxPrice => (chargedBoxes ?? 0) * appliedUnitPrice,
      PricingBehaviorIds.unitPrice ||
      PricingBehaviorIds.manualPrice ||
      PricingBehaviorIds.servicePrice => roundedQuantity * appliedUnitPrice,
      _ => 0,
    };
    return MoneyFormatter.roundMoney(total);
  }

  Map<String, dynamic> _snapshot({
    required CalculationInput input,
    required MaterialItem material,
    required MaterialPrice price,
    required PricingTier pricingTier,
    required double rawQuantity,
    required int roundedQuantity,
    required int? chargedBoxes,
    required double lineTotal,
    required DateTime calculatedAt,
  }) {
    return {
      'material': material.toJson(),
      'price': price.toJson(),
      'pricingTier': pricingTier.toJson(),
      'formulaTypeId': material.formulaTypeId,
      'formulaValues': {
        'coverageValue': material.coverageValue,
        'multiplierValue': material.multiplierValue,
        'fixedQuantity': material.fixedQuantity,
        'manualQuantity': input.manualQuantities[material.id],
      },
      'calculation': {
        'area': input.area,
        'rawQuantity': rawQuantity,
        'roundedQuantity': roundedQuantity,
        'chargedBoxes': chargedBoxes,
        'appliedUnitPrice': price.price,
        'lineTotal': lineTotal,
      },
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}
