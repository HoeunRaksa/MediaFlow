#include "measurement_engine.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <limits>
#include <new>
#include <numeric>
#include <utility>
#include <vector>

namespace {

constexpr double kEpsilon = 1e-7;
constexpr uint32_t kDefaultSearchLimit = 200000;
constexpr uint32_t kMaxRooms = 1000;
constexpr uint32_t kMaxVariants = 32;
constexpr uint32_t kMaxLanes = 100000;
constexpr uint32_t kMaxCuts = 1000000;

struct Demand {
  uint32_t room_index;
  int32_t room_id;
  uint32_t lane_index;
  double length_mm;
};

struct Piece {
  uint32_t variant_index;
  uint32_t piece_index;
  double source_length_mm;
  double remaining_mm;
  uint32_t segments_used;
};

struct Policy {
  bool mixed;
  int32_t single_variant_id;
  std::vector<uint32_t> variants;
};

struct PlanChoice {
  uint32_t first_variant = 0;
  uint32_t second_variant = 0;
  uint32_t first_count = 0;
  uint32_t second_count = 0;
  uint32_t purchase_pieces = 0;
  double purchased_length_mm = 0;
  double cost = 0;
};

struct CandidateWork {
  bool valid = false;
  bool mixed = false;
  int32_t candidate_id = -1;
  int32_t single_variant_id = -1;
  uint32_t base_piece_count = 0;
  uint32_t reserve_piece_count = 0;
  uint32_t purchase_piece_count = 0;
  uint32_t joint_count = 0;
  double required_area_m2 = 0;
  double purchased_area_m2 = 0;
  double waste_area_m2 = 0;
  double waste_percent = 0;
  double total_cost = 0;
  double score = 0;
  std::vector<MeasurementVariantQuantityC> quantities;
  std::vector<MeasurementCutSegmentC> cuts;
  std::vector<MeasurementRoomLayoutC> layouts;
};

struct SearchStats {
  uint64_t considered = 0;
  uint64_t pruned = 0;
};

bool almost_equal(double left, double right) {
  const double scale = std::max({1.0, std::fabs(left), std::fabs(right)});
  return std::fabs(left - right) <= kEpsilon * scale;
}

int compare_double(double left, double right) {
  if (almost_equal(left, right)) {
    return 0;
  }
  return left < right ? -1 : 1;
}

bool candidate_better(const CandidateWork& left,
                      const CandidateWork& right,
                      uint8_t optimize_for) {
  if (left.valid != right.valid) {
    return left.valid;
  }
  if (!left.valid) {
    return false;
  }

  const auto compare_cost = [&]() {
    return compare_double(left.total_cost, right.total_cost);
  };
  const auto compare_waste = [&]() {
    return compare_double(left.waste_area_m2, right.waste_area_m2);
  };
  const auto compare_pieces = [&]() {
    if (left.purchase_piece_count == right.purchase_piece_count) return 0;
    return left.purchase_piece_count < right.purchase_piece_count ? -1 : 1;
  };
  const auto compare_joints = [&]() {
    if (left.joint_count == right.joint_count) return 0;
    return left.joint_count < right.joint_count ? -1 : 1;
  };

  int comparisons[4] = {};
  if (optimize_for == MEASUREMENT_OPTIMIZE_LOWEST_WASTE) {
    comparisons[0] = compare_waste();
    comparisons[1] = compare_cost();
    comparisons[2] = compare_joints();
    comparisons[3] = compare_pieces();
  } else if (optimize_for == MEASUREMENT_OPTIMIZE_FEWEST_JOINTS) {
    comparisons[0] = compare_joints();
    comparisons[1] = compare_waste();
    comparisons[2] = compare_cost();
    comparisons[3] = compare_pieces();
  } else {
    comparisons[0] = compare_cost();
    comparisons[1] = compare_waste();
    comparisons[2] = compare_pieces();
    comparisons[3] = compare_joints();
  }
  for (const int comparison : comparisons) {
    if (comparison != 0) {
      return comparison < 0;
    }
  }
  return left.candidate_id < right.candidate_id;
}

bool valid_request(const MeasurementRequestC& request) {
  if (request.rooms == nullptr || request.variants == nullptr ||
      request.room_count == 0 || request.room_count > kMaxRooms ||
      request.variant_count == 0 || request.variant_count > kMaxVariants) {
    return false;
  }
  if (request.options.optimize_for > MEASUREMENT_OPTIMIZE_FEWEST_JOINTS ||
      request.options.reserved_0 > MEASUREMENT_ORIENTATION_FORCE_WIDTH ||
      !std::isfinite(request.options.spare_percent) ||
      request.options.spare_percent < 0 ||
      request.options.spare_percent > 100) {
    return false;
  }
  for (uint32_t i = 0; i < request.room_count; ++i) {
    const auto& room = request.rooms[i];
    if (!std::isfinite(room.length_mm) || !std::isfinite(room.width_mm) ||
        room.length_mm <= 0 || room.width_mm <= 0) {
      return false;
    }
  }
  const double product_width = request.variants[0].width_mm;
  const double product_thickness = request.variants[0].thickness_mm;
  for (uint32_t i = 0; i < request.variant_count; ++i) {
    const auto& variant = request.variants[i];
    if (!std::isfinite(variant.width_mm) ||
        !std::isfinite(variant.length_mm) ||
        !std::isfinite(variant.thickness_mm) ||
        !std::isfinite(variant.unit_price) || variant.width_mm <= 0 ||
        variant.length_mm <= 0 || variant.thickness_mm <= 0 ||
        variant.unit_price < 0 || !almost_equal(variant.width_mm, product_width) ||
        !almost_equal(variant.thickness_mm, product_thickness)) {
      return false;
    }
    for (uint32_t j = 0; j < i; ++j) {
      if (request.variants[j].variant_id == variant.variant_id) {
        return false;
      }
    }
  }
  return true;
}

double room_required_area(const MeasurementRequestC& request) {
  double area = 0;
  for (uint32_t i = 0; i < request.room_count; ++i) {
    area += request.rooms[i].length_mm * request.rooms[i].width_mm / 1000000.0;
  }
  return area;
}

std::vector<std::vector<uint8_t>> orientation_plans(
    const MeasurementRequestC& request,
    double panel_width_mm) {
  std::vector<std::vector<uint8_t>> plans;
  plans.reserve(request.room_count <= 4 ? request.room_count + 4 : 3);
  std::vector<uint8_t> all_length(request.room_count,
                                  MEASUREMENT_ORIENTATION_ALONG_LENGTH);
  std::vector<uint8_t> all_width(request.room_count,
                                 MEASUREMENT_ORIENTATION_ALONG_WIDTH);
  std::vector<uint8_t> greedy(request.room_count);
  for (uint32_t i = 0; i < request.room_count; ++i) {
    const auto& room = request.rooms[i];
    const double along_length =
        std::ceil(room.width_mm / panel_width_mm) * room.length_mm;
    const double along_width =
        std::ceil(room.length_mm / panel_width_mm) * room.width_mm;
    greedy[i] = static_cast<uint8_t>(
        along_width + kEpsilon < along_length
            ? MEASUREMENT_ORIENTATION_ALONG_WIDTH
            : MEASUREMENT_ORIENTATION_ALONG_LENGTH);
  }
  if (request.options.reserved_0 == MEASUREMENT_ORIENTATION_FORCE_LENGTH) {
    plans.push_back(std::move(all_length));
    return plans;
  }
  if (request.options.reserved_0 == MEASUREMENT_ORIENTATION_FORCE_WIDTH) {
    plans.push_back(std::move(all_width));
    return plans;
  }
  plans.push_back(all_length);
  plans.push_back(all_width);
  plans.push_back(greedy);
  if (request.room_count > 1 && request.room_count <= 4) {
    auto inverse = greedy;
    for (auto& orientation : inverse) {
      orientation = static_cast<uint8_t>(
          orientation == MEASUREMENT_ORIENTATION_ALONG_LENGTH
              ? MEASUREMENT_ORIENTATION_ALONG_WIDTH
              : MEASUREMENT_ORIENTATION_ALONG_LENGTH);
    }
    plans.push_back(std::move(inverse));
    const uint32_t toggles = request.room_count;
    for (uint32_t i = 0; i < toggles; ++i) {
      auto toggled = greedy;
      toggled[i] = static_cast<uint8_t>(
          toggled[i] == MEASUREMENT_ORIENTATION_ALONG_LENGTH
              ? MEASUREMENT_ORIENTATION_ALONG_WIDTH
              : MEASUREMENT_ORIENTATION_ALONG_LENGTH);
      plans.push_back(std::move(toggled));
    }
  }
  std::sort(plans.begin(), plans.end());
  plans.erase(std::unique(plans.begin(), plans.end()), plans.end());
  return plans;
}

bool build_demands(const MeasurementRequestC& request,
                   const std::vector<uint8_t>& orientations,
                   double panel_width_mm,
                   std::vector<Demand>* demands,
                   std::vector<MeasurementRoomLayoutC>* layouts) {
  demands->clear();
  layouts->clear();
  uint64_t total_lanes = 0;
  for (uint32_t room_index = 0; room_index < request.room_count; ++room_index) {
    const auto& room = request.rooms[room_index];
    const uint8_t orientation = orientations[room_index];
    const double longitudinal =
        orientation == MEASUREMENT_ORIENTATION_ALONG_LENGTH ? room.length_mm
                                                            : room.width_mm;
    const double cross =
        orientation == MEASUREMENT_ORIENTATION_ALONG_LENGTH ? room.width_mm
                                                            : room.length_mm;
    const uint32_t lanes = static_cast<uint32_t>(
        std::ceil((cross - kEpsilon) / panel_width_mm));
    total_lanes += lanes;
    if (lanes == 0 || total_lanes > kMaxLanes) {
      return false;
    }
    layouts->push_back(MeasurementRoomLayoutC{
        0,
        room.room_id,
        orientation,
        0,
        0,
        0,
        lanes,
        longitudinal,
        cross,
    });
    for (uint32_t lane = 0; lane < lanes; ++lane) {
      demands->push_back(Demand{room_index, room.room_id, lane, longitudinal});
    }
  }
  return true;
}

uint32_t choose_variant(const MeasurementRequestC& request,
                        const Policy& policy,
                        double need_mm,
                        uint32_t new_piece_ordinal,
                        uint32_t strategy) {
  const bool allow_joints = request.options.allow_joints != 0;
  const auto eligible = [&](uint32_t index) {
    return allow_joints || request.variants[index].length_mm + kEpsilon >= need_mm;
  };

  if (strategy > 0) {
    const uint32_t start = strategy <= policy.variants.size()
                               ? strategy - 1
                               : new_piece_ordinal % policy.variants.size();
    for (uint32_t offset = 0; offset < policy.variants.size(); ++offset) {
      const uint32_t index = policy.variants[(start + offset) % policy.variants.size()];
      if (eligible(index)) return index;
    }
    return std::numeric_limits<uint32_t>::max();
  }

  uint32_t best = std::numeric_limits<uint32_t>::max();
  for (const uint32_t index : policy.variants) {
    if (!eligible(index)) continue;
    if (best == std::numeric_limits<uint32_t>::max()) {
      best = index;
      continue;
    }
    const auto& candidate = request.variants[index];
    const auto& selected = request.variants[best];
    bool take = false;
    if (request.options.optimize_for == MEASUREMENT_OPTIMIZE_FEWEST_JOINTS) {
      const bool candidate_fits = candidate.length_mm + kEpsilon >= need_mm;
      const bool selected_fits = selected.length_mm + kEpsilon >= need_mm;
      if (candidate_fits != selected_fits) {
        take = candidate_fits;
      } else if (candidate_fits) {
        take = candidate.length_mm < selected.length_mm - kEpsilon;
      } else {
        take = candidate.length_mm > selected.length_mm + kEpsilon;
      }
      if (almost_equal(candidate.length_mm, selected.length_mm)) {
        take = candidate.unit_price < selected.unit_price - kEpsilon;
      }
    } else if (request.options.optimize_for == MEASUREMENT_OPTIMIZE_LOWEST_WASTE) {
      const double candidate_over = candidate.length_mm >= need_mm
                                        ? candidate.length_mm - need_mm
                                        : std::numeric_limits<double>::max();
      const double selected_over = selected.length_mm >= need_mm
                                       ? selected.length_mm - need_mm
                                       : std::numeric_limits<double>::max();
      if (compare_double(candidate_over, selected_over) != 0) {
        take = candidate_over < selected_over;
      } else {
        take = candidate.unit_price < selected.unit_price - kEpsilon;
      }
    } else {
      const bool candidate_fits = candidate.length_mm + kEpsilon >= need_mm;
      const bool selected_fits = selected.length_mm + kEpsilon >= need_mm;
      const double candidate_metric = candidate_fits
                                          ? candidate.unit_price
                                          : candidate.unit_price /
                                                candidate.length_mm;
      const double selected_metric = selected_fits
                                         ? selected.unit_price
                                         : selected.unit_price /
                                               selected.length_mm;
      if (compare_double(candidate_metric, selected_metric) != 0) {
        take = candidate_metric < selected_metric;
      } else {
        take = candidate.length_mm > selected.length_mm + kEpsilon;
      }
    }
    if (take) best = index;
  }
  return best;
}

void finalize_candidate(const MeasurementRequestC& request,
                        const std::vector<uint32_t>& base_quantities,
                        CandidateWork* candidate) {
  candidate->quantities.clear();
  candidate->base_piece_count = 0;
  candidate->reserve_piece_count = 0;
  candidate->purchase_piece_count = 0;
  candidate->purchased_area_m2 = 0;
  candidate->total_cost = 0;
  for (uint32_t index = 0; index < request.variant_count; ++index) {
    const uint32_t base = base_quantities[index];
    if (base == 0) continue;
    const uint32_t reserve = request.options.spare_percent <= 0
                                 ? 0
                                 : static_cast<uint32_t>(std::ceil(
                                       base * request.options.spare_percent /
                                           100.0 -
                                       kEpsilon));
    const uint32_t purchase = base + reserve;
    candidate->base_piece_count += base;
    candidate->reserve_piece_count += reserve;
    candidate->purchase_piece_count += purchase;
    const auto& variant = request.variants[index];
    candidate->purchased_area_m2 +=
        purchase * variant.width_mm * variant.length_mm / 1000000.0;
    candidate->total_cost += purchase * variant.unit_price;
    candidate->quantities.push_back(MeasurementVariantQuantityC{
        0, variant.variant_id, base, reserve, purchase});
  }
  candidate->required_area_m2 = room_required_area(request);
  candidate->waste_area_m2 =
      std::max(0.0, candidate->purchased_area_m2 - candidate->required_area_m2);
  candidate->waste_percent = candidate->purchased_area_m2 <= kEpsilon
                                 ? 0
                                 : candidate->waste_area_m2 /
                                       candidate->purchased_area_m2 * 100.0;
  candidate->score = request.options.optimize_for ==
                             MEASUREMENT_OPTIMIZE_LOWEST_WASTE
                         ? candidate->waste_area_m2
                     : request.options.optimize_for ==
                               MEASUREMENT_OPTIMIZE_FEWEST_JOINTS
                         ? static_cast<double>(candidate->joint_count)
                         : candidate->total_cost;
}

CandidateWork simulate(const MeasurementRequestC& request,
                       const Policy& policy,
                       int32_t candidate_id,
                       const std::vector<Demand>& demands,
                       const std::vector<MeasurementRoomLayoutC>& layouts,
                       uint32_t strategy,
                       const std::vector<uint32_t>* fixed_quantities) {
  CandidateWork candidate;
  candidate.mixed = policy.mixed;
  candidate.candidate_id = candidate_id;
  candidate.single_variant_id = policy.single_variant_id;
  candidate.layouts = layouts;
  candidate.cuts.reserve(std::min<size_t>(demands.size() * 2, kMaxCuts));

  std::vector<uint32_t> base_quantities(request.variant_count, 0);
  std::vector<Piece> pieces;
  if (fixed_quantities != nullptr) {
    uint32_t piece_index = 0;
    const uint32_t total = std::accumulate(fixed_quantities->begin(),
                                           fixed_quantities->end(), 0U);
    pieces.reserve(total);
    for (uint32_t variant_index = 0; variant_index < request.variant_count;
         ++variant_index) {
      base_quantities[variant_index] = (*fixed_quantities)[variant_index];
      for (uint32_t count = 0; count < (*fixed_quantities)[variant_index];
           ++count) {
        pieces.push_back(Piece{variant_index,
                               piece_index++,
                               request.variants[variant_index].length_mm,
                               request.variants[variant_index].length_mm,
                               0});
      }
    }
  } else {
    pieces.reserve(std::min<size_t>(demands.size() * 2, kMaxCuts));
  }

  uint32_t new_piece_ordinal = 0;
  uint32_t next_piece_index = static_cast<uint32_t>(pieces.size());
  uint32_t previous_room = std::numeric_limits<uint32_t>::max();
  for (const auto& demand : demands) {
    if (!request.options.project_mode && previous_room != demand.room_index) {
      for (auto& piece : pieces) piece.remaining_mm = 0;
    }
    previous_room = demand.room_index;
    double remaining_need = demand.length_mm;
    uint32_t segment_index = 0;
    while (remaining_need > kEpsilon) {
      if (candidate.cuts.size() >= kMaxCuts) return candidate;
      Piece* selected_piece = nullptr;
      if (request.options.reuse_offcuts) {
        for (auto& piece : pieces) {
          if (piece.remaining_mm <= kEpsilon) continue;
          if (!request.options.allow_joints &&
              piece.remaining_mm + kEpsilon < remaining_need) {
            continue;
          }
          if (selected_piece == nullptr) {
            selected_piece = &piece;
            continue;
          }
          const bool piece_fits = piece.remaining_mm + kEpsilon >= remaining_need;
          const bool selected_fits =
              selected_piece->remaining_mm + kEpsilon >= remaining_need;
          if (piece_fits != selected_fits) {
            if (piece_fits) selected_piece = &piece;
          } else if (piece_fits) {
            if (piece.remaining_mm < selected_piece->remaining_mm - kEpsilon) {
              selected_piece = &piece;
            }
          } else if (piece.remaining_mm >
                     selected_piece->remaining_mm + kEpsilon) {
            selected_piece = &piece;
          }
        }
      }

      if (selected_piece == nullptr) {
        if (fixed_quantities != nullptr) return candidate;
        const uint32_t variant_index = choose_variant(
            request, policy, remaining_need, new_piece_ordinal, strategy);
        if (variant_index == std::numeric_limits<uint32_t>::max()) {
          return candidate;
        }
        ++new_piece_ordinal;
        ++base_quantities[variant_index];
        const double source_length = request.variants[variant_index].length_mm;
        pieces.push_back(Piece{variant_index,
                               next_piece_index++,
                               source_length,
                               source_length,
                               0});
        selected_piece = &pieces.back();
      }

      const double used = request.options.allow_joints
                              ? std::min(remaining_need,
                                         selected_piece->remaining_mm)
                              : remaining_need;
      if (used <= kEpsilon ||
          used > selected_piece->remaining_mm + kEpsilon) {
        return candidate;
      }
      const bool reused = selected_piece->segments_used > 0;
      selected_piece->remaining_mm =
          std::max(0.0, selected_piece->remaining_mm - used);
      candidate.cuts.push_back(MeasurementCutSegmentC{
          0,
          demand.room_id,
          demand.lane_index,
          request.variants[selected_piece->variant_index].variant_id,
          selected_piece->piece_index,
          segment_index,
          static_cast<uint8_t>(reused ? 1 : 0),
          0,
          0,
          0,
          selected_piece->source_length_mm,
          used,
          selected_piece->remaining_mm,
      });
      ++selected_piece->segments_used;
      remaining_need = std::max(0.0, remaining_need - used);
      ++segment_index;
      if (!request.options.reuse_offcuts) {
        selected_piece->remaining_mm = 0;
      }
    }
    if (segment_index > 0) candidate.joint_count += segment_index - 1;
  }

  if (policy.mixed) {
    uint32_t distinct = 0;
    for (const uint32_t quantity : base_quantities) {
      if (quantity > 0) ++distinct;
    }
    if (distinct < 2) return candidate;
  }
  candidate.valid = true;
  finalize_candidate(request, base_quantities, &candidate);
  return candidate;
}

bool preliminary_plan_better(const PlanChoice& left,
                             const PlanChoice& right,
                             uint8_t optimize_for) {
  if (optimize_for == MEASUREMENT_OPTIMIZE_LOWEST_WASTE) {
    const int length = compare_double(left.purchased_length_mm,
                                      right.purchased_length_mm);
    if (length != 0) return length < 0;
    const int cost = compare_double(left.cost, right.cost);
    if (cost != 0) return cost < 0;
    return left.purchase_pieces < right.purchase_pieces;
  }
  if (optimize_for == MEASUREMENT_OPTIMIZE_FEWEST_JOINTS) {
    if (left.purchase_pieces != right.purchase_pieces) {
      return left.purchase_pieces < right.purchase_pieces;
    }
    const int length = compare_double(left.purchased_length_mm,
                                      right.purchased_length_mm);
    if (length != 0) return length < 0;
    return left.cost < right.cost - kEpsilon;
  }
  const int cost = compare_double(left.cost, right.cost);
  if (cost != 0) return cost < 0;
  const int length = compare_double(left.purchased_length_mm,
                                    right.purchased_length_mm);
  if (length != 0) return length < 0;
  return left.purchase_pieces < right.purchase_pieces;
}

std::vector<PlanChoice> mixed_quantity_plans(
    const MeasurementRequestC& request,
    const Policy& policy,
    double total_demand_mm,
    SearchStats* stats) {
  std::vector<PlanChoice> plans;
  const uint32_t search_limit = request.options.max_search_candidates == 0
                                    ? kDefaultSearchLimit
                                    : request.options.max_search_candidates;
  for (size_t first_pos = 0; first_pos < policy.variants.size(); ++first_pos) {
    for (size_t second_pos = first_pos + 1;
         second_pos < policy.variants.size(); ++second_pos) {
      const uint32_t first = policy.variants[first_pos];
      const uint32_t second = policy.variants[second_pos];
      const auto& first_variant = request.variants[first];
      const auto& second_variant = request.variants[second];
      const uint32_t max_first = static_cast<uint32_t>(
          std::ceil(total_demand_mm / first_variant.length_mm)) + 1;
      for (uint32_t first_count = 1; first_count <= max_first; ++first_count) {
        if (stats->considered >= search_limit) {
          ++stats->pruned;
          break;
        }
        ++stats->considered;
        const double remainder =
            total_demand_mm - first_count * first_variant.length_mm;
        const uint32_t second_count = std::max<uint32_t>(
            1, remainder <= 0
                   ? 1
                   : static_cast<uint32_t>(
                         std::ceil((remainder - kEpsilon) /
                                   second_variant.length_mm)));
        PlanChoice plan;
        plan.first_variant = first;
        plan.second_variant = second;
        plan.first_count = first_count;
        plan.second_count = second_count;
        for (const auto [variant_index, base] :
             {std::pair{first, first_count}, std::pair{second, second_count}}) {
          const uint32_t reserve = request.options.spare_percent <= 0
                                       ? 0
                                       : static_cast<uint32_t>(std::ceil(
                                             base *
                                                 request.options.spare_percent /
                                                 100.0 -
                                             kEpsilon));
          const uint32_t purchase = base + reserve;
          plan.purchase_pieces += purchase;
          plan.purchased_length_mm +=
              purchase * request.variants[variant_index].length_mm;
          plan.cost += purchase * request.variants[variant_index].unit_price;
        }
        plans.push_back(std::move(plan));
      }
    }
  }
  std::sort(plans.begin(), plans.end(), [&](const PlanChoice& left,
                                            const PlanChoice& right) {
    return preliminary_plan_better(left, right, request.options.optimize_for);
  });
  const size_t retained =
      request.options.optimize_for == MEASUREMENT_OPTIMIZE_FEWEST_JOINTS ? 8 : 4;
  if (plans.size() > retained) {
    stats->pruned += plans.size() - retained;
    plans.resize(retained);
  }
  return plans;
}

CandidateWork evaluate_policy(const MeasurementRequestC& request,
                              const Policy& policy,
                              int32_t candidate_id,
                              SearchStats* stats,
                              bool* limit_exceeded) {
  CandidateWork best;
  best.mixed = policy.mixed;
  best.candidate_id = candidate_id;
  best.single_variant_id = policy.single_variant_id;
  const double panel_width = request.variants[policy.variants.front()].width_mm;
  const auto plans = orientation_plans(request, panel_width);
  std::vector<Demand> demands;
  std::vector<MeasurementRoomLayoutC> layouts;
  for (const auto& orientation_plan : plans) {
    if (!build_demands(request, orientation_plan, panel_width, &demands,
                       &layouts)) {
      *limit_exceeded = true;
      continue;
    }
    const double total_demand = std::accumulate(
        demands.begin(), demands.end(), 0.0,
        [](double sum, const Demand& demand) { return sum + demand.length_mm; });

    if (policy.mixed && request.options.allow_joints &&
        request.options.reuse_offcuts &&
        (request.options.project_mode || request.room_count == 1)) {
      const auto quantity_plans =
          mixed_quantity_plans(request, policy, total_demand, stats);
      for (const auto& plan : quantity_plans) {
        std::vector<uint32_t> fixed_quantities(request.variant_count, 0);
        fixed_quantities[plan.first_variant] = plan.first_count;
        fixed_quantities[plan.second_variant] = plan.second_count;
        CandidateWork current = simulate(request, policy, candidate_id, demands,
                                         layouts, 0, &fixed_quantities);
        if (candidate_better(current, best, request.options.optimize_for)) {
          best = std::move(current);
        }
      }
    } else {
      const uint32_t strategies = policy.mixed
                                      ? static_cast<uint32_t>(
                                            policy.variants.size() + 2)
                                      : 1;
      for (uint32_t strategy = 0; strategy < strategies; ++strategy) {
        ++stats->considered;
        CandidateWork current = simulate(request, policy, candidate_id, demands,
                                         layouts, strategy, nullptr);
        if (candidate_better(current, best, request.options.optimize_for)) {
          best = std::move(current);
        }
      }
    }
  }
  return best;
}

template <typename T>
bool allocate_and_copy(const std::vector<T>& source, T** destination) {
  *destination = nullptr;
  if (source.empty()) return true;
  T* data = new (std::nothrow) T[source.size()];
  if (data == nullptr) return false;
  std::copy(source.begin(), source.end(), data);
  *destination = data;
  return true;
}

void clear_result(MeasurementResultC* result) {
  result->status = MEASUREMENT_STATUS_INTERNAL_ERROR;
  result->selected_candidate_index = -1;
  result->candidates = nullptr;
  result->candidate_count = 0;
  result->quantities = nullptr;
  result->quantity_count = 0;
  result->cuts = nullptr;
  result->cut_count = 0;
  result->room_layouts = nullptr;
  result->room_layout_count = 0;
  result->diagnostics = MeasurementDiagnosticsC{};
}

}  // namespace

