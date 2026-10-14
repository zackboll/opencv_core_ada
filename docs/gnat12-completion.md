# CORE-EXT-003-FINAL qualification

## Baselines and scope

Starting verified main: `23a8a4796691cd3fe552db4aa0e8351e691a53b5`.
Reviewed predecessor PR #80 head: `d1c650668906e8ef6a11306f941543d1cfa4496f`.
PR #80 merged as `c50336a807c5311219947cf82f4261c5f0b3fad6` during this
campaign. Its merged production and test tree equals the reviewed tree.
The integration branch fast-forwarded to that merged baseline without changing
the corrections or predecessor worktrees. Version remains `0.5.0-dev`.

This change has no public API, C ABI, shim, or dependency changes. It reuses
`Object_Storage`, `External_View_Alignment`, and the three existing typed
view/borrowing generics. No alternative layout framework was introduced.

Local evidence is retained at
`/home/zboll/qualification/core-ext-003-gnat12-final-evidence`.
Predecessor evidence remains at its original R3B/R3C/R3G/R3H locations; nothing
was reset, cleaned, stashed, amended, or force-pushed.

## Complete diagnostic inventory

A fresh actual `opencv_core.gpr` build used Debian 12, GCC/GNAT 12.2.0,
matching `/usr/lib/gcc/x86_64-linux-gnu/12/adalib`, and OpenCV 4.6.0.
The single keep-going diagnostic build made 211 Ada compiler invocations and
compiled the production C++ shim. Flags retained `-gnatwa -gnatwe -Werror`.
Only `Internal.Typed_Access` selects Ada 2022, exactly as before.

Results: 84 distinct `condition is not known at compile time` errors across
69 vector bodies; four additional compound-condition warnings in Float32 and
Float64 Vec2 view/buffer bodies. No scalar or other production blocker and no
secondary C_API assertion error appeared in this complete diagnostic build.

`tests/gnat12/inventory.py` renders the exact baseline file/line/expression,
compiler diagnostic, original requirement, and replacement enforcement for
every incompatible assertion, and lists **all 96 concrete bodies**. Run:

```sh
python3 tests/gnat12/inventory.py \
  d1c650668906e8ef6a11306f941543d1cfa4496f \
  /home/zboll/qualification/core-ext-003-gnat12-final-evidence/diagnostic-native12.log
```

The generated `assertion-inventory.json`, diagnostic log, unique diagnostics,
96-body list, initial and corrected hashes, and correction patches are evidence
artifacts. This renderer is not a validation-boundary policy checker.

| Family | Widths | Bodies changed | Incompatible conditions |
| --- | --- | ---: | ---: |
| UInt8 | 2/3/4 | 9 | 9 alignment |
| Int8 | 2/3/4 | 9 | 9 Object_Size + 9 alignment |
| UInt16 | 2/3/4 | 9 | 9 alignment |
| Int16 | 2/3/4 | 9 | 9 alignment |
| Int32 | 2/3/4 | 9 | 9 alignment |
| Float16 | 3/4 | 6 | 6 Object_Size + 6 alignment |
| Float32 | 2/3/4 | 9 | 9 alignment |
| Float64 | 2/3/4 | 9 | 9 alignment |
| Scalars | eight depths, three paths | 0 | none |
| Float16 Vec2 | three paths | 0 | predecessor already corrected |

Every listed width has view, row, and continuous-buffer bodies. Thus 24 scalar
and 72 vector bodies are inventoried; 69 change in this PR and 27 do not.

## Equivalent enforcement

For the 15 incompatible vector Object_Size conditions the existing ordinary
guard checks `Element_Type'Object_Size /= Expected_Element_Bits` independently
of `Size` and array stride. For 69 alignment conditions it checks
`Element_Type'Alignment > Native_Alignment`, and independently checks that the
allowance equals the depth-derived native 1/2/4/8-byte allowance. None is an
assertion that `-gnatp` can eliminate.

External views call this guard and validate the actual backing address before
native construction. Borrowing verifies representation before acquiring any
lease; returned addresses are checked before typed pointer conversion.
Geometry, capacity, byte counts, native depth/channels, and ownership guards
remain unchanged. Scalar size/Object_Size, vector scalar component size,
element size, array component stride, component index bounds, and independent
C/Ada ABI assertions remain compile-time checks.

The four Float32/Float64 Vec2 compound assertions were split into independent
static checks to avoid GNAT 12's invalid-value warning. Their statically
provable requirements were retained, not moved or discarded.

