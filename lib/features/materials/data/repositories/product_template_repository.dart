import '../../../../core/storage/local_json_storage.dart';
import '../models/product_type_template.dart';

abstract class ProductTemplateRepository {
  Future<List<ProductTypeTemplate>> getProductTemplates();
  Future<void> saveProductTemplate(ProductTypeTemplate template);
}

class LocalProductTemplateRepository implements ProductTemplateRepository {
  LocalProductTemplateRepository(this._storage);

  static const _key = 'productTypeTemplates';
  final LocalJsonStorage _storage;

  @override
  Future<List<ProductTypeTemplate>> getProductTemplates() async {
    final rows = await _storage.readCollection(_key);
    final templates = rows.map(ProductTypeTemplate.fromJson).toList();
    templates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return templates;
  }

  @override
  Future<void> saveProductTemplate(ProductTypeTemplate template) async {
    final templates = await getProductTemplates();
    final existing = templates.indexWhere((entry) => entry.id == template.id);
    final normalized = template.isDefault
        ? templates.map((entry) => entry.copyWith(isDefault: false)).toList()
        : templates;
    if (existing >= 0) {
      normalized[existing] = template;
    } else {
      normalized.add(template);
    }
    await _storage.writeCollection(
      _key,
      normalized.map((item) => item.toJson()).toList(),
    );
  }
}
