import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_bindings.g.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_mapper.dart';

void main() {
  test('flat native buffers map to owned Dart result', () {
    final result = calloc<MeasurementResultC>();
    final candidates = calloc<MeasurementCandidateC>(1);
    final quantities = calloc<MeasurementVariantQuantityC>(1);
    final cuts = calloc<MeasurementCutSegmentC>(1);
    final layouts = calloc<MeasurementRoomLayoutC>(1);
    addTearDown(() {
      calloc.free(layouts);
      calloc.free(cuts);
      calloc.free(quantities);
      calloc.free(candidates);
      calloc.free(result);
    });

    result.ref
      ..status = 0
      ..selected_candidate_index = 0
      ..candidates = candidates
      ..candidate_count = 1
      ..quantities = quantities
      ..quantity_count = 1
      ..cuts = cuts
      ..cut_count = 1
      ..room_layouts = layouts
      ..room_layout_count = 1;
    result.ref.diagnostics
      ..candidates_considered = 8
      ..candidates_pruned = 2
      ..execution_time_us = 35
      ..cuts = 1
      ..offcuts_created = 1
      ..offcuts_reused = 0;
    candidates.ref
      ..candidate_id = 7
      ..single_variant_id = 3000
      ..quantity_offset = 0
      ..quantity_count = 1
      ..cut_offset = 0
      ..cut_count = 1
      ..room_layout_offset = 0
      ..room_layout_count = 1
      ..base_piece_count = 1
      ..purchase_piece_count = 1
      ..valid = 1
      ..stock_mode = 0
      ..required_area_m2 = 1
      ..purchased_area_m2 = 1.2
      ..waste_area_m2 = 0.2
      ..waste_percent = 16.666
      ..total_cost = 9;
    quantities.ref
      ..variant_id = 3000
      ..base_quantity = 1
      ..purchase_quantity = 1;
    cuts.ref
      ..room_id = 1
      ..lane_index = 0
      ..source_variant_id = 3000
      ..source_piece_index = 0
      ..source_length_mm = 3000
      ..used_length_mm = 2400
      ..remainder_length_mm = 600;
    layouts.ref
      ..room_id = 1
      ..orientation = 1
      ..lane_count = 3
      ..longitudinal_span_mm = 2400
      ..cross_span_mm = 900;

    final mapped = const MeasurementNativeMapper().fromNative(result);
    expect(mapped.status, MeasurementStatus.ok);
    expect(mapped.selectedCandidate!.candidateId, 7);
    expect(mapped.selectedCandidate!.quantities.single.variantId, 3000);
    expect(mapped.selectedCandidate!.cuts.single.remainderLengthMm, 600);
    expect(
      mapped.selectedCandidate!.roomLayouts.single.orientation,
      MeasurementOrientation.alongWidth,
    );
    expect(mapped.diagnostics.candidatesConsidered, 8);
  });
}
