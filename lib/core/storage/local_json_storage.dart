import 'dart:convert';
import 'dart:io' if (dart.library.js_interop) 'browser_json_files.dart';

import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';
import 'app_data_bootstrapper.dart';

class LocalJsonStorage {
  LocalJsonStorage({
    this.fileName = AppConstants.storageFileName,
    Directory? baseDirectory,
  }) : _baseDirectory = baseDirectory;

  final String fileName;
  final Directory? _baseDirectory;

  static const _collectionFiles = {
    'materials': 'materials.json',
    'prices': 'prices.json',
    'materialQuantityPriceTiers': 'material_quantity_price_tiers.json',
    'packagingRules': 'packaging.json',
    'productTypeTemplates': 'product_kinds.json',
    'pricingTiers': 'settings.json',
    'formulaRules': 'settings.json',
    'units': 'settings.json',
    'categories': 'settings.json',
    'sellModes': 'settings.json',
  };

  Future<Directory> directory() async {
    final dir =
        _baseDirectory ?? await AppDataBootstrapper.defaultDataDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _file() async {
    final dir = await directory();
    return File(p.join(dir.path, fileName));
  }

  Future<File> _collectionFile(String key) async {
    final dir = await directory();
    return File(p.join(dir.path, _collectionFiles[key] ?? fileName));
  }

  Future<void> ensureSeeded(Map<String, dynamic> seedData) async {
    for (final entry in seedData.entries) {
      if (_collectionFiles.containsKey(entry.key) && entry.value is List) {
        await _ensureCollectionSeeded(entry.key, entry.value as List<dynamic>);
      }
    }

    final settingsSeed = seedData['settings'];
    if (settingsSeed is Map<String, dynamic>) {
      final current = await readSettings();
      await writeSettings({...settingsSeed, ...current});
    }
  }

  Future<Map<String, dynamic>> readAll() async {
    final result = <String, dynamic>{};
    for (final key in _collectionFiles.keys) {
      result[key] = await readCollection(key);
    }
    result['settings'] = await readSettings();
    final legacyFile = await _file();
    if (await legacyFile.exists()) {
      final text = await legacyFile.readAsString(encoding: utf8);
      if (text.trim().isNotEmpty) {
        final legacy = jsonDecode(text);
        if (legacy is Map) {
          for (final entry in legacy.entries) {
            result.putIfAbsent('${entry.key}', () => entry.value);
          }
        }
      }
    }
    return result;
  }

  Future<void> writeAll(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      if (_collectionFiles.containsKey(entry.key) && entry.value is List) {
        final collection = (entry.value as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        await writeCollection(entry.key, collection);
      }
    }
    final settings = data['settings'];
    if (settings is Map<String, dynamic>) {
      await writeSettings(settings);
    }
  }

  Future<List<Map<String, dynamic>>> readCollection(String key) async {
    final file = await _collectionFile(key);
    if (!await file.exists()) {
      return const [];
    }
    final decoded = await _readJson(file);
    final collection = decoded is List
        ? decoded
        : decoded is Map
        ? decoded[key] as List<dynamic>? ?? const []
        : const [];
    return collection
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> writeCollection(
    String key,
    List<Map<String, dynamic>> collection,
  ) async {
    final file = await _collectionFile(key);
    if (_isSettingsBacked(key)) {
      final data = await _readObject(file);
      data[key] = collection;
      await _writeJson(file, data);
      return;
    }
    await _writeJson(file, collection);
  }

  Future<Map<String, dynamic>> readSettings() async {
    final file = await _collectionFile('pricingTiers');
    final data = await _readObject(file);
    return Map<String, dynamic>.from(data['settings'] as Map? ?? const {});
  }

  Future<void> writeSettings(Map<String, dynamic> settings) async {
    final file = await _collectionFile('pricingTiers');
    final data = await _readObject(file);
    data['settings'] = settings;
    await _writeJson(file, data);
  }

  Future<void> _ensureCollectionSeeded(
    String key,
    List<dynamic> incoming,
  ) async {
    final file = await _collectionFile(key);
    if (!await file.exists()) {
      await writeCollection(
        key,
        incoming.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
      );
      return;
    }

    final existing = [...await readCollection(key)];
    final existingIds = <Object?>{
      for (final item in existing)
        if (item['id'] != null) item['id'],
    };
    final missing = incoming
        .where((item) {
          if (item is! Map || item['id'] == null) {
            return false;
          }
          return !existingIds.contains(item['id']);
        })
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      existing.addAll(missing);
    }

    var repaired = switch (key) {
      'materials' => _repairPvcMasterData(existing, incoming),
      'prices' => _repairSeededSalePrices(existing, incoming),
      'packagingRules' => _removeDeprecatedPvcPackaging(existing, incoming),
      _ => existing,
    };
    if (key == 'prices') {
      repaired = _removeRetypedPvcPrices(repaired, incoming);
    }
    repaired = _deduplicatePvcCollection(key, repaired, incoming);
    final migrated = key == 'prices' ? _migratePriceCents(repaired) : repaired;
    if (missing.isNotEmpty || !identical(migrated, existing)) {
      await writeCollection(key, migrated);
    }
  }

  static String? _remapLegacyPvcId(String id) {
    if (id.startsWith('pvc_k') && id.endsWith('_3000')) return 'pvc_k_3000';
    if (id.startsWith('pvc_k') && id.endsWith('_4000')) return 'pvc_k_4000';
    if (id.startsWith('pvc_p') && id.endsWith('_3000')) return 'pvc_p_3000';
    if (id.startsWith('pvc_p') && id.endsWith('_4000')) return 'pvc_p_4000';
    if (id == 'pvc_gd_selling_3000' ||
        (id.startsWith('pvc_gd') && id.endsWith('_3000'))) {
      return 'pvc_gd_3000';
    }
    if (id.startsWith('pvc_gd') && id.endsWith('_4000')) return 'pvc_gd_4000';
    if (id == 'pvc_db01_selling_4000' || id.startsWith('pvc_db')) {
      return 'pvc_db_4000';
    }
    if (id == 'pvc_image1_row03_160x20x3000' ||
        id == 'pvc_factory_160x22x3000') {
      return 'pvc_4flu_tbom_3000';
    }
    if (id == 'pvc_image1_row04_195x3000' || id == 'pvc_factory_195x12x3000') {
      return 'pvc_3flu_tbom_teab_3000';
    }
    if (id == 'pvc_image1_row05_150x3000' || id == 'pvc_factory_160x9x3000') {
      return 'pvc_4flu_teab_3000';
    }
    if (id == 'pvc_image2_100_piece_accessory') return 'pvc_image1_row16';
    if (id == 'pvc_image2_row21') return 'pvc_image1_row18';
    return null;
  }

  List<Map<String, dynamic>> _deduplicatePvcCollection(
    String key,
    List<Map<String, dynamic>> existing,
    List<dynamic> incoming,
  ) {
    final incomingById = <Object?, Map<String, dynamic>>{
      for (final item in incoming)
        if (item is Map && item['id'] != null)
          item['id']: Map<String, dynamic>.from(item),
    };

    if (key == 'materials') {
      final resultMap = <String, Map<String, dynamic>>{};
      for (final row in existing) {
        final id = row['id'] as String?;
        if (id == null) continue;
        final mappedId = _remapLegacyPvcId(id) ?? id;
        if (resultMap.containsKey(mappedId)) {
          final seed = incomingById[mappedId];
          if (seed != null) {
            resultMap[mappedId] = {...seed};
          }
        } else {
          final seed = incomingById[mappedId];
          if (seed != null) {
            resultMap[mappedId] = {...seed};
          } else {
            resultMap[mappedId] = {...row, 'id': mappedId};
          }
        }
      }
      return resultMap.values.toList();
    }

    if (key == 'prices') {
      final resultMap = <String, Map<String, dynamic>>{};
      for (final row in existing) {
        final materialId = row['materialId'] as String?;
        final priceTypeId = row['priceTypeId'] as String?;
        if (materialId == null || priceTypeId == null) continue;
        final mappedMaterialId = _remapLegacyPvcId(materialId) ?? materialId;
        final priceKey = '${mappedMaterialId}_$priceTypeId';
        final updatedRow = {
          ...row,
          'id': priceKey,
          'materialId': mappedMaterialId,
        };
        final existingRow = resultMap[priceKey];
        if (existingRow == null) {
          resultMap[priceKey] = updatedRow;
        } else {
          final existingPrice = (existingRow['price'] as num?)?.toDouble() ?? 0;
          final newPrice = (updatedRow['price'] as num?)?.toDouble() ?? 0;
          if (existingPrice == 0 && newPrice > 0) {
            resultMap[priceKey] = updatedRow;
          }
        }
      }
      return resultMap.values.toList();
    }

    if (key == 'materialQuantityPriceTiers') {
      final resultMap = <String, Map<String, dynamic>>{};
      for (final row in existing) {
        final materialId = row['materialId'] as String?;
        final minQty = row['minQuantity'];
        if (materialId == null || minQty == null) continue;
        final mappedMaterialId = _remapLegacyPvcId(materialId) ?? materialId;
        final tierKey = '${mappedMaterialId}_quantity_$minQty';
        final updatedRow = {
          ...row,
          'id': tierKey,
          'materialId': mappedMaterialId,
        };
        resultMap.putIfAbsent(tierKey, () => updatedRow);
      }
      return resultMap.values.toList();
    }

    if (key == 'packagingRules') {
      final resultMap = <String, Map<String, dynamic>>{};
      for (final row in existing) {
        final materialId = row['materialId'] as String?;
        if (materialId == null) continue;
        final mappedMaterialId = _remapLegacyPvcId(materialId) ?? materialId;
        final pkgKey = 'packaging_$mappedMaterialId';
        final updatedRow = {
          ...row,
          'id': pkgKey,
          'materialId': mappedMaterialId,
        };
        resultMap.putIfAbsent(pkgKey, () => updatedRow);
      }
      return resultMap.values.toList();
    }

    return existing;
  }

  List<Map<String, dynamic>> _repairPvcMasterData(
    List<Map<String, dynamic>> existing,
    List<dynamic> incoming,
  ) {
    final seedById = <Object?, Map<String, dynamic>>{
      for (final item in incoming)
        if (item is Map && item['id'] != null)
          item['id']: Map<String, dynamic>.from(item),
    };
    const authoritativeFields = {
      'khmerName',
      'englishName',
      'spec',
      'code',
      'productFamilyId',
      'widthMm',
      'thicknessMm',
      'lengthMm',
      'piecesPerBundle',
      'itemsPerBox',
      'unitId',
      'unitKhmer',
      'unitEnglish',
      'notes',
    };
    var changed = false;
    final repaired = [
      for (final row in existing)
        () {
          final seed = seedById[row['id']];
          if (seed == null || seed['categoryId'] != 'pvc') return row;
          final untouched = row['createdAt'] == row['updatedAt'];
          if (!untouched && !_containsDeprecatedPvcName(row)) return row;
          final replacement = {...row};
          var rowChanged = false;
          for (final field in authoritativeFields) {
            if (replacement[field] != seed[field]) {
              replacement[field] = seed[field];
              rowChanged = true;
            }
          }
          if (!rowChanged) return row;
          changed = true;
          return replacement;
        }(),
    ];
    return changed ? repaired : existing;
  }

  bool _containsDeprecatedPvcName(Map<String, dynamic> row) {
    final text = [
      row['khmerName'],
      row['englishName'],
      row['code'],
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('row-') ||
        text.contains('row ') ||
        text.contains('factory-') ||
        text.contains('factory-list') ||
        text.contains('selling-list') ||
        text.contains('accessory') ||
        text.contains('door trim') ||
        text.contains('wall base') ||
        text.contains('top trim') ||
        text.contains('corner trim') ||
        text.contains('pvc panel') ||
        text.contains('pvc glue') ||
        text.contains('pvc v');
  }

  List<Map<String, dynamic>> _removeDeprecatedPvcPackaging(
    List<Map<String, dynamic>> existing,
    List<dynamic> incoming,
  ) {
    final incomingIds = {
      for (final item in incoming)
        if (item is Map && item['id'] != null) item['id'],
    };
    const deprecatedIds = {
      'packaging_pvc_image1_row13',
      'packaging_pvc_image1_row14',
    };
    final repaired = existing
        .where(
          (row) =>
              !deprecatedIds.contains(row['id']) ||
              incomingIds.contains(row['id']),
        )
        .toList(growable: false);
    return repaired.length == existing.length ? existing : repaired;
  }

  List<Map<String, dynamic>> _removeRetypedPvcPrices(
    List<Map<String, dynamic>> existing,
    List<dynamic> incoming,
  ) {
    const retypedMaterialIds = {
      'pvc_image1_row13',
      'pvc_image1_row14',
      'pvc_image1_row16',
      'pvc_image1_row17',
      'pvc_image1_row18',
      'pvc_image2_row21',
    };
    final incomingTypes = <String, Set<String>>{};
    for (final item in incoming) {
      if (item is! Map) continue;
      final materialId = item['materialId'];
      final priceTypeId = item['priceTypeId'];
      if (materialId is String && priceTypeId is String) {
        incomingTypes
            .putIfAbsent(materialId, () => <String>{})
            .add(priceTypeId);
      }
    }
    final repaired = existing
        .where((row) {
          final materialId = row['materialId'];
          final priceTypeId = row['priceTypeId'];
          if (materialId is! String ||
              priceTypeId is! String ||
              !retypedMaterialIds.contains(materialId)) {
            return true;
          }
          final expected = incomingTypes[materialId] ?? const <String>{};
          if (expected.contains(priceTypeId)) return true;
          final isSale =
              priceTypeId == 'sale_unit_price' ||
              priceTypeId == 'sale_box_price';
          final isCost =
              priceTypeId == 'cost_unit_price' ||
              priceTypeId == 'cost_box_price';
          final hasReplacement = expected.any(
            (type) =>
                (isSale &&
                    (type == 'sale_unit_price' || type == 'sale_box_price')) ||
                (isCost &&
                    (type == 'cost_unit_price' || type == 'cost_box_price')),
          );
          return !hasReplacement;
        })
        .toList(growable: false);
    return repaired.length == existing.length ? existing : repaired;
  }

  List<Map<String, dynamic>> _repairSeededSalePrices(
    List<Map<String, dynamic>> existing,
    List<dynamic> incoming,
  ) {
    final seedById = <Object?, Map<String, dynamic>>{
      for (final item in incoming)
        if (item is Map && item['id'] != null)
          item['id']: Map<String, dynamic>.from(item),
    };
    var changed = false;
    final nowText = DateTime.now().toIso8601String();
    final repaired = [
      for (final row in existing)
        () {
          final typeId = row['priceTypeId'];
          final isSalePrice =
              typeId == 'sale_unit_price' || typeId == 'sale_box_price';
          final price = (row['price'] as num?)?.toDouble();
          final seedPrice = (seedById[row['id']]?['price'] as num?)?.toDouble();
          if (isSalePrice && price == 0 && seedPrice != null && seedPrice > 0) {
            changed = true;
            final seedPriceCents =
                (seedById[row['id']]?['priceCents'] as num?)?.toInt() ??
                (seedPrice * 100).round();
            return {
              ...row,
              'price': seedPrice,
              'priceCents': seedPriceCents,
              'updatedAt': nowText,
            };
          }
          return row;
        }(),
    ];
    return changed ? repaired : existing;
  }

  List<Map<String, dynamic>> _migratePriceCents(
    List<Map<String, dynamic>> existing,
  ) {
    var changed = false;
    final migrated = [
      for (final row in existing)
        if (row['priceCents'] == null && row['price'] is num)
          () {
            changed = true;
            return {
              ...row,
              'priceCents': ((row['price'] as num).toDouble() * 100).round(),
            };
          }()
        else
          row,
    ];
    return changed ? migrated : existing;
  }

  bool _isSettingsBacked(String key) {
    return _collectionFiles[key] == 'settings.json';
  }

  Future<Map<String, dynamic>> _readObject(File file) async {
    if (!await file.exists()) {
      return {};
    }
    final decoded = await _readJson(file);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  Future<dynamic> _readJson(File file) async {
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) {
      return null;
    }
    return jsonDecode(text);
  }

  Future<void> _writeJson(File file, Object? value) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      encoding: utf8,
    );
  }
}
