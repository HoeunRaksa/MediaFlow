import '../../../../core/storage/local_json_storage.dart';
import '../models/packaging_rule.dart';

abstract class PackagingRepository {
  Future<List<PackagingRule>> getPackagingRules();
  Future<void> savePackagingRule(PackagingRule rule);
}

class LocalPackagingRepository implements PackagingRepository {
  LocalPackagingRepository(this._storage);

  static const _key = 'packagingRules';
  final LocalJsonStorage _storage;

  @override
  Future<List<PackagingRule>> getPackagingRules() async {
    final rows = await _storage.readCollection(_key);
    return rows.map(PackagingRule.fromJson).toList(growable: false);
  }

  @override
  Future<void> savePackagingRule(PackagingRule rule) async {
    final rules = await getPackagingRules();
    final existing = rules.indexWhere((entry) => entry.id == rule.id);
    if (existing >= 0) {
      rules[existing] = rule;
    } else {
      rules.add(rule);
    }
    await _storage.writeCollection(
      _key,
      rules.map((item) => item.toJson()).toList(),
    );
  }
}
