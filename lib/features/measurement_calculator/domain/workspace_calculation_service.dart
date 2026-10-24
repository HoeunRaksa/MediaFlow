import 'dart:math' as math;

import '../../../core/constants/business_ids.dart';
import '../native/measurement_native_api.dart';
import 'models/measurement_models.dart';
import 'services/area_coverage_estimator.dart';
import 'workspace_models.dart';

const _cuttingEstimateNotice =
    'ត្រូវការបណ្ដោយ និងទទឹង សម្រាប់គណនាការកាត់ឲ្យច្បាស់';
const _linearGeometryNotice = 'ទំហំ m² មិនអាចគណនាសម្ភារៈតាមបរិមាត្របានទេ';

class WorkspaceCalculationService {
  WorkspaceCalculationService({MeasurementOptimizer? optimizer})
    : _optimizer = optimizer ?? const MeasurementNativeApi();

  final MeasurementOptimizer _optimizer;

  Future<WorkspaceCalculationResult> calculate({
    required List<MeasurementRoom> rooms,
    required List<WorkspaceProductSelection> selections,
    required MeasurementOptimizationOptions options,
  }) async {
    if (rooms.isEmpty || rooms.any((room) => !_isValidRoomGroup(room))) {
      throw const FormatException(
        'Room measurements must be greater than 0 and count at least 1.',
      );
    }
    final physicalRooms = expandMeasurementRooms(
      rooms.where((room) => room.mode == MeasurementRoomMode.dimensions),
    );
    final directAreaM2 = rooms
        .where((room) => room.mode == MeasurementRoomMode.area)
        .fold(0.0, (total, room) => total + room.totalAreaM2);
    final materials = <WorkspaceMaterialResult>[];
    for (final selection in selections) {
      materials.add(
        await _calculateMaterial(
          roomGroups: rooms,
          physicalRooms: physicalRooms,
          directAreaM2: directAreaM2,
          selection: selection,
          options: options,
        ),
      );
    }
    return WorkspaceCalculationResult(
      materials: List.unmodifiable(materials),
      areaM2: rooms.fold(0.0, (total, room) => total + room.totalAreaM2),
    );
  }

  Future<WorkspaceMaterialResult> _calculateMaterial({
    required List<MeasurementRoom> roomGroups,
    required List<MeasurementRoom> physicalRooms,
    required double directAreaM2,
    required WorkspaceProductSelection selection,
    required MeasurementOptimizationOptions options,
  }) {
    return switch (selection.product.calculationKind) {
      WorkspaceCalculationKind.coverage => _calculateCoverage(
        roomGroups: roomGroups,
        physicalRooms: physicalRooms,
        directAreaM2: directAreaM2,
        selection: selection,
        options: options,
      ),
      WorkspaceCalculationKind.linear => Future.value(
        _calculateLinear(roomGroups: roomGroups, selection: selection),
      ),
      WorkspaceCalculationKind.fixed => Future.value(
        _calculateFixed(roomGroups: roomGroups, selection: selection),
      ),
    };
  }

