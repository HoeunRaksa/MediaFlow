import '../../../../core/storage/local_json_storage.dart';
import '../models/material_item.dart';

abstract class MaterialRepository {
  Future<List<MaterialItem>> getMaterials();
  Future<void> saveMaterial(MaterialItem item);
  Future<void> updateMaterial(MaterialItem item);
  Future<void> deleteOrDeactivateMaterial(String id);
}

class LocalMaterialRepository implements MaterialRepository {
  LocalMaterialRepository(this._storage);

  static const _key = 'materials';
  final LocalJsonStorage _storage;

  @override
  Future<List<MaterialItem>> getMaterials() async {
    final rows = await _storage.readCollection(_key);
    final items = rows.map(MaterialItem.fromJson).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  @override
  Future<void> saveMaterial(MaterialItem item) async {
    final items = await getMaterials();
    final existing = items.indexWhere((entry) => entry.id == item.id);
    if (existing >= 0) {
      items[existing] = item;
    } else {
      items.add(item);
    }
    await _saveAll(items);
  }

  @override
  Future<void> updateMaterial(MaterialItem item) => saveMaterial(item);

  @override
  Future<void> deleteOrDeactivateMaterial(String id) async {
    final items = await getMaterials();
    final now = DateTime.now();
    final next = items
        .map(
          (item) => item.id == id
              ? item.copyWith(active: false, updatedAt: now)
              : item,
        )
        .toList();
    await _saveAll(next);
  }

  Future<void> _saveAll(List<MaterialItem> items) {
    return _storage.writeCollection(
      _key,
      items.map((item) => item.toJson()).toList(),
    );
  }
}
