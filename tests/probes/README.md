# Native empty UMat probe

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