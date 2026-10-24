import 'package:flutter/material.dart';

import 'core/storage/app_data_bootstrapper.dart';
import 'core/storage/local_json_storage.dart';
import 'core/utils/quantity_rounding.dart';
import 'features/materials/data/models/formula_rule.dart';
import 'features/materials/data/models/material_category.dart';
import 'features/materials/data/models/material_item.dart';
import 'features/materials/data/models/material_price.dart';
import 'features/materials/data/models/material_quantity_price_tier.dart';
import 'features/materials/data/models/packaging_rule.dart';
import 'features/materials/data/models/pricing_tier.dart';
import 'features/materials/data/models/product_type_template.dart';
import 'features/materials/data/models/sell_mode.dart';
import 'features/materials/data/models/unit_of_measure.dart';
import 'features/materials/data/repositories/catalog_repository.dart';
import 'features/materials/data/repositories/formula_rule_repository.dart';
import 'features/materials/data/repositories/material_price_repository.dart';
import 'features/materials/data/repositories/material_quantity_price_tier_repository.dart';
import 'features/materials/data/repositories/material_repository.dart';
import 'features/materials/data/repositories/packaging_repository.dart';
import 'features/materials/data/repositories/pricing_tier_repository.dart';
import 'features/materials/data/repositories/product_template_repository.dart';
import 'features/materials/data/repositories/sell_mode_repository.dart';
import 'features/materials/data/seed/default_material_seed.dart';
import 'features/materials/domain/live_calculation_models.dart';
import 'features/materials/domain/live_material_calculation_engine.dart';
import 'features/materials/domain/product_sale_engine.dart';
import 'features/materials/domain/product_sale_models.dart';
import 'features/measurement_calculator/domain/models/measurement_models.dart';

class AppState extends ChangeNotifier {
  AppState({LocalJsonStorage? storage})
    : _storage = storage ?? LocalJsonStorage() {
    _materialRepository = LocalMaterialRepository(_storage);
    _priceRepository = LocalMaterialPriceRepository(_storage);
    _quantityPriceTierRepository = LocalMaterialQuantityPriceTierRepository(
      _storage,
    );
    _tierRepository = LocalPricingTierRepository(_storage);
    _formulaRepository = LocalFormulaRuleRepository(_storage);
    _catalogRepository = LocalCatalogRepository(_storage);
    _productTemplateRepository = LocalProductTemplateRepository(_storage);
    _sellModeRepository = LocalSellModeRepository(_storage);
    _packagingRepository = LocalPackagingRepository(_storage);
  }

  final LocalJsonStorage _storage;
  late final MaterialRepository _materialRepository;
  late final MaterialPriceRepository _priceRepository;
  late final MaterialQuantityPriceTierRepository _quantityPriceTierRepository;
  late final PricingTierRepository _tierRepository;
  late final FormulaRuleRepository _formulaRepository;
  late final CatalogRepository _catalogRepository;
  late final ProductTemplateRepository _productTemplateRepository;
  late final SellModeRepository _sellModeRepository;
  late final PackagingRepository _packagingRepository;
  final LiveMaterialCalculationEngine _engine =
      const LiveMaterialCalculationEngine();
  final ProductSaleEngine _saleEngine = const ProductSaleEngine();

  bool isLoading = true;
  String? loadError;
  List<MaterialItem> materials = [];
  List<MaterialPrice> prices = [];
  List<MaterialQuantityPriceTier> materialQuantityPriceTiers = [];
  List<PricingTier> pricingTiers = [];
  List<FormulaRule> formulaRules = [];
  List<MaterialCategory> categories = [];
  List<UnitOfMeasure> units = [];
  List<ProductTypeTemplate> productTemplates = [];
  List<SellMode> sellModes = [];
  List<PackagingRule> packagingRules = [];
  LiveCalculationResult? liveResult;
  List<ProductSaleResult> currentSaleItems = [];
  bool useSavedPriceAsDefault = true;
  bool allowSaleBelowCost = false;
  MeasurementOptimizationOptions measurementOptions =
      const MeasurementOptimizationOptions();
  List<MeasurementProductVariant> measurementVariants =
      MeasurementProductDefaults.variants;

