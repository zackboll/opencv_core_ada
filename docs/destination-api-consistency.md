# Destination API consistency

Audit of public caller-owned destination procedures against their
function-returning counterparts. Starting point: `origin/main` at
`9ebb63f81a788e7468a095023ed9b656a55a3310` (PR #59 merged).

This change adds record overloads for the polar destination procedures.
It does not change C or C++ shim interfaces, existing signatures, or
native transforms.

## Inventory

| Family | Destination form | Disposition |
| --- | --- | --- |
| `Convert_To`, `Normalize` | Mat and UMat, `Destination : in out`, defaults match the functions | INTENTIONAL_DIFFERENCE: none. Naming and modes already match. |
| `Add`, `Subtract`, `Multiply`, `Divide`, `Abs_Diff` | Mat and UMat, inputs then `Destination : in out` | INTENTIONAL_DIFFERENCE: none. |
| `Minimum`, `Maximum` | Mat and UMat, same order | INTENTIONAL_DIFFERENCE: none. |
| `Add_Weighted`, `Scale_Add` | Mat and UMat | INTENTIONAL_DIFFERENCE: none. Parameter order was not rearranged. |
| `Sqrt`, `Exp`, `Log`, `Pow` | Mat and UMat, `Destination : in out` | INTENTIONAL_DIFFERENCE: none. |
| `Magnitude`, `Phase` | Single `Destination : in out` for Mat and UMat; `Phase` keeps `Units` last | INTENTIONAL_DIFFERENCE: single output, so no record grouping applies. |
| `Bitwise_And`, `Bitwise_Or`, `Bitwise_Xor`, `Bitwise_Not` | Unmasked and masked Mat and UMat overloads | INTENTIONAL_DIFFERENCE: none. |
| `Compare`, `In_Range` | Mat and UMat, `Destination : in out` | INTENTIONAL_DIFFERENCE: none. Exact UMat alias limits stay as documented ABI policy. |
| `Cart_To_Polar`, `Polar_To_Cart` | Functions return records; procedures took separate `in out` fields | CONFIRMED_INCONSISTENCY, corrected by six record overloads that delegate to the existing procedures. Individual-field overloads remain. |
| `Copy_To` | Mat has unmasked and masked `in out` destinations. UMat has only `function Copy_To return UMat` | MISSING_FEATURE, deferred. See below. |
| `K_Means_Result`, `Nearest_Neighbor_Result`, `Covariance_Result`, `Eigen_Decomposition_Result`, `Principal_Component_Analysis_Result`, `Linear_Discriminant_Analysis_Result`, `Singular_Value_Decomposition_Result`, `Polynomial_Solution_Result`, `Inversion_Result`, `Solve_Result`, `Linear_Program_Result`, `Cubic_Solution_Result` | Function-only records or discriminated results | INTENTIONAL_DIFFERENCE: no established destination API. Not extended; native storage reuse is not qualified here. |
| Sparse `Convert_To`, `Normalize`, `To_Dense` | Functions only | INTENTIONAL_DIFFERENCE: no destination procedure to make inconsistent. |
| `OpenCV.Core.Transfers` | `To_UMat` / `To_Mat` functions only | INTENTIONAL_DIFFERENCE: ownership-transfer constructors, not reusable destinations. |

Child packages under `src/` that are not listed are typed access, views,
fixed matrices, or sparse element access. Their `in out` parameters update
elements of an existing matrix; they are not algorithm destination outputs.

## Record overload contract

`Polar_Coordinates`, `Cartesian_Coordinates`,
`UMat_Polar_Coordinates`, and `UMat_Cartesian_Coordinates` group logically
related destinations. A record overload:

- calls the existing individual-destination procedure;
- does not allocate a fresh record and assign it back;
- does not make the two fields one transaction;
- does not change native alias or overlap rules.

Each field independently owns its Mat or UMat header. Compatible storage
can be reused. Mismatched storage can detach or reallocate on its own.

## Deferred: UMat `Copy_To` destination

Native `UMat::copyTo(OutputArray)` and the masked overload exist on
OpenCV 4.1.2, 4.6.0, 4.10.0, and 5.0.0. The unmasked implementation calls
`OutputArray::create` with the source size and type, so a compatible
destination can be reused and a mismatched one reallocated. An exact
same-header, same-offset destination returns without copying. An empty
source releases the destination. OpenCV 5 then stamps the source type
onto a zero-dimension empty header; 4.1 through 4.10 only release it.
Partial overlap is not given a binding-level safety proof: after
`create`, unequal offsets still perform an allocator copy.

The current Ada `Copy_To` for UMat allocates a new UMat and copies into
that fresh header. Adding `procedure Copy_To (Self : UMat; Destination :
in out UMat)` needs a new shim entry, empty-metadata tests on each
supported OpenCV version, and an overlap contract. That is a separate
implementation task. This change does not add that binding and does not
implement copy-through-assignment.

## Not unresolved

No audited destination family was left unclassified.
