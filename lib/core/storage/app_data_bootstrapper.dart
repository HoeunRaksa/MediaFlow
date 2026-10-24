import 'dart:convert';
import 'dart:io' if (dart.library.js_interop) 'browser_json_files.dart';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

typedef SeedAssetLoader = Future<String> Function(String assetPath);

class AppDataBootstrapper {
  AppDataBootstrapper({
    Directory? dataDirectory,
    SeedAssetLoader? assetLoader,
    this.seedAssetPaths = AppConstants.seedAssetPaths,
    this.legacyFileName = AppConstants.storageFileName,
  }) : _dataDirectory = dataDirectory,
       _assetLoader = assetLoader ?? rootBundle.loadString;

  final Directory? _dataDirectory;
  final SeedAssetLoader _assetLoader;
  final Map<String, String> seedAssetPaths;
  final String legacyFileName;

  Future<void> ensureSeedDataInstalled() async {
    final directory = await dataDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final legacyData = await _legacyData(directory);
    for (final entry in seedAssetPaths.entries) {
      final target = File(p.join(directory.path, entry.key));
      if (await target.exists()) {
        continue;
      }
      final legacyJson = _legacyJsonForFile(entry.key, legacyData);
      if (legacyJson != null) {
        await _writeJson(target, legacyJson);
        continue;
      }
      final assetText = await _assetLoader(entry.value);
      await target.writeAsString(assetText, encoding: utf8);
    }
  }

  Future<Directory> dataDirectory() async {
    if (_dataDirectory != null) {
      return _dataDirectory;
    }
    if (kIsWeb) return Directory('/MaterialQuotePro');
    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null && appData.trim().isNotEmpty) {
      return Directory(p.join(appData, AppConstants.dataFolderName));
    }
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, AppConstants.dataFolderName));
  }

  static Future<Directory> defaultDataDirectory() {
    return AppDataBootstrapper().dataDirectory();
  }

  Future<Map<String, dynamic>?> _legacyData(Directory directory) async {
    final legacyFile = File(p.join(directory.path, legacyFileName));
    if (!await legacyFile.exists()) {
      return null;
    }
    final text = await legacyFile.readAsString(encoding: utf8);
    if (text.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  }

  Object? _legacyJsonForFile(
    String fileName,
    Map<String, dynamic>? legacyData,
  ) {
    if (legacyData == null) {
      return null;
    }
    return switch (fileName) {
      'materials.json' => legacyData['materials'],
      'prices.json' => legacyData['prices'],
      'material_quantity_price_tiers.json' =>
        legacyData['materialQuantityPriceTiers'],
      'packaging.json' => legacyData['packagingRules'],
      'product_kinds.json' => legacyData['productTypeTemplates'],
      'settings.json' => {
        'settings': legacyData['settings'] ?? <String, dynamic>{},
        'pricingTiers': legacyData['pricingTiers'] ?? const [],
        'formulaRules': legacyData['formulaRules'] ?? const [],
        'units': legacyData['units'] ?? const [],
        'categories': legacyData['categories'] ?? const [],
        'sellModes': legacyData['sellModes'] ?? const [],
      },
      _ => null,
    };
  }

  Future<void> _writeJson(File file, Object? value) {
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      encoding: utf8,
    );
  }
}
