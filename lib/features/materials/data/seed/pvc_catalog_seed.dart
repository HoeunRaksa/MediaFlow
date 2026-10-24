import '../../../../core/constants/business_ids.dart';
import '../models/material_item.dart';
import '../models/material_price.dart';
import '../models/material_quantity_price_tier.dart';
import '../models/packaging_rule.dart';

class PvcMaterialIds {
  const PvcMaterialIds._();

  static const k3000 = 'pvc_k_3000';
  static const k4000 = 'pvc_k_4000';
  static const p3000 = 'pvc_p_3000';
  static const p4000 = 'pvc_p_4000';
  static const gd3000 = 'pvc_gd_3000';
  static const gd4000 = 'pvc_gd_4000';
  static const db4000 = 'pvc_db_4000';
  static const cLine023_4000 = 'pvc_c_line_023_4000';
  static const cLine027_4000 = 'pvc_c_line_027_4000';

  // Legacy aliases
  static const k01_3000 = k3000;
  static const k01_4000 = k4000;
  static const p01_3000 = p3000;
  static const p01_4000 = p4000;
}

class PvcCatalogSeed {
  const PvcCatalogSeed._();

  static final DateTime factorySourceDate = DateTime.utc(2026, 5, 16);
  static final DateTime sellingSourceDate = DateTime.utc(2026, 8, 8);

  static List<MaterialItem> materials(DateTime now) {
    final products = _products();
    return [
      for (var index = 0; index < products.length; index++)
        MaterialItem(
          id: products[index].id,
          khmerName: products[index].name,
          englishName: products[index].name,
          spec: products[index].spec,
          unitId: 'piece',
          unitKhmer: 'ដើម',
          unitEnglish: 'Piece',
          categoryId: 'pvc',
          categoryKhmer: 'PVC',
          categoryEnglish: 'PVC',
          formulaTypeId: FormulaTypeIds.manualQuantity,
          coverageValue: null,
          multiplierValue: null,
          fixedQuantity: null,
          itemsPerBox: products[index].piecesPerBundle ?? 1,
          active: true,
          includedByDefault: false,
          showInCustomerQuote: products[index].sellingPriceCents != null,
          showInPickList: true,
          isOptionalAddon: true,
          isServiceOnly: false,
          sortOrder: 1000 + index,
          createdAt: now,
          updatedAt: now,
          code: products[index].code,
          productFamilyId: products[index].productFamilyId,
          widthMm: products[index].widthMm,
          thicknessMm: products[index].thicknessMm,
          lengthMm: products[index].lengthMm,
          piecesPerBundle: products[index].piecesPerBundle,
          notes: products[index].notes,
          designCodes: products[index].designCodes,
        ),
    ];
  }

  static List<MaterialPrice> prices(DateTime now) {
    final result = <MaterialPrice>[];
    for (final product in _products()) {
      final saleCents = product.sellingPriceCents;
      if (saleCents != null) {
        result.add(
          _price(
            materialId: product.id,
            priceTypeId: product.bundlePrice
                ? PriceTypeIds.saleBoxPrice
                : PriceTypeIds.saleUnitPrice,
            priceCents: saleCents,
            effectiveFrom: sellingSourceDate,
            now: now,
          ),
        );
      }
      final costCents = product.costPriceCents;
      if (costCents != null) {
        result.add(
          _price(
            materialId: product.id,
            priceTypeId: product.bundlePrice
                ? PriceTypeIds.costBoxPrice
                : PriceTypeIds.costUnitPrice,
            priceCents: costCents,
            effectiveFrom: factorySourceDate,
            now: now,
          ),
        );
      }
    }
    return result;
  }

  static List<MaterialQuantityPriceTier> quantityPriceTiers(DateTime now) {
    return [
      for (final product in _products())
        for (final entry in product.wholesalePriceCents.entries)
          MaterialQuantityPriceTier(
            id: '${product.id}_quantity_${entry.key}',
            materialId: product.id,
            minQuantity: entry.key,
            unitPriceCents: entry.value,
            currencyCode: 'USD',
            sourceDate: factorySourceDate,
            active: true,
            createdAt: now,
            updatedAt: now,
          ),
    ];
  }

  static List<PackagingRule> packagingRules(DateTime now) {
    return [
      for (final product in _products())
        if (product.piecesPerBundle != null)
          PackagingRule(
            id: 'packaging_${product.id}',
            materialId: product.id,
            itemsPerBox: product.piecesPerBundle!,
            boxUnitNameKhmer: 'បាច់',
            boxUnitNameEnglish: 'Bundle',
            size: product.spec,
            length: product.lengthMm == null
                ? ''
                : '${product.lengthMm!.toStringAsFixed(0)} mm',
            note: '${product.piecesPerBundle} pieces per bundle',
            active: true,
            updatedAt: now,
          ),
    ];
  }

