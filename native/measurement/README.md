# Measurement engine

The measurement module is a deterministic C++17 cutting/layout optimizer behind
one C-compatible request/result interface. Dart owns text parsing, validation,
state, persistence, UI, quotation mapping, and isolate scheduling. No STL type,
exception, or ownership ambiguity crosses the ABI.

## Physical model

For every room, the engine evaluates panels running along the room length and
along the room width. Lanes are calculated independently from stock length:

`lane count = ceil(cross span / product width)`

Each lane is then covered from compatible original stock lengths. With offcut
reuse enabled, a cut remainder stays available to later lanes and, in project
mode, later rooms. With reuse disabled, a remainder is final waste. With joints
disabled, one remaining stock segment must cover an entire lane.

Candidate order is deterministic. Normal two-length stock is searched exactly
over bounded 3m/4m quantity pairs. Larger variant sets use bounded pairwise
mixed-stock generation and prune to the best preliminary candidates before
physical cut simulation. This keeps the common PVC case exact without an
unbounded combinational solver.

## 6.0m × 4.2m regression geometry

For a 400mm-wide panel:

- Along the 6.0m side: `ceil(4.2 / 0.4) = 11` lanes, requiring 66.0m.
- Along the 4.2m side: `ceil(6.0 / 0.4) = 15` lanes, requiring 63.0m.

The verified lower-waste orientation is therefore panels running along the
4.2m room width. With 3m stock at $9 and 4m stock at $12, the Release engine
selects the exact 63m mixed plan: one 3m piece plus fifteen 4m pieces. It buys
16 pieces for $189, has 0.000m² final waste, and creates 15 joints. The 3m-only
candidate uses 21 pieces for $189 with 0.000m² waste; the 4m-only candidate uses
16 pieces for $192 with 0.400m² waste. The permanent native regression verifies
orientation, quantities, total cut length, cost, waste, joints, and offcut reuse.

## Build and validation

From the repository root:

```powershell
cmake -S native\measurement -B build\native_measurement -A x64 `
  -DMEASUREMENT_BUILD_TESTS=ON -DMEASUREMENT_BUILD_BENCHMARKS=ON
cmake --build build\native_measurement --config Release --parallel
ctest --test-dir build\native_measurement -C Release --output-on-failure
build\native_measurement\Release\measurement_engine_benchmark.exe
dart run tool\measurement_ffi_benchmark.dart
```

The benchmark matrix covers 1, 10, and 100 rooms; 2, 5, and 10 variants;
offcut reuse on/off; joints on/off; and mixed-stock search. Flutter's Windows
CMake build installs `measurement_engine.dll` beside the application executable.
