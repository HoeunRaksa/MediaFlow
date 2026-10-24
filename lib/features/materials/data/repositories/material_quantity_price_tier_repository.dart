import '../../../../core/storage/local_json_storage.dart';
import '../models/material_quantity_price_tier.dart';

abstract class MaterialQuantityPriceTierRepository {
  Future<List<MaterialQuantityPriceTier>> getTiers();
  Future<void> saveTier(MaterialQuantityPriceTier tier);
}

class LocalMaterialQuantityPriceTierRepository
    implements MaterialQuantityPriceTierRepository {
  LocalMaterialQuantityPriceTierRepository(this._storage);

  static const _key = 'materialQuantityPriceTiers';
  final LocalJsonStorage _storage;

  @override
  Future<List<MaterialQuantityPriceTier>> getTiers() async {
    final rows = await _storage.readCollection(_key);
    final tiers = rows.map(MaterialQuantityPriceTier.fromJson).toList();
    tiers.sort((a, b) {
      final byMaterial = a.materialId.compareTo(b.materialId);
      if (byMaterial != 0) return byMaterial;
      final byQuantity = a.minQuantity.compareTo(b.minQuantity);
      return byQuantity != 0 ? byQuantity : a.id.compareTo(b.id);
    });
    return tiers;
  }

  @override
  Future<void> saveTier(MaterialQuantityPriceTier tier) async {
    final tiers = await getTiers();
    final existing = tiers.indexWhere((entry) => entry.id == tier.id);
    if (existing >= 0) {
      tiers[existing] = tier;
    } else {
      tiers.add(tier);
    }
    await _storage.writeCollection(
      _key,
      tiers.map((entry) => entry.toJson()).toList(),
    );
  }
}