  Future<void> initialize() async {
    try {
      isLoading = true;
      notifyListeners();
      final seed = DefaultMaterialSeed.json(DateTime.now());
      await AppDataBootstrapper(
        dataDirectory: await _storage.directory(),
      ).ensureSeedDataInstalled();
      await _storage.ensureSeeded(seed);
      await _repairSeedTextIfNeeded(seed);
      await reload();
    } catch (error) {
      loadError = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    materials = await _materialRepository.getMaterials();
    // Correct the original ceiling catalog label while retaining saved IDs.
    materials = materials
        .map(
          (item) => item.id == 'ceiling_6mm' && item.spec == '6លី'
              ? item.copyWith(spec: '4លី')
              : item,
        )
        .toList();
    prices = await _priceRepository.getPrices();
    materialQuantityPriceTiers = await _quantityPriceTierRepository.getTiers();
    pricingTiers = await _tierRepository.getPricingTiers();
    formulaRules = await _formulaRepository.getFormulaRules();
    categories = await _catalogRepository.getCategories();
    units = await _catalogRepository.getUnits();
    productTemplates = await _productTemplateRepository.getProductTemplates();
    sellModes = await _sellModeRepository.getSellModes();
    packagingRules = await _packagingRepository.getPackagingRules();
    final settings = await _storage.readSettings();
    useSavedPriceAsDefault =
        settings['useSavedPriceAsDefault'] as bool? ?? useSavedPriceAsDefault;
    allowSaleBelowCost =
        settings['allowSaleBelowCost'] as bool? ?? allowSaleBelowCost;
    final measurement = settings['measurementCalculator'];
    if (measurement is Map) {
      final optimizeIndex =
          (measurement['optimizeFor'] as num?)?.toInt() ??
          measurementOptions.optimizeFor.index;
      measurementOptions = measurementOptions.copyWith(
        optimizeFor:
            MeasurementOptimizeFor.values[optimizeIndex.clamp(
              0,
              MeasurementOptimizeFor.values.length - 1,
            )],
        allowJoints:
            measurement['allowJoints'] as bool? ??
            measurementOptions.allowJoints,
        reuseOffcuts:
            measurement['reuseOffcuts'] as bool? ??
            measurementOptions.reuseOffcuts,
        projectMode:
            measurement['projectMode'] as bool? ??
            measurementOptions.projectMode,
        sparePercent:
            (measurement['sparePercent'] as num?)?.toDouble() ??
            measurementOptions.sparePercent,
        orientationOverride: measurement['orientationOverride'] is num
            ? MeasurementOrientation.values[(measurement['orientationOverride']
                      as num)
                  .toInt()
                  .clamp(0, MeasurementOrientation.values.length - 1)]
            : null,
        clearOrientationOverride: measurement['orientationOverride'] == null,
      );
      final savedVariants = measurement['variants'];
      if (savedVariants is List) {
        final decoded = <MeasurementProductVariant>[];
        for (final item in savedVariants) {
          if (item is! Map) {
            continue;
          }
          final width = (item['widthMm'] as num?)?.toDouble();
          final length = (item['lengthMm'] as num?)?.toDouble();
          final thickness = (item['thicknessMm'] as num?)?.toDouble();
          final price = (item['unitPrice'] as num?)?.toDouble();
          final id = (item['variantId'] as num?)?.toInt();
          if (id == null ||
              width == null ||
              length == null ||
              thickness == null ||
              price == null ||
              width <= 0 ||
              length <= 0 ||
              thickness <= 0 ||
              price < 0) {
            continue;
          }
          decoded.add(
            MeasurementProductVariant(
              variantId: id,
              label:
                  item['label'] as String? ??
                  '$width × $thickness × $length mm',
              widthMm: width,
              lengthMm: length,
              thicknessMm: thickness,
              unitPrice: price,
              materialId: item['materialId'] as String?,
              productFamilyId: item['productFamilyId'] as String?,
              productCode: item['productCode'] as String?,
            ),
          );
        }
        if (decoded.isNotEmpty) {
          measurementVariants = List.unmodifiable(decoded);
        }
      }
    }
    notifyListeners();
  }

  PricingTier? get defaultTier {
    for (final tier in pricingTiers) {
      if (tier.active && tier.isDefault) {
        return tier;
      }
    }
    return pricingTiers.where((tier) => tier.active).firstOrNull;
  }

  List<MaterialItem> get optionalMaterials => materials
      .where((material) => material.active && material.isOptionalAddon)
      .toList(growable: false);

  List<MaterialItem> get manualMaterials => materials
      .where(
        (material) =>
            material.active && material.formulaTypeId == 'manual_quantity',
      )
      .toList(growable: false);

  ProductTypeTemplate? get defaultProductTemplate {
    for (final template in productTemplates) {
      if (template.active && template.isDefault) {
        return template;
      }
    }
    return productTemplates.where((template) => template.active).firstOrNull;
  }

  void calculateLive(LiveCalculationInput input) {
    final productType = productTemplates
        .where((template) => template.id == input.productTypeTemplateId)
        .firstOrNull;
    if (productType == null) {
      liveResult = LiveCalculationResult(
        productTypeTemplateId: input.productTypeTemplateId,
        productTypeNameKhmer: '',
        productTypeNameEnglish: '',
        lines: const [],
        subtotal: 0,
        discountTotal: 0,
        grandTotal: 0,
        validationErrors: const ['Product type must be selected.'],
      );
      notifyListeners();
      return;
    }
    liveResult = _engine.calculate(
      input: input,
      productType: productType,
      materials: materials,
      prices: prices,
      sellModes: sellModes,
      packagingRules: packagingRules,
    );
    notifyListeners();
  }

  ProductSaleResult calculateProductSale(
    ProductSaleInput input, {
    QuantityRounder? automaticQuantityRounder,
  }) {
    return _saleEngine.calculate(
      input: input,
      productKinds: productTemplates,
      materials: materials,
      prices: prices,
      packagingRules: packagingRules,
      automaticQuantityRounder: automaticQuantityRounder,
    );
  }

  void addTemporarySaleResults(List<ProductSaleResult> results) {
    final validResults = results
        .where((result) => result.canAddToTemporarySale)
        .toList(growable: false);
    if (validResults.isEmpty) {
      return;
    }
    currentSaleItems = [...currentSaleItems, ...validResults];
    notifyListeners();
  }

  void removeTemporarySaleItem(int index) {
    if (index < 0 || index >= currentSaleItems.length) {
      return;
    }
    currentSaleItems = [
      for (var i = 0; i < currentSaleItems.length; i++)
        if (i != index) currentSaleItems[i],
    ];
    notifyListeners();
  }

  void clearTemporarySale() {
    if (currentSaleItems.isEmpty) {
      return;
    }
    currentSaleItems = [];
    notifyListeners();
  }

  TemporarySaleSummary get temporarySaleSummary {
    return TemporarySaleSummary.fromItems(currentSaleItems);
  }

  void setUseSavedPriceAsDefault(bool value) {
    if (useSavedPriceAsDefault == value) {
      return;
    }
    useSavedPriceAsDefault = value;
    _saveSettings();
    notifyListeners();
  }

  void setAllowSaleBelowCost(bool value) {
    if (allowSaleBelowCost == value) {
      return;
    }
    allowSaleBelowCost = value;
    _saveSettings();
    notifyListeners();
  }

  void setMeasurementOptions(MeasurementOptimizationOptions value) {
    if (measurementOptions.optimizeFor == value.optimizeFor &&
        measurementOptions.allowJoints == value.allowJoints &&
        measurementOptions.reuseOffcuts == value.reuseOffcuts &&
        measurementOptions.projectMode == value.projectMode &&
        measurementOptions.sparePercent == value.sparePercent) {
      return;
    }
    measurementOptions = value;
    _saveSettings();
    notifyListeners();
  }

  void setMeasurementVariants(List<MeasurementProductVariant> value) {
    if (value.isEmpty) return;
    measurementVariants = List.unmodifiable(value);
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() {
    return _storage.writeSettings({
      'useSavedPriceAsDefault': useSavedPriceAsDefault,
      'allowSaleBelowCost': allowSaleBelowCost,
      'measurementCalculator': {
        'optimizeFor': measurementOptions.optimizeFor.index,
        'allowJoints': measurementOptions.allowJoints,
        'reuseOffcuts': measurementOptions.reuseOffcuts,
        'projectMode': measurementOptions.projectMode,
        'sparePercent': measurementOptions.sparePercent,
        'orientationOverride': measurementOptions.orientationOverride?.index,
        'variants': [
          for (final variant in measurementVariants)
            {
              'variantId': variant.variantId,
              'label': variant.label,
              'widthMm': variant.widthMm,
              'lengthMm': variant.lengthMm,
              'thicknessMm': variant.thicknessMm,
              'unitPrice': variant.unitPrice,
              'materialId': variant.materialId,
              'productFamilyId': variant.productFamilyId,
              'productCode': variant.productCode,
            },
        ],
      },
    });
  }

  Future<void> saveMaterial(MaterialItem item) async {
    await _materialRepository.saveMaterial(
      item.copyWith(updatedAt: DateTime.now()),
    );
    await reload();
  }

  Future<void> deactivateMaterial(String id) async {
    await _materialRepository.deleteOrDeactivateMaterial(id);
    await reload();
  }

  Future<void> savePrice(MaterialPrice price) async {
    await _priceRepository.savePrice(price.copyWith(updatedAt: DateTime.now()));
    await reload();
  }

  Future<void> saveMaterialQuantityPriceTier(
    MaterialQuantityPriceTier tier,
  ) async {
    await _quantityPriceTierRepository.saveTier(
      tier.copyWith(updatedAt: DateTime.now()),
    );
    await reload();
  }

  Future<void> saveTier(PricingTier tier) async {
    await _tierRepository.savePricingTier(
      tier.copyWith(updatedAt: DateTime.now()),
    );
    await reload();
  }

  Future<void> saveCategory(MaterialCategory category) async {
    await _catalogRepository.saveCategory(category);
    await reload();
  }

  Future<void> saveUnit(UnitOfMeasure unit) async {
    await _catalogRepository.saveUnit(unit);
    await reload();
  }

  Future<void> saveProductTemplate(ProductTypeTemplate template) async {
    await _productTemplateRepository.saveProductTemplate(template);
    await reload();
  }

  Future<void> savePackagingRule(PackagingRule rule) async {
    await _packagingRepository.savePackagingRule(
      rule.copyWith(updatedAt: DateTime.now()),
    );
    await reload();
  }

  Future<void> _repairSeedTextIfNeeded(Map<String, dynamic> seed) async {
    final data = await _storage.readAll();
    var changed = false;
    const keys = {
      'materials',
      'pricingTiers',
      'formulaRules',
      'units',
      'categories',
      'sellModes',
      'productTypeTemplates',
      'packagingRules',
    };

    for (final key in keys) {
      final current = data[key];
      final incoming = seed[key];
      if (current is! List || incoming is! List) {
        continue;
      }
      final seedById = <Object?, Map<String, dynamic>>{
        for (final item in incoming)
          if (item is Map && item['id'] != null)
            item['id']: Map<String, dynamic>.from(item),
      };
      for (final item in current) {
        if (item is! Map || item['id'] == null) {
          continue;
        }
        final seedItem = seedById[item['id']];
        if (seedItem == null) {
          continue;
        }
        final currentItem = item.cast<String, dynamic>();
        for (final entry in seedItem.entries) {
          final value = currentItem[entry.key];
          if (value is String &&
              entry.value is String &&
              _looksLikeMojibake(value)) {
            currentItem[entry.key] = entry.value;
            changed = true;
          }
        }
      }
    }

    if (changed) {
      await _storage.writeAll(data);
    }
  }

  bool _looksLikeMojibake(String value) {
    return value.contains('áž') ||
        value.contains('áŸ') ||
        value.contains('Â') ||
        value.contains('Ã');
  }
}
