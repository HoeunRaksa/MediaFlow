#include "measurement_engine.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <vector>

#if defined(_MSC_VER) && defined(_DEBUG)
#include <crtdbg.h>
#endif

namespace {

int failures = 0;

#define CHECK(condition)                                                       \
  do {                                                                         \
    if (!(condition)) {                                                        \
      std::cerr << __FUNCTION__ << ":" << __LINE__                            \
                << " check failed: " #condition "\n";                        \
      ++failures;                                                              \
      return;                                                                  \
    }                                                                          \
  } while (false)

struct RunResult {
  MeasurementResultC value{};
  int32_t status = MEASUREMENT_STATUS_INTERNAL_ERROR;

  ~RunResult() { measurement_result_release(&value); }
};

MeasurementOptionsC options(uint8_t optimize_for =
                                MEASUREMENT_OPTIMIZE_LOWEST_WASTE,
                            bool joints = true,
                            bool reuse = true,
                            bool project = true,
                            double spare = 0,
                            uint8_t orientation = MEASUREMENT_ORIENTATION_AUTO) {
  return MeasurementOptionsC{optimize_for,
                             static_cast<uint8_t>(joints),
                             static_cast<uint8_t>(reuse),
                             static_cast<uint8_t>(project),
                             1,
                             orientation,
                             0,
                             0,
                             spare,
                             200000};
}

void run(const std::vector<MeasurementRoomC>& rooms,
         const std::vector<MeasurementProductVariantC>& variants,
         const MeasurementOptionsC& calculation_options,
         RunResult* output) {
  MeasurementHandle* handle = measurement_engine_create();
  CHECK(handle != nullptr);
  const MeasurementRequestC request{rooms.data(),
                                    static_cast<uint32_t>(rooms.size()),
                                    variants.data(),
                                    static_cast<uint32_t>(variants.size()),
                                    calculation_options};
  output->status = measurement_optimize(handle, &request, &output->value);
  measurement_engine_destroy(handle);
}

const MeasurementCandidateC* selected(const RunResult& result) {
  if (result.value.selected_candidate_index < 0) return nullptr;
  return &result.value.candidates[result.value.selected_candidate_index];
}

const MeasurementCandidateC* candidate_for(const RunResult& result,
                                            int32_t variant_id) {
  for (uint32_t i = 0; i < result.value.candidate_count; ++i) {
    if (result.value.candidates[i].single_variant_id == variant_id) {
      return &result.value.candidates[i];
    }
  }
  return nullptr;
}

const MeasurementCandidateC* mixed_candidate(const RunResult& result) {
  for (uint32_t i = 0; i < result.value.candidate_count; ++i) {
    if (result.value.candidates[i].stock_mode == MEASUREMENT_STOCK_MIXED) {
      return &result.value.candidates[i];
    }
  }
  return nullptr;
}

void exact_fit() {
  RunResult result;
  run({{1, 3000, 400}}, {{30, 400, 3000, 10, 9}}, options(), &result);
  CHECK(result.status == MEASUREMENT_STATUS_OK);
  CHECK(selected(result)->base_piece_count == 1);
  CHECK(std::fabs(selected(result)->waste_area_m2) < 1e-7);
  CHECK(selected(result)->joint_count == 0);
}

void partial_fit_and_cut() {
  RunResult result;
  run({{1, 2400, 400}}, {{40, 400, 4000, 10, 12}}, options(), &result);
  CHECK(result.status == MEASUREMENT_STATUS_OK);
  CHECK(result.value.cut_count >= 1);
  CHECK(std::fabs(result.value.cuts[0].remainder_length_mm - 1600) < 1e-7);
  CHECK(std::fabs(selected(result)->waste_area_m2 - 0.64) < 1e-7);
}

void stock_modes_and_reference_geometry() {
  RunResult result;
  run({{1, 6000, 4200}},
      {{30, 400, 3000, 10, 9}, {40, 400, 4000, 10, 12}},
      options(MEASUREMENT_OPTIMIZE_LOWEST_WASTE), &result);
  CHECK(result.status == MEASUREMENT_STATUS_OK);
  const auto* three = candidate_for(result, 30);
  const auto* four = candidate_for(result, 40);
  const auto* mixed = mixed_candidate(result);
  CHECK(three != nullptr && three->valid != 0);
  CHECK(four != nullptr && four->valid != 0);
  CHECK(mixed != nullptr && mixed->valid != 0);
  CHECK(three->joint_count > 0);
  CHECK(four->joint_count > 0);
  CHECK(mixed->quantity_count == 2);
  CHECK(three->base_piece_count == 21);
  CHECK(std::fabs(three->total_cost - 189) < 1e-7);
  CHECK(std::fabs(three->waste_area_m2) < 1e-7);
  CHECK(four->base_piece_count == 16);
  CHECK(std::fabs(four->total_cost - 192) < 1e-7);
  CHECK(std::fabs(four->waste_area_m2 - 0.4) < 1e-7);

  // Manual geometry check: along width gives 15 lanes x 4.2m = 63m of
  // 400mm panel, exactly the 25.2m2 room area. Along length would need
  // 11 lanes x 6m = 66m, so the selected layout must rotate 90 degrees.
  const auto* best = selected(result);
  CHECK(best != nullptr);
  const auto& layout = result.value.room_layouts[best->room_layout_offset];
  CHECK(layout.orientation == MEASUREMENT_ORIENTATION_ALONG_WIDTH);
  CHECK(layout.lane_count == 15);
  CHECK(std::fabs(layout.longitudinal_span_mm - 4200) < 1e-7);
  double used_length = 0;
  for (uint32_t i = 0; i < best->cut_count; ++i) {
    used_length += result.value.cuts[best->cut_offset + i].used_length_mm;
  }
  CHECK(std::fabs(used_length - 63000) < 1e-7);
  CHECK(result.value.diagnostics.offcuts_reused > 0);
}

void clearly_better_orientation() {
  RunResult result;
  run({{1, 10000, 1000}}, {{40, 400, 4000, 10, 12}}, options(), &result);
  CHECK(result.status == MEASUREMENT_STATUS_OK);
  const auto* best = selected(result);
  CHECK(best != nullptr);
  const auto& layout = result.value.room_layouts[best->room_layout_offset];
  CHECK(layout.orientation == MEASUREMENT_ORIENTATION_ALONG_WIDTH);
}

void joints_disabled_and_enabled() {
  const std::vector<MeasurementRoomC> rooms{{1, 6000, 4200}};
  const std::vector<MeasurementProductVariantC> variants{
      {30, 400, 3000, 10, 9}, {40, 400, 4000, 10, 12}};
  RunResult disabled;
  run(rooms, variants, options(MEASUREMENT_OPTIMIZE_LOWEST_WASTE, false),
      &disabled);
  CHECK(disabled.status == MEASUREMENT_STATUS_NO_SOLUTION);
  RunResult enabled;
  run(rooms, variants, options(), &enabled);
  CHECK(enabled.status == MEASUREMENT_STATUS_OK);
  CHECK(selected(enabled)->joint_count > 0);
}

void offcut_reuse_in_room() {
  const std::vector<MeasurementRoomC> rooms{{1, 1600, 800}};
  const std::vector<MeasurementProductVariantC> variants{{40, 400, 4000, 10, 12}};
  RunResult no_reuse;
  run(rooms, variants,
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST, false, false), &no_reuse);
  RunResult reuse;
  run(rooms, variants,
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST, false, true), &reuse);
  CHECK(selected(no_reuse)->base_piece_count == 2);
  CHECK(selected(reuse)->base_piece_count == 1);
  CHECK(reuse.value.diagnostics.offcuts_reused >= 1);
}

