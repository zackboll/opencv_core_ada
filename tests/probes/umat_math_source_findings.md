# Task 035 native-source and isolated-probe findings

Inspected exact OpenCV tags 4.1.0, 4.10.0, and 5.0.0 in
`modules/core/src/{mathfuncs.cpp,umatrix.cpp,ocl.cpp,matrix_wrap.cpp}`.
Normalize is in `convert_scale.dispatch.cpp` on 4.1, `norm.cpp` on 4.10,
and `norm.dispatch.cpp` on 5.0. Norm/minmax dispatch tables were also inspected
(`norm.cpp`, `minmax.cpp`, and the 5.0 dispatch/SIMD files).
Declarations/documentation were inspected in installed 4.10 `core.hpp` and
the tagged 4.1 header. Source URLs use `https://github.com/opencv/opencv/blob/`
followed by the exact tag and path, not a moving branch.

## Common operation contracts

| Operation | Native depths | Channels / dimensions | Output |
|---|---|---|---|
| Normalize L1/L2/Infinity | 8U/8S/16U/16S/32S/32F/64F/16F | All channels reduced together; N-D | Source depth/channels/shape, independent |
| Normalize MinMax | Above except 16F on 4.x; 5.0 adds 16F | All channels, unmasked; N-D | Source type/shape, independent |
| Sqrt | 32F/64F (`pow(...,0.5)`) | Independent channels; N-D CPU iterator | Same type/shape |
| Exp | 32F/64F | Independent channels; N-D CPU iterator | Same type/shape |
| Log | 32F/64F | Independent channels; N-D CPU iterator | Same type/shape |
| Pow | Integer powers: integer/floating dispatch; noninteger: 32F/64F | Independent channels; N-D | Same type/shape; native optimized 0/1/2 and +/-0.5 |
| Magnitude | Matching 32F/64F | Independent channels; native N-D CPU iterator | Same type/shape |
| Phase | Matching 32F/64F | Independent channels; native N-D CPU iterator | Same type/shape |
| CartToPolar | Matching 32F/64F | Independent channels; native N-D CPU iterator | Two same-type/shape outputs |
| PolarToCart | Angle 32F/64F, nonempty magnitude matching | Independent channels; native N-D CPU iterator | Two Angle-type/shape outputs |

The Ada Cartesian vector family retains its Rows/Columns 2-D contract despite
native N-D iteration. PolarToCart's existing Mat validator returns early for
empty Magnitude: angle-only native N-D remains possible; nonempty Magnitude
requires the existing 2-D matching policy. No new restriction is imposed there.
OpenCL unary/math dispatch generally gates dimensions <=2; CPU fallback is
normal Transparent API behavior. Calling OpenCV with typed UMat outputs does
not guarantee GPU execution. OpenCV's own CPU fallback maps internally; the
binding does not introduce mapping or Mat temporaries.

## Version-specific evidence

- **4.1:** math CPU paths use NAryMatIterator and 32F/64F HAL functions
  (`exp32f/64f`, `log32f/64f`, `magnitude32f/64f`, `fastAtan32f/64f`).
  Sqrt uses Pow's half-power path. Norm widens half blocks internally for norm
  computation; MinMax's half dispatch slot is null. Normalize keeps `rtype=-1`.
- **4.10:** same depth/dimension model. PolarToCart adds distinct-output and
  in-place handling. Math remains approximate. Typed empty Mat outputs retain
  metadata except Normalize, which releases its output.
- **5.0:** new MinMax half dispatch, and polarToCart32f/64f HAL dispatch.
  The pow 0/1/2 shortcuts remain native. Unary and vector float restrictions
  remain 32F/64F. Existing Ada Pow Float16 rejection is preserved even if a
  particular optimized native power could accept it.

No binding-side Float16 widening is added. Normalize retains native half
norm support and version-dependent MinMax acceptance. Sqrt/Exp/Log/vector
operations reject half; Pow uses the unchanged shared Ada depth/power policy.

## Empty behavior and hazards

`UMat::getMat` returns default Mat when `u == nullptr` on all three tags,
discarding typed-empty metadata. OpenCL `PROCESS_SRC` skips empty inputs, but
`checkOptimalVectorWidth` dereferences `min_element(kercns.begin(),end())`
without checking that the vector is nonempty. This is undefined behavior,
not merely an exception. The local Normalize backtrace confirms this path.

The disposable C++ probe runs one operation per process, compiled with C++17,
Wall/Wextra/Wpedantic/Werror against local 4.10. Core dumps were disabled.
Both OpenCL-use states were probed before AUnit empty tests were introduced.

| Operation | Local typed-empty Mat | Local typed-empty UMat, OpenCL off/on |
|---|---|---|
| Normalize all kinds (32F) | Default-empty result | Default-empty / SIGSEGV |
| Sqrt | Typed-empty | Default-empty / typed-empty |
| Exp | Typed-empty | Default-empty / SIGSEGV |
| Log | Typed-empty | Default-empty / SIGSEGV |
| Pow 2 | Typed-empty | Typed-empty / SIGSEGV |
| Magnitude | Typed-empty | Default-empty / SIGSEGV |
| Phase | Typed-empty | Default-empty / default-empty |
| CartToPolar | Two typed-empty | Native assertion / native assertion |
| PolarToCart | Two typed-empty | Two default-empty / two default-empty |

