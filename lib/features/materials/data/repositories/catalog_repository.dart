import '../../../../core/storage/local_json_storage.dart';
import '../models/material_category.dart';
import '../models/unit_of_measure.dart';

abstract class CatalogRepository {
  Future<List<MaterialCategory>> getCategories();
  Future<void> saveCategory(MaterialCategory category);
  Future<List<UnitOfMeasure>> getUnits();
  Future<void> saveUnit(UnitOfMeasure unit);
}

class LocalCatalogRepository implements CatalogRepository {
  LocalCatalogRepository(this._storage);

  static const _categoriesKey = 'categories';
  static const _unitsKey = 'units';
  final LocalJsonStorage _storage;

  @override
  Future<List<MaterialCategory>> getCategories() async {
    final rows = await _storage.readCollection(_categoriesKey);
    final categories = rows.map(MaterialCategory.fromJson).toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  @override
  Future<void> saveCategory(MaterialCategory category) async {
    final categories = await getCategories();
    final existing = categories.indexWhere((entry) => entry.id == category.id);
    if (existing >= 0) {
      categories[existing] = category;
    } else {
      categories.add(category);
    }
    await _storage.writeCollection(
      _categoriesKey,
      categories.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<List<UnitOfMeasure>> getUnits() async {
    final rows = await _storage.readCollection(_unitsKey);
    final units = rows.map(UnitOfMeasure.fromJson).toList();
    units.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return units;
  }

  @override
  Future<void> saveUnit(UnitOfMeasure unit) async {
    final units = await getUnits();
    final existing = units.indexWhere((entry) => entry.id == unit.id);
    if (existing >= 0) {
      units[existing] = unit;
    } else {
      units.add(unit);
    }
    await _storage.writeCollection(
      _unitsKey,
      units.map((item) => item.toJson()).toList(),
    );
  }
}