void offcut_reuse_across_rooms() {
  const std::vector<MeasurementRoomC> rooms{{1, 1600, 400}, {2, 1600, 400}};
  const std::vector<MeasurementProductVariantC> variants{{40, 400, 4000, 10, 12}};
  RunResult separate;
  run(rooms, variants,
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST, false, true, false),
      &separate);
  RunResult project;
  run(rooms, variants,
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST, false, true, true), &project);
  CHECK(selected(separate)->base_piece_count == 2);
  CHECK(selected(project)->base_piece_count == 1);
}

void width_rounding_decimal_and_tiny() {
  RunResult rounded;
  run({{1, 3000.5, 900.25}}, {{40, 400, 4000, 10, 12}}, options(),
      &rounded);
  CHECK(rounded.status == MEASUREMENT_STATUS_OK);
  const auto* best = selected(rounded);
  CHECK(best != nullptr);
  const auto& layout = rounded.value.room_layouts[best->room_layout_offset];
  const uint32_t expected_lanes = layout.orientation ==
                                          MEASUREMENT_ORIENTATION_ALONG_LENGTH
                                      ? 3
                                      : 8;
  CHECK(layout.lane_count == expected_lanes);
  RunResult tiny;
  run({{1, 1, 1}}, {{40, 400, 4000, 10, 12}}, options(), &tiny);
  CHECK(tiny.status == MEASUREMENT_STATUS_OK);
  CHECK(selected(tiny)->base_piece_count == 1);
}

void invalid_and_large() {
  RunResult invalid;
  run({{1, 0, 400}}, {{40, 400, 4000, 10, 12}}, options(), &invalid);
  CHECK(invalid.status == MEASUREMENT_STATUS_INVALID_ARGUMENT);
  RunResult negative;
  run({{1, -1, 400}}, {{40, 400, 4000, 10, 12}}, options(), &negative);
  CHECK(negative.status == MEASUREMENT_STATUS_INVALID_ARGUMENT);
  RunResult large;
  run({{1, 100000, 50000}}, {{40, 400, 4000, 10, 12}}, options(), &large);
  CHECK(large.status == MEASUREMENT_STATUS_OK);
  CHECK(selected(large)->base_piece_count > 1000);
}

