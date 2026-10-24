import '../../measurement_calculator/domain/models/measurement_models.dart';

enum PvcProductCalculationUnit { area, linear, manual }

enum PvcAreaAllocationRole { none, fixed, fillCapable }

enum PvcProductCategory { panels, trims, cLine, gdDb, other }

enum PvcGroupInputMode { dimensions, area }

enum PvcZoneInputMode {
  dimensions,
  area,
  sheetQuantity,
  perimeterStrip,
  linear,
}

enum PvcPerimeterRunMode { autoPerimeter, custom }

enum PvcZoneCalculationMode { auto, coveragePerPiece, manualQuantity }

class PvcPerMeterPackaging {
  const PvcPerMeterPackaging({
    required this.piecesPerMeter,
    required this.piecesPerPackage,
  });

  final double piecesPerMeter;
  final int piecesPerPackage;

  int piecesForLength(double lengthM) {
    if (lengthM <= 0 || piecesPerMeter <= 0) return 0;
    return (lengthM * piecesPerMeter - 1e-9).ceil();
  }

  int packagesForPieces(int pieces) {
    if (pieces <= 0 || piecesPerPackage <= 0) return 0;
    return (pieces / piecesPerPackage).ceil();
  }
}

class PvcPhysicalProduct {
  const PvcPhysicalProduct({
    required this.id,
    required this.nameKhmer,
    required this.family,
    required this.spec,
    required this.calculationUnit,
    required this.areaAllocationRole,
    required this.category,
    required this.sortOrder,
    required this.designCodes,
    this.widthMm,
    this.thicknessMm,
    this.lengthMm,
    this.perMeterPackaging,
    this.piecesPerPackage,
    this.imagePath,
  });

  final String id;
  final String nameKhmer;
  final String family;
  final String spec;
  final PvcProductCalculationUnit calculationUnit;
  final PvcAreaAllocationRole areaAllocationRole;
  final PvcProductCategory category;
  final int sortOrder;
  final double? widthMm;
  final double? thicknessMm;
  final double? lengthMm;
  final PvcPerMeterPackaging? perMeterPackaging;

  /// Physical pieces included in one sellable bundle/box.
  final int? piecesPerPackage;
  final List<String> designCodes;
  final String? imagePath;

  double? get rawCoverageM2 {
    if (widthMm == null || lengthMm == null) return null;
    return widthMm! * lengthMm! / 1000000;
  }

  double? get pieceLengthM => lengthMm == null ? null : lengthMm! / 1000;

  bool get consumesRoomArea => areaAllocationRole != PvcAreaAllocationRole.none;

  bool get isLinearAccessory =>
      calculationUnit == PvcProductCalculationUnit.linear;

  bool get usesEditablePerimeterLength => perMeterPackaging != null;

  bool get isPackagePriced => piecesPerPackage != null && piecesPerPackage! > 1;

  /// Customer-facing unit for a complete sellable package.
  ///
  /// C-Line is sold in bundles (បាច់), while the stainless PVC clips are
  /// sold in packages (កញ្ចប់). Keep this distinction on the shared product
  /// model so Windows and Web quotations cannot drift apart.
  String get packageUnitLabel =>
      perMeterPackaging != null || category != PvcProductCategory.cLine
      ? 'កញ្ចប់'
      : 'បាច់';

  /// Customer-facing name for quotation lines. The catalog retains the full
  /// physical product name, but quotations use the concise trade names.
  String get customerNameKhmer {
    if (perMeterPackaging != null) return 'ឃ្នៀប';
    if (category == PvcProductCategory.cLine && pieceLengthM != null) {
      final meters = pieceLengthM!;
      final length = meters == meters.roundToDouble()
          ? meters.toInt().toString()
          : meters.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
      return 'C-Line ${length}m';
    }
    return nameKhmer;
  }

  bool get supportsManualSheetQuantity =>
      calculationUnit == PvcProductCalculationUnit.area &&
      category == PvcProductCategory.panels;
}

