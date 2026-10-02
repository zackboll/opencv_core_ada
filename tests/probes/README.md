# Native empty UMat probe

`umat_math_empty_probe.cpp` likewise stays outside the AUnit executable. It
accepts `mat|umat operation layout packed_type power opencl`, where operations
are `normalize-l1`, `normalize-l2`, `normalize-inf`, `normalize-minmax`, `sqrt`,
`exp`, `log`, `pow`, `magnitude`, `phase`, `cart`, or `polar`. Layouts are
`default`, `typed`, `full`, `nd`, `unit-default`, and `unit-typed`. The last two
use nonempty Angle with empty Magnitude. Example isolated build/run:

```sh
g++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  $(pkg-config --cflags opencv4) tests/probes/umat_math_empty_probe.cpp \
  -lopencv_core -o /tmp/umat-math-probe
(ulimit -c 0; /tmp/umat-math-probe umat pow typed 5 2 1)
```

See `umat_math_source_findings.md` for the pinned 4.1/4.10/5.0 source review,
local empty crashes, depth/dimensional contracts, and residency audit.

`umat_bitwise_empty_probe.cpp` is deliberately outside `tests/cpp`: it must
not be linked into the AUnit executable. Compile against the OpenCV version
being investigated and run each mode/form in a separate process. Modes 0–5
are binary AND, unary NOT, masked AND, masked NOT, scalar inRange and compare.
The form bitmask selects typed 0×0 storage for left (1), right (2), and mask
(4); the final argument requests OpenCL use (0/1). A native crash must not
take down the test suite.

Local 4.10 default and typed 0×0 tests: binary/unary/masked bitwise normally
return the corresponding empty representation, mixed binary forms can throw,
inRange rejects all empty forms, and compare releases its result. The regular
Ada suite additionally exposed a 4.10 UMat OpenCL-vector-width segfault for
typed empty bitwise inputs; the native bitwise helper bypasses that path.
OpenCV 4.1 and 5.0 probes also find that inRange rejects empties and compare
releases the output. OpenCV 5.0 throws for default-empty bitwise operations;
the shim's ABI-safety bypass preserves the established Mat empty policy.