## Representation measurements

`Representation_Measurements` measures the actual public scalar/vector types,
not their C interop records. Native GNAT 12 O0/O2 and GNAT 16 four-version
outputs agree exactly:

| Depth | Scalar Size/Object_Size | Vec2 | Vec3 | Vec4 | Alignment/allowance |
| --- | ---: | ---: | ---: | ---: | ---: |
| UInt8 / Int8 | 8 | 16 | 24 | 32 | 1 |
| UInt16 / Int16 / Float16 | 16 | 32 | 48 | 64 | 2 |
| Int32 / Float32 | 32 | 64 | 96 | 128 | 4 |
| Float64 | 64 | 128 | 192 | 256 | 8 |

Each vector Object_Size equals its value Size; array Component_Size equals
that full element size. A two-element array has exactly twice those bits.
Vector scalar Component_Size and channel index ranges remain static production
requirements. AArch64 GNAT 12 also compiles the public measurement executable
and emits target representation information; no target execution is claimed.

## Safety and all-family coverage mapping

The existing qualified generic tests are instantiated on actual public types:

| Production paths (all 32 scalar/vector types) | Authoritative tests |
| --- | --- |
| Packed N-D writable, 2-D shape parity, zero-copy buffer, Clone/no escape | `ND_Mat_View_Tests` / `ND_Mat_View_Checks` |
| Packed 2-D/N-D read-only and strided 2-D/N-D read-only | `ND_Mat_View_Tests` / `Read_Only_Mat_View_Checks` |
| Strided N-D writable, geometry/strides, noncontiguous buffer rejection, padding | `ND_Strided_Mat_View_Tests` / `ND_Strided_Mat_View_Checks` |
| Row writable/read-only, 2-D writable/strided views, callback lifetime | scalar row/view tests and UInt8/UInt16 Vec3, signed vector, Vec2/Vec4, Float16 vector test packages |
| N-D continuous borrowing writable/read-only | `ND_Buffer_Access_Tests` / `ND_Buffer_Checks` |

These tests already test nonzero lower bounds, channel-independent values,
exact aliases and write propagation, read-only API behavior, padding, callback
exceptions, shared ownership, and Clone independence. Float16 tests compare
binary16 bits including signed zero, NaN payloads, infinities, and subnormals.
No 96-fold copy of a generic test was added.

`All_Family_Controls` executes all 2,025 tests against production with real
GNU ld constructor/lease wrappers. All four constructors must have nonzero
entry counts; every acquired lease must be destroyed, with no live views or
leases after the suite. It forwards to the real shim, not mocked constructors.

Independent negative evidence at both O0 and O2/-gnatp:

* legal Size=32/Object_Size=64 padded object rejects in Object_Storage;
* eight external-view forms reject padded storage before constructors or
  callbacks, preserving the entire initialized 32-byte snapshot;
* wrong value size, array stride, over-alignment, and native allowance reject
  independently; four legal wrong-allowance borrows reject before lease entry;
* null/misaligned untyped backing addresses reject without typed overlays;
* intercepted misaligned returned row/buffer addresses reject before callback
  or conversion and release all acquired leases;
* Float16 Vec3 production geometry/capacity rejections cover all eight forms,
  with no constructor/callback and the full initialized 48 bytes unchanged;
* callback exceptions release views and leases; positive paths prove the
  interception instrumentation actually runs;
* the predecessor compressed padded aliased-callback fixture remains a
  compiler rejection, reproduced independently, not a fabricated runtime test.

## Native GNAT 12 and consumers

Full fresh production build passes, with fatal warnings and no GNAT 16 ALIs.
Full AUnit: **2,025/2,025**, zero failures/errors. Instrumented all-family suite,
layout controls O0/O2, representation measurements, production negatives,
K_Means forwarding controls, and native source-unit controls pass.

Explicit Alire selection reports `gnat_external 12.2.0`; `gnatls` and runtime
paths confirm GNAT 12. Release-profile production with `ADAFLAGS="-gnatwa
-gnatwe"` passes all 2,025 tests. A separate O2/-gnatp production build also
passes all 2,025 with the checked test harness.

Direct GPRinstall and fresh independent Ada-only and mixed consumers execute
before and after prefix relocation. Installed GPR resolution, source/library
paths, `ldd -r`, and ELF metadata show OpenCV 4.6/libstdc++ and `libgnat-12.so`,
without checkout dependencies or GNAT 16 contamination. An additional direct
consumer runner lives under `tests/gnat12` for matrix reuse.