struct MeasurementHandle {
  uint64_t calculations = 0;
};

extern "C" {

MeasurementHandle* measurement_engine_create(void) {
  return new (std::nothrow) MeasurementHandle();
}

void measurement_engine_destroy(MeasurementHandle* handle) { delete handle; }

int32_t measurement_optimize(MeasurementHandle* handle,
                             const MeasurementRequestC* request,
                             MeasurementResultC* result) {
  if (result == nullptr) return MEASUREMENT_STATUS_INVALID_ARGUMENT;
  clear_result(result);
  if (handle == nullptr || request == nullptr || !valid_request(*request)) {
    result->status = MEASUREMENT_STATUS_INVALID_ARGUMENT;
    return result->status;
  }

  const auto started = std::chrono::steady_clock::now();
  ++handle->calculations;
  SearchStats stats;
  bool limit_exceeded = false;

  std::vector<Policy> policies;
  policies.reserve(request->variant_count + (request->variant_count > 1 ? 1 : 0));
  for (uint32_t i = 0; i < request->variant_count; ++i) {
    policies.push_back(Policy{false, request->variants[i].variant_id, {i}});
  }
  if (request->variant_count > 1) {
    Policy mixed;
    mixed.mixed = true;
    mixed.single_variant_id = -1;
    mixed.variants.resize(request->variant_count);
    std::iota(mixed.variants.begin(), mixed.variants.end(), 0U);
    policies.push_back(std::move(mixed));
  }

  std::vector<CandidateWork> work;
  work.reserve(policies.size());
  int32_t selected = -1;
  for (uint32_t i = 0; i < policies.size(); ++i) {
    CandidateWork candidate =
        evaluate_policy(*request, policies[i], static_cast<int32_t>(i), &stats,
                        &limit_exceeded);
    work.push_back(std::move(candidate));
    if (work.back().valid &&
        (selected < 0 || candidate_better(work.back(), work[selected],
                                          request->options.optimize_for))) {
      selected = static_cast<int32_t>(i);
    }
  }

  std::vector<MeasurementCandidateC> candidates;
  std::vector<MeasurementVariantQuantityC> quantities;
  std::vector<MeasurementCutSegmentC> cuts;
  std::vector<MeasurementRoomLayoutC> layouts;
  candidates.reserve(work.size());
  for (uint32_t i = 0; i < work.size(); ++i) {
    auto& item = work[i];
    const uint32_t quantity_offset = static_cast<uint32_t>(quantities.size());
    const uint32_t cut_offset = static_cast<uint32_t>(cuts.size());
    const uint32_t layout_offset = static_cast<uint32_t>(layouts.size());
    for (auto quantity : item.quantities) {
      quantity.candidate_index = i;
      quantities.push_back(quantity);
    }
    for (auto cut : item.cuts) {
      cut.candidate_index = i;
      cuts.push_back(cut);
    }
    for (auto layout : item.layouts) {
      layout.candidate_index = i;
      layouts.push_back(layout);
    }
    candidates.push_back(MeasurementCandidateC{
        item.candidate_id,
        item.single_variant_id,
        quantity_offset,
        static_cast<uint32_t>(item.quantities.size()),
        cut_offset,
        static_cast<uint32_t>(item.cuts.size()),
        layout_offset,
        static_cast<uint32_t>(item.layouts.size()),
        item.base_piece_count,
        item.reserve_piece_count,
        item.purchase_piece_count,
        item.joint_count,
        static_cast<uint8_t>(item.valid ? 1 : 0),
        static_cast<uint8_t>(item.mixed ? MEASUREMENT_STOCK_MIXED
                                        : MEASUREMENT_STOCK_SINGLE),
        0,
        0,
        item.required_area_m2,
        item.purchased_area_m2,
        item.waste_area_m2,
        item.waste_percent,
        item.total_cost,
        item.score,
    });
  }

  if (!allocate_and_copy(candidates, &result->candidates) ||
      !allocate_and_copy(quantities, &result->quantities) ||
      !allocate_and_copy(cuts, &result->cuts) ||
      !allocate_and_copy(layouts, &result->room_layouts)) {
    measurement_result_release(result);
    result->status = MEASUREMENT_STATUS_OUT_OF_MEMORY;
    return result->status;
  }
  result->candidate_count = static_cast<uint32_t>(candidates.size());
  result->quantity_count = static_cast<uint32_t>(quantities.size());
  result->cut_count = static_cast<uint32_t>(cuts.size());
  result->room_layout_count = static_cast<uint32_t>(layouts.size());
  result->selected_candidate_index = selected;
  result->status = selected >= 0
                       ? MEASUREMENT_STATUS_OK
                       : (limit_exceeded ? MEASUREMENT_STATUS_LIMIT_EXCEEDED
                                         : MEASUREMENT_STATUS_NO_SOLUTION);
  result->diagnostics.candidates_considered = stats.considered;
  result->diagnostics.candidates_pruned = stats.pruned;
  if (selected >= 0) {
    const auto& selected_work = work[static_cast<size_t>(selected)];
    result->diagnostics.cuts = static_cast<uint32_t>(selected_work.cuts.size());
    for (const auto& cut : selected_work.cuts) {
      if (cut.remainder_length_mm > kEpsilon) {
        ++result->diagnostics.offcuts_created;
      }
      if (cut.reused_offcut) ++result->diagnostics.offcuts_reused;
    }
  }
  result->diagnostics.execution_time_us = static_cast<uint64_t>(
      std::chrono::duration_cast<std::chrono::microseconds>(
          std::chrono::steady_clock::now() - started)
          .count());
  return result->status;
}

void measurement_result_release(MeasurementResultC* result) {
  if (result == nullptr) return;
  delete[] result->candidates;
  delete[] result->quantities;
  delete[] result->cuts;
  delete[] result->room_layouts;
  clear_result(result);
}

}  // extern "C"
