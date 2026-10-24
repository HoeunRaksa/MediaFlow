import '../../../../core/storage/local_json_storage.dart';
import '../models/sell_mode.dart';

abstract class SellModeRepository {
  Future<List<SellMode>> getSellModes();
}

class LocalSellModeRepository implements SellModeRepository {
  LocalSellModeRepository(this._storage);

  static const _key = 'sellModes';
  final LocalJsonStorage _storage;

  @override
  Future<List<SellMode>> getSellModes() async {
    final rows = await _storage.readCollection(_key);
    return rows.map(SellMode.fromJson).toList(growable: false);
  }
}
