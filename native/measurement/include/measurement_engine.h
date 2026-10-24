#ifndef MATERIAL_QUOTE_PRO_MEASUREMENT_ENGINE_H_
#define MATERIAL_QUOTE_PRO_MEASUREMENT_ENGINE_H_

#include <stdint.h>

#if defined(_WIN32)
#if defined(MEASUREMENT_ENGINE_BUILD)
#define MEASUREMENT_API __declspec(dllexport)
#else
#define MEASUREMENT_API __declspec(dllimport)
#endif
#else
#define MEASUREMENT_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct MeasurementHandle MeasurementHandle;

enum MeasurementStatusC {
  MEASUREMENT_STATUS_OK = 0,
  MEASUREMENT_STATUS_INVALID_ARGUMENT = 1,
  MEASUREMENT_STATUS_NO_SOLUTION = 2,
  MEASUREMENT_STATUS_LIMIT_EXCEEDED = 3,
  MEASUREMENT_STATUS_OUT_OF_MEMORY = 4,
  MEASUREMENT_STATUS_INTERNAL_ERROR = 5
};

enum MeasurementOptimizeForC {
  MEASUREMENT_OPTIMIZE_LOWEST_COST = 0,
  MEASUREMENT_OPTIMIZE_LOWEST_WASTE = 1,
  MEASUREMENT_OPTIMIZE_FEWEST_JOINTS = 2
};

enum MeasurementOrientationC {
  MEASUREMENT_ORIENTATION_ALONG_LENGTH = 0,
  MEASUREMENT_ORIENTATION_ALONG_WIDTH = 1
};

enum MeasurementOrientationPreferenceC {
  MEASUREMENT_ORIENTATION_AUTO = 0,
  MEASUREMENT_ORIENTATION_FORCE_LENGTH = 1,
  MEASUREMENT_ORIENTATION_FORCE_WIDTH = 2
};

enum MeasurementStockModeC {
  MEASUREMENT_STOCK_SINGLE = 0,
  MEASUREMENT_STOCK_MIXED = 1
};

typedef struct MeasurementRoomC {
  int32_t room_id;
  double length_mm;
  double width_mm;
} MeasurementRoomC;

typedef struct MeasurementProductVariantC {
  int32_t variant_id;
  double width_mm;
  double length_mm;
  double thickness_mm;
  double unit_price;
} MeasurementProductVariantC;

typedef struct MeasurementOptionsC {
  uint8_t optimize_for;
  uint8_t allow_joints;
  uint8_t reuse_offcuts;
  uint8_t project_mode;
  uint8_t debug_diagnostics;
  uint8_t reserved_0;
  uint8_t reserved_1;
  uint8_t reserved_2;
  double spare_percent;
  uint32_t max_search_candidates;
} MeasurementOptionsC;

typedef struct MeasurementRequestC {
  const MeasurementRoomC* rooms;
  uint32_t room_count;
  const MeasurementProductVariantC* variants;
  uint32_t variant_count;
  MeasurementOptionsC options;
} MeasurementRequestC;

typedef struct MeasurementCandidateC {
  int32_t candidate_id;
  int32_t single_variant_id;
  uint32_t quantity_offset;
  uint32_t quantity_count;
  uint32_t cut_offset;
  uint32_t cut_count;
  uint32_t room_layout_offset;
  uint32_t room_layout_count;
  uint32_t base_piece_count;
  uint32_t reserve_piece_count;
  uint32_t purchase_piece_count;
  uint32_t joint_count;
  uint8_t valid;
  uint8_t stock_mode;
  uint8_t reserved_0;
  uint8_t reserved_1;
  double required_area_m2;
  double purchased_area_m2;
  double waste_area_m2;
  double waste_percent;
  double total_cost;
  double score;
} MeasurementCandidateC;

typedef struct MeasurementVariantQuantityC {
  uint32_t candidate_index;
  int32_t variant_id;
  uint32_t base_quantity;
  uint32_t reserve_quantity;
  uint32_t purchase_quantity;
} MeasurementVariantQuantityC;

typedef struct MeasurementCutSegmentC {
  uint32_t candidate_index;
  int32_t room_id;
  uint32_t lane_index;
  int32_t source_variant_id;
  uint32_t source_piece_index;
  uint32_t segment_index;
  uint8_t reused_offcut;
  uint8_t reserved_0;
  uint8_t reserved_1;
  uint8_t reserved_2;
  double source_length_mm;
  double used_length_mm;
  double remainder_length_mm;
} MeasurementCutSegmentC;

typedef struct MeasurementRoomLayoutC {
  uint32_t candidate_index;
  int32_t room_id;
  uint8_t orientation;
  uint8_t reserved_0;
  uint8_t reserved_1;
  uint8_t reserved_2;
  uint32_t lane_count;
  double longitudinal_span_mm;
  double cross_span_mm;
} MeasurementRoomLayoutC;

typedef struct MeasurementDiagnosticsC {
  uint64_t candidates_considered;
  uint64_t candidates_pruned;
  uint64_t execution_time_us;
  uint32_t cuts;
  uint32_t offcuts_created;
  uint32_t offcuts_reused;
} MeasurementDiagnosticsC;

typedef struct MeasurementResultC {
  int32_t status;
  int32_t selected_candidate_index;
  MeasurementCandidateC* candidates;
  uint32_t candidate_count;
  MeasurementVariantQuantityC* quantities;
  uint32_t quantity_count;
  MeasurementCutSegmentC* cuts;
  uint32_t cut_count;
  MeasurementRoomLayoutC* room_layouts;
  uint32_t room_layout_count;
  MeasurementDiagnosticsC diagnostics;
} MeasurementResultC;

MEASUREMENT_API MeasurementHandle* measurement_engine_create(void);

MEASUREMENT_API void measurement_engine_destroy(MeasurementHandle* handle);

MEASUREMENT_API int32_t measurement_optimize(
    MeasurementHandle* handle,
    const MeasurementRequestC* request,
    MeasurementResultC* result);

MEASUREMENT_API void measurement_result_release(MeasurementResultC* result);

#ifdef __cplusplus
}
#endif

#endif  // MATERIAL_QUOTE_PRO_MEASUREMENT_ENGINE_H_
