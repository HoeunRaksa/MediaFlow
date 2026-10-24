import 'dart:math' as math;

import 'package:material_quote_pro/core/utils/quantity_rounding.dart';

class CeilingVRoomGroup {
  const CeilingVRoomGroup({
    required this.lengthM,
    required this.widthM,
    required this.roomCount,
  });

  final double lengthM;
  final double widthM;
  final int roomCount;
}

class CeilingVExtraResult {
  const CeilingVExtraResult({
    required this.actualVRequired,
    required this.existingVQuantity,
    required this.extraVToBuy,
  });

  final int actualVRequired;
  final int existingVQuantity;
  final int extraVToBuy;
}

class CeilingVExtraCalculator {
  const CeilingVExtraCalculator();

  static const usableLengthPerPieceM = 2.90;

  CeilingVExtraResult calculate({
    required Iterable<CeilingVRoomGroup> roomGroups,
    required int existingVQuantity,
  }) {
    var totalRaw = 0.0;
    for (final group in roomGroups) {
      if (group.lengthM <= 0 || group.widthM <= 0 || group.roomCount <= 0) {
        continue;
      }
      final perimeterPerRoomM = (group.lengthM + group.widthM) * 2;
      final groupRaw =
          (perimeterPerRoomM / usableLengthPerPieceM) * group.roomCount;
      totalRaw += groupRaw;
    }

    final actualVRequired = roundCeilingQuantity(totalRaw);
    final normalizedExisting = math.max(0, existingVQuantity);
    return CeilingVExtraResult(
      actualVRequired: actualVRequired,
      existingVQuantity: normalizedExisting,
      extraVToBuy: math.max(0, actualVRequired - normalizedExisting),
    );
  }
}
