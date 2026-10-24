cmake_minimum_required(VERSION 3.14)
project(measurement_engine LANGUAGES CXX)

option(MEASUREMENT_BUILD_TESTS "Build measurement native tests" OFF)
option(MEASUREMENT_BUILD_BENCHMARKS "Build measurement native benchmarks" OFF)

add_library(measurement_engine SHARED
  src/measurement_engine.cpp
)
target_include_directories(measurement_engine PUBLIC include)
target_compile_features(measurement_engine PUBLIC cxx_std_17)
target_compile_definitions(measurement_engine PRIVATE MEASUREMENT_ENGINE_BUILD)

if(COMMAND APPLY_STANDARD_SETTINGS)
  apply_standard_settings(measurement_engine)
elseif(MSVC)
  target_compile_options(measurement_engine PRIVATE /W4 /WX /EHsc)
  target_compile_definitions(measurement_engine PRIVATE _HAS_EXCEPTIONS=0 NOMINMAX)
else()
  target_compile_options(measurement_engine PRIVATE -Wall -Wextra -Werror)
endif()

if(MEASUREMENT_BUILD_TESTS)
  enable_testing()
  add_executable(measurement_engine_tests tests/measurement_engine_test.cpp)
  target_link_libraries(measurement_engine_tests PRIVATE measurement_engine)
  target_compile_features(measurement_engine_tests PRIVATE cxx_std_17)
  if(MSVC)
    target_compile_options(measurement_engine_tests PRIVATE /W4 /WX /EHsc)
    target_compile_definitions(measurement_engine_tests PRIVATE _HAS_EXCEPTIONS=0 NOMINMAX)
  else()
    target_compile_options(measurement_engine_tests PRIVATE -Wall -Wextra -Werror)
  endif()
  add_test(NAME measurement_engine_tests COMMAND measurement_engine_tests)
endif()

if(MEASUREMENT_BUILD_BENCHMARKS)
  add_executable(measurement_engine_benchmark
    benchmarks/measurement_engine_benchmark.cpp
  )
  target_link_libraries(measurement_engine_benchmark PRIVATE measurement_engine)
  target_compile_features(measurement_engine_benchmark PRIVATE cxx_std_17)
  if(MSVC)
    target_compile_options(measurement_engine_benchmark PRIVATE /W4 /WX /EHsc)
    target_compile_definitions(measurement_engine_benchmark PRIVATE _HAS_EXCEPTIONS=0 NOMINMAX)
  else()
    target_compile_options(measurement_engine_benchmark PRIVATE -Wall -Wextra -Werror)
  endif()
endif()
