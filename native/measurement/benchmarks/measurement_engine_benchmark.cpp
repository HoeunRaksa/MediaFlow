#include "measurement_engine.h"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <vector>

namespace {

struct SampleSummary {
  double median_us;
  double p95_us;
  double worst_us;
};

SampleSummary summarize(std::vector<double> samples) {
  std::sort(samples.begin(), samples.end());
  const size_t middle = samples.size() / 2;
  const double median = samples.size() % 2 == 0
                            ? (samples[middle - 1] + samples[middle]) / 2.0
                            : samples[middle];
  const size_t p95_index = static_cast<size_t>(
      static_cast<double>(samples.size() - 1) * 0.95);
  return {median, samples[p95_index], samples.back()};
}

std::vector<MeasurementRoomC> make_rooms(uint32_t count) {
  std::vector<MeasurementRoomC> rooms;
  rooms.reserve(count);
  for (uint32_t i = 0; i < count; ++i) {
    rooms.push_back(MeasurementRoomC{static_cast<int32_t>(i + 1),
                                     2400.0 + (i % 7) * 137.0,
                                     1200.0 + (i % 5) * 113.0});
  }
  return rooms;
}

std::vector<MeasurementProductVariantC> make_variants(uint32_t count) {
  std::vector<MeasurementProductVariantC> variants;
  variants.reserve(count);
  for (uint32_t i = 0; i < count; ++i) {
    variants.push_back(MeasurementProductVariantC{
        static_cast<int32_t>(100 + i),
        400,
        3000.0 + i * 250.0,
        10,
        9.0 + i * 0.65,
    });
  }
  return variants;
}

SampleSummary benchmark(uint32_t room_count,
                        uint32_t variant_count,
                        bool reuse,
                        bool joints) {
  const auto rooms = make_rooms(room_count);
  const auto variants = make_variants(variant_count);
  const MeasurementOptionsC options{
      MEASUREMENT_OPTIMIZE_LOWEST_WASTE,
      static_cast<uint8_t>(joints),
      static_cast<uint8_t>(reuse),
      1,
      0,
      0,
      0,
      0,
      5,
      200000,
  };
  const MeasurementRequestC request{rooms.data(),
                                    static_cast<uint32_t>(rooms.size()),
                                    variants.data(),
                                    static_cast<uint32_t>(variants.size()),
                                    options};
  MeasurementHandle* handle = measurement_engine_create();
  std::vector<double> samples;
  const uint32_t iterations = room_count == 100 ? 30 : 100;
  samples.reserve(iterations);
  for (uint32_t iteration = 0; iteration < iterations + 5; ++iteration) {
    MeasurementResultC result{};
    const auto started = std::chrono::steady_clock::now();
    const int32_t status = measurement_optimize(handle, &request, &result);
    const auto elapsed = std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now() - started);
    if (status != MEASUREMENT_STATUS_OK) {
      std::cerr << "benchmark request failed with status " << status << "\n";
      measurement_result_release(&result);
      measurement_engine_destroy(handle);
      return {0, 0, 0};
    }
    measurement_result_release(&result);
    if (iteration >= 5) samples.push_back(elapsed.count());
  }
  measurement_engine_destroy(handle);
  return summarize(std::move(samples));
}

}  // namespace

int main() {
  std::cout << "rooms,variants,offcut_reuse,joints,median_us,p95_us,worst_us\n";
  std::cout << std::fixed << std::setprecision(2);
  for (const uint32_t rooms : {1U, 10U, 100U}) {
    for (const uint32_t variants : {2U, 5U, 10U}) {
      for (const bool reuse : {false, true}) {
        for (const bool joints : {false, true}) {
          const auto summary = benchmark(rooms, variants, reuse, joints);
          std::cout << rooms << ',' << variants << ',' << (reuse ? "on" : "off")
                    << ',' << (joints ? "on" : "off") << ','
                    << summary.median_us << ',' << summary.p95_us << ','
                    << summary.worst_us << '\n';
        }
      }
    }
  }
  std::cout << "allocator_note,not instrumented; result ownership uses four flat arrays\n";
  return 0;
}
