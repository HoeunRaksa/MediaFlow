import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/core/storage/local_json_storage.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/materials/data/seed/pvc_catalog_seed.dart';
import 'package:material_quote_pro/features/materials/domain/material_quantity_pricing.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8);

  MaterialPrice price(String materialId, String priceTypeId) {
    return DefaultMaterialSeed.prices(now).singleWhere(
      (entry) =>
          entry.materialId == materialId && entry.priceTypeId == priceTypeId,
    );
  }

  group('PVC catalog seed & deduplication', () {
    test(
      'defines exactly one canonical calculation product per physical variant',
      () {
        final materials = DefaultMaterialSeed.materials(now);

        final k3m = materials
            .where((item) => item.khmerName == 'K 3m')
            .toList();
        final k4m = materials
            .where((item) => item.khmerName == 'K 4m')
            .toList();
        final p3m = materials
            .where((item) => item.khmerName == 'P 3m')
            .toList();
        final p4m = materials
            .where((item) => item.khmerName == 'P 4m')
            .toList();
        final gd3m = materials
            .where((item) => item.khmerName == 'GD 3m')
            .toList();
        final gd4m = materials
            .where((item) => item.khmerName == 'GD 4m')
            .toList();
        final db4m = materials
            .where((item) => item.khmerName == 'DB 4m')
            .toList();

        expect(k3m, hasLength(1));
        expect(k4m, hasLength(1));
        expect(p3m, hasLength(1));
        expect(p4m, hasLength(1));
        expect(gd3m, hasLength(1));
        expect(gd4m, hasLength(1));
        expect(db4m, hasLength(1));

        // Design codes check
        expect(
          k3m.first.designCodes,
          containsAll(['K-01', 'K-02', 'K-05', 'K-12']),
        );
        expect(p3m.first.designCodes, containsAll(['P-01', 'P-02', 'P-03']));
        expect(
          gd3m.first.designCodes,
          containsAll(['GD14', 'GD105', 'GD147', 'GD309']),
        );
        expect(db4m.first.designCodes, containsAll(['DB01', 'DB02', 'DB05']));
      },
    );

    test('contains all requested selling and base factory prices', () {
      expect(
        price(PvcMaterialIds.k3000, PriceTypeIds.saleUnitPrice).price,
        6.70,
      );
      expect(
        price(PvcMaterialIds.k4000, PriceTypeIds.saleUnitPrice).price,
        8.60,
      );
      expect(
        price(PvcMaterialIds.p3000, PriceTypeIds.saleUnitPrice).price,
        6.90,
      );
      expect(
        price(PvcMaterialIds.p4000, PriceTypeIds.saleUnitPrice).price,
        8.85,
      );
      expect(
        price(PvcMaterialIds.k3000, PriceTypeIds.costUnitPrice).price,
        5.80,
      );
      expect(
        price(PvcMaterialIds.gd3000, PriceTypeIds.saleUnitPrice).price,
        22.00,
      );
      expect(
        price(PvcMaterialIds.gd3000, PriceTypeIds.costUnitPrice).price,
        18.00,
      );
      expect(
        price(PvcMaterialIds.gd4000, PriceTypeIds.costUnitPrice).price,
        23.50,
      );

      final cLine023Sale = price(
        PvcMaterialIds.cLine023_4000,
        PriceTypeIds.saleBoxPrice,
      );
      final cLine023Cost = price(
        PvcMaterialIds.cLine023_4000,
        PriceTypeIds.costBoxPrice,
      );
      final cLine027Sale = price(
        PvcMaterialIds.cLine027_4000,
        PriceTypeIds.saleBoxPrice,
      );
      final cLine027Cost = price(
        PvcMaterialIds.cLine027_4000,
        PriceTypeIds.costBoxPrice,
      );
      expect(cLine023Sale.priceCents, 1624);
      expect(cLine023Cost.priceCents, 850);
      expect(cLine027Sale.priceCents, 1719);
      expect(cLine027Cost.priceCents, 950);
    });

    test('quantity tier lookup uses the highest eligible breakpoint', () {
      final tiers = DefaultMaterialSeed.quantityPriceTiers(now);

      final quantity100 = MaterialQuantityPricing.resolve(
        materialId: PvcMaterialIds.k3000,
        quantity: 100,
        tiers: tiers,
      );
      final quantity500 = MaterialQuantityPricing.resolve(
        materialId: PvcMaterialIds.k3000,
        quantity: 500,
        tiers: tiers,
      );

      expect(quantity100?.unitPriceCents, 530);
      expect(quantity500?.unitPriceCents, 500);
    });

    test('resolves design codes like GD147 to GD family products', () {
      final materials = DefaultMaterialSeed.materials(now);
      final query = 'GD147'.toLowerCase();

      final matches = materials.where((item) {
        final codeLower = (item.code ?? '').toLowerCase();
        final nameLower = item.khmerName.toLowerCase();
        final designMatch = item.designCodes.any(
          (c) => c.toLowerCase().contains(query),
        );
        return codeLower.contains(query) ||
            nameLower.contains(query) ||
            designMatch;
      }).toList();

      final names = matches.map((m) => m.khmerName).toSet();
      expect(names, containsAll(['GD 3m', 'GD 4m']));
    });

    test('uses authoritative factory package sizes for clips and screws', () {
      final materials = DefaultMaterialSeed.materials(now);
      final clip = materials.singleWhere(
        (item) => item.id == 'pvc_image1_row16',
      );
      final ceilingScrew = materials.singleWhere(
        (item) => item.id == 'pvc_image1_row17',
      );
      final floorScrew = materials.singleWhere(
        (item) => item.id == 'pvc_image1_row18',
      );

      expect(clip.spec, '100គ្រាប់/កញ្ចប់');
      expect(clip.piecesPerBundle, 100);
      expect(ceilingScrew.spec, '1000គ្រាប់/កញ្ចប់');
      expect(ceilingScrew.piecesPerBundle, 1000);
      expect(floorScrew.piecesPerBundle, 1000);
      expect(price('pvc_image1_row16', PriceTypeIds.saleBoxPrice).price, 4);
    });

    test(
      'seeding twice does not duplicate products, prices, or tiers',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'mqp_pvc_seed_',
        );
        addTearDown(() async {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        });
        final storage = LocalJsonStorage(baseDirectory: directory);
        final seed = DefaultMaterialSeed.json(now);

        await storage.ensureSeeded(seed);
        await storage.ensureSeeded(seed);

        for (final key in const [
          'materials',
          'prices',
          'materialQuantityPriceTiers',
        ]) {
          final rows = await storage.readCollection(key);
          final ids = rows.map((row) => row['id']).toList();
          expect(ids.toSet(), hasLength(ids.length), reason: key);
          expect(rows, hasLength((seed[key] as List).length), reason: key);
        }
      },
    );

    test(
      'legacy duplicate PVC records migrate to canonical master data idempotently',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'mqp_pvc_dedup_',
        );
        addTearDown(() async {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        });
        final storage = LocalJsonStorage(baseDirectory: directory);

        // Simulate legacy database with duplicate K and GD entries
        final legacyMaterials = [
          MaterialItem(
            id: 'pvc_k01_3000',
            khmerName: 'K 3m',
            englishName: 'K 3m',
            spec: '400 × 10 × 3000 mm',
            unitId: 'piece',
            unitKhmer: 'ដើម',
            unitEnglish: 'Piece',
            categoryId: 'pvc',
            categoryKhmer: 'PVC',
            categoryEnglish: 'PVC',
            formulaTypeId: 'manual_quantity',
            coverageValue: null,
            multiplierValue: null,
            fixedQuantity: null,
            itemsPerBox: 1,
            active: true,
            includedByDefault: false,
            showInCustomerQuote: true,
            showInPickList: true,
            isOptionalAddon: true,
            isServiceOnly: false,
            sortOrder: 100,
            createdAt: now,
            updatedAt: now,
          ).toJson(),
          MaterialItem(
            id: 'pvc_gd14_3000',
            khmerName: 'GD 3m',
            englishName: 'GD 3m',
            spec: '23 × 400 × 3000 mm',
            unitId: 'piece',
            unitKhmer: 'ដើម',
            unitEnglish: 'Piece',
            categoryId: 'pvc',
            categoryKhmer: 'PVC',
            categoryEnglish: 'PVC',
            formulaTypeId: 'manual_quantity',
            coverageValue: null,
            multiplierValue: null,
            fixedQuantity: null,
            itemsPerBox: 1,
            active: true,
            includedByDefault: false,
            showInCustomerQuote: true,
            showInPickList: true,
            isOptionalAddon: true,
            isServiceOnly: false,
            sortOrder: 101,
            createdAt: now,
            updatedAt: now,
          ).toJson(),
        ];
        await storage.writeCollection('materials', legacyMaterials);

        final seed = DefaultMaterialSeed.json(now);
        await storage.ensureSeeded(seed);
        await storage.ensureSeeded(seed);

        final materials = await storage.readCollection('materials');
        final k3mRows = materials
            .where((m) => m['khmerName'] == 'K 3m')
            .toList();
        final gd3mRows = materials
            .where((m) => m['khmerName'] == 'GD 3m')
            .toList();

        expect(k3mRows, hasLength(1));
        expect(gd3mRows, hasLength(1));
        expect(k3mRows.first['id'], PvcMaterialIds.k3000);
        expect(gd3mRows.first['id'], PvcMaterialIds.gd3000);
      },
    );

    test('legacy decimal prices migrate to canonical cents', () async {
      final legacy = MaterialPrice.fromJson({
        'id': 'legacy',
        'materialId': 'legacy',
        'priceTypeId': PriceTypeIds.saleUnitPrice,
        'price': 16.24,
        'currencyCode': 'USD',
        'effectiveFrom': DateTime.utc(2020).toIso8601String(),
        'effectiveTo': null,
        'active': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(legacy.priceCents, 1624);
      expect(legacy.toJson()['priceCents'], 1624);
    });
  });
}