Two deliberately broader diagnostic runs are retained, not hidden:

1. Alire's optional production development profile enables `-gnatVa`, whose
   floating-point mode rejects IEEE NaN/infinity. Eight special-value tests
   then raise Constraint_Error, on both GNAT 12 and GNAT 16. The established
   production release profile does not enable this mode. No validity switches
   or tests were disabled to conceal it. See GCC 12.2 GNAT User's Guide,
   **Validity Checking**. This is an existing profile/IEEE contract mismatch,
   not an unresolved compiler diagnostic in the required production profile.
2. Compiling the entire existing test harness with `-gnatp` disables two
   deliberate subtype-conversion tests. Production O2/-gnatp is qualified
   with test checks retained; focused representation guards themselves execute
   at O2/-gnatp. Test-side range checking is not evidence of a runtime guard.

## Full AArch64 cross qualification

Public Debian GCC/GNAT/G++ 12.2.0, matching cross runtime, target-only pkg-config,
and OpenCV 4.6 sysroot compile the **entire** library and shim. Recursive
installation and independent Ada/mixed consumer cross-linking pass. ELF
inspection covers 217 archive/consumer objects, all ELF64 AArch64. Consumers
NEEDED include OpenCV `.406`, libstdc++, and `libgnat-12.so`.

The predecessor minimal sysroot initially lacked Debian libc linker-script
paths and target OpenCV dependency libraries. The disposable campaign copy
was completed from the already installed ARM64 packages, with package and ELF
evidence retained. No host library was substituted. QEMU/hardware was not
available; **target executables were not run**. Proprietary Yocto Scarthgap
support is not claimed.

The independent target ABI oracle passes all **26 C/Ada records** and rejects
all **eight comparator mutations**, separately from public vector tests.

## GNAT 16 nonregression

| OpenCV | Production/AUnit | Added O0/O2 layout | Instrumented all-family | GPRinstall tests | Installed/relocated Ada + mixed |
| --- | --- | --- | --- | --- | --- |
| 4.1 | Pass / 2025 | Pass | Pass / 2025 | 3/3 | Pass |
| 4.6 | Pass / 2025 | Pass | Pass / 2025 | 3/3 | Pass |
| 4.10 | Pass / 2025 | Pass | Pass / 2025 | 3/3 | Pass |
| 5.0 | Pass / 2025 | Pass | Pass / 2025 | 3/3 | Pass |

Independent matrix builds use separate containers/trees. Final direct
consumer runners cover **both** prefixes, Ada and mixed execution, and ELF
resolution on all four versions. Production source identities are preserved;
failed preliminary environment/style invocations remain in the evidence.
Existing macOS/Windows configurations are unchanged.

## Hosted CI and release boundary

`gnat12-production.yml` uses a real Debian 12 native compiler/runtime and
OpenCV 4.6; it invokes the actual production GPR projects, full AUnit,
instrumented all-family tests, focused O0/O2 controls, K_Means controls, and
installed consumers. Test-only AUnit sources are fetched without selecting a
GNAT 16 compiler. TLS certificate verification is retained. Existing native
and AArch64 selected-unit negative controls remain unchanged.

The hosted GNAT 16 matrix also executes added layout and instrumented
all-family controls. Hosted AArch64 full cross-link coverage is **not claimed**;
the full cross-build/link evidence above is local.

The native hosted commands were rehearsed in a **fresh stock Debian 12**
container, installing the workflow packages and retrieving Alire/AUnit with
normal verified TLS. The complete production script passes there with the
system GPRbuild and GNAT 12 runtime; it is not dependent on the preserved
research image. Workflow YAML parses successfully. Actual GitHub runs remain
separate evidence, not implied by this local rehearsal.

Production-source manifest SHA256:
`8574fccea3b8609d00e0e2f7da51af5cf066442330cb410bc5864f639db2d388`.
The same manifest matches native, cross, and all four regression trees.
The complete 96-body/84-condition inventory SHA256 is
`b986b3d51adda7e5f655130f82c16b8fe9a65c12ed1d1597048def097ca9689b`.

No public semantic validation is duplicated in the C++ shim.
No tag, release publication, Alire index PR, or merge is authorized. Alire
0.5.0 still requires independent review and hosted results for the exact
integration PR head. The optional development-profile IEEE mismatch remains
explicitly recorded for any future profile-policy decision.