class PvcQuantityZone {
  const PvcQuantityZone({
    required this.id,
    required this.name,
    required this.product,
    required this.inputMode,
    this.lengthM,
    this.widthM,
    this.areaM2,
    this.requiredLinearM,
    this.stripWidthM,
    this.perimeterRunMode = PvcPerimeterRunMode.autoPerimeter,
    this.customRunM,
    this.useRemainingArea = false,
    this.calculationMode = PvcZoneCalculationMode.auto,
    this.coveragePerPieceM2,
    this.manualQuantity,
    this.orientation,
  });

  final int id;
  final String name;
  final PvcPhysicalProduct product;
  final PvcZoneInputMode inputMode;
  final double? lengthM;
  final double? widthM;
  final double? areaM2;
  final double? requiredLinearM;
  final double? stripWidthM;
  final PvcPerimeterRunMode perimeterRunMode;
  final double? customRunM;
  final bool useRemainingArea;
  final PvcZoneCalculationMode calculationMode;
  final double? coveragePerPieceM2;
  final int? manualQuantity;
  final MeasurementOrientation? orientation;

  bool get usesManualSheetQuantity =>
      inputMode == PvcZoneInputMode.sheetQuantity &&
      product.supportsManualSheetQuantity;

  bool get allocatesRoomArea =>
      product.consumesRoomArea && inputMode != PvcZoneInputMode.sheetQuantity;

  PvcZoneDerivedMeasurement derive({
    required double parentAreaM2,
    required double parentPerimeterM,
    required double allocatedBeforeM2,
  }) {
    if (useRemainingArea && allocatesRoomArea) {
      final remaining = parentAreaM2 - allocatedBeforeM2;
      return PvcZoneDerivedMeasurement(
        assignedAreaPerRoomM2: remaining > 0 ? remaining : 0,
        runLengthPerRoomM: 0,
        usesRemainingArea: true,
      );
    }
    return _deriveMeasured(parentPerimeterM);
  }

  PvcZoneDerivedMeasurement _deriveMeasured(double parentPerimeterM) =>
      switch (product.calculationUnit) {
        PvcProductCalculationUnit.area => _deriveArea(parentPerimeterM),
        PvcProductCalculationUnit.linear => _deriveLinear(parentPerimeterM),
        PvcProductCalculationUnit.manual => const PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: 0,
        ),
      };

  PvcZoneDerivedMeasurement _deriveArea(double parentPerimeterM) =>
      switch (inputMode) {
        PvcZoneInputMode.dimensions => PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: (lengthM ?? 0) * (widthM ?? 0),
          runLengthPerRoomM: 0,
        ),
        PvcZoneInputMode.area => PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: areaM2 ?? 0,
          runLengthPerRoomM: 0,
        ),
        PvcZoneInputMode.sheetQuantity => const PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: 0,
        ),
        PvcZoneInputMode.perimeterStrip => _derivePerimeter(parentPerimeterM),
        PvcZoneInputMode.linear => PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: requiredLinearM ?? 0,
        ),
      };

  PvcZoneDerivedMeasurement _deriveLinear(double parentPerimeterM) =>
      switch (inputMode) {
        PvcZoneInputMode.dimensions => PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: _rectangularRun,
        ),
        PvcZoneInputMode.area => const PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: 0,
        ),
        PvcZoneInputMode.sheetQuantity => const PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: 0,
        ),
        PvcZoneInputMode.perimeterStrip => _deriveLinearPerimeter(
          parentPerimeterM,
        ),
        PvcZoneInputMode.linear => PvcZoneDerivedMeasurement(
          assignedAreaPerRoomM2: 0,
          runLengthPerRoomM: requiredLinearM ?? 0,
        ),
      };

  double get _rectangularRun {
    final length = lengthM ?? 0;
    final width = widthM ?? 0;
    if (length <= 0 || width <= 0) return 0;
    return 2 * (length + width);
  }

  bool get _canActAsAutomaticFill =>
      product.areaAllocationRole == PvcAreaAllocationRole.fillCapable &&
      (inputMode == PvcZoneInputMode.dimensions ||
          inputMode == PvcZoneInputMode.area);

  PvcZoneDerivedMeasurement _derivePerimeter(double parentPerimeterM) {
    final run = switch (perimeterRunMode) {
      PvcPerimeterRunMode.autoPerimeter => parentPerimeterM,
      PvcPerimeterRunMode.custom => customRunM ?? 0,
    };
    return PvcZoneDerivedMeasurement(
      assignedAreaPerRoomM2: (stripWidthM ?? 0) * run,
      runLengthPerRoomM: run,
      autoPerimeterM: parentPerimeterM,
    );
  }

  PvcZoneDerivedMeasurement _deriveLinearPerimeter(double parentPerimeterM) {
    final run = switch (perimeterRunMode) {
      PvcPerimeterRunMode.autoPerimeter => parentPerimeterM,
      PvcPerimeterRunMode.custom => customRunM ?? 0,
    };
    return PvcZoneDerivedMeasurement(
      assignedAreaPerRoomM2: 0,
      runLengthPerRoomM: run,
      autoPerimeterM: parentPerimeterM,
    );
  }
}

