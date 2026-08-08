# Testing Rules

## Test Crate Ownership

All automated tests for `opencvcore_ada` belong in the separate `tests` Alire crate.

Do not add AUnit as a dependency of the top-level `opencvcore_ada` library crate.

The `tests` crate should depend on:

- `aunit`
- `gnatprove`
- `gnatcov`
- the local `opencvcore_ada` crate pinned to `..`

Verification and coverage tooling should remain test/development dependencies and must not become dependencies of the public `opencvcore_ada` library crate.

Test-only helpers and test-only dependencies should remain under the `tests` crate unless they are genuinely part of the reusable public library.

## Coverage Expectations

Every new public binding operation should normally have focused automated test coverage.

Tests should verify both:

- expected successful behavior
- important failure or boundary cases

When adding a new public API operation, the agent should update or add tests in the same task rather than postponing test coverage.

Prefer small, focused tests over large end-to-end tests when validating individual binding operations.

## AUnit Organization

Organize AUnit tests by public feature or type rather than placing unrelated tests into one large test package.

Prefer focused test packages such as:

- `Mat_Tests`
- `Point_Tests`
- `Size_Tests`
- `Scalar_Tests`
- `Type_Conversion_Tests`

Each test should have one clear behavioral purpose.

Use descriptive test names that state what is being verified.

Prefer assertions against the public thick Ada API.

Do not test internal C shim functions directly from ordinary AUnit tests unless the test specifically targets the interoperability layer.

Where practical, validate observable OpenCV semantics rather than implementation details.

## Error and Exception Tests

Test error translation deliberately.

When a public Ada operation can fail because OpenCV rejects an input or the shim reports an error, add tests that verify the thick Ada API produces the intended Ada-level behavior.

Tests should cover important cases such as:

- invalid dimensions
- incompatible matrix types
- invalid channel counts
- null or empty object states where relevant
- OpenCV exceptions translated by the shim
- invalid arguments rejected by Ada contracts before reaching the shim

Do not merely assert that "an exception occurred" when a specific Ada exception is part of the public contract.

Prefer assertions that verify the expected exception category and, where stable and useful, the associated diagnostic information.

Do not depend on exact OpenCV exception-message wording unless that wording is intentionally part of the binding's public API.

The agent should add at least one negative-path test when introducing a new API operation with meaningful failure behavior.

## GNATcov Coverage

GNATcov is a development dependency of the `tests` crate, not the public `opencvcore_ada` crate.

Run GNATcov from the `tests` crate so that tests exercise the library through its normal pinned dependency on `opencvcore_ada`.

Do not add GNATcov to the public library crate merely to make coverage tooling available.

Coverage analysis should primarily answer:

- which public Ada operations are exercised
- which Ada error-handling paths are exercised
- which ownership and finalization paths are exercised
- which conversion and validation paths are exercised

Do not treat high line coverage alone as sufficient evidence of correctness.

Prefer meaningful behavioral coverage over tests written only to increase percentages.

Distinguish between Ada coverage and C++ shim coverage.

GNATcov coverage of Ada code does not automatically prove that all C++ shim paths are covered.

If C++ shim coverage becomes important, use an appropriate C/C++ coverage mechanism separately rather than assuming GNATcov covers the entire native stack.

When adding a significant new public feature, the agent should run the relevant tests and GNATcov when practical before considering the task complete.

## Ownership and Lifetime Tests

Resource ownership behavior must be tested explicitly for controlled OpenCV wrapper types such as `Mat`.

For `Mat`, tests should cover:

- default construction and destruction
- construction of a non-empty matrix
- Ada assignment
- shallow-copy behavior after assignment
- reference-counted shared storage behavior
- explicit `Clone` deep-copy behavior
- reassignment over an existing value
- finalization of one shallow copy while another remains valid
- self-assignment where relevant
- exception paths that occur after a C++ object has been allocated

Tests must be designed to detect:

- double destruction
- use-after-free
- leaked owned handles
- incorrect shallow-copy behavior
- accidental deep copies
- invalid handles left after failed construction

Where behavior can be observed through the public API, test it through the public API rather than inspecting internal handles.

Use external memory-checking tools when appropriate for native lifetime bugs that cannot be proven through AUnit assertions alone.