Default-empty Normalize succeeds. Default-empty Sqrt/Exp/Log/vector operations
fail depth validation. Default-empty Pow is publicly accepted only for
nonnegative integer powers. Native empty Pow was separately probed for
0,1,2,3,-1,-2,0.5,-0.5,1.5 on integer and floating typed empties, with OpenCL
disabled. Public Pow acceptance is Ada policy, not these raw native outcomes.
All accepted empty Pow outputs are constructed locally, consistent with the
existing Mat OpenCV 5 ARM64/KleidiCV safety bypass.

Both default-empty and typed-empty Magnitude select unit magnitude for a
nonempty floating Angle; native source tests `src1.empty()`, not `dims==0`.
Typed-empty UMat results are reconstructed without mapping for accepted float
unary/vector inputs. Normalize retains the Mat release behavior instead.

Local OpenCL runtime was available, but some device kernels failed compilation
because the installed compiler's OpenCL PCH references a missing header.
Transparent API CPU fallback nevertheless passed numerical tests. This is not
evidence of successful GPU kernel execution.

## Legacy Float64 unit-magnitude corrective (PR #36)

The reviewed head `8b3bb3385ed49b9bbcf58feb93a7df396e617415` failed hosted run
37072922847: OpenCV 4.1/4.6, Fedora, Ubuntu ARM64, and release entry point.
The direct 4.1 log reports `FAIL UMat vectors and polar` and
`FAIL UMat math OpenCL disabled`, both `angle only X` at line 42:
1553/1555 passed. Float32 succeeds; legacy Float64 empty-Magnitude CPU output
does not numerically represent unit magnitude.

Exact tags 4.1.0, 4.6.0, and 4.9.0 `modules/core/src/mathfuncs.cpp`, function
`polarToCart`, convert double Angle into float buffers and run `SinCos_32f`.
With nonempty Magnitude, they assign `x[k] = buf[0][k]*m` (and Y), correctly
converting numerically. With empty Magnitude, however, they execute:

```cpp
std::memcpy(x, buf[0], sizeof(float) * len);
std::memcpy(y, buf[1], sizeof(float) * len);
```

Here X/Y are `double *`: float representations are copied directly, and only
half the destination bytes are initialized. OpenCV 4.10.0 replaces that double
branch with element-wise `x[k] = buf[0][k]; y[k] = buf[1][k];`. Its remaining
memcpy belongs to the separate Float32 in-place branch and is not defective.
OpenCV 5.0 uses corrected polarToCart32f/64f HAL behavior.

The shared Dense helper now uses a compile-time gate
`CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR < 10` and selects compatibility only
for empty Magnitude, nonempty Angle, and CV_64F Angle. It converts Angle to a
Float32 Dense temporary, calls native unit-magnitude polarToCart with noArray,
and numerically converts the two Float32 Dense outputs to Float64. This keeps
the old Float32 SinCos precision while eliminating invalid byte copies.
Mat and UMat both use the same template. The UMat overload's typed-empty Angle
branch remains separate and unchanged. Versions 4.10/5 stay native.

All three temporaries are declared `Dense`, so the UMat instantiation has
only cv::UMat temporaries. No getMat, Mat temporary, transfer function, or
Transfers package was introduced. The retained empty/depth guard is an
upstream compatibility selector, with an ABI-safety comment identifying
partially uninitialized double outputs; it is not duplicated public rejection.

Existing UMat Vector_And_Polar assertions remain unchanged. New regressions
exercise Float64 Mat and UMat angle-only, default-empty, and typed-empty forms,
zero radians and nonzero radians/degrees with native approximation tolerance.
The OpenCL-disabled public test also runs the focused UMat regression.

Local corrective validation: full suites in isolated existing Podman images
against OpenCV 4.1.0 and 4.6.0 each passed 1557/1557, including both previously
failing UMat tests and the new Float64 Mat regression. Local 4.10.0 also passed
1557/1557; an isolated OpenCV 5.0.0 full suite also passed 1557/1557.
GNATformat checks cover the new Mat regression range and the modified UMat
test file; pre-existing Mat formatting outside that range is preserved.
Production C++ and Ada builds retain warnings-as-errors. The local
Alire pkg_config deployment attempted sudo and failed; validation used direct
GPR with the configured toolchain, without sudo or Alire configuration changes.

## Residency and validation-boundary review

Production UMat math dispatch uses cv::UMat inputs/results directly. No
getMat, transfer symbol, OpenCV.Core.Transfers dependency, cv::Mat temporary,
or mixed operand path was added. Dual publication allocates both wrapper
headers under unique_ptr before releasing either.

Raw enum/angle checks protect C ABI representations. Retained empty/depth/type
conditions select valid empty-result construction without entering undefined
OpenCL vector-width behavior; their concrete safety reasons are documented
beside the code. They are not a second general semantic validator. Polar empty
construction restores metadata lost by native mapping, not an added semantic
rejection. Nonempty inputs go directly to OpenCV, except the narrowly gated
legacy Float64 unit-magnitude compatibility described above.