  static MaterialPrice _price({
    required String materialId,
    required String priceTypeId,
    required int priceCents,
    required DateTime effectiveFrom,
    required DateTime now,
  }) {
    return MaterialPrice(
      id: '${materialId}_$priceTypeId',
      materialId: materialId,
      priceTypeId: priceTypeId,
      price: priceCents / 100,
      priceCents: priceCents,
      currencyCode: 'USD',
      effectiveFrom: effectiveFrom,
      effectiveTo: null,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<_PvcProduct> _products() {
    return const [
      // K Series Calculation Products
      _PvcProduct(
        id: PvcMaterialIds.k3000,
        code: 'K',
        productFamilyId: 'pvc_k',
        name: 'K 3m',
        spec: '400 × 10 × 3000 mm',
        widthMm: 400,
        thicknessMm: 10,
        lengthMm: 3000,
        sellingPriceCents: 670,
        costPriceCents: 580,
        wholesalePriceCents: {50: 560, 100: 530, 300: 510, 500: 500},
        designCodes: [
          'K-01',
          'K-02',
          'K-03',
          'K-04',
          'K-05',
          'K-06',
          'K-08',
          'K-10',
          'K-11',
          'K-12',
        ],
        notes: 'Canonical calculation product for K 3m',
      ),
      _PvcProduct(
        id: PvcMaterialIds.k4000,
        code: 'K',
        productFamilyId: 'pvc_k',
        name: 'K 4m',
        spec: '400 × 10 × 4000 mm',
        widthMm: 400,
        thicknessMm: 10,
        lengthMm: 4000,
        sellingPriceCents: 860,
        costPriceCents: 770,
        wholesalePriceCents: {50: 750, 100: 720, 300: 700, 500: 690},
        designCodes: [
          'K-01',
          'K-02',
          'K-03',
          'K-04',
          'K-05',
          'K-06',
          'K-08',
          'K-10',
          'K-11',
          'K-12',
        ],
        notes: 'Canonical calculation product for K 4m',
      ),

      // P Series Calculation Products
      _PvcProduct(
        id: PvcMaterialIds.p3000,
        code: 'P',
        productFamilyId: 'pvc_p',
        name: 'P 3m',
        spec: '400 × 10 × 3000 mm',
        widthMm: 400,
        thicknessMm: 10,
        lengthMm: 3000,
        sellingPriceCents: 690,
        costPriceCents: 600,
        wholesalePriceCents: {50: 580, 100: 550, 300: 530, 500: 520},
        designCodes: ['P-01', 'P-02', 'P-03'],
        notes: 'Canonical calculation product for P 3m',
      ),
      _PvcProduct(
        id: PvcMaterialIds.p4000,
        code: 'P',
        productFamilyId: 'pvc_p',
        name: 'P 4m',
        spec: '400 × 10 × 4000 mm',
        widthMm: 400,
        thicknessMm: 10,
        lengthMm: 4000,
        sellingPriceCents: 885,
        costPriceCents: 795,
        wholesalePriceCents: {50: 775, 100: 745, 300: 725, 500: 715},
        designCodes: ['P-01', 'P-02', 'P-03'],
        notes: 'Canonical calculation product for P 4m',
      ),

      // GD Series Calculation Products
      _PvcProduct(
        id: PvcMaterialIds.gd3000,
        code: 'GD',
        productFamilyId: 'pvc_gd',
        name: 'GD 3m',
        spec: '23 × 400 × 3000 mm',
        widthMm: 400,
        thicknessMm: 23,
        lengthMm: 3000,
        sellingPriceCents: 2200,
        costPriceCents: 1800,
        designCodes: ['GD14', 'GD105', 'GD125', 'GD147', 'GD309'],
        notes: 'Canonical calculation product for GD 3m',
      ),
      _PvcProduct(
        id: PvcMaterialIds.gd4000,
        code: 'GD',
        productFamilyId: 'pvc_gd',
        name: 'GD 4m',
        spec: '23 × 400 × 4000 mm',
        widthMm: 400,
        thicknessMm: 23,
        lengthMm: 4000,
        sellingPriceCents: 2900,
        costPriceCents: 2350,
        designCodes: ['GD14', 'GD105', 'GD125', 'GD147', 'GD309'],
        notes: 'Canonical calculation product for GD 4m',
      ),

      // DB Series Calculation Product
      _PvcProduct(
        id: PvcMaterialIds.db4000,
        code: 'DB',
        productFamilyId: 'pvc_db',
        name: 'DB 4m',
        spec: '23 × 333 × 4000 mm',
        widthMm: 333,
        thicknessMm: 23,
        lengthMm: 4000,
        sellingPriceCents: 2470,
        costPriceCents: 2070,
        designCodes: ['DB01', 'DB02', 'DB03', 'DB04', 'DB05'],
        notes: 'Canonical calculation product for DB 4m',
      ),

      // C-Line Products
      _PvcProduct(
        id: PvcMaterialIds.cLine023_4000,
        code: 'C.Line 0.23 x 4m',
        productFamilyId: 'pvc_c_line_023',
        name: 'C.Line 0.23 x 4m',
        spec: '1បាច់ = 20ដើម',
        lengthMm: 4000,
        piecesPerBundle: 20,
        bundlePrice: true,
        sellingPriceCents: 1624,
        costPriceCents: 850,
        notes: 'Selling and factory prices are per 20-piece bundle.',
      ),
      _PvcProduct(
        id: PvcMaterialIds.cLine027_4000,
        code: 'C.Line 0.27 x 4m',
        productFamilyId: 'pvc_c_line_027',
        name: 'C.Line 0.27 x 4m',
        spec: '1បាច់ = 20ដើម',
        lengthMm: 4000,
        piecesPerBundle: 20,
        bundlePrice: true,
        sellingPriceCents: 1719,
        costPriceCents: 950,
        notes: 'Selling and factory prices are per 20-piece bundle.',
      ),

      // Other Real Khmer PVC Ceiling / Wall Types
      _PvcProduct(
        id: 'pvc_4flu_tbom_3000',
        code: '4ភ្លឺធំ',
        productFamilyId: 'pvc_4flu_tbom',
        name: '4ភ្លឺធំ',
        spec: '160 × 22 × 3000 mm',
        widthMm: 160,
        thicknessMm: 22,
        lengthMm: 3000,
        sellingPriceCents: 580,
        costPriceCents: 490,
        wholesalePriceCents: {30: 480, 50: 450, 100: 430, 300: 410, 500: 400},
        notes: 'Authoritative factory and selling PVC sheet.',
      ),
      _PvcProduct(
        id: 'pvc_3flu_tbom_teab_3000',
        code: '3ភ្លឺធំទាប',
        productFamilyId: 'pvc_3flu_tbom_teab',
        name: '3ភ្លឺធំទាប',
        spec: '195 × 12 × 3000 mm',
        widthMm: 195,
        thicknessMm: 12,
        lengthMm: 3000,
        sellingPriceCents: 650,
        costPriceCents: 510,
        wholesalePriceCents: {30: 500, 50: 470, 100: 450, 300: 430, 500: 420},
        notes: 'Authoritative factory and selling PVC sheet.',
      ),
      _PvcProduct(
        id: 'pvc_4flu_teab_3000',
        code: '4ភ្លឺទាប',
        productFamilyId: 'pvc_4flu_teab',
        name: '4ភ្លឺទាប',
        spec: '150 × 9 × 3000 mm',
        widthMm: 150,
        thicknessMm: 9,
        lengthMm: 3000,
        sellingPriceCents: 550,
        costPriceCents: 440,
        wholesalePriceCents: {30: 430, 50: 400, 100: 380, 300: 360, 500: 350},
        notes: 'Authoritative factory and selling PVC sheet.',
      ),
      _PvcProduct(
        id: 'pvc_v_25x25x3000',
        code: 'ជ្រី V',
        productFamilyId: 'pvc_v',
        name: 'ជ្រី V',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 350,
        costPriceCents: 250,
        notes: 'Authoritative PVC V trim.',
      ),

      // Real Khmer Accessories (Single Item Per Physical Type)
      _PvcProduct(
        id: 'pvc_image1_row07',
        code: 'ជ្រីស៊ុមទ្វាបង្អួច',
        productFamilyId: 'pvc_image1_row07',
        name: 'ជ្រីស៊ុមទ្វាបង្អួច',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 550,
        costPriceCents: 430,
        notes: 'Door & window frame trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row08',
        code: 'ជ្រីជើងជញ្ជាំង',
        productFamilyId: 'pvc_image1_row08',
        name: 'ជ្រីជើងជញ្ជាំង',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 550,
        costPriceCents: 430,
        notes: 'Wall base skirting trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row09',
        code: 'ជ្រីធំលើ',
        productFamilyId: 'pvc_image1_row09',
        name: 'ជ្រីធំលើ',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 550,
        costPriceCents: 430,
        notes: 'Top crown molding trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row10',
        code: 'ជ្រីដេគ័រ',
        productFamilyId: 'pvc_image1_row10',
        name: 'ជ្រីដេគ័រ',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 400,
        costPriceCents: 280,
        notes: 'Decorative trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row11',
        code: 'ជ្រីកែង',
        productFamilyId: 'pvc_image1_row11',
        name: 'ជ្រីកែង',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 400,
        costPriceCents: 280,
        notes: 'Corner trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row12',
        code: 'ជ្រីតតំណ',
        productFamilyId: 'pvc_image1_row12',
        name: 'ជ្រីតតំណ',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 420,
        costPriceCents: 280,
        notes: 'Joint trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row13',
        code: 'ជ្រីចំហៀង',
        productFamilyId: 'pvc_image1_row13',
        name: 'ជ្រីចំហៀង',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 550,
        costPriceCents: 280,
        notes: 'Side trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row14',
        code: 'ញូម',
        productFamilyId: 'pvc_image1_row14',
        name: 'ញូម',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 600,
        costPriceCents: 320,
        notes: 'Nyum trim.',
      ),
      _PvcProduct(
        id: 'pvc_image1_row16',
        code: 'ឃ្មៀបអ៊ីណុក',
        productFamilyId: 'pvc_image1_row16',
        name: 'ឃ្មៀបអ៊ីណុក',
        spec: '100គ្រាប់/កញ្ចប់',
        piecesPerBundle: 100,
        bundlePrice: true,
        sellingPriceCents: 400,
        costPriceCents: 400,
        notes: 'Stainless steel clips (100 pcs/pack).',
      ),
      _PvcProduct(
        id: 'pvc_image1_row17',
        code: 'វីសបាញ់ពិដាន',
        productFamilyId: 'pvc_image1_row17',
        name: 'វីសបាញ់ពិដាន',
        spec: '1000គ្រាប់/កញ្ចប់',
        piecesPerBundle: 1000,
        bundlePrice: true,
        sellingPriceCents: 400,
        costPriceCents: 260,
        notes: 'Ceiling screws (1000 pcs/pack).',
      ),
      _PvcProduct(
        id: 'pvc_image1_row18',
        code: 'វីសបាញ់ក្តារក្រាលបាត',
        productFamilyId: 'pvc_image1_row18',
        name: 'វីសបាញ់ក្តារក្រាលបាត',
        spec: '1000គ្រាប់/កញ្ចប់',
        piecesPerBundle: 1000,
        bundlePrice: true,
        sellingPriceCents: 460,
        costPriceCents: 380,
        notes: 'Subfloor screws (1000 pcs/pack).',
      ),
      _PvcProduct(
        id: 'pvc_glue',
        code: 'កាវ',
        productFamilyId: 'pvc_glue',
        name: 'កាវ',
        spec: '',
        sellingPriceCents: 450,
        costPriceCents: 250,
        notes: 'PVC Glue.',
      ),
      _PvcProduct(
        id: 'pvc_last_accessory_3000',
        code: 'ជ្រីខណ្ឌជញ្ជាំង',
        productFamilyId: 'pvc_last_accessory',
        name: 'ជ្រីខណ្ឌជញ្ជាំង',
        spec: '3 m',
        lengthMm: 3000,
        sellingPriceCents: 1000,
        costPriceCents: 800,
        notes: 'Wall partition trim.',
      ),
    ];
  }
}

class _PvcProduct {
  const _PvcProduct({
    required this.id,
    required this.code,
    required this.productFamilyId,
    required this.name,
    required this.spec,
    this.widthMm,
    this.thicknessMm,
    this.lengthMm,
    this.piecesPerBundle,
    this.bundlePrice = false,
    this.sellingPriceCents,
    this.costPriceCents,
    this.wholesalePriceCents = const {},
    this.designCodes = const [],
    required this.notes,
  });

  final String id;
  final String code;
  final String productFamilyId;
  final String name;
  final String spec;
  final double? widthMm;
  final double? thicknessMm;
  final double? lengthMm;
  final int? piecesPerBundle;
  final bool bundlePrice;
  final int? sellingPriceCents;
  final int? costPriceCents;
  final Map<int, int> wholesalePriceCents;
  final List<String> designCodes;
  final String notes;
}
