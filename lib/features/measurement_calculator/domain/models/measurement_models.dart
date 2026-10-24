enum MeasurementInputMode { dimensions, areaOnly, smartText }

enum MeasurementRoomMode { dimensions, area }

enum MeasurementOptimizeFor { lowestCost, lowestWaste, fewestJoints }

enum MeasurementOrientation { alongLength, alongWidth }

enum MeasurementStockMode { single, mixed }

enum MeasurementStatus {
  ok,
  invalidArgument,
  noSolution,
  limitExceeded,
  outOfMemory,
  internalError;

  factory MeasurementStatus.fromCode(int code) {
    return switch (code) {
      0 => MeasurementStatus.ok,
      1 => MeasurementStatus.invalidArgument,
      2 => MeasurementStatus.noSolution,
      3 => MeasurementStatus.limitExceeded,
      4 => MeasurementStatus.outOfMemory,
      _ => MeasurementStatus.internalError,
    };
  }
}

class MeasurementRoom {
  const MeasurementRoom({
    required this.id,
    required this.name,
    required this.lengthM,
    required this.widthM,
    this.count = 1,
  }) : mode = MeasurementRoomMode.dimensions,
       directAreaM2 = null;

  const MeasurementRoom.area({
    required this.id,
    required this.name,
    required this.directAreaM2,
    this.count = 1,
  }) : mode = MeasurementRoomMode.area,
       lengthM = null,
       widthM = null;

  final int id;
  final String name;
  final MeasurementRoomMode mode;
  final double? lengthM;
  final double? widthM;
  final double? directAreaM2;
  final int count;

  bool get hasGeometry => mode == MeasurementRoomMode.dimensions;

  double get areaPerRoomM2 => switch (mode) {
    MeasurementRoomMode.dimensions => (lengthM ?? 0) * (widthM ?? 0),
    MeasurementRoomMode.area => directAreaM2 ?? 0,
  };
  double get totalAreaM2 => areaPerRoomM2 * count;

  /// Retained for callers that previously summed individual room areas.
  double get areaM2 => totalAreaM2;

  double? get perimeterPerRoomM =>
      hasGeometry ? 2 * (lengthM! + widthM!) : null;
  double? get totalPerimeterM =>
      perimeterPerRoomM == null ? null : perimeterPerRoomM! * count;
}

List<MeasurementRoom> expandMeasurementRooms(Iterable<MeasurementRoom> groups) {
  final physicalRooms = <MeasurementRoom>[];
  for (final group in groups) {
    final validInput = switch (group.mode) {
      MeasurementRoomMode.dimensions =>
        group.lengthM != null &&
            group.widthM != null &&
            group.lengthM!.isFinite &&
            group.widthM!.isFinite &&
            group.lengthM! > 0 &&
            group.widthM! > 0,
      MeasurementRoomMode.area =>
        group.directAreaM2 != null &&
            group.directAreaM2!.isFinite &&
            group.directAreaM2! > 0,
    };
    if (group.count < 1 || !validInput) {
      throw const FormatException(
        'Room input must be greater than 0 and count at least 1.',
      );
    }
    for (var instance = 0; instance < group.count; instance++) {
      final id = group.count == 1 ? group.id : group.id * 10000 + instance + 1;
      final name = group.count == 1
          ? group.name
          : '${group.name} ${instance + 1}/${group.count}';
      physicalRooms.add(switch (group.mode) {
        MeasurementRoomMode.dimensions => MeasurementRoom(
          id: id,
          name: name,
          lengthM: group.lengthM!,
          widthM: group.widthM!,
        ),
        MeasurementRoomMode.area => MeasurementRoom.area(
          id: id,
          name: name,
          directAreaM2: group.directAreaM2!,
        ),
      });
    }
  }
  return List.unmodifiable(physicalRooms);
}

class MeasurementProductVariant {
  const MeasurementProductVariant({
    required this.variantId,
    required this.label,
    required this.widthMm,
    required this.lengthMm,
    required this.thicknessMm,
    required this.unitPrice,
    this.materialId,
    this.productFamilyId,
    this.productCode,
  });

  final int variantId;
  final String label;
  final double widthMm;
  final double lengthMm;
  final double thicknessMm;
  final double unitPrice;
  final String? materialId;
  final String? productFamilyId;
  final String? productCode;

  double get areaM2 => widthMm * lengthMm / 1000000;
}

class MeasurementProductDefaults {
  const MeasurementProductDefaults._();

  static const variants = [
    MeasurementProductVariant(
      variantId: 3000,
      label: '400 × 10 × 3000 mm',
      widthMm: 400,
      lengthMm: 3000,
      thicknessMm: 10,
      unitPrice: 9,
    ),
    MeasurementProductVariant(
      variantId: 4000,
      label: '400 × 10 × 4000 mm',
      widthMm: 400,
      lengthMm: 4000,
      thicknessMm: 10,
      unitPrice: 12,
    ),
  ];
}

class MeasurementOptimizationOptions {
  const MeasurementOptimizationOptions({
    this.optimizeFor = MeasurementOptimizeFor.lowestWaste,
    this.allowJoints = true,
    this.reuseOffcuts = true,
    this.projectMode = true,
    this.sparePercent = 0,
    this.debugDiagnostics = false,
    this.maxSearchCandidates = 200000,
    this.orientationOverride,
  });

  final MeasurementOptimizeFor optimizeFor;
  final bool allowJoints;
  final bool reuseOffcuts;
  final bool projectMode;
  final double sparePercent;
  final bool debugDiagnostics;
  final int maxSearchCandidates;
  final MeasurementOrientation? orientationOverride;

