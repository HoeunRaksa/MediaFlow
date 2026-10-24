import 'dart:math' as math;

import '../../measurement_calculator/domain/models/measurement_models.dart';
import '../../measurement_calculator/native/measurement_native_api.dart';
import 'pvc_quantity_models.dart';

class PvcQuantityCalculationService {
  PvcQuantityCalculationService({
    MeasurementOptimizer? optimizer,
    this.simpleAreaEstimates = false,
  }) : _optimizer = optimizer ?? const MeasurementNativeApi();

  final MeasurementOptimizer _optimizer;

  /// Uses total area and raw product coverage for automatic panel quantities.
  ///
  /// This is enabled by the Flutter Web screen because the native cutting
  /// optimizer is not available/reliable in that browser calculation mode.
  /// Windows keeps the existing optimizer-backed behavior by default.
  final bool simpleAreaEstimates;

  Future<PvcQuantityWorkspaceResult> calculate({
    required List<PvcMeasurementGroup> groups,
    MeasurementOptimizationOptions options =
        const MeasurementOptimizationOptions(),
  }) async {
    final zoneResults = <PvcZoneQuantityResult>[];
    for (final group in groups) {
      final derivedZones = group.derivedZones;
      for (var index = 0; index < group.zones.length; index++) {
        zoneResults.add(
          await _calculateZone(
            group,
            group.zones[index],
            derivedZones[index],
            options,
          ),
        );
      }
    }

    final byProduct = <String, List<PvcZoneQuantityResult>>{};
    for (final result in zoneResults) {
      byProduct.putIfAbsent(result.product.id, () => []).add(result);
    }
    final productResults = <PvcProductQuantityResult>[];
    for (final results in byProduct.values) {
      final first = results.first;
      productResults.add(
        PvcProductQuantityResult(
          product: first.product,
          quantity: results.fold(0, (total, item) => total + item.quantity),
          unitLabel: first.unitLabel,
          assignedAreaM2: results.fold(
            0,
            (total, item) => total + item.assignedAreaM2,
          ),
          requiredLinearM: results.fold(
            0,
            (total, item) => total + item.requiredLinearM,
          ),
          zones: List.unmodifiable(results),
        ),
      );
    }
    productResults.sort(
      (a, b) => a.product.sortOrder.compareTo(b.product.sortOrder),
    );
    return PvcQuantityWorkspaceResult(
      groups: List.unmodifiable(groups),
      zoneResults: List.unmodifiable(zoneResults),
      products: List.unmodifiable(productResults),
    );
  }

