import 'models/measurement_models.dart';

enum WorkspaceProductCategory { pvc, accessories, cLine, db, gd }

enum WorkspaceCalculationKind { coverage, linear, fixed }

class WorkspaceDesignOption {
  const WorkspaceDesignOption({
    required this.materialId,
    required this.code,
    required this.name,
  });

  final String materialId;
  final String code;
  final String name;
}

class WorkspaceProductVariant {
  const WorkspaceProductVariant({
    required this.variantId,
    required this.materialId,
    required this.label,
    required this.lengthMm,
    required this.widthMm,
    required this.thicknessMm,
    required this.unitPrice,
    required this.priceTypeId,
    required this.itemsPerBundle,
  });

  final int variantId;
  final String materialId;
  final String label;
  final double? lengthMm;
  final double? widthMm;
  final double? thicknessMm;
  final double unitPrice;
  final String priceTypeId;
  final int itemsPerBundle;

  WorkspaceProductVariant copyWith({
    int? variantId,
    String? label,
    double? lengthMm,
    double? unitPrice,
  }) {
    return WorkspaceProductVariant(
      variantId: variantId ?? this.variantId,
      materialId: materialId,
      label: label ?? this.label,
      lengthMm: lengthMm ?? this.lengthMm,
      widthMm: widthMm,
      thicknessMm: thicknessMm,
      unitPrice: unitPrice ?? this.unitPrice,
      priceTypeId: priceTypeId,
      itemsPerBundle: itemsPerBundle,
    );
  }

  MeasurementProductVariant toMeasurementVariant(String productFamilyId) {
    return MeasurementProductVariant(
      variantId: variantId,
      label: label,
      widthMm: widthMm!,
      lengthMm: lengthMm!,
      thicknessMm: thicknessMm!,
      unitPrice: unitPrice,
      materialId: materialId,
      productFamilyId: productFamilyId,
    );
  }
}

class WorkspaceProduct {
  const WorkspaceProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.calculationKind,
    required this.variants,
    required this.designOptions,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String name;
  final WorkspaceProductCategory category;
  final WorkspaceCalculationKind calculationKind;
  final List<WorkspaceProductVariant> variants;
  final List<WorkspaceDesignOption> designOptions;
  final int sortOrder;

  String get dimensionsLabel {
    final first = variants.first;
    final width = first.widthMm;
    final thickness = first.thicknessMm;
    final length = first.lengthMm;
    if (width == null) return first.label;
    if (thickness == null) {
      return length == null
          ? '${_number(width)} mm'
          : '${_number(width)} × ${_number(length)} mm';
    }
    return length == null
        ? '${_number(width)} × ${_number(thickness)} mm'
        : '${_number(width)} × ${_number(thickness)} × ${_number(length)} mm';
  }

  String get availabilityLabel {
    if (designOptions.length > 1) {
      return '${designOptions.length} color/design options';
    }
    final lengths = variants
        .where((variant) => variant.lengthMm != null)
        .map((variant) => '${_number(variant.lengthMm! / 1000)}m')
        .toSet();
    return lengths.isEmpty ? variants.first.label : lengths.join(' / ');
  }

  String get priceLabel => variants
      .map((variant) => '\$${variant.unitPrice.toStringAsFixed(2)}')
      .join(' / ');
}

class WorkspaceMaterialOverride {
  const WorkspaceMaterialOverride({
    this.variantId,
    this.customLengthMm,
    this.quantity,
    this.unitPrice,
    this.sparePercent,
    this.orientation,
  });

  final int? variantId;
  final double? customLengthMm;
  final int? quantity;
  final double? unitPrice;
  final double? sparePercent;
  final MeasurementOrientation? orientation;
}

class WorkspaceProductSelection {
  const WorkspaceProductSelection({required this.product, this.overrides});

  final WorkspaceProduct product;
  final WorkspaceMaterialOverride? overrides;

  WorkspaceProductSelection copyWith({WorkspaceMaterialOverride? overrides}) {
    return WorkspaceProductSelection(
      product: product,
      overrides: overrides ?? this.overrides,
    );
  }
}

class WorkspaceMaterialLine {
  const WorkspaceMaterialLine({
    required this.variant,
    required this.quantity,
    required this.unitLabel,
    required this.unitPrice,
    required this.totalPrice,
    required this.detail,
  });

  final WorkspaceProductVariant variant;
  final int quantity;
  final String unitLabel;
  final double unitPrice;
  final double totalPrice;
  final String detail;
}

class WorkspaceMaterialResult {
  const WorkspaceMaterialResult({
    required this.selection,
    required this.lines,
    required this.totalQuantity,
    required this.totalPrice,
    required this.wasteAreaM2,
    required this.wasteLinearM,
    this.candidate,
    this.notice,
  });

  final WorkspaceProductSelection selection;
  final List<WorkspaceMaterialLine> lines;
  final int totalQuantity;
  final double totalPrice;
  final double wasteAreaM2;
  final double wasteLinearM;
  final MeasurementCandidate? candidate;
  final String? notice;
}

class WorkspaceCalculationResult {
  const WorkspaceCalculationResult({
    required this.materials,
    required this.areaM2,
  });

  final List<WorkspaceMaterialResult> materials;
  final double areaM2;

  double get totalPrice =>
      materials.fold(0, (total, material) => total + material.totalPrice);
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
