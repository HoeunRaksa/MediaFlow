import '../../materials/data/models/material_item.dart';
import '../domain/pvc_quantity_models.dart';

class PvcPhysicalCatalog {
  const PvcPhysicalCatalog();

  List<PvcPhysicalProduct> build(List<MaterialItem> materials) {
    final grouped = <String, List<MaterialItem>>{};
    for (final material in materials) {
      if (!material.active || material.categoryId != 'pvc') continue;
      final family = _family(material);
      final key = [
        family.key,
        _dimensionKey(material.widthMm),
        _dimensionKey(material.thicknessMm),
        _dimensionKey(material.lengthMm),
        _calculationUnit(material).name,
      ].join('|');
      grouped.putIfAbsent(key, () => []).add(material);
    }

    final products = <PvcPhysicalProduct>[];
    for (final entry in grouped.entries) {
      final rows = entry.value..sort(_compareMaterials);
      final material = rows.first;
      final family = _family(material);
      final designCodes = <String>{};
      for (final row in rows) {
        designCodes.addAll(row.designCodes);
        final code = (row.code ?? '').trim();
        if (_isDesignCode(code, family.key)) designCodes.add(code);
      }
      final calculationUnit = _calculationUnit(material);
      products.add(
        PvcPhysicalProduct(
          id: _canonicalId(rows),
          nameKhmer: _physicalName(family, material),
          family: family.label,
          spec: material.spec.trim().isEmpty
              ? _dimensions(material)
              : material.spec.trim(),
          calculationUnit: calculationUnit,
          areaAllocationRole: _areaAllocationRole(family, calculationUnit),
          category: _category(family, calculationUnit),
          sortOrder: rows
              .map((row) => row.sortOrder)
              .reduce((a, b) => a < b ? a : b),
          widthMm: material.widthMm,
          thicknessMm: material.thicknessMm,
          lengthMm: material.lengthMm,
          perMeterPackaging: _perMeterPackaging(material),
          designCodes: List.unmodifiable(designCodes.toList()..sort()),
          imagePath:
              rows.where((r) => r.imagePath != null).firstOrNull?.imagePath ??
              material.imagePath,
        ),
      );
    }
    products.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.nameKhmer.compareTo(b.nameKhmer);
    });
    return List.unmodifiable(products);
  }

  int _compareMaterials(MaterialItem a, MaterialItem b) {
    final aCanonical = _isCanonical(a) ? 0 : 1;
    final bCanonical = _isCanonical(b) ? 0 : 1;
    final canonical = aCanonical.compareTo(bCanonical);
    if (canonical != 0) return canonical;
    final order = a.sortOrder.compareTo(b.sortOrder);
    return order != 0 ? order : a.id.compareTo(b.id);
  }

  bool _isCanonical(MaterialItem material) {
    final code = (material.code ?? '').trim().toUpperCase();
    return const {'K', 'P', 'GD', 'DB'}.contains(code) ||
        material.designCodes.isNotEmpty;
  }

  String _canonicalId(List<MaterialItem> rows) =>
      rows.firstWhere(_isCanonical, orElse: () => rows.first).id;

  _Family _family(MaterialItem material) {
    final raw = (material.code ?? material.englishName).trim();
    final code = raw.toUpperCase().replaceAll(' ', '');
    if (RegExp(r'^K-?\d+$').hasMatch(code) || code == 'K') {
      return const _Family('k', 'K');
    }
    if (RegExp(r'^P-?\d+$').hasMatch(code) || code == 'P') {
      return const _Family('p', 'P');
    }
    if (RegExp(r'^GD-?\d+$').hasMatch(code) || code == 'GD') {
      return const _Family('gd', 'GD');
    }
    if (RegExp(r'^DB-?\d+$').hasMatch(code) || code == 'DB') {
      return const _Family('db', 'DB');
    }
    if (code.startsWith('C.LINE')) return _Family(code.toLowerCase(), raw);
    return _Family(code.toLowerCase(), raw);
  }

  bool _isDesignCode(String code, String family) {
    final normalized = code.toUpperCase().replaceAll(' ', '');
    return switch (family) {
      'k' => RegExp(r'^K-?\d+$').hasMatch(normalized),
      'p' => RegExp(r'^P-?\d+$').hasMatch(normalized),
      'gd' => RegExp(r'^GD-?\d+$').hasMatch(normalized),
      'db' => RegExp(r'^DB-?\d+$').hasMatch(normalized),
      _ => false,
    };
  }

  PvcProductCalculationUnit _calculationUnit(MaterialItem material) {
    if (_perMeterPackaging(material) != null) {
      return PvcProductCalculationUnit.linear;
    }
    if (material.widthMm != null && material.lengthMm != null) {
      return PvcProductCalculationUnit.area;
    }
    if (material.lengthMm != null) return PvcProductCalculationUnit.linear;
    return PvcProductCalculationUnit.manual;
  }

  PvcPerMeterPackaging? _perMeterPackaging(MaterialItem material) {
    if (material.id != 'pvc_image1_row16') return null;
    return PvcPerMeterPackaging(
      piecesPerMeter: 2,
      piecesPerPackage: material.piecesPerBundle ?? 100,
    );
  }

  PvcProductCategory _category(
    _Family family,
    PvcProductCalculationUnit calculationUnit,
  ) {
    if (family.key.startsWith('c.line')) return PvcProductCategory.cLine;
    if (family.key == 'gd' || family.key == 'db') {
      return PvcProductCategory.gdDb;
    }
    if (calculationUnit == PvcProductCalculationUnit.area) {
      return PvcProductCategory.panels;
    }
    if (calculationUnit == PvcProductCalculationUnit.linear) {
      return PvcProductCategory.trims;
    }
    return PvcProductCategory.other;
  }

  PvcAreaAllocationRole _areaAllocationRole(
    _Family family,
    PvcProductCalculationUnit calculationUnit,
  ) {
    if (calculationUnit != PvcProductCalculationUnit.area) {
      return PvcAreaAllocationRole.none;
    }
    return const {'k', 'p'}.contains(family.key)
        ? PvcAreaAllocationRole.fillCapable
        : PvcAreaAllocationRole.fixed;
  }

  String _physicalName(_Family family, MaterialItem material) {
    if (const {'k', 'p', 'gd', 'db'}.contains(family.key) &&
        material.lengthMm != null) {
      return '${family.label} ${_meters(material.lengthMm!)}m';
    }
    return material.khmerName.trim().isEmpty
        ? family.label
        : material.khmerName.trim();
  }

  String _dimensions(MaterialItem material) {
    final values = [
      material.widthMm,
      material.thicknessMm,
      material.lengthMm,
    ].whereType<double>().map(_number).toList();
    return values.isEmpty ? '' : '${values.join(' × ')} mm';
  }

  String _dimensionKey(double? value) =>
      value == null ? '-' : value.toStringAsFixed(4);

  String _meters(double mm) {
    final meters = mm / 1000;
    return meters == meters.roundToDouble()
        ? meters.toInt().toString()
        : meters.toStringAsFixed(1);
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _Family {
  const _Family(this.key, this.label);

  final String key;
  final String label;
}
