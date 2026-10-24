import 'dart:ffi';

import '../domain/models/measurement_models.dart';
import 'measurement_bindings.g.dart';

class MeasurementNativeMapper {
  const MeasurementNativeMapper();

  MeasurementOptimizationResult fromNative(
    Pointer<MeasurementResultC> resultPointer,
  ) {
    final result = resultPointer.ref;
    final candidates = <MeasurementCandidate>[];
    for (
      var candidateIndex = 0;
      candidateIndex < result.candidate_count;
      candidateIndex++
    ) {
      final native = (result.candidates + candidateIndex).ref;
      final quantities = <MeasurementVariantQuantity>[];
      for (var i = 0; i < native.quantity_count; i++) {
        final quantity = (result.quantities + native.quantity_offset + i).ref;
        quantities.add(
          MeasurementVariantQuantity(
            variantId: quantity.variant_id,
            baseQuantity: quantity.base_quantity,
            reserveQuantity: quantity.reserve_quantity,
            purchaseQuantity: quantity.purchase_quantity,
          ),
        );
      }
      final cuts = <MeasurementCutSegment>[];
      for (var i = 0; i < native.cut_count; i++) {
        final cut = (result.cuts + native.cut_offset + i).ref;
        cuts.add(
          MeasurementCutSegment(
            roomId: cut.room_id,
            laneIndex: cut.lane_index,
            sourceVariantId: cut.source_variant_id,
            sourcePieceIndex: cut.source_piece_index,
            segmentIndex: cut.segment_index,
            sourceLengthMm: cut.source_length_mm,
            usedLengthMm: cut.used_length_mm,
            remainderLengthMm: cut.remainder_length_mm,
            reusedOffcut: cut.reused_offcut != 0,
          ),
        );
      }
      final layouts = <MeasurementRoomLayout>[];
      for (var i = 0; i < native.room_layout_count; i++) {
        final layout =
            (result.room_layouts + native.room_layout_offset + i).ref;
        layouts.add(
          MeasurementRoomLayout(
            roomId: layout.room_id,
            orientation: layout.orientation == 0
                ? MeasurementOrientation.alongLength
                : MeasurementOrientation.alongWidth,
            laneCount: layout.lane_count,
            longitudinalSpanMm: layout.longitudinal_span_mm,
            crossSpanMm: layout.cross_span_mm,
          ),
        );
      }
      candidates.add(
        MeasurementCandidate(
          candidateId: native.candidate_id,
          valid: native.valid != 0,
          stockMode: native.stock_mode == 0
              ? MeasurementStockMode.single
              : MeasurementStockMode.mixed,
          singleVariantId: native.single_variant_id < 0
              ? null
              : native.single_variant_id,
          quantities: List.unmodifiable(quantities),
          cuts: List.unmodifiable(cuts),
          roomLayouts: List.unmodifiable(layouts),
          basePieceCount: native.base_piece_count,
          reservePieceCount: native.reserve_piece_count,
          purchasePieceCount: native.purchase_piece_count,
          jointCount: native.joint_count,
          requiredAreaM2: native.required_area_m2,
          purchasedAreaM2: native.purchased_area_m2,
          wasteAreaM2: native.waste_area_m2,
          wastePercent: native.waste_percent,
          totalCost: native.total_cost,
          score: native.score,
        ),
      );
    }
    final diagnostics = result.diagnostics;
    return MeasurementOptimizationResult(
      status: MeasurementStatus.fromCode(result.status),
      selectedCandidateIndex: result.selected_candidate_index,
      candidates: List.unmodifiable(candidates),
      diagnostics: MeasurementDiagnostics(
        candidatesConsidered: diagnostics.candidates_considered,
        candidatesPruned: diagnostics.candidates_pruned,
        executionTimeUs: diagnostics.execution_time_us,
        cuts: diagnostics.cuts,
        offcutsCreated: diagnostics.offcuts_created,
        offcutsReused: diagnostics.offcuts_reused,
      ),
    );
  }
}
