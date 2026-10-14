# GNAT 12 Float16 Vec2 layout compatibility

Starting main: `23a8a4796691cd3fe552db4aa0e8351e691a53b5` (merged PR #79).
Version remains 0.5.0-dev. This is focused Vec2 qualification, **not full
production-library GNAT 12 qualification**.

## Safety policy

GNAT 12 cannot evaluate the concrete generic-array Vector Object_Size and
Alignment expressions in Compile_Time_Error. The original buffer diagnostic
is `opencv-core-float16_vec2_buffer_access.adb:23:41: condition is not known at
compile time`. This is not a measured ABI mismatch.

The three Float16 Vec2 view/row/buffer bodies replace only those concrete
vector checks. Scalar Size/Object_Size, vector Size, scalar component size,
array packing and component indices remain statically checked. C_API ABI
assertions and all public specifications are unchanged.

The shared internal Object_Storage helper separately checks value Size,
Object_Size, array component bits, element alignment, and native alignment
allowance using ordinary call-time conditionals. The production instantiations
derive the expected allowance from depth (1/2/4/8 bytes). Object_Size is never
replaced by Size or stride. The internal generic alignment pragmas become
call-time checks; other concrete families retain their existing assertions.

Views validate representation and backing address before native construction.
Both row and buffer modes validate representation before acquiring a lease.
Actual borrowed addresses are validated before every typed pointer conversion.
Existing geometry, capacity, byte-count and ownership checks remain intact.

## Evidence

Local artifacts are retained outside the checkout at
`/home/zboll/qualification/core-ext-003-r3h-evidence`.
Predecessor worktrees and R3G evidence were inventoried, hashed and archived
without modification. R3G evidence archive SHA256:
`44c7fadb976909a15715d46eb5fee33728928355cee7dc1404a8b5363a04aeb7`.
The imported address helper matches preserved hashes:

- body: `7fe7fa22219cfa8533b0e5f7daa64681db570519ab0affef84ae38bf4505dc33`
- spec: `1597b27ad8063dbd68bbe8fd84043736b9c7c715928efabe1c10e13817eff0f4`

Native Debian GNAT 12.2.0, matching runtime, OpenCV 4.6.0:
the actual production dependency closure passes at O0 and O2/-gnatp with
warnings-as-errors. Tests cover all eight packed/strided 2-D/N-D view forms,
row/buffer modes, address identity, signed zero, infinity, NaN payload,
negative infinity, subnormal bits, stride padding and exception cleanup.
GNU ld wrappers forward to the real shim and account for constructor,
lease and destruction entries. No shim/header modification is involved.

Negative evidence is deliberately separated:

- The compressed padded callback fixture remains compiler-rejected for
  aliased-formal static mismatch. It is not claimed as a runtime borrowing test.
- A legal padded type (Size=32/Object_Size=64) independently executes the actual
  helper and rejects. Eight external-view forms reject before constructors or
  callbacks, with the entire initialized 32-byte storage unchanged.
- A legal incompatible native-allowance borrowing instantiation rejects all
  four operations with zero lease entries. Valid production paths establish
  positive lease interception and balanced cleanup, including callback errors.
- A separately measured over-aligned Vec2 (Size=Object_Size=32, alignment=4,
  component bits=32) rejects in the helper. Wrong Size, stride and allowance
  mutations reject independently. Misaligned untyped borrowed addresses reject
  before callback or typed conversion, with byte preservation and no live lease.

Native GNAT 12 and GNAT 16 measurements agree: scalar Size/Object_Size=16,
Vec2=32, component bits=16, alignment=2, array stride=4 bytes.

Public Debian AArch64 GNAT 12 compiles all three corrected bodies and five
shared helper/generic dependencies as AArch64 ELF64 using the matching runtime
and target sysroot. No host library linking or target execution is claimed.
The independent 26-record C/Ada AArch64 ABI oracle and all eight comparator
mutations pass; this is separate from public vector layout/runtime evidence.

| GNAT 16/OpenCV | Production | AUnit | Added controls O0/O2 | GPRinstall tests | Installed/relocated Ada |
| --- | --- | --- | --- | --- | --- |
| 4.1 | Pass | 2025/2025 | Pass | 3/3 | Pass |
| 4.6 | Pass | 2025/2025 | Pass | 3/3 | Pass |
| 4.10 | Pass | 2025/2025 | Pass | 3/3 | Pass |
| 5.0 | Pass | 2025/2025 | Pass | 3/3 | Pass |

Mixed Ada/C++ consumers execute against relocated prefixes on all four
configurations with native include paths. Debian 4.6 additionally runs the
existing installed/relocated mixed-consumer and ELF-resolution qualification.
GNATformat, shell syntax, source parity and git diff checks are performed.
The Linux compatibility matrix now runs the added controls. Existing Windows
and macOS workflows are preserved.

## Remaining scope

Float16 Vec3/Vec4 Object_Size assertions and other concrete vector alignment
expressions remain GNAT 12 blockers. This correction does not qualify the full
GNAT 12 library, its installation, AArch64 execution, or proprietary Yocto.
No public semantic validation is duplicated in the C++ shim.
No tag or release is part of this task; the PR must remain open for review.