  Future<WorkspaceMaterialResult> _calculateCoverage({
    required List<MeasurementRoom> roomGroups,
    required List<MeasurementRoom> physicalRooms,
    required double directAreaM2,
    required WorkspaceProductSelection selection,
    required MeasurementOptimizationOptions options,
  }) async {
    final workspaceVariants = _effectiveVariants(selection);
    final overrideQuantity = selection.overrides?.quantity;
    if (overrideQuantity != null) {
      final variant = workspaceVariants.first;
      final purchasedArea =
          overrideQuantity * variant.widthMm! * variant.lengthMm! / 1000000;
      final requiredArea = roomGroups.fold(
        0.0,
        (total, room) => total + room.totalAreaM2,
      );
      final price = selection.overrides?.unitPrice ?? variant.unitPrice;
      return WorkspaceMaterialResult(
        selection: selection,
        lines: [
          WorkspaceMaterialLine(
            variant: variant,
            quantity: overrideQuantity,
            unitLabel: 'សន្លឹក',
            unitPrice: price,
            totalPrice: price * overrideQuantity,
            detail: 'បញ្ចូលចំនួនផ្ទាល់ខ្លួន',
          ),
        ],
        totalQuantity: overrideQuantity,
        totalPrice: price * overrideQuantity,
        wasteAreaM2: math.max(0, purchasedArea - requiredArea),
        wasteLinearM: 0,
      );
    }

    final measurementVariants = [
      for (final variant in workspaceVariants)
        variant.toMeasurementVariant(selection.product.id),
    ];
    final requestOptions = options.copyWith(
      sparePercent: selection.overrides?.sparePercent ?? options.sparePercent,
      orientationOverride: selection.overrides?.orientation,
      clearOrientationOverride: selection.overrides?.orientation == null,
    );
    MeasurementCandidate? candidate;
    final purchaseQuantities = <int, int>{};
    var wasteAreaM2 = 0.0;
    if (physicalRooms.isNotEmpty) {
      final optimization = await _optimizer.optimize(
        MeasurementOptimizationRequest(
          rooms: physicalRooms,
          variants: measurementVariants,
          options: requestOptions,
        ),
      );
      candidate = optimization.selectedCandidate;
      if (optimization.status != MeasurementStatus.ok || candidate == null) {
        throw StateError(
          'No valid cutting plan for ${selection.product.code}.',
        );
      }
      for (final quantity in candidate.quantities) {
        purchaseQuantities.update(
          quantity.variantId,
          (value) => value + quantity.purchaseQuantity,
          ifAbsent: () => quantity.purchaseQuantity,
        );
      }
      wasteAreaM2 += candidate.wasteAreaM2;
    }

    int? estimatedVariantId;
    if (directAreaM2 > 0) {
      final estimate = const AreaCoverageEstimator().estimate(
        areaM2: directAreaM2,
        variants: measurementVariants,
        options: requestOptions,
      );
      final areaCandidate = estimate.selectedCandidate;
      estimatedVariantId = areaCandidate.variantId;
      purchaseQuantities.update(
        areaCandidate.variantId,
        (value) => value + areaCandidate.purchaseQuantity,
        ifAbsent: () => areaCandidate.purchaseQuantity,
      );
      wasteAreaM2 += areaCandidate.wasteAreaM2;
    }
    final byId = {
      for (final variant in workspaceVariants) variant.variantId: variant,
    };
    final lines = <WorkspaceMaterialLine>[];
    for (final entry in purchaseQuantities.entries) {
      final variant = byId[entry.key];
      if (variant == null || entry.value <= 0) continue;
      final price = selection.overrides?.unitPrice ?? variant.unitPrice;
      final estimated = entry.key == estimatedVariantId;
      lines.add(
        WorkspaceMaterialLine(
          variant: variant,
          quantity: entry.value,
          unitLabel: 'សន្លឹក',
          unitPrice: price,
          totalPrice: price * entry.value,
          detail:
              '${_meters(variant.lengthMm!)}m${estimated ? ' • ប៉ាន់ស្មានតាម m²' : ''}',
        ),
      );
    }
    final total = lines.fold(0.0, (value, line) => value + line.totalPrice);
    return WorkspaceMaterialResult(
      selection: selection,
      lines: List.unmodifiable(lines),
      totalQuantity: lines.fold(0, (value, line) => value + line.quantity),
      totalPrice: total,
      wasteAreaM2: wasteAreaM2,
      wasteLinearM: 0,
      candidate: candidate,
      notice: directAreaM2 > 0 ? _cuttingEstimateNotice : null,
    );
  }

