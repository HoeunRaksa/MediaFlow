## Native Performance Policy

This application uses Flutter/Dart for presentation and orchestration and
C++ for computation that is demonstrably performance-sensitive.

Before implementing a computationally expensive feature:

1. Inspect the existing C++ engine and FFI layer.
2. Reuse the existing native runtime rather than creating parallel engines.
3. Keep FFI calls coarse-grained.
4. Never place thousands of FFI calls inside a Dart loop.
5. Never move trivial UI/business logic to C++ without a performance reason.
6. Keep heavy native computation off the Flutter UI thread.
7. Profile Release builds before claiming a performance improvement.
8. Correctness and maintainability take priority over speculative optimization.
9. Native APIs must use a stable C ABI.
10. C++ exceptions, STL containers, and ownership ambiguity must never cross FFI.
11. Add correctness tests before optimizing an algorithm.
12. Add benchmarks for every new performance-critical native subsystem.
13. Preserve deterministic results for seller/business calculations.
14. Do not rewrite an existing working native subsystem unless measurements
    demonstrate a concrete need.

For optimization/search workloads, prefer:
- compact contiguous structures
- reusable buffers
- bounded search
- pruning
- memoization/dynamic programming where appropriate
- minimal allocations in hot loops
- batch request/result transfer across FFI

Flutter must remain responsive at 60/120 Hz while native computation runs.