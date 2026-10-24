class FormulaTypeIds {
  const FormulaTypeIds._();

  static const areaDividedByCoverage = 'area_divided_by_coverage';
  static const areaTimesMultiplier = 'area_times_multiplier';
  static const fixedQuantity = 'fixed_quantity';
  static const manualQuantity = 'manual_quantity';
  static const areaService = 'area_service';
  static const areaTimesMultiplierPlusFixed =
      'area_times_multiplier_plus_fixed';
  static const areaDividedByCoveragePlusWaste =
      'area_divided_by_coverage_plus_waste';

  static const supportedNow = {
    areaDividedByCoverage,
    areaTimesMultiplier,
    fixedQuantity,
    manualQuantity,
    areaService,
  };
}

class PricingBehaviorIds {
  const PricingBehaviorIds._();

  static const unitPrice = 'unit_price';
  static const boxPrice = 'box_price';
  static const manualPrice = 'manual_price';
  static const servicePrice = 'service_price';

  static const supportedNow = {unitPrice, boxPrice, manualPrice, servicePrice};
}

class PricingTierIds {
  const PricingTierIds._();

  static const retail = 'retail';
  static const wholesale = 'wholesale';
  static const box = 'box';
}

class InputModeIds {
  const InputModeIds._();

  static const areaM2 = 'area_m2';
  static const manualQuantity = 'manual_quantity';
  static const boxQuantity = 'box_quantity';
  static const mixedAreaAndManual = 'mixed_area_and_manual';

  static const supportedNow = {
    areaM2,
    manualQuantity,
    boxQuantity,
    mixedAreaAndManual,
  };
}

class SellModeIds {
  const SellModeIds._();

  static const unitOnly = 'unit_only';
  static const boxOnlyRoundUp = 'box_only_round_up';
  static const boxPlusLoose = 'box_plus_loose';
  static const manualTotal = 'manual_total';
  static const areaService = 'area_service';

  static const supportedNow = {
    unitOnly,
    boxOnlyRoundUp,
    boxPlusLoose,
    manualTotal,
    areaService,
  };
}

class PriceTypeIds {
  const PriceTypeIds._();

  static const saleUnitPrice = 'sale_unit_price';
  static const saleBoxPrice = 'sale_box_price';
  static const areaM2SalePrice = 'area_m2_sale_price';
  static const areaM2CostPrice = 'area_m2_cost_price';
  static const costUnitPrice = 'cost_unit_price';
  static const costBoxPrice = 'cost_box_price';
  static const deliveryPrice = 'delivery_price';

  // Legacy IDs are kept so older saved data and the original calculator tests
  // can still resolve prices.
  static const unitPrice = 'unit_price';
  static const boxPrice = 'box_price';
  static const wholesaleUnitPrice = 'wholesale_unit_price';
  static const servicePrice = 'service_price';
  static const manualPrice = 'manual_price';

  static const editableDefaults = {
    saleUnitPrice,
    saleBoxPrice,
    areaM2SalePrice,
    areaM2CostPrice,
    costUnitPrice,
    costBoxPrice,
    unitPrice,
    boxPrice,
    wholesaleUnitPrice,
    servicePrice,
    manualPrice,
    deliveryPrice,
  };
}

class DeliveryPayerIds {
  const DeliveryPayerIds._();

  static const ownerPays = 'owner_pays';
  static const customerPays = 'customer_pays';
  static const noDelivery = 'no_delivery';

  static const supportedNow = {ownerPays, customerPays, noDelivery};
}

class DeliveryModeIds {
  const DeliveryModeIds._();

  static const flatDelivery = 'flat_delivery';
  static const perBoxDelivery = 'per_box_delivery';

  static const supportedNow = {flatDelivery, perBoxDelivery};
}