class PvcZoneDerivedMeasurement {
  const PvcZoneDerivedMeasurement({
    required this.assignedAreaPerRoomM2,
    required this.runLengthPerRoomM,
    this.usesRemainingArea = false,
    this.autoPerimeterM = 0,
  });

  final double assignedAreaPerRoomM2;
  final double runLengthPerRoomM;
  final bool usesRemainingArea;
  final double autoPerimeterM;
}

class PvcMeasurementGroup {
  const PvcMeasurementGroup({
    required this.id,
    required this.name,
    required this.inputMode,
    required this.roomCount,
    required this.zones,
    this.lengthM,
    this.widthM,
    this.directAreaM2,
  });

  final int id;
  final String name;
  final PvcGroupInputMode inputMode;
  final double? lengthM;
  final double? widthM;
  final double? directAreaM2;
  final int roomCount;
  final List<PvcQuantityZone> zones;

  double get areaPerRoomM2 => switch (inputMode) {
    PvcGroupInputMode.dimensions => (lengthM ?? 0) * (widthM ?? 0),
    PvcGroupInputMode.area => directAreaM2 ?? 0,
  };

  double get totalAreaM2 => areaPerRoomM2 * roomCount;

  double get perimeterPerRoomM {
    if (inputMode != PvcGroupInputMode.dimensions ||
        lengthM == null ||
        widthM == null) {
      return 0;
    }
    return 2 * (lengthM! + widthM!);
  }

  List<PvcZoneDerivedMeasurement> get derivedZones {
    if (zones.isEmpty) return const [];
    final fillIndex = _fillZoneIndex;
    final result = List<PvcZoneDerivedMeasurement?>.filled(zones.length, null);
    var allocated = 0.0;
    for (var index = 0; index < zones.length; index++) {
      if (index == fillIndex) continue;
      final derived = zones[index]._deriveMeasured(perimeterPerRoomM);
      result[index] = derived;
      allocated += derived.assignedAreaPerRoomM2;
    }
    if (fillIndex != null) {
      final remaining = areaPerRoomM2 - allocated;
      result[fillIndex] = PvcZoneDerivedMeasurement(
        assignedAreaPerRoomM2: remaining > 0 ? remaining : 0,
        runLengthPerRoomM: 0,
        usesRemainingArea: true,
      );
    }
    return List.unmodifiable(result.cast<PvcZoneDerivedMeasurement>());
  }

  int? get _fillZoneIndex {
    final explicitFillCapable = zones.indexWhere(
      (zone) =>
          zone.useRemainingArea &&
          zone.allocatesRoomArea &&
          zone.product.areaAllocationRole == PvcAreaAllocationRole.fillCapable,
    );
    if (explicitFillCapable >= 0) return explicitFillCapable;

    final hasFixedArea = zones.any(
      (zone) =>
          zone.allocatesRoomArea &&
          zone.product.areaAllocationRole == PvcAreaAllocationRole.fixed,
    );
    if (hasFixedArea) {
      final automaticFill = zones.indexWhere(
        (zone) => zone._canActAsAutomaticFill,
      );
      if (automaticFill >= 0) return automaticFill;
    }

    final explicitAreaFill = zones.indexWhere(
      (zone) => zone.useRemainingArea && zone.allocatesRoomArea,
    );
    return explicitAreaFill >= 0 ? explicitAreaFill : null;
  }