  WorkspaceMaterialResult _calculateLinear({
    required List<MeasurementRoom> roomGroups,
    required WorkspaceProductSelection selection,
  }) {
    final geometryGroups = roomGroups
        .where((room) => room.mode == MeasurementRoomMode.dimensions)
        .toList(growable: false);
    final hasDirectArea = geometryGroups.length != roomGroups.length;
    final overrideQuantity = selection.overrides?.quantity;
    if (geometryGroups.isEmpty) {
      if (overrideQuantity != null) {
        final variant = _effectiveVariants(selection).first;
        final price = selection.overrides?.unitPrice ?? variant.unitPrice;
        final isBundle = variant.priceTypeId == PriceTypeIds.saleBoxPrice;
        return WorkspaceMaterialResult(
          selection: selection,
          lines: [
            WorkspaceMaterialLine(
              variant: variant,
              quantity: overrideQuantity,
              unitLabel: isBundle ? 'បាច់' : 'ដើម',
              unitPrice: price,
              totalPrice: overrideQuantity * price,
              detail: 'បញ្ចូលចំនួនផ្ទាល់ខ្លួន',
            ),
          ],
          totalQuantity: overrideQuantity,
          totalPrice: overrideQuantity * price,
          wasteAreaM2: 0,
          wasteLinearM: 0,
        );
      }
      return WorkspaceMaterialResult(
        selection: selection,
        lines: const [],
        totalQuantity: 0,
        totalPrice: 0,
        wasteAreaM2: 0,
        wasteLinearM: 0,
        notice: _linearGeometryNotice,
      );
    }

    final perimeterM = geometryGroups.fold(
      0.0,
      (total, room) => total + room.totalPerimeterM!,
    );
    WorkspaceMaterialResult? best;
    for (final variant in _effectiveVariants(selection)) {
      final lengthM = variant.lengthMm! / 1000;
      final requiredPieces = math.max(1, (perimeterM / lengthM).ceil());
      final isBundle = variant.priceTypeId == PriceTypeIds.saleBoxPrice;
      final automaticQuantity = isBundle
          ? (requiredPieces / variant.itemsPerBundle).ceil()
          : requiredPieces;
      final quantity = overrideQuantity ?? automaticQuantity;
      final purchasedPieces = isBundle
          ? quantity * variant.itemsPerBundle
          : quantity;
      final price = selection.overrides?.unitPrice ?? variant.unitPrice;
      final result = WorkspaceMaterialResult(
        selection: selection,
        lines: [
          WorkspaceMaterialLine(
            variant: variant,
            quantity: quantity,
            unitLabel: isBundle ? 'បាច់' : 'ដើម',
            unitPrice: price,
            totalPrice: quantity * price,
            detail: isBundle
                ? '$requiredPieces ដើម / ${variant.itemsPerBundle} ក្នុងមួយបាច់'
                : '${_meters(variant.lengthMm!)}m',
          ),
        ],
        totalQuantity: quantity,
        totalPrice: quantity * price,
        wasteAreaM2: 0,
        wasteLinearM: math.max(0, purchasedPieces * lengthM - perimeterM),
        notice: hasDirectArea && overrideQuantity == null
            ? _linearGeometryNotice
            : null,
      );
      if (best == null ||
          result.wasteLinearM < best.wasteLinearM - 0.0001 ||
          ((result.wasteLinearM - best.wasteLinearM).abs() < 0.0001 &&
              result.totalPrice < best.totalPrice)) {
        best = result;
      }
    }
    return best!;
  }

  WorkspaceMaterialResult _calculateFixed({
    required List<MeasurementRoom> roomGroups,
    required WorkspaceProductSelection selection,
  }) {
    final variant = _effectiveVariants(selection).first;
    final physicalRoomCount = roomGroups.fold<int>(
      0,
      (total, room) => total + room.count,
    );
    final quantity = selection.overrides?.quantity ?? physicalRoomCount;
    final price = selection.overrides?.unitPrice ?? variant.unitPrice;
    final isBundle = variant.priceTypeId == PriceTypeIds.saleBoxPrice;
    return WorkspaceMaterialResult(
      selection: selection,
      lines: [
        WorkspaceMaterialLine(
          variant: variant,
          quantity: quantity,
          unitLabel: isBundle ? 'បាច់' : 'ឯកតា',
          unitPrice: price,
          totalPrice: quantity * price,
          detail: variant.label,
        ),
      ],
      totalQuantity: quantity,
      totalPrice: quantity * price,
      wasteAreaM2: 0,
      wasteLinearM: 0,
    );
  }

  List<WorkspaceProductVariant> _effectiveVariants(
    WorkspaceProductSelection selection,
  ) {
    final overrides = selection.overrides;
    var variants = selection.product.variants;
    if (overrides?.variantId != null) {
      variants = variants
          .where((variant) => variant.variantId == overrides!.variantId)
          .toList();
    }
    if (variants.isEmpty) variants = selection.product.variants;
    if (overrides?.customLengthMm != null) {
      final base = variants.first;
      variants = [
        base.copyWith(
          variantId: 900000 + base.variantId,
          lengthMm: overrides!.customLengthMm,
          label: '${overrides.customLengthMm!.toStringAsFixed(0)} mm (custom)',
        ),
      ];
    }
    if (overrides?.unitPrice != null) {
      variants = [
        for (final variant in variants)
          variant.copyWith(unitPrice: overrides!.unitPrice),
      ];
    }
    return variants;
  }

  bool _isValidRoomGroup(MeasurementRoom room) {
    if (room.count < 1) return false;
    return switch (room.mode) {
      MeasurementRoomMode.dimensions =>
        room.lengthM != null &&
            room.widthM != null &&
            room.lengthM!.isFinite &&
            room.widthM!.isFinite &&
            room.lengthM! > 0 &&
            room.widthM! > 0,
      MeasurementRoomMode.area =>
        room.directAreaM2 != null &&
            room.directAreaM2!.isFinite &&
            room.directAreaM2! > 0,
    };
  }

  String _meters(double lengthMm) {
    final meters = lengthMm / 1000;
    return meters == meters.roundToDouble()
        ? meters.toInt().toString()
        : meters.toStringAsFixed(1);
  }
}
