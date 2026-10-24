import '../../../../core/storage/local_json_storage.dart';
import '../models/pricing_tier.dart';

abstract class PricingTierRepository {
  Future<List<PricingTier>> getPricingTiers();
  Future<void> savePricingTier(PricingTier tier);
  Future<void> updatePricingTier(PricingTier tier);
}

class LocalPricingTierRepository implements PricingTierRepository {
  LocalPricingTierRepository(this._storage);

  static const _key = 'pricingTiers';
  final LocalJsonStorage _storage;

  @override
  Future<List<PricingTier>> getPricingTiers() async {
    final rows = await _storage.readCollection(_key);
    final tiers = rows.map(PricingTier.fromJson).toList();
    tiers.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tiers;
  }

  @override
  Future<void> savePricingTier(PricingTier tier) async {
    final tiers = await getPricingTiers();
    final existing = tiers.indexWhere((entry) => entry.id == tier.id);
    final normalized = tier.isDefault
        ? tiers.map((entry) => entry.copyWith(isDefault: false)).toList()
        : tiers;
    if (existing >= 0) {
      normalized[existing] = tier;
    } else {
      normalized.add(tier);
    }
    await _saveAll(normalized);
  }

  @override
  Future<void> updatePricingTier(PricingTier tier) => savePricingTier(tier);

  Future<void> _saveAll(List<PricingTier> tiers) {
    return _storage.writeCollection(
      _key,
      tiers.map((tier) => tier.toJson()).toList(),
    );
  }
}
