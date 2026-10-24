@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/storage/local_json_storage.dart';
import 'dart:io'
    if (dart.library.js_interop) 'package:material_quote_pro/core/storage/browser_json_files.dart';
import 'package:web/web.dart' as web;

void main() {
  test('browser JSON storage persists collections and keeps settings together', () async {
    final path = '/storage-test-${DateTime.now().microsecondsSinceEpoch}';
    final storage = LocalJsonStorage(baseDirectory: Directory(path));
    addTearDown(() {
      for (final file in ['prices.json', 'settings.json']) {
        web.window.localStorage.removeItem('material_quote_pro:$path/$file');
      }
    });
    await storage.writeCollection('prices', [{'id': 'test-price', 'price': 8.5}]);
    await storage.writeSettings({'currency': 'USD'});
    await storage.writeCollection('units', [{'id': 'm2'}]);
    final reloaded = LocalJsonStorage(baseDirectory: Directory(path));
    expect((await reloaded.readCollection('prices')).single['price'], 8.5);
    expect(await reloaded.readSettings(), {'currency': 'USD'});
    expect((await reloaded.readCollection('units')).single['id'], 'm2');
  });
}
