import '../../../../core/storage/local_json_storage.dart';
import '../models/formula_rule.dart';

abstract class FormulaRuleRepository {
  Future<List<FormulaRule>> getFormulaRules();
}

class LocalFormulaRuleRepository implements FormulaRuleRepository {
  LocalFormulaRuleRepository(this._storage);

  static const _key = 'formulaRules';
  final LocalJsonStorage _storage;

  @override
  Future<List<FormulaRule>> getFormulaRules() async {
    final rows = await _storage.readCollection(_key);
    final rules = rows.map(FormulaRule.fromJson).toList();
    rules.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rules;
  }
}