void spare_and_price_preference() {
  RunResult spare;
  run({{1, 3000, 400}}, {{30, 400, 3000, 10, 9}},
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST, true, true, true, 10),
      &spare);
  CHECK(selected(spare)->base_piece_count == 1);
  CHECK(selected(spare)->reserve_piece_count == 1);
  CHECK(selected(spare)->purchase_piece_count == 2);

  RunResult price;
  run({{1, 4000, 400}},
      {{30, 400, 3000, 10, 1}, {40, 400, 4000, 10, 100}},
      options(MEASUREMENT_OPTIMIZE_LOWEST_COST), &price);
  CHECK(selected(price)->single_variant_id == 30);
}

void deterministic_ties() {
  RunResult first;
  RunResult second;
  const std::vector<MeasurementRoomC> rooms{{1, 3000, 400}};
  const std::vector<MeasurementProductVariantC> variants{
      {30, 400, 3000, 10, 9}, {31, 400, 3000, 10, 9}};
  run(rooms, variants, options(MEASUREMENT_OPTIMIZE_LOWEST_COST), &first);
  run(rooms, variants, options(MEASUREMENT_OPTIMIZE_LOWEST_COST), &second);
  CHECK(first.value.selected_candidate_index == second.value.selected_candidate_index);
  CHECK(selected(first)->single_variant_id == 30);
  RunResult waste_tie;
  run(rooms, variants, options(MEASUREMENT_OPTIMIZE_LOWEST_WASTE), &waste_tie);
  CHECK(selected(waste_tie)->single_variant_id == 30);
}

void forced_orientation() {
  RunResult length;
  run({{1, 6000, 4200}}, {{40, 400, 4000, 10, 12}},
      options(MEASUREMENT_OPTIMIZE_LOWEST_WASTE, true, true, true, 0,
              MEASUREMENT_ORIENTATION_FORCE_LENGTH),
      &length);
  CHECK(length.status == MEASUREMENT_STATUS_OK);
  const auto* length_candidate = selected(length);
  CHECK(length_candidate != nullptr);
  CHECK(length.value.room_layouts[length_candidate->room_layout_offset]
            .orientation == MEASUREMENT_ORIENTATION_ALONG_LENGTH);

  RunResult width;
  run({{1, 6000, 4200}}, {{40, 400, 4000, 10, 12}},
      options(MEASUREMENT_OPTIMIZE_LOWEST_WASTE, true, true, true, 0,
              MEASUREMENT_ORIENTATION_FORCE_WIDTH),
      &width);
  CHECK(width.status == MEASUREMENT_STATUS_OK);
  const auto* width_candidate = selected(width);
  CHECK(width_candidate != nullptr);
  CHECK(width.value.room_layouts[width_candidate->room_layout_offset]
            .orientation == MEASUREMENT_ORIENTATION_ALONG_WIDTH);
}

void repeated_create_optimize_release() {
  const std::vector<MeasurementRoomC> rooms{{1, 6000, 4200}};
  const std::vector<MeasurementProductVariantC> variants{
      {30, 400, 3000, 10, 9}, {40, 400, 4000, 10, 12}};
  const MeasurementRequestC request{
      rooms.data(), 1, variants.data(), 2, options()};
  MeasurementHandle* handle = measurement_engine_create();
  CHECK(handle != nullptr);
#if defined(_MSC_VER) && defined(_DEBUG)
  _CrtMemState before{};
  _CrtMemState after{};
  _CrtMemState difference{};
  _CrtMemCheckpoint(&before);
#endif
  for (uint32_t i = 0; i < 2000; ++i) {
    MeasurementResultC result{};
    CHECK(measurement_optimize(handle, &request, &result) ==
          MEASUREMENT_STATUS_OK);
    measurement_result_release(&result);
    CHECK(result.candidates == nullptr);
    CHECK(result.cuts == nullptr);
  }
#if defined(_MSC_VER) && defined(_DEBUG)
  _CrtMemCheckpoint(&after);
  CHECK(_CrtMemDifference(&difference, &before, &after) == 0);
#endif
  measurement_engine_destroy(handle);
}

}  // namespace

int main() {
  exact_fit();
  partial_fit_and_cut();
  stock_modes_and_reference_geometry();
  clearly_better_orientation();
  joints_disabled_and_enabled();
  offcut_reuse_in_room();
  offcut_reuse_across_rooms();
  width_rounding_decimal_and_tiny();
  invalid_and_large();
  spare_and_price_preference();
  deterministic_ties();
  forced_orientation();
  repeated_create_optimize_release();
  if (failures != 0) {
    std::cerr << failures << " native measurement test(s) failed\n";
    return 1;
  }
  std::cout << "All native measurement tests passed\n";
  return 0;
}
