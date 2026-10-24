import '../../../../core/storage/local_json_storage.dart';
import '../models/material_price.dart';

abstract class MaterialPriceRepository {
  Future<List<MaterialPrice>> getPrices();
  Future<void> savePrice(MaterialPrice price);
  Future<void> updatePrice(MaterialPrice price);
  Future<void> deactivatePrice(String priceId);
}

class LocalMaterialPriceRepository implements MaterialPriceRepository {
  LocalMaterialPriceRepository(this._storage);

  static const _key = 'prices';
  final LocalJsonStorage _storage;

  @override
  Future<List<MaterialPrice>> getPrices() async {
    final rows = await _storage.readCollection(_key);
    return rows.map(MaterialPrice.fromJson).toList(growable: false);
  }

  @override
  Future<void> savePrice(MaterialPrice price) async {
    final prices = await getPrices();
    final existing = prices.indexWhere((entry) => entry.id == price.id);
    if (existing >= 0) {
      prices[existing] = price;
    } else {
      prices.add(price);
    }
    await _saveAll(prices);
  }

  @override
  Future<void> updatePrice(MaterialPrice price) => savePrice(price);

  @override
  Future<void> deactivatePrice(String priceId) async {
    final prices = await getPrices();
    final now = DateTime.now();
    await _saveAll(
      prices
          .map(
            (price) => price.id == priceId
                ? price.copyWith(
                    active: false,
                    effectiveTo: now,
                    updatedAt: now,
                  )
                : price,
          )
          .toList(),
    );
  }

  Future<void> _saveAll(List<MaterialPrice> prices) {
    return _storage.writeCollection(
      _key,
      prices.map((price) => price.toJson()).toList(),
    );
  }
}