  MeasurementOptimizationOptions copyWith({
    MeasurementOptimizeFor? optimizeFor,
    bool? allowJoints,
    bool? reuseOffcuts,
    bool? projectMode,
    double? sparePercent,
    bool? debugDiagnostics,
    int? maxSearchCandidates,
    MeasurementOrientation? orientationOverride,
    bool clearOrientationOverride = false,
  }) {
    return MeasurementOptimizationOptions(
      optimizeFor: optimizeFor ?? this.optimizeFor,
      allowJoints: allowJoints ?? this.allowJoints,
      reuseOffcuts: reuseOffcuts ?? this.reuseOffcuts,
      projectMode: projectMode ?? this.projectMode,
      sparePercent: sparePercent ?? this.sparePercent,
      debugDiagnostics: debugDiagnostics ?? this.debugDiagnostics,
      maxSearchCandidates: maxSearchCandidates ?? this.maxSearchCandidates,
      orientationOverride: clearOrientationOverride
          ? null
          : orientationOverride ?? this.orientationOverride,
    );
  }
}

class MeasurementOptimizationRequest {
  const MeasurementOptimizationRequest({
    required this.rooms,
    required this.variants,
    required this.options,
  });

  final List<MeasurementRoom> rooms;
  final List<MeasurementProductVariant> variants;
  final MeasurementOptimizationOptions options;
}

class MeasurementVariantQuantity {
  const MeasurementVariantQuantity({
    required this.variantId,
    required this.baseQuantity,
    required this.reserveQuantity,
    required this.purchaseQuantity,
  });

  final int variantId;
  final int baseQuantity;
  final int reserveQuantity;
  final int purchaseQuantity;
}

class MeasurementCutSegment {
  const MeasurementCutSegment({
    required this.roomId,
    required this.laneIndex,
    required this.sourceVariantId,
    required this.sourcePieceIndex,
    required this.segmentIndex,
    required this.sourceLengthMm,
    required this.usedLengthMm,
    required this.remainderLengthMm,
    required this.reusedOffcut,
  });

  final int roomId;
  final int laneIndex;
  final int sourceVariantId;
  final int sourcePieceIndex;
  final int segmentIndex;
  final double sourceLengthMm;
  final double usedLengthMm;
  final double remainderLengthMm;
  final bool reusedOffcut;
}

class MeasurementRoomLayout {
  const MeasurementRoomLayout({
    required this.roomId,
    required this.orientation,
    required this.laneCount,
    required this.longitudinalSpanMm,
    required this.crossSpanMm,
  });

  final int roomId;
  final MeasurementOrientation orientation;
  final int laneCount;
  final double longitudinalSpanMm;
  final double crossSpanMm;
}

class MeasurementCandidate {
  const MeasurementCandidate({
    required this.candidateId,
    required this.valid,
    required this.stockMode,
    required this.singleVariantId,
    required this.quantities,
    required this.cuts,
    required this.roomLayouts,
    required this.basePieceCount,
    required this.reservePieceCount,
    required this.purchasePieceCount,
    required this.jointCount,
    required this.requiredAreaM2,
    required this.purchasedAreaM2,
    required this.wasteAreaM2,
    required this.wastePercent,
    required this.totalCost,
    required this.score,
  });

  final int candidateId;
  final bool valid;
  final MeasurementStockMode stockMode;
  final int? singleVariantId;
  final List<MeasurementVariantQuantity> quantities;
  final List<MeasurementCutSegment> cuts;
  final List<MeasurementRoomLayout> roomLayouts;
  final int basePieceCount;
  final int reservePieceCount;
  final int purchasePieceCount;
  final int jointCount;
  final double requiredAreaM2;
  final double purchasedAreaM2;
  final double wasteAreaM2;
  final double wastePercent;
  final double totalCost;
  final double score;
}

class MeasurementDiagnostics {
  const MeasurementDiagnostics({
    required this.candidatesConsidered,
    required this.candidatesPruned,
    required this.executionTimeUs,
    required this.cuts,
    required this.offcutsCreated,
    required this.offcutsReused,
  });

  final int candidatesConsidered;
  final int candidatesPruned;
  final int executionTimeUs;
  final int cuts;
  final int offcutsCreated;
  final int offcutsReused;
}

class MeasurementOptimizationResult {
  const MeasurementOptimizationResult({
    required this.status,
    required this.selectedCandidateIndex,
    required this.candidates,
    required this.diagnostics,
  });

  final MeasurementStatus status;
  final int selectedCandidateIndex;
  final List<MeasurementCandidate> candidates;
  final MeasurementDiagnostics diagnostics;

  MeasurementCandidate? get selectedCandidate {
    if (selectedCandidateIndex < 0 ||
        selectedCandidateIndex >= candidates.length) {
      return null;
    }
    return candidates[selectedCandidateIndex];
  }
}

class AreaCoverageCandidate {
  const AreaCoverageCandidate({
    required this.variantId,
    required this.baseQuantity,
    required this.reserveQuantity,
    required this.purchaseQuantity,
    required this.requiredAreaM2,
    required this.purchasedAreaM2,
    required this.wasteAreaM2,
    required this.wastePercent,
    required this.totalCost,
  });

  final int variantId;
  final int baseQuantity;
  final int reserveQuantity;
  final int purchaseQuantity;
  final double requiredAreaM2;
  final double purchasedAreaM2;
  final double wasteAreaM2;
  final double wastePercent;
  final double totalCost;
}

class AreaCoverageResult {
  const AreaCoverageResult({
    required this.candidates,
    required this.selectedCandidateIndex,
  });

  final List<AreaCoverageCandidate> candidates;
  final int selectedCandidateIndex;

  AreaCoverageCandidate get selectedCandidate =>
      candidates[selectedCandidateIndex];
}
