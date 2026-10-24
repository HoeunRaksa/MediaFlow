import '../../../core/constants/business_ids.dart';
import '../../materials/data/models/material_item.dart';
import '../../materials/data/models/material_price.dart';
import '../domain/models/measurement_models.dart';

class MeasurementProductFamily {
  const MeasurementProductFamily({
    required this.id,
    required this.code,
    required this.name,
    required this.widthMm,
    required this.thicknessMm,
    required this.variants,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String name;
  final double widthMm;
  final double thicknessMm;
  final List<MeasurementProductVariant> variants;
  final int sortOrder;

  String get availabilityLabel => variants
      .map((variant) => '${_format(variant.lengthMm / 1000)}m')
      .join(' / ');

  String get dimensionsLabel =>
      '${_format(widthMm)} × ${_format(thicknessMm)} mm';

  static String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class MeasurementProductCatalog {
  const MeasurementProductCatalog();

  List<MeasurementProductFamily> build({
    required List<MaterialItem> materials,
    required List<MaterialPrice> prices,
    DateTime? at,
  }) {
    final effectiveAt = at ?? DateTime.now();
    final salePrices = <String, MaterialPrice>{};
    for (final price in prices) {
      if (price.priceTypeId != PriceTypeIds.saleUnitPrice ||
          !price.isEffectiveAt(effectiveAt)) {
        continue;
      }
      final current = salePrices[price.materialId];
      if (current == null ||
          price.effectiveFrom.isAfter(current.effectiveFrom)) {
        salePrices[price.materialId] = price;
      }
    }

    final grouped = <String, List<MaterialItem>>{};
    for (final material in materials) {
      final familyId = material.productFamilyId;
      final hasCompleteDimensions =
          material.widthMm != null &&
          material.widthMm! > 0 &&
          material.thicknessMm != null &&
          material.thicknessMm! > 0 &&
          material.lengthMm != null &&
          material.lengthMm! > 0;
      if (!material.active ||
          material.categoryId != 'pvc' ||
          familyId == null ||
          !hasCompleteDimensions ||
          salePrices[material.id] == null) {
        continue;
      }
      grouped.putIfAbsent(familyId, () => []).add(material);
    }

    final families = <MeasurementProductFamily>[];
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final byLength = a.lengthMm!.compareTo(b.lengthMm!);
        return byLength != 0 ? byLength : a.id.compareTo(b.id);
      });
      final first = entry.value.first;
      final variants = [
        for (final material in entry.value)
          MeasurementProductVariant(
            variantId: material.lengthMm!.round(),
            label: material.spec,
            widthMm: material.widthMm!,
            lengthMm: material.lengthMm!,
            thicknessMm: material.thicknessMm!,
            unitPrice: salePrices[material.id]!.price,
            materialId: material.id,
            productFamilyId: entry.key,
            productCode: material.code,
          ),
      ];
      families.add(
        MeasurementProductFamily(
          id: entry.key,
          code: first.code ?? first.englishName,
          name: first.englishName,
          widthMm: first.widthMm!,
          thicknessMm: first.thicknessMm!,
          variants: List.unmodifiable(variants),
          sortOrder: first.sortOrder,
        ),
      );
    }
    families.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });
    return List.unmodifiable(families);
  }
}
