/*
 * Compile-only check that exported shim operations remain declared with their
 * exact C ABI signatures. This translation unit is not linked or executed.
 */
#include "opencv_core_shim.h"

typedef opencv_core_status (*opencv_core_sparse_norm_fn)(
    const opencv_core_sparse_mat_handle *source, int32_t norm_kind,
    double *result);
typedef opencv_core_status (*opencv_core_sparse_normalize_fn)(
    const opencv_core_sparse_mat_handle *source, double target_norm,
    int32_t norm_kind, opencv_core_sparse_mat_handle **out);
typedef opencv_core_status (*opencv_core_sparse_min_max_loc_fn)(
    const opencv_core_sparse_mat_handle *source, double *minimum,
    double *maximum, int32_t *minimum_indices, int32_t *maximum_indices,
    int32_t index_count, uint8_t *has_minimum, uint8_t *has_maximum);

static opencv_core_sparse_norm_fn const sparse_norm =
    opencv_core_sparse_norm;
static opencv_core_sparse_normalize_fn const sparse_normalize =
    opencv_core_sparse_normalize;
static opencv_core_sparse_min_max_loc_fn const sparse_min_max_loc =
    opencv_core_sparse_min_max_loc;

int shim_header_probe(void)
{
    return sparse_norm == 0 || sparse_normalize == 0 ||
           sparse_min_max_loc == 0;
}
