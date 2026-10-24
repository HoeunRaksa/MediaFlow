import '../data/models/material_quantity_price_tier.dart';

class MaterialQuantityPricing {
  const MaterialQuantityPricing._();

  static MaterialQuantityPriceTier? resolve({
    required String materialId,
    required int quantity,
    required List<MaterialQuantityPriceTier> tiers,
  }) {
    MaterialQuantityPriceTier? selected;
    for (final tier in tiers) {
      if (!tier.active ||
          tier.materialId != materialId ||
          tier.minQuantity > quantity) {
        continue;
      }
      if (selected == null ||
          tier.minQuantity > selected.minQuantity ||
          (tier.minQuantity == selected.minQuantity &&
              tier.id.compareTo(selected.id) < 0)) {
        selected = tier;
      }
    }
    return selected;
  }
}