  double get allocatedAreaPerRoomM2 =>
      derivedZones.fold(0, (total, zone) => total + zone.assignedAreaPerRoomM2);

  double get allocatedAreaM2 => allocatedAreaPerRoomM2 * roomCount;

  double get allocationDeltaM2 => totalAreaM2 - allocatedAreaM2;
}

class PvcZoneQuantityResult {
  const PvcZoneQuantityResult({
    required this.groupId,
    required this.groupName,
    required this.zoneId,
    required this.zoneName,
    required this.product,
    required this.quantity,
    required this.unitLabel,
    required this.assignedAreaM2,
    required this.requiredLinearM,
    required this.methodLabel,
    this.notice,
  });

  final int groupId;
  final String groupName;
  final int zoneId;
  final String zoneName;
  final PvcPhysicalProduct product;
  final int quantity;
  final String unitLabel;
  final double assignedAreaM2;
  final double requiredLinearM;
  final String methodLabel;
  final String? notice;
}

class PvcProductQuantityResult {
  const PvcProductQuantityResult({
    required this.product,
    required this.quantity,
    required this.unitLabel,
    required this.assignedAreaM2,
    required this.requiredLinearM,
    required this.zones,
  });

  final PvcPhysicalProduct product;
  final int quantity;
  final String unitLabel;
  final double assignedAreaM2;
  final double requiredLinearM;
  final List<PvcZoneQuantityResult> zones;

  int? get requiredPackages {
    final piecesPerPackage = product.piecesPerPackage;
    if (piecesPerPackage == null || piecesPerPackage <= 0) return null;
    return (quantity / piecesPerPackage).ceil();
  }

  int? get loosePieces {
    final piecesPerPackage = product.piecesPerPackage;
    if (piecesPerPackage == null || piecesPerPackage <= 0) return null;
    return quantity % piecesPerPackage;
  }

  String get priceUnitLabel =>
      product.isPackagePriced ? product.packageUnitLabel : unitLabel;

  double get billableQuantity => product.isPackagePriced
      ? (requiredPackages ?? 0).toDouble()
      : quantity.toDouble();

  /// A compact, customer-facing description of the purchase quantity.
  /// Packaged products are billed by full packages and show the physical
  /// contents customers receive, e.g. `2 បាច់ (40 ដើម)`.
  String get quantitySummary {
    final packages = requiredPackages;
    if (packages == null) return '$quantity $unitLabel';
    final piecesPerPackage = product.piecesPerPackage!;
    final purchasedPieces = packages * piecesPerPackage;
    return '$packages ${product.packageUnitLabel} '
        '($purchasedPieces $unitLabel)';
  }

  /// Full-package breakdown used in detailed result panels.
  String get packageSummary => quantitySummary;

  /// Validation/calculation notices must remain visible instead of silently
  /// presenting a zero quantity for an item that could not be calculated.
  List<String> get notices =>
      zones.map((zone) => zone.notice).whereType<String>().toList();

  bool get isAreaEstimate =>
      zones.any((zone) => zone.methodLabel.contains('area estimate'));
}

class PvcQuantityWorkspaceResult {
  const PvcQuantityWorkspaceResult({
    required this.groups,
    required this.zoneResults,
    required this.products,
  });

  final List<PvcMeasurementGroup> groups;
  final List<PvcZoneQuantityResult> zoneResults;
  final List<PvcProductQuantityResult> products;

  double get totalAreaM2 =>
      groups.fold(0, (total, group) => total + group.totalAreaM2);

  double get allocatedAreaM2 =>
      groups.fold(0, (total, group) => total + group.allocatedAreaM2);
}