  Future<PvcZoneQuantityResult> _calculateZone(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    PvcZoneDerivedMeasurement measurement,
    MeasurementOptimizationOptions options,
  ) async {
    final assignedArea = measurement.assignedAreaPerRoomM2 * group.roomCount;
    final requiredLinear = measurement.runLengthPerRoomM * group.roomCount;
    final unitLabel = _unitLabel(zone.product);
    final invalidGroup = group.roomCount < 1;
    if (invalidGroup) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        notice: 'Room count must be at least 1.',
      );
    }

    if (zone.usesManualSheetQuantity) {
      return _manualSheets(
        group,
        zone,
        unitLabel,
        assignedArea,
        requiredLinear,
      );
    }

    return switch (zone.calculationMode) {
      PvcZoneCalculationMode.manualQuantity => _manual(
        group,
        zone,
        unitLabel,
        assignedArea,
        requiredLinear,
      ),
      PvcZoneCalculationMode.coveragePerPiece => _coverage(
        group,
        zone,
        unitLabel,
        assignedArea,
        requiredLinear,
        measurement.assignedAreaPerRoomM2,
      ),
      PvcZoneCalculationMode.auto => _auto(
        group,
        zone,
        options,
        unitLabel,
        assignedArea,
        requiredLinear,
        measurement.assignedAreaPerRoomM2,
        measurement.runLengthPerRoomM,
      ),
    };
  }

  PvcZoneQuantityResult _manualSheets(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
  ) {
    final sheets = zone.manualQuantity;
    if (sheets == null || sheets <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Manual sheet quantity',
        notice: 'Enter a sheet quantity greater than 0.',
      );
    }
    return _result(
      group,
      zone,
      quantity: sheets,
      unitLabel: unitLabel,
      assignedArea: assignedArea,
      requiredLinear: requiredLinear,
      method: 'Manual sheet quantity',
    );
  }

  PvcZoneQuantityResult _manual(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
  ) {
    final manual = zone.manualQuantity;
    if (manual == null || manual <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Manual quantity',
        notice: 'Enter a manual quantity greater than 0.',
      );
    }
    return _result(
      group,
      zone,
      quantity: manual * group.roomCount,
      unitLabel: unitLabel,
      assignedArea: assignedArea,
      requiredLinear: requiredLinear,
      method: 'Manual quantity',
    );
  }

  PvcZoneQuantityResult _coverage(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
    double assignedAreaPerRoom,
  ) {
    final coverage = zone.coveragePerPieceM2;
    if (assignedArea <= 0 || coverage == null || coverage <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Coverage per piece',
        notice: 'Enter an assigned area and coverage greater than 0.',
      );
    }
    return _result(
      group,
      zone,
      quantity: _piecesFor(assignedAreaPerRoom, coverage) * group.roomCount,
      unitLabel: unitLabel,
      assignedArea: assignedArea,
      requiredLinear: requiredLinear,
      method: '${_number(coverage)} m² per piece',
    );
  }

  Future<PvcZoneQuantityResult> _auto(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    MeasurementOptimizationOptions options,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
    double assignedAreaPerRoom,
    double requiredLinearPerRoom,
  ) async {
    if (zone.product.category == PvcProductCategory.cLine) {
      return _autoCLine(group, zone, assignedArea, requiredLinear);
    }
    return switch (zone.product.calculationUnit) {
      PvcProductCalculationUnit.area => _autoArea(
        group,
        zone,
        options,
        unitLabel,
        assignedArea,
        requiredLinear,
        assignedAreaPerRoom,
      ),
      PvcProductCalculationUnit.linear => _autoLinear(
        group,
        zone,
        unitLabel,
        assignedArea,
        requiredLinear,
        requiredLinearPerRoom,
      ),
      PvcProductCalculationUnit.manual => _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Manual material',
        notice: 'This material has no physical coverage. Set manual quantity.',
      ),
    };
  }

  PvcZoneQuantityResult _autoCLine(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    double assignedArea,
    double requiredLinear,
  ) {
    final totalArea = group.totalAreaM2;
    final piecesPerBox = zone.product.piecesPerPackage ?? 20;
    const physicalUnitLabel = 'ដើម';
    if (totalArea <= 0 || piecesPerBox <= 0) {
      return _result(
        group,
        zone,
        unitLabel: physicalUnitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: '16 m² per box · area estimate',
        notice: 'Enter room dimensions or total area greater than 0.',
      );
    }
    final boxes = (totalArea / 16 - 1e-9).ceil();
    return _result(
      group,
      zone,
      quantity: boxes * piecesPerBox,
      unitLabel: physicalUnitLabel,
      assignedArea: totalArea,
      requiredLinear: requiredLinear,
      method: '16 m² per box · area estimate',
    );
  }

  Future<PvcZoneQuantityResult> _autoArea(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    MeasurementOptimizationOptions options,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
    double assignedAreaPerRoom,
  ) async {
    final product = zone.product;
    final coverage = product.rawCoverageM2;
    if (assignedArea <= 0 || coverage == null || coverage <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Automatic',
        notice: 'Enter an assigned area or dimensions greater than 0.',
      );
    }

    if (simpleAreaEstimates) {
      return _result(
        group,
        zone,
        quantity: _piecesFor(assignedAreaPerRoom, coverage) * group.roomCount,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: '${_number(coverage)} m² per sheet · area estimate',
      );
    }

    if (zone.inputMode != PvcZoneInputMode.dimensions) {
      return _result(
        group,
        zone,
        quantity: _piecesFor(assignedAreaPerRoom, coverage) * group.roomCount,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: '${_number(coverage)} m² raw coverage',
      );
    }

    final length = zone.lengthM;
    final width = zone.widthM;
    if (length == null || width == null || length <= 0 || width <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Exact geometry',
        notice: 'Enter zone length and width greater than 0.',
      );
    }
    final variant = MeasurementProductVariant(
      variantId: product.lengthMm!.round(),
      label: product.spec,
      widthMm: product.widthMm!,
      lengthMm: product.lengthMm!,
      thicknessMm: product.thicknessMm ?? 1,
      unitPrice: 0,
      materialId: product.id,
      productFamilyId: product.family,
      productCode: product.nameKhmer,
    );
    try {
      final optimized = await _optimizer.optimize(
        MeasurementOptimizationRequest(
          rooms: [
            MeasurementRoom(
              id: group.id * 1000 + zone.id,
              name: '${group.name} · ${zone.name}',
              lengthM: length,
              widthM: width,
            ),
          ],
          variants: [variant],
          options: options.copyWith(
            orientationOverride: zone.orientation,
            clearOrientationOverride: zone.orientation == null,
          ),
        ),
      );
      final candidate = optimized.selectedCandidate;
      if (optimized.status != MeasurementStatus.ok || candidate == null) {
        return _result(
          group,
          zone,
          unitLabel: unitLabel,
          assignedArea: assignedArea,
          requiredLinear: requiredLinear,
          method: 'Exact geometry',
          notice: 'No physically valid cutting layout was found.',
        );
      }
      final quantity = candidate.quantities.fold(
        0,
        (total, item) => total + item.purchaseQuantity,
      );
      return _result(
        group,
        zone,
        quantity: quantity * group.roomCount,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Exact geometry · cuts included',
      );
    } on Object catch (error) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Exact geometry',
        notice: 'Geometry calculation failed: $error',
      );
    }
  }

  PvcZoneQuantityResult _autoLinear(
    PvcMeasurementGroup group,
    PvcQuantityZone zone,
    String unitLabel,
    double assignedArea,
    double requiredLinear,
    double requiredLinearPerRoom,
  ) {
    final packaging = zone.product.perMeterPackaging;
    if (packaging != null) {
      if (!_clipAppliesToGroup(group)) {
        return _result(
          group,
          zone,
          unitLabel: unitLabel,
          assignedArea: assignedArea,
          requiredLinear: requiredLinear,
          method: 'Only for K / P PVC',
          notice: 'Clips are only required for K and P PVC panels.',
        );
      }
      if (requiredLinear <= 0) {
        return _result(
          group,
          zone,
          unitLabel: unitLabel,
          assignedArea: assignedArea,
          requiredLinear: requiredLinear,
          method: 'Automatic perimeter accessory',
          notice: 'Enter required linear meters greater than 0.',
        );
      }
      return _result(
        group,
        zone,
        quantity:
            packaging.piecesForLength(requiredLinearPerRoom) * group.roomCount,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: '${_number(packaging.piecesPerMeter)} pieces per meter',
      );
    }
    final pieceLength = zone.product.pieceLengthM;
    if (requiredLinear <= 0 || pieceLength == null || pieceLength <= 0) {
      return _result(
        group,
        zone,
        unitLabel: unitLabel,
        assignedArea: assignedArea,
        requiredLinear: requiredLinear,
        method: 'Automatic linear',
        notice: 'Enter required linear meters greater than 0.',
      );
    }
    return _result(
      group,
      zone,
      quantity:
          _piecesFor(requiredLinearPerRoom, pieceLength) * group.roomCount,
      unitLabel: unitLabel,
      assignedArea: assignedArea,
      requiredLinear: requiredLinear,
      method: '${_number(pieceLength)} m per piece',
    );
  }

  bool _clipAppliesToGroup(PvcMeasurementGroup group) => group.zones.any(
    (zone) =>
        zone.product.calculationUnit == PvcProductCalculationUnit.area &&
        const {'K', 'P'}.contains(zone.product.family.trim().toUpperCase()),
  );

  PvcZoneQuantityResult _result(
    PvcMeasurementGroup group,
    PvcQuantityZone zone, {
    int quantity = 0,
    required String unitLabel,
    required double assignedArea,
    required double requiredLinear,
    String method = 'Automatic',
    String? notice,
  }) {
    return PvcZoneQuantityResult(
      groupId: group.id,
      groupName: group.name,
      zoneId: zone.id,
      zoneName: zone.name,
      product: zone.product,
      quantity: quantity,
      unitLabel: unitLabel,
      assignedAreaM2: assignedArea,
      requiredLinearM: requiredLinear,
      methodLabel: method,
      notice: notice,
    );
  }

  String _unitLabel(PvcPhysicalProduct product) =>
      product.perMeterPackaging != null
      ? 'ឃ្នៀប'
      : switch (product.calculationUnit) {
          PvcProductCalculationUnit.area => 'សន្លឹក',
          PvcProductCalculationUnit.linear => 'ដើម',
          PvcProductCalculationUnit.manual => 'ឯកតា',
        };

  String _number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  int _piecesFor(double required, double capacity) {
    return math.max(1, (required / capacity - 1e-9).ceil());
  }
}
