import '../../../core/constants/business_ids.dart';
import '../../materials/data/models/material_item.dart';
import '../../materials/data/models/material_price.dart';
import '../domain/workspace_models.dart';

class MeasurementWorkspaceCatalog {
  const MeasurementWorkspaceCatalog();

  List<WorkspaceProduct> build({
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    DateTime? at,
  }) {
    final effectiveAt = at ?? DateTime.now();
    final pricesByMaterial = <String, MaterialPrice>{};
    for (final price in prices) {
      final isSelling =
          price.priceTypeId == PriceTypeIds.saleUnitPrice ||
          price.priceTypeId == PriceTypeIds.saleBoxPrice;
      if (!isSelling || !price.isEffectiveAt(effectiveAt)) continue;
      final current = pricesByMaterial[price.materialId];
      if (current == null ||
          price.effectiveFrom.isAfter(current.effectiveFrom)) {
        pricesByMaterial[price.materialId] = price;
      }
    }

    final grouped = <String, List<_CatalogEntry>>{};
    for (final material in materials) {
      final price = pricesByMaterial[material.id];
      if (!material.active || material.categoryId != 'pvc' || price == null) {
        continue;
      }
      final type = _calculationType(material);
      final key = _calculationIdentity(
        type: type,
        material: material,
        price: price,
      );
      grouped
          .putIfAbsent(key, () => <_CatalogEntry>[])
          .add(_CatalogEntry(material: material, price: price, type: type));
    }

    final products = <WorkspaceProduct>[];
    for (final group in grouped.values) {
      group.sort((a, b) {
        final byOrder = a.material.sortOrder.compareTo(b.material.sortOrder);
        return byOrder != 0
            ? byOrder
            : _materialCode(a.material).compareTo(_materialCode(b.material));
      });
      final representative = group.first;
      final material = representative.material;
      final price = representative.price;
      final type = representative.type;
      final code = _calculationLabel(type, material);
      final category = _category(type, material);
      final variant = WorkspaceProductVariant(
        variantId: material.lengthMm?.round() ?? 100000 + material.sortOrder,
        materialId: material.id,
        label: material.spec.isEmpty ? code : material.spec,
        lengthMm: material.lengthMm,
        widthMm: material.widthMm,
        thicknessMm: material.thicknessMm,
        unitPrice: price.price,
        priceTypeId: price.priceTypeId,
        itemsPerBundle: material.piecesPerBundle ?? material.itemsPerBox ?? 1,
      );
      final hasCoverageData =
          variant.priceTypeId == PriceTypeIds.saleUnitPrice &&
          variant.lengthMm != null &&
          variant.widthMm != null &&
          variant.thicknessMm != null;
      final calculationKind =
          hasCoverageData &&
              (category == WorkspaceProductCategory.pvc ||
                  category == WorkspaceProductCategory.db ||
                  category == WorkspaceProductCategory.gd)
          ? WorkspaceCalculationKind.coverage
          : variant.lengthMm != null
          ? WorkspaceCalculationKind.linear
          : WorkspaceCalculationKind.fixed;
      final designOptions = _designOptions(
        type: type,
        representative: material,
        materials: materials,
      );

      products.add(
        WorkspaceProduct(
          id: material.id,
          code: code,
          name: code,
          category: category,
          calculationKind: calculationKind,
          variants: List.unmodifiable([variant]),
          designOptions: List.unmodifiable(designOptions),
          sortOrder: group
              .map((entry) => entry.material.sortOrder)
              .reduce((left, right) => left < right ? left : right),
        ),
      );
    }
    products.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });
    return List.unmodifiable(products);
  }

  String _calculationIdentity({
    required _CalculationType type,
    required MaterialItem material,
    required MaterialPrice price,
  }) {
    return [
      type.key,
      _dimensionKey(material.widthMm),
      _dimensionKey(material.thicknessMm),
      _dimensionKey(material.lengthMm),
      material.unitId,
      material.formulaTypeId,
      price.priceTypeId,
      price.currencyCode,
      price.priceCents,
      material.piecesPerBundle ?? material.itemsPerBox ?? 1,
    ].join('|');
  }

  _CalculationType _calculationType(MaterialItem material) {
    final code = _materialCode(material).trim();
    final normalized = code.toUpperCase();
    if (RegExp(r'^K-?\d+$').hasMatch(normalized) || normalized == 'K') {
      return const _CalculationType(key: 'k', label: 'K');
    }
    if (RegExp(r'^P-?\d+$').hasMatch(normalized) || normalized == 'P') {
      return const _CalculationType(key: 'p', label: 'P');
    }
    if (RegExp(r'^GD-?\d+$').hasMatch(normalized) || normalized == 'GD') {
      return const _CalculationType(key: 'gd', label: 'GD');
    }
    if (RegExp(r'^DB-?\d+$').hasMatch(normalized) || normalized == 'DB') {
      return const _CalculationType(key: 'db', label: 'DB');
    }
    if (normalized.startsWith('C.LINE')) {
      return _CalculationType(key: normalized.toLowerCase(), label: code);
    }
    return _CalculationType(key: normalized.toLowerCase(), label: code);
  }

  String _calculationLabel(_CalculationType type, MaterialItem material) {
    if (const {'k', 'p', 'gd', 'db'}.contains(type.key) &&
        material.lengthMm != null) {
      return '${type.label} ${_meters(material.lengthMm!)}';
    }
    return type.label;
  }

  WorkspaceProductCategory _category(
    _CalculationType type,
    MaterialItem material,
  ) {
    if (type.key.startsWith('c.line')) return WorkspaceProductCategory.cLine;
    if (type.key == 'db') return WorkspaceProductCategory.db;
    if (type.key == 'gd') return WorkspaceProductCategory.gd;
    if (type.key == 'k' ||
        type.key == 'p' ||
        (material.widthMm != null &&
            material.widthMm! >= 100 &&
            material.thicknessMm != null)) {
      return WorkspaceProductCategory.pvc;
    }
    return WorkspaceProductCategory.accessories;
  }

  String _materialCode(MaterialItem material) =>
      material.code ?? material.englishName;

  List<WorkspaceDesignOption> _designOptions({
    required _CalculationType type,
    required MaterialItem representative,
    required List<MaterialItem> materials,
  }) {
    if (representative.designCodes.isNotEmpty) {
      return [
        for (final code in representative.designCodes)
          WorkspaceDesignOption(
            materialId: representative.id,
            code: code,
            name: code,
          ),
      ];
    }
    final matching = materials.where((material) {
      return material.active &&
          material.categoryId == 'pvc' &&
          _calculationType(material).key == type.key &&
          material.widthMm == representative.widthMm &&
          material.thicknessMm == representative.thicknessMm &&
          material.lengthMm == representative.lengthMm &&
          material.unitId == representative.unitId &&
          material.formulaTypeId == representative.formulaTypeId &&
          (material.piecesPerBundle ?? material.itemsPerBox ?? 1) ==
              (representative.piecesPerBundle ??
                  representative.itemsPerBox ??
                  1);
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final byCode = <String, MaterialItem>{};
    for (final material in matching) {
      byCode.putIfAbsent(_materialCode(material), () => material);
    }
    if (type.key == 'gd' && byCode.length > 1) {
      byCode.removeWhere((code, _) => code.toUpperCase() == 'GD');
    }
    return [
      for (final entry in byCode.entries)
        WorkspaceDesignOption(
          materialId: entry.value.id,
          code: entry.key,
          name: entry.value.englishName,
        ),
    ];
  }

  String _dimensionKey(double? value) =>
      value == null ? '-' : value.toStringAsFixed(4);

  String _meters(double lengthMm) {
    final meters = lengthMm / 1000;
    final value = meters == meters.roundToDouble()
        ? meters.toInt().toString()
        : meters.toStringAsFixed(1);
    return '${value}m';
  }
}

class _CatalogEntry {
  const _CatalogEntry({
    required this.material,
    required this.price,
    required this.type,
  });

  final MaterialItem material;
  final MaterialPrice price;
  final _CalculationType type;
}

class _CalculationType {
  const _CalculationType({required this.key, required this.label});

  final String key;
  final String label;
}
