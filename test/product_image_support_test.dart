import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/services/product_image_service.dart';
import 'package:material_quote_pro/core/widgets/product_image_thumbnail.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_engine.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('product_image_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Product Image Domain & Serialization', () {
    test('MaterialItem deserializes correctly when imagePath is null', () {
      final json = {
        'id': 'test_1',
        'khmerName': 'ពិដាន',
        'englishName': 'Ceiling',
        'spec': '6mm',
        'unitId': 'sheet',
        'unitKhmer': 'សន្លឹក',
        'unitEnglish': 'sheet',
        'categoryId': 'ceiling',
        'categoryKhmer': 'ពិដាន',
        'categoryEnglish': 'Ceiling',
        'formulaTypeId': 'area_divided_by_coverage',
        'coverageValue': 0.36,
        'active': true,
        'includedByDefault': false,
        'showInCustomerQuote': true,
        'showInPickList': true,
        'isOptionalAddon': false,
        'isServiceOnly': false,
        'sortOrder': 1,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };

      final item = MaterialItem.fromJson(json);
      expect(item.imagePath, isNull);
      expect(item.toJson()['imagePath'], isNull);
    });

    test(
      'MaterialItem deserializes and serializes imagePath when provided',
      () {
        final json = {
          'id': 'test_2',
          'khmerName': 'ពិដាន',
          'englishName': 'Ceiling',
          'spec': '6mm',
          'unitId': 'sheet',
          'unitKhmer': 'សន្លឹក',
          'unitEnglish': 'sheet',
          'categoryId': 'ceiling',
          'categoryKhmer': 'ពិដាន',
          'categoryEnglish': 'Ceiling',
          'formulaTypeId': 'area_divided_by_coverage',
          'coverageValue': 0.36,
          'active': true,
          'includedByDefault': false,
          'showInCustomerQuote': true,
          'showInPickList': true,
          'isOptionalAddon': false,
          'isServiceOnly': false,
          'sortOrder': 1,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
          'imagePath': '/managed/test_2_123.png',
        };

        final item = MaterialItem.fromJson(json);
        expect(item.imagePath, '/managed/test_2_123.png');
        expect(item.toJson()['imagePath'], '/managed/test_2_123.png');

        final updated = item.copyWith(clearImagePath: true);
        expect(updated.imagePath, isNull);
      },
    );
  });

  group('Product Image Storage & File Management', () {
    test(
      'importImage copies file to managed dir with valid extension',
      () async {
        final sampleSource = File('${tempDir.path}/sample.png');
        await sampleSource.writeAsBytes([0x89, 0x50, 0x4E, 0x47]); // PNG header

        final importedPath = await ProductImageService.importImage(
          sampleSource.path,
          productId: 'prod_1',
          baseDataDir: tempDir,
        );

        expect(importedPath, isNotNull);
        expect(File(importedPath!).existsSync(), isTrue);
        expect(importedPath.contains('prod_1_'), isTrue);
      },
    );

    test('invalid non-image file is rejected by importImage', () async {
      final invalidFile = File('${tempDir.path}/sample.txt');
      await invalidFile.writeAsString('hello text');

      final result = await ProductImageService.importImage(
        invalidFile.path,
        productId: 'prod_1',
        baseDataDir: tempDir,
      );

      expect(result, isNull);
    });

    test(
      'replaceImage removes old managed file and imports new image',
      () async {
        final source1 = File('${tempDir.path}/img1.png');
        await source1.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

        final path1 = await ProductImageService.importImage(
          source1.path,
          productId: 'prod_2',
          baseDataDir: tempDir,
        );
        expect(File(path1!).existsSync(), isTrue);

        final source2 = File('${tempDir.path}/img2.jpg');
        await source2.writeAsBytes([0xFF, 0xD8, 0xFF]);

        final path2 = await ProductImageService.replaceImage(
          oldImagePath: path1,
          newSourceFilePath: source2.path,
          productId: 'prod_2',
          baseDataDir: tempDir,
        );

        expect(path2, isNotNull);
        expect(File(path2!).existsSync(), isTrue);
        expect(File(path1).existsSync(), isFalse); // Old file cleaned up
      },
    );

    test(
      'deleteManagedImage removes file without throwing if missing',
      () async {
        final file = File('${tempDir.path}/delete_me.png');
        await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);

        await ProductImageService.deleteManagedImage(file.path);
        expect(file.existsSync(), isFalse);

        // Should not throw on non-existent file
        await ProductImageService.deleteManagedImage(file.path);
      },
    );
  });

  group('Product Image Presentation & Calculation Neutrality', () {
    testWidgets(
      'missing or corrupt image renders placeholder without crashing',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProductImageThumbnail(
                imagePath: '/non_existent_path/fake.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      },
    );

    test('Adding image to product does not alter calculation output', () {
      final now = DateTime.now();
      final baseItem = MaterialItem(
        id: 'ceiling_6mm',
        khmerName: 'ពិដាន 6លី',
        englishName: 'Ceiling 6mm',
        spec: '6mm',
        unitId: 'sheet',
        unitKhmer: 'សន្លឹក',
        unitEnglish: 'sheet',
        categoryId: 'ceiling',
        categoryKhmer: 'ពិដាន',
        categoryEnglish: 'Ceiling',
        formulaTypeId: 'area_divided_by_coverage',
        coverageValue: 0.36,
        multiplierValue: null,
        fixedQuantity: null,
        itemsPerBox: 1,
        active: true,
        includedByDefault: true,
        showInCustomerQuote: true,
        showInPickList: true,
        isOptionalAddon: false,
        isServiceOnly: false,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
        imagePath: null,
      );

      final itemWithImage = baseItem.copyWith(
        imagePath: '/managed/product_images/ceiling_6mm_123.png',
      );

      const engine = ProductSaleEngine();
      final result1 = engine.calculate(
        input: const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.areaM2,
          areaM2: 25.2,
          buyModeId: InputMethodIds.areaM2,
        ),
        productKinds: const [],
        materials: [baseItem],
        prices: const [],
        packagingRules: const [],
      );

      final result2 = engine.calculate(
        input: const ProductSaleInput(
          productKindId: 'ceiling_full_set',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.areaM2,
          areaM2: 25.2,
          buyModeId: InputMethodIds.areaM2,
        ),
        productKinds: const [],
        materials: [itemWithImage],
        prices: const [],
        packagingRules: const [],
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1.sellQuantity, equals(result2.sellQuantity));
      expect(result1.sellQuantity, equals(70));
    });
  });
}
