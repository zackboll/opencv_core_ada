#ifndef OPENCV_CORE_SHIM_H
#define OPENCV_CORE_SHIM_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t opencv_core_status;

#define OPENCV_CORE_OK ((opencv_core_status)0)
#define OPENCV_CORE_ERROR_OPENCV ((opencv_core_status)1)
#define OPENCV_CORE_ERROR_STD ((opencv_core_status)2)
#define OPENCV_CORE_ERROR_UNKNOWN ((opencv_core_status)3)
#define OPENCV_CORE_ERROR_INVALID_ARGUMENT ((opencv_core_status)4)

/* Stable linear-program result identifiers, translated from cv::SolveLPResult. */
#define OPENCV_CORE_LP_UNIQUE ((int32_t)0)
#define OPENCV_CORE_LP_MULTIPLE ((int32_t)1)
#define OPENCV_CORE_LP_UNBOUNDED ((int32_t)2)
#define OPENCV_CORE_LP_INFEASIBLE ((int32_t)3)
#define OPENCV_CORE_LP_NUMERICAL_LOSS ((int32_t)4)

typedef struct opencv_core_mat_handle opencv_core_mat_handle;
typedef struct opencv_core_file_storage_handle
    opencv_core_file_storage_handle;

typedef struct opencv_core_point {
    int32_t x;
    int32_t y;
} opencv_core_point;

typedef struct {
    double component_0;
    double component_1;
    double component_2;
    double component_3;
} opencv_core_scalar;

/*
 * Sets the calling thread's OpenCV default RNG state.  The state is owned by
 * OpenCV and is consumed by subsequent random operations on that thread.
 */
opencv_core_status opencv_core_set_rng_seed(int32_t seed);

typedef struct {
    uint8_t component_0;
    uint8_t component_1;
    uint8_t component_2;
} opencv_core_uint8_vec3;

typedef struct {
    float component_0;
    float component_1;
    float component_2;
} opencv_core_float32_vec3;
/*
 * Stable depth identifiers for the C ABI. These are translated explicitly to
 * OpenCV depth constants by the shim and are not OpenCV's encoded Mat types.
 */
#define OPENCV_CORE_DEPTH_UINT8 ((int32_t)0)
#define OPENCV_CORE_DEPTH_INT8 ((int32_t)1)
#define OPENCV_CORE_DEPTH_UINT16 ((int32_t)2)
#define OPENCV_CORE_DEPTH_INT16 ((int32_t)3)
#define OPENCV_CORE_DEPTH_INT32 ((int32_t)4)
#define OPENCV_CORE_DEPTH_FLOAT32 ((int32_t)5)
#define OPENCV_CORE_DEPTH_FLOAT64 ((int32_t)6)
#define OPENCV_CORE_DEPTH_FLOAT16 ((int32_t)7)

#define OPENCV_CORE_MAX_CHANNELS ((int32_t)512)

/*
 * Stable norm identifiers for the C ABI. These are translated explicitly to
 * OpenCV norm constants by the shim.
 */
#define OPENCV_CORE_NORM_L1 ((int32_t)1)
#define OPENCV_CORE_NORM_L2 ((int32_t)2)
#define OPENCV_CORE_NORM_INF ((int32_t)3)

/* Stable normalization identifiers, translated explicitly by the shim. */
#define OPENCV_CORE_NORMALIZE_L1 ((int32_t)1)
#define OPENCV_CORE_NORMALIZE_L2 ((int32_t)2)
#define OPENCV_CORE_NORMALIZE_INF ((int32_t)3)
#define OPENCV_CORE_NORMALIZE_MIN_MAX ((int32_t)4)

/*
 * Stable comparison-kind identifiers for the C ABI. These are translated
 * explicitly to OpenCV CmpTypes by the shim and are not cv::CmpTypes values.
 */
#define OPENCV_CORE_COMPARE_EQUAL ((int32_t)0)
#define OPENCV_CORE_COMPARE_NOT_EQUAL ((int32_t)1)
#define OPENCV_CORE_COMPARE_LESS_THAN ((int32_t)2)
#define OPENCV_CORE_COMPARE_LESS_OR_EQUAL ((int32_t)3)
#define OPENCV_CORE_COMPARE_GREATER_THAN ((int32_t)4)
#define OPENCV_CORE_COMPARE_GREATER_OR_EQUAL ((int32_t)5)

/* Stable flip identifiers with the documented cv::flip sign semantics. */
#define OPENCV_CORE_FLIP_VERTICAL ((int32_t)0)
#define OPENCV_CORE_FLIP_HORIZONTAL ((int32_t)1)
#define OPENCV_CORE_FLIP_BOTH_AXES ((int32_t)-1)

/* Stable border identifiers, translated explicitly to cv::BorderTypes. */
#define OPENCV_CORE_BORDER_CONSTANT ((int32_t)0)
#define OPENCV_CORE_BORDER_REPLICATE ((int32_t)1)
#define OPENCV_CORE_BORDER_REFLECT ((int32_t)2)
#define OPENCV_CORE_BORDER_REFLECT_101 ((int32_t)3)
#define OPENCV_CORE_BORDER_WRAP ((int32_t)4)

/*
 * Maps a zero-based one-dimensional coordinate through a stable border kind.
 * On success, out_index is a source coordinate or -1 for an out-of-range
 * constant border coordinate.
 */
opencv_core_status opencv_core_border_interpolate(int32_t position,
                                                  int32_t length,
                                                  int32_t border_kind,
                                                  int32_t *out_index);

/* Stable rotation identifiers, translated explicitly to cv::RotateFlags. */
#define OPENCV_CORE_ROTATE_90_CLOCKWISE ((int32_t)0)
#define OPENCV_CORE_ROTATE_180 ((int32_t)1)
#define OPENCV_CORE_ROTATE_90_COUNTERCLOCKWISE ((int32_t)2)

/* Stable reduction identifiers, translated explicitly by the shim. */
#define OPENCV_CORE_REDUCE_ACROSS_ROWS ((int32_t)0)
#define OPENCV_CORE_REDUCE_ACROSS_COLUMNS ((int32_t)1)
#define OPENCV_CORE_REDUCE_SUM ((int32_t)0)
#define OPENCV_CORE_REDUCE_AVERAGE ((int32_t)1)
#define OPENCV_CORE_REDUCE_MAXIMUM ((int32_t)2)
#define OPENCV_CORE_REDUCE_MINIMUM ((int32_t)3)
#define OPENCV_CORE_REDUCE_SUM_OF_SQUARES ((int32_t)4)
#define OPENCV_CORE_DEFAULT_OUTPUT_DEPTH ((int32_t)-1)

#define OPENCV_CORE_TRANSPOSED_PRODUCT_TRANSPOSE_TIMES_SELF ((uint8_t)0)
#define OPENCV_CORE_TRANSPOSED_PRODUCT_SELF_TIMES_TRANSPOSE ((uint8_t)1)

#define OPENCV_CORE_SAMPLE_ORIENTATION_ROWS ((int32_t)0)
#define OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS ((int32_t)1)

#define OPENCV_CORE_COVARIANCE_SCALING_UNSCALED ((int32_t)0)
#define OPENCV_CORE_COVARIANCE_SCALING_BY_SAMPLE_COUNT ((int32_t)1)

/*
 * Stable DFT transform-kind identifiers for the C ABI. These are
 * translated explicitly to OpenCV DftFlags by the shim and are not
 * a raw cv::DftFlags mask.
 */
#define OPENCV_CORE_DFT_FORWARD_COMPLEX ((int32_t)0)
#define OPENCV_CORE_DFT_INVERSE_COMPLEX ((int32_t)1)
#define OPENCV_CORE_DFT_INVERSE_REAL ((int32_t)2)

/*
 * Stable DCT transform-kind identifiers for the C ABI. These are
 * translated explicitly to OpenCV DCT flags by the shim and are not
 * a raw cv::DftFlags / DCT_* mask.
 */
#define OPENCV_CORE_DCT_FORWARD ((int32_t)0)
#define OPENCV_CORE_DCT_INVERSE ((int32_t)1)

/*
 * Stable spectrum-product identifiers for the C ABI. These are
 * translated explicitly to cv::mulSpectrums conjB by the shim and
 * are not a raw OpenCV flag or Boolean.
 */
#define OPENCV_CORE_SPECTRUM_PRODUCT_ORDINARY ((int32_t)0)
#define OPENCV_CORE_SPECTRUM_PRODUCT_CONJUGATE_RIGHT ((int32_t)1)

/*
 * Returns a borrowed pointer to the diagnostic for the most recent failed shim
 * operation on the calling thread. The pointer remains valid only until a
 * subsequent shim operation changes that thread's error state. The caller must
 * not free it and must copy it to retain the message.
 */
const char *opencv_core_last_error_message(void);

opencv_core_status
opencv_core_mat_create(opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_create_2d(int32_t rows, int32_t columns, int32_t depth,
                          int32_t channels,
                          opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_copy(const opencv_core_mat_handle *source,
                     opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_clone(const opencv_core_mat_handle *source,
                      opencv_core_mat_handle **out_mat);

/*
 * Clusters borrowed Float32 samples with cv::kmeans. Initialization is the
 * stable ABI identifier 0 (random centers) or 1 (k-means++ centers), not an
 * OpenCV flag. All output pointers must be non-null and labels/centers output
 * pointer locations must be distinct. Each supplied output is initialized to
 * null/null/0 before validation or work. Both independently owned handles are
 * allocated before either is published, so every failure leaves safe values in
 * all supplied outputs. The shim rejects arithmetic ranges that OpenCV 4.10
 * evaluates with signed int before allocation or parallel work.
 */
opencv_core_status
opencv_core_mat_kmeans(const opencv_core_mat_handle *samples,
                       int32_t cluster_count, int32_t maximum_iterations,
                       double epsilon, int32_t attempts,
                       int32_t initialization,
                       opencv_core_mat_handle **out_labels,
                       opencv_core_mat_handle **out_centers,
                       double *out_compactness);

/*
 * Clusters borrowed Float32 samples using borrowed Int32 C1 initial labels.
 * The labels must be a row or column vector with one label per sample. The
 * shim clones and canonicalizes labels before cv::kmeans, so the caller's Mat
 * is never used as its mutable InputOutputArray. subsequent_initialization is
 * the stable ABI identifier 0 (random centers) or 1 (k-means++ centers), not
 * an OpenCV flag. Output initialization, alias rejection, and ownership
 * publication follow opencv_core_mat_kmeans.
 */
opencv_core_status
opencv_core_mat_kmeans_with_initial_labels(
    const opencv_core_mat_handle *samples,
    const opencv_core_mat_handle *initial_labels, int32_t cluster_count,
    int32_t maximum_iterations, double epsilon, int32_t attempts,
    int32_t subsequent_initialization, opencv_core_mat_handle **out_labels,
    opencv_core_mat_handle **out_centers, double *out_compactness);

/*
 * Finds K nearest rows with cv::batchDistance. Queries and candidates are
 * borrowed. kind is the stable ABI identifier 0..4 for L1, L2, squared L2,
 * Hamming, and Hamming2. Each supplied output is initialized to null before
 * validation; output pointer locations must be distinct. On success both
 * independently owned handles are published together. On failure every
 * supplied output remains null. Mask, update, crosscheck, and K=0 mode are
 * intentionally unavailable through this ABI.
 */
opencv_core_status
opencv_core_mat_batch_distance(const opencv_core_mat_handle *queries,
                               const opencv_core_mat_handle *candidates,
                               int32_t neighbor_count, int32_t kind,
                               opencv_core_mat_handle **out_distances,
                               opencv_core_mat_handle **out_indices);

/*
 * Returns a newly allocated, independent Mat with rows and columns exchanged.
 * The result preserves source type, including depth and channel count.
 */
opencv_core_status
opencv_core_mat_transpose(const opencv_core_mat_handle *source,
                          opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat with source dimensions and type.
 * flip_kind reverses rows (VERTICAL), columns (HORIZONTAL), or both axes.
 */
opencv_core_status
opencv_core_mat_flip(const opencv_core_mat_handle *source, int32_t flip_kind,
                     opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat with source dimensions and type.
 * axis is 0 (each row) or 1 (each column). descending is 0 (ascending) or 1
 * (descending). source is borrowed. The result does not share storage with
 * source. OpenCV 4.10 requires a single-channel source of a supported depth.
 */
opencv_core_status
opencv_core_mat_sort(const opencv_core_mat_handle *source, uint8_t axis,
                     uint8_t descending, opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Int32 single-channel Mat of source
 * size. axis is 0 (each row) or 1 (each column). descending is 0 (ascending)
 * or 1 (descending). source is borrowed. The result stores zero-based original
 * column indices when axis is 0 and original row indices when axis is 1.
 * OpenCV 4.10 requires a single-channel source of a supported depth.
 */
opencv_core_status
opencv_core_mat_sort_indices(const opencv_core_mat_handle *source, uint8_t axis,
                             uint8_t descending,
                             opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat with the requested border. The
 * border kind is a stable ABI identifier. isolated is uint8_t false (0) or
 * true (1); true restricts Region extrapolation to Region boundaries.
 */
opencv_core_status
opencv_core_mat_copy_make_border(const opencv_core_mat_handle *source,
                                 int32_t top, int32_t bottom, int32_t left,
                                 int32_t right, int32_t border_kind,
                                 const opencv_core_scalar *value,
                                 uint8_t isolated,
                                 opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat rotated by a multiple of 90
 * degrees. The result preserves source type; 90-degree rotations exchange
 * rows and columns, while a 180-degree rotation preserves source dimensions.
 */
opencv_core_status
opencv_core_mat_rotate(const opencv_core_mat_handle *source, int32_t rotation_kind,
                       opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing row_repetitions by
 * column_repetitions tiles of source. Both counts must be positive. Source
 * type is preserved, including depth and channel count.
 */
opencv_core_status
opencv_core_mat_repeat(const opencv_core_mat_handle *source,
                       int32_t row_repetitions, int32_t column_repetitions,
                       opencv_core_mat_handle **out_mat);

/*
 * Reduces a two-dimensional Mat along the requested axis. output_depth is a
 * stable depth identifier, or OPENCV_CORE_DEFAULT_OUTPUT_DEPTH to use cv::reduce
 * default dtype behavior. The result is a newly owned Mat handle.
 */
opencv_core_status
opencv_core_mat_reduce(const opencv_core_mat_handle *source, int32_t axis,
                       int32_t reduction_kind, int32_t output_depth,
                       opencv_core_mat_handle **out_mat);

/*
 * Returns a newly owned CV_32SC1 Mat of zero-based extremum indices. axis uses
 * OPENCV_CORE_REDUCE_ACROSS_ROWS or OPENCV_CORE_REDUCE_ACROSS_COLUMNS;
 * last_index is 0 for first occurrence and 1 for last occurrence.
 */
opencv_core_status
opencv_core_mat_reduce_arg_min(const opencv_core_mat_handle *source,
                               int32_t axis, uint8_t last_index,
                               opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_reduce_arg_max(const opencv_core_mat_handle *source,
                               int32_t axis, uint8_t last_index,
                               opencv_core_mat_handle **out_mat);

/*
 * Horizontally concatenates count borrowed source Mats in input order. Inputs
 * must have identical row counts and complete types. An empty input collection
 * produces an empty Mat. On success out_mat receives one independently owned
 * Mat handle.
 */
opencv_core_status
opencv_core_mat_hconcat(const opencv_core_mat_handle *const *sources,
                        int32_t count, opencv_core_mat_handle **out_mat);

/*
 * Vertically concatenates count borrowed source Mats in input order. Inputs
 * must have identical column counts and complete types. An empty input
 * collection produces an empty Mat. On success out_mat receives one
 * independently owned Mat handle.
 */
opencv_core_status
opencv_core_mat_vconcat(const opencv_core_mat_handle *const *sources,
                        int32_t count, opencv_core_mat_handle **out_mat);

/*
 * Splits a non-empty Mat into count independently owned, single-channel Mat
 * handles. count must equal source's channel count. out_mats must reference
 * count writable handle slots; all slots are initialized to null before work
 * begins. The caller owns each returned handle and must destroy it. For an
 * empty source, count must be zero and no output handles are returned.
 */
opencv_core_status
opencv_core_mat_split(const opencv_core_mat_handle *source,
                      opencv_core_mat_handle **out_mats, int32_t count);

/*
 * Extracts the zero-based channel from source into one independently owned,
 * single-channel Mat handle. channel must be less than source's channel count.
 * source may be empty; it then has one channel and channel must be zero.
 */
opencv_core_status
opencv_core_mat_extract_channel(const opencv_core_mat_handle *source,
                                int32_t channel,
                                opencv_core_mat_handle **out_mat);

/*
 * Copies the single channel in source into the zero-based channel of the
 * preallocated destination. Source and destination must have identical
 * dimensions and depth; channel must be less than destination's channel count.
 * Destination storage is modified in place.
 */
opencv_core_status
opencv_core_mat_insert_channel(const opencv_core_mat_handle *source,
                                opencv_core_mat_handle *destination,
                                int32_t channel);

/*
 * Mixes channels between preallocated Mat collections. sources and
 * destinations are borrowed arrays of handles. from_to contains pair_count
 * flattened source/destination channel pairs; a negative source channel
 * zero-fills its destination channel.
 */
opencv_core_status
opencv_core_mat_mix_channels(const opencv_core_mat_handle *const *sources,
                             int32_t source_count,
                             opencv_core_mat_handle *const *destinations,
                             int32_t destination_count,
                             const int32_t *from_to, int32_t pair_count);

/*
 * Merges count non-empty Mats with identical dimensions and depth. Each input
 * may have multiple channels; their channels are concatenated in input order.
 * sources is borrowed and remains owned by the caller. count must be positive
 * and the total channel count must not exceed OPENCV_CORE_MAX_CHANNELS. On
 * success out_mat receives one independently owned Mat handle.
 */
opencv_core_status
opencv_core_mat_merge(const opencv_core_mat_handle *const *sources,
                      int32_t count, opencv_core_mat_handle **out_mat);

/*
 * Copies source into destination. Destination is allocated or reallocated to
 * source's shape and type when necessary. Exact self-copy is supported;
 * partially overlapping source and destination storage is not supported.
 */
opencv_core_status
opencv_core_mat_copy_to(const opencv_core_mat_handle *source,
                        opencv_core_mat_handle *destination);

/*
 * Copies source elements selected by mask into destination. Mask must be a
 * same-sized single-channel UInt8 Mat; any nonzero value selects the complete
 * source element, including every channel. If destination is allocated or
 * reallocated, unselected elements are initialized to zero; otherwise they
 * retain their previous values. Exact self-copy is supported; partially
 * overlapping source and destination storage is not supported.
 */
opencv_core_status
opencv_core_mat_copy_to_masked(const opencv_core_mat_handle *source,
                               opencv_core_mat_handle *destination,
                               const opencv_core_mat_handle *mask);

/*
 * Converts source data to the requested depth, preserving its channel count,
 * using OpenCV's saturating alpha * source + beta transformation.
 */
opencv_core_status
opencv_core_mat_convert_to(const opencv_core_mat_handle *source,
                           int32_t depth, double scale, double offset,
                           opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated UInt8 Mat with source's shape and channel count.
 * Each component is converted by OpenCV as saturate_cast<uchar>(abs(source *
 * scale + offset)).
 */
opencv_core_status
opencv_core_mat_convert_scale_abs(const opencv_core_mat_handle *source,
                                  double scale, double offset,
                                  opencv_core_mat_handle **out_mat);

/*
 * Applies a 256-entry lookup table with cv::LUT. Source must have CV_8U
 * or CV_8S depth. The table must contain exactly 256 continuous elements
 * and either one channel or the same channel count as source. The result
 * has source's shape and channel count, the table's depth, and newly
 * owned independent storage. CV_16F tables are not supported.
 */
opencv_core_status
opencv_core_mat_apply_lut(const opencv_core_mat_handle *source,
                          const opencv_core_mat_handle *lut,
                          opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing the per-element
 * square root of source via cv::sqrt. Source must have CV_32F or CV_64F
 * depth. The result has source's shape, depth, and channel count.
 */
opencv_core_status
opencv_core_mat_sqrt(const opencv_core_mat_handle *source,
                     opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing the per-element
 * exponential of source via cv::exp. Source must have CV_32F or CV_64F
 * depth. The result has source's shape, depth, and channel count.
 */
opencv_core_status
opencv_core_mat_exp(const opencv_core_mat_handle *source,
                    opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing the per-element
 * natural logarithm of source via cv::log. Source must have CV_32F or
 * CV_64F depth. The result has source's shape, depth, and channel count.
 */
opencv_core_status
opencv_core_mat_log(const opencv_core_mat_handle *source,
                    opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing each source
 * element raised to power via cv::pow. Integer powers support the
 * integer and floating depths that OpenCV implements; non-integer
 * powers require CV_32F or CV_64F. The result has source's shape,
 * depth, and channel count.
 */
opencv_core_status
opencv_core_mat_pow(const opencv_core_mat_handle *source, double power,
                    opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing the per-element
 * magnitude of matching (x, y) pairs via cv::magnitude. X and Y must have
 * CV_32F or CV_64F depth and identical size and type. The result has X's
 * shape, depth, and channel count.
 */
opencv_core_status
opencv_core_mat_magnitude(const opencv_core_mat_handle *x,
                          const opencv_core_mat_handle *y,
                          opencv_core_mat_handle **out_mat);

/*
 * Returns a newly allocated, independent Mat containing the per-element
 * phase of matching (x, y) pairs via cv::phase. X and Y must have
 * CV_32F or CV_64F depth and identical size and type. angle_in_degrees
 * is uint8_t false (0) or true (1). The result has X's shape, depth,
 * and channel count.
 */
opencv_core_status
opencv_core_mat_phase(const opencv_core_mat_handle *x,
                      const opencv_core_mat_handle *y,
                      uint8_t angle_in_degrees,
                      opencv_core_mat_handle **out_mat);

/*
 * Returns two newly allocated, independent Mats containing the per-element
 * magnitude and phase of matching (x, y) pairs via cv::cartToPolar. X and Y
 * must have CV_32F or CV_64F depth and identical size and type.
 * angle_in_degrees is uint8_t false (0) or true (1). Both results have X's
 * shape, depth, and channel count. Both output pointer arguments must be
 * non-null and distinct. On success both returned handles are independently
 * owned. On any failure both outputs remain null.
 */
opencv_core_status
opencv_core_mat_cart_to_polar(const opencv_core_mat_handle *x,
                              const opencv_core_mat_handle *y,
                              uint8_t angle_in_degrees,
                              opencv_core_mat_handle **out_magnitude,
                              opencv_core_mat_handle **out_angle);

/*
 * Returns two newly allocated, independent Mats containing the per-element
 * Cartesian coordinates of matching (magnitude, angle) pairs via
 * cv::polarToCart. Angle must have CV_32F or CV_64F depth and determines
 * both output sizes and types. An empty Magnitude is treated as unit
 * magnitude; a non-empty Magnitude must have the same size and type as
 * Angle. angle_in_degrees is uint8_t false (0) or true (1). Both output
 * pointer arguments must be non-null and distinct. On success both
 * returned handles are independently owned. On any failure both outputs
 * remain null.
 */
opencv_core_status
opencv_core_mat_polar_to_cart(const opencv_core_mat_handle *magnitude,
                              const opencv_core_mat_handle *angle,
                              uint8_t angle_in_degrees,
                              opencv_core_mat_handle **out_x,
                              opencv_core_mat_handle **out_y);

/*
 * Returns a newly allocated, independent Mat normalized with no mask and the
 * same depth as source. For norm modes beta is ignored by OpenCV; for min/max
 * mode alpha and beta define the destination range.
 */
opencv_core_status
opencv_core_mat_normalize(const opencv_core_mat_handle *source,
                          int32_t normalize_kind, double alpha, double beta,
                          opencv_core_mat_handle **out_mat);

/*
 * Adds or subtracts two Mats with identical dimensions and type. Each returns
 * a newly allocated, independent result with the same type as its operands.
 */
opencv_core_status
opencv_core_mat_add(const opencv_core_mat_handle *left,
                    const opencv_core_mat_handle *right,
                    opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_subtract(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat);

/*
 * Multiplies or divides two Mats with identical dimensions and type using an
 * OpenCV scale of 1.0. Each returns an independent result of the same type.
 */
opencv_core_status
opencv_core_mat_multiply(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_divide(const opencv_core_mat_handle *left,
                       const opencv_core_mat_handle *right,
                       opencv_core_mat_handle **out_mat);

/*
 * Calculates the OpenCV absolute difference of two Mats with identical
 * dimensions and type, returning an independently allocated result.
 */
opencv_core_status
opencv_core_mat_abs_diff(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat);

/*
 * Calculates the OpenCV per-element minimum or maximum of two Mats with
 * identical dimensions and type, returning an independently allocated result.
 */
opencv_core_status
opencv_core_mat_minimum(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_maximum(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        opencv_core_mat_handle **out_mat);

/*
 * Returns alpha * left + beta * right + gamma for two Mats with identical
 * dimensions and type, using the same output type and independent storage.
 */
opencv_core_status
opencv_core_mat_add_weighted(const opencv_core_mat_handle *left, double alpha,
                             const opencv_core_mat_handle *right, double beta,
                             double gamma, opencv_core_mat_handle **out_mat);

/*
 * Returns scale * left + right for two Mats with identical dimensions and
 * type, using cv::scaleAdd. The result has the same type and independent
 * storage. Depths below CV_32F use OpenCV's addWeighted path: 8- and
 * 16-bit integer depths saturate; CV_32S does not.
 */
opencv_core_status
opencv_core_mat_scale_add(const opencv_core_mat_handle *left, double scale,
                          const opencv_core_mat_handle *right,
                          opencv_core_mat_handle **out_mat);

/* Unmasked bitwise operations preserve the complete stored bit pattern. */
opencv_core_status
opencv_core_mat_bitwise_and(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_or(const opencv_core_mat_handle *left,
                           const opencv_core_mat_handle *right,
                           opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_xor(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_not(const opencv_core_mat_handle *source,
                            opencv_core_mat_handle **out_mat);

/* Masked operations accept a same-sized, single-channel UInt8 mask. */
opencv_core_status
opencv_core_mat_bitwise_and_masked(const opencv_core_mat_handle *left,
                                   const opencv_core_mat_handle *right,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_or_masked(const opencv_core_mat_handle *left,
                                  const opencv_core_mat_handle *right,
                                  const opencv_core_mat_handle *mask,
                                  opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_xor_masked(const opencv_core_mat_handle *left,
                                   const opencv_core_mat_handle *right,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_bitwise_not_masked(const opencv_core_mat_handle *source,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat);

/* Produces a UInt8 single-channel inclusive range mask for one to four channels. */
opencv_core_status
opencv_core_mat_in_range_scalar(const opencv_core_mat_handle *source,
                                const opencv_core_scalar *lower,
                                const opencv_core_scalar *upper,
                                opencv_core_mat_handle **out_mat);

/*
 * Compares two single-channel Mats with identical rows, columns, and depth.
 * Returns an independently allocated UInt8 single-channel mask with 255 where
 * the comparison is true and 0 otherwise. Non-contiguous views are supported.
 */
opencv_core_status
opencv_core_mat_compare(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        int32_t comparison_kind,
                        opencv_core_mat_handle **out_mat);

/*
 * Creates a distinct Mat header for the indicated non-empty 2D region. The
 * header shares source storage through OpenCV reference counting.
 */
opencv_core_status
opencv_core_mat_region(const opencv_core_mat_handle *source, int32_t x,
                       int32_t y, int32_t width, int32_t height,
                       opencv_core_mat_handle **out_mat);

/*
 * Create distinct Mat headers for a single row, single column, or half-open
 * row/column range. The headers share source storage through OpenCV reference
 * counting and do not copy data. Range start is inclusive and range stop is
 * exclusive; equal endpoints are accepted and yield an empty Mat.
 */
opencv_core_status
opencv_core_mat_row_view(const opencv_core_mat_handle *source, int32_t row,
                         opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_column_view(const opencv_core_mat_handle *source,
                            int32_t column,
                            opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_row_range_view(const opencv_core_mat_handle *source,
                               int32_t start, int32_t stop,
                               opencv_core_mat_handle **out_mat);

opencv_core_status
opencv_core_mat_column_range_view(const opencv_core_mat_handle *source,
                                  int32_t start, int32_t stop,
                                  opencv_core_mat_handle **out_mat);

/*
 * Creates a distinct two-dimensional Mat header by invoking Mat::reshape.
 * channels must be in 1 .. OPENCV_CORE_MAX_CHANNELS. A rows value of zero
 * preserves the source row count; otherwise it is the requested positive row
 * count. The returned header shares source storage and never copies data.
 */
opencv_core_status
opencv_core_mat_reshape(const opencv_core_mat_handle *source, int32_t channels,
                        int32_t rows, opencv_core_mat_handle **out_mat);

/*
 * Creates an independent square diagonal matrix from a row or column vector.
 * The result has the source element type, including channel count, and its
 * off-diagonal elements are zero. Source and result do not share storage.
 */
opencv_core_status
opencv_core_mat_diagonal_matrix(const opencv_core_mat_handle *diagonal,
                                opencv_core_mat_handle **out_mat);

/*
 * Creates a distinct single-column Mat header for a non-empty source diagonal.
 * Offset zero selects the main diagonal; positive offsets select diagonals
 * above it and negative offsets select diagonals below it. The header shares
 * source storage through OpenCV reference counting and does not copy data.
 */
opencv_core_status
opencv_core_mat_diagonal_view(const opencv_core_mat_handle *source,
                              int32_t offset,
                              opencv_core_mat_handle **out_mat);

/* Null-safe and non-throwing. */
void opencv_core_mat_destroy(opencv_core_mat_handle *mat);

opencv_core_status
opencv_core_mat_is_empty(const opencv_core_mat_handle *mat,
                         uint8_t *out_is_empty);

opencv_core_status
opencv_core_mat_rows(const opencv_core_mat_handle *mat, int32_t *out_rows);

opencv_core_status
opencv_core_mat_columns(const opencv_core_mat_handle *mat,
                        int32_t *out_columns);

opencv_core_status
opencv_core_mat_channels(const opencv_core_mat_handle *mat,
                         int32_t *out_channels);

opencv_core_status
opencv_core_mat_depth(const opencv_core_mat_handle *mat, int32_t *out_depth);

opencv_core_status
opencv_core_mat_total(const opencv_core_mat_handle *mat, uint64_t *out_total);

opencv_core_status
opencv_core_mat_element_size(const opencv_core_mat_handle *mat,
                             uint64_t *out_element_size);

opencv_core_status
opencv_core_mat_channel_size(const opencv_core_mat_handle *mat,
                             uint64_t *out_channel_size);

opencv_core_status
opencv_core_mat_is_continuous(const opencv_core_mat_handle *mat,
                              uint8_t *out_is_continuous);

opencv_core_status
opencv_core_mat_is_submatrix(const opencv_core_mat_handle *mat,
                             uint8_t *out_is_submatrix);

/*
 * Read or write one element of a two-dimensional, single-channel Mat with the
 * indicated storage type. Row and column are zero-based. These functions
 * validate the handle, type, channel count, and bounds before access.
 */
opencv_core_status
opencv_core_mat_get_uint8(const opencv_core_mat_handle *mat, int32_t row,
                          int32_t column, uint8_t *out_value);

opencv_core_status
opencv_core_mat_set_uint8(opencv_core_mat_handle *mat, int32_t row,
                          int32_t column, uint8_t value);

opencv_core_status
opencv_core_mat_get_float32(const opencv_core_mat_handle *mat, int32_t row,
                            int32_t column, float *out_value);

/* Stable Float32 classification identifiers. */
#define OPENCV_CORE_FLOAT32_FINITE ((int32_t)0)
#define OPENCV_CORE_FLOAT32_POSITIVE_INFINITY ((int32_t)1)
#define OPENCV_CORE_FLOAT32_NEGATIVE_INFINITY ((int32_t)2)
#define OPENCV_CORE_FLOAT32_NOT_A_NUMBER ((int32_t)3)

opencv_core_status
opencv_core_mat_classify_float32(const opencv_core_mat_handle *mat,
                                 int32_t row, int32_t column,
                                 int32_t *out_classification);

opencv_core_status
opencv_core_mat_set_float32(opencv_core_mat_handle *mat, int32_t row,
                            int32_t column, float value);

/*
 * Copy one complete row of a two-dimensional, single-channel Mat. The caller
 * supplies exactly mat columns elements. Each row may be copied independently;
 * whole-Mat continuity is not required.
 */
opencv_core_status
opencv_core_mat_read_uint8_row(const opencv_core_mat_handle *mat, int32_t row,
                               uint8_t *data, uint64_t element_count);

opencv_core_status
opencv_core_mat_write_uint8_row(opencv_core_mat_handle *mat, int32_t row,
                                const uint8_t *data, uint64_t element_count);

opencv_core_status
opencv_core_mat_read_float32_row(const opencv_core_mat_handle *mat,
                                 int32_t row, float *data,
                                 uint64_t element_count);

opencv_core_status
opencv_core_mat_write_float32_row(opencv_core_mat_handle *mat,
                                  int32_t row, const float *data,
                                  uint64_t element_count);

/*
 * Read or write one element of a two-dimensional, exactly three-channel Mat.
 * Row, column, and component numbering are zero-based. The ABI Vec structs
 * are converted explicitly to/from cv::Vec; their layouts are independent.
 */
opencv_core_status
opencv_core_mat_get_uint8_vec3(const opencv_core_mat_handle *mat, int32_t row,
                               int32_t column,
                               opencv_core_uint8_vec3 *out_value);

opencv_core_status
opencv_core_mat_set_uint8_vec3(opencv_core_mat_handle *mat, int32_t row,
                               int32_t column,
                               const opencv_core_uint8_vec3 *value);

opencv_core_status
opencv_core_mat_get_float32_vec3(const opencv_core_mat_handle *mat,
                                 int32_t row, int32_t column,
                                 opencv_core_float32_vec3 *out_value);

opencv_core_status
opencv_core_mat_set_float32_vec3(opencv_core_mat_handle *mat,
                                 int32_t row, int32_t column,
                                 const opencv_core_float32_vec3 *value);

/*
 * Copy one complete row of a two-dimensional, exactly three-channel Mat.
 * element_count is the logical Vec3 element count and must equal mat columns.
 * data is a flat scalar buffer ordered as column0.component0,
 * column0.component1, column0.component2, column1.component0, and so on.
 * The representation is independent of cv::Vec layout.
 */
opencv_core_status
opencv_core_mat_read_uint8_vec3_row(const opencv_core_mat_handle *mat,
                                    int32_t row, uint8_t *data,
                                    uint64_t element_count);

opencv_core_status
opencv_core_mat_write_uint8_vec3_row(opencv_core_mat_handle *mat,
                                     int32_t row, const uint8_t *data,
                                     uint64_t element_count);

opencv_core_status
opencv_core_mat_read_float32_vec3_row(const opencv_core_mat_handle *mat,
                                      int32_t row, float *data,
                                      uint64_t element_count);

opencv_core_status
opencv_core_mat_write_float32_vec3_row(opencv_core_mat_handle *mat,
                                       int32_t row, const float *data,
                                       uint64_t element_count);

opencv_core_status
opencv_core_mat_set_to(opencv_core_mat_handle *mat,
                       const opencv_core_scalar *value);

/* Fills an existing Mat in place using OpenCV's default RNG. */
opencv_core_status
opencv_core_mat_fill_uniform(opencv_core_mat_handle *destination,
                             const opencv_core_scalar *lower_bound,
                             const opencv_core_scalar *upper_bound);

opencv_core_status
opencv_core_mat_fill_normal(opencv_core_mat_handle *destination,
                            const opencv_core_scalar *mean,
                            const opencv_core_scalar *standard_deviation);

/* Shuffles a non-empty 2-D row or column vector in place using the calling
 * thread's OpenCV default RNG. Complete elements must have a dispatcher-
 * supported size: 1, 2, 3, 4, 6, 8, 12, 16, 24, or 32 bytes. */
opencv_core_status
opencv_core_mat_shuffle(opencv_core_mat_handle *destination);

/*
 * Sets source elements selected by mask to value. Mask must be a same-sized
 * single-channel UInt8 Mat; any nonzero value selects the complete element.
 */
opencv_core_status
opencv_core_mat_set_to_masked(opencv_core_mat_handle *mat,
                              const opencv_core_scalar *value,
                              const opencv_core_mat_handle *mask);

opencv_core_status
opencv_core_mat_sum(const opencv_core_mat_handle *mat,
                    opencv_core_scalar *out_sum);

/*
 * Computes the per-channel sum of the main diagonal. Source must have at
 * most four channels so its complete result fits opencv_core_scalar. Empty
 * and rectangular Mats are accepted.
 */
opencv_core_status
opencv_core_mat_trace(const opencv_core_mat_handle *mat,
                      opencv_core_scalar *out_trace);

/*
 * Computes the determinant of a borrowed non-empty square single-channel
 * floating Mat. Supported types are CV_32FC1 and CV_64FC1. A value of 0.0
 * is a successful singular-matrix result, not an ABI failure.
 */
opencv_core_status
opencv_core_mat_determinant(const opencv_core_mat_handle *source,
                            double *out_determinant);

/*
 * Computes the scalar dot product of two borrowed Mats using
 * cv::Mat::dot. Both operands must be non-empty, at most
 * two-dimensional, and share identical rows, columns, and complete
 * type. Supported depths are CV_8U, CV_8S, CV_16U, CV_16S, CV_32S,
 * CV_32F, and CV_64F. CV_16F is rejected. Multi-channel Mats are
 * accepted; every corresponding channel component is multiplied and
 * summed. Two-channel values are ordinary scalar channels, not
 * complex/Hermitian arithmetic. Continuity is not required. Inputs
 * are borrowed and unmodified. The result is one double.
 */
opencv_core_status
opencv_core_mat_dot_product(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            double *out_value);

/*
 * Computes the scalar Mahalanobis distance of two borrowed 1D vectors
 * using cv::Mahalanobis. Self and Other must be non-empty, at most
 * two-dimensional, single-channel Float32 or Float64 row (1 x N) or
 * column (N x 1) vectors with identical shape and complete type.
 * Inverse_Covariance must be a non-empty single-channel Mat of the
 * same depth and exactly N x N. Arbitrary M x N matrices are not
 * flattened into vectors. Continuity is not required. Inputs are
 * borrowed and unmodified. The result is one double.
 */
opencv_core_status
opencv_core_mat_mahalanobis_distance(
    const opencv_core_mat_handle *left,
    const opencv_core_mat_handle *right,
    const opencv_core_mat_handle *inverse_covariance,
    double *out_value);

/*
 * Computes the 3D vector cross product of two borrowed Mats using
 * cv::Mat::cross: result = left x right. Both operands must be
 * non-empty, at most two-dimensional, and share identical rows,
 * columns, and complete type. Supported public representations of one
 * three-component vector are 3x1 C1, 1x3 C1, and 1x1 C3. Supported
 * depths are CV_32F and CV_64F. Unusual shapes that happen to contain
 * three scalars, including 3x1 C3, are rejected. Continuity is not
 * required. Inputs are borrowed and unmodified. The independently
 * owned result has the same rows, columns, and complete type as left.
 */
opencv_core_status
opencv_core_mat_cross_product(const opencv_core_mat_handle *left,
                              const opencv_core_mat_handle *right,
                              opencv_core_mat_handle **out_mat);

/*
 * Inverts a borrowed square single-channel floating Mat with OpenCV
 * DECOMP_LU. Supported types are CV_32FC1 and CV_64FC1. Source is not
 * modified. A singular matrix is a successful result: out_invertible is
 * 0 and out_mat remains null. A non-singular matrix sets out_invertible
 * to 1 and publishes an independently owned result handle.
 */
opencv_core_status
opencv_core_mat_invert(const opencv_core_mat_handle *source,
                       uint8_t *out_invertible,
                       opencv_core_mat_handle **out_mat);

/*
 * Solves A * X = B for a borrowed square single-channel floating
 * coefficient matrix with OpenCV DECOMP_LU. Supported types are
 * CV_32FC1 and CV_64FC1. The right-hand side must be non-empty, have
 * the same type as the coefficients, and have the same number of rows.
 * Multiple right-hand-side columns are accepted. Both inputs are
 * borrowed and unmodified. A singular coefficient matrix is a
 * successful result: out_solved is 0 and out_solution remains null. A
 * unique solution sets out_solved to 1 and publishes an independently
 * owned result handle of shape coefficients.cols x right_hand_side.cols.
 */
opencv_core_status
opencv_core_mat_solve(const opencv_core_mat_handle *coefficients,
                      const opencv_core_mat_handle *right_hand_side,
                      uint8_t *out_solved,
                      opencv_core_mat_handle **out_solution);

/*
 * Computes OpenCV 4.10's DECOMP_SVD pseudo-solution minimizing A * X - B.
 * Inputs are borrowed and unchanged. The independently owned solution has
 * coefficients.cols rows and right_hand_side.cols columns. It is published
 * only after success; *out_solution is initialized to null on entry.
 */
opencv_core_status
opencv_core_mat_solve_least_squares(
    const opencv_core_mat_handle *coefficients,
    const opencv_core_mat_handle *right_hand_side,
    opencv_core_mat_handle **out_solution);

/*
 * Solves OpenCV 4.10's continuous maximization linear program. Objective and
 * constraints are borrowed and unchanged. On successful execution,
 * out_lp_status receives one OPENCV_CORE_LP_* identifier. Unique and multiple
 * optima publish an independently owned Float64 column solution; unbounded,
 * infeasible, and numerical-loss results leave out_solution null. Both output
 * pointers must be non-null and are initialized to INFEASIBLE and null before
 * work. The public Ada layer owns mathematical input validation.
 */
opencv_core_status
opencv_core_solve_linear_program(
    const opencv_core_mat_handle *objective,
    const opencv_core_mat_handle *constraints,
    double constraint_tolerance,
    int32_t *out_lp_status,
    opencv_core_mat_handle **out_solution);

/*
 * Finds real roots with cv::solveCubic. coefficients is borrowed. out_root_count
 * and out_roots must be non-null; they are initialized to zero and null before
 * work. The opencv_core_status reports execution success or failure.
 * On success, out_root_count is cv::solveCubic's mathematical -1/0/1/2/3 result;
 * a positive count publishes an independently owned 3 x 1 roots handle, while
 * counts at most zero leave out_roots null. On failure outputs remain safe.
 */
opencv_core_status
opencv_core_mat_solve_cubic(const opencv_core_mat_handle *coefficients,
                            int32_t *out_root_count,
                            opencv_core_mat_handle **out_roots);

/*
 * Reports the degree cv::solvePoly will use after converting coefficients to
 * CV_64F and trimming trailing coefficients whose abs(real) + abs(imaginary)
 * is at most DBL_EPSILON. out_has_leading_coefficient reports whether the
 * coefficient at that degree exceeds the same threshold. coefficients is
 * borrowed; outputs must be non-null and are initialized to safe values on
 * failure.
 */
opencv_core_status
opencv_core_mat_solve_poly_effective_degree(
    const opencv_core_mat_handle *coefficients, int32_t *out_degree,
    uint8_t *out_has_leading_coefficient);

/*
 * Solves coefficients with cv::solvePoly. coefficients is borrowed. On
 * success out_roots owns an independent effective-degree x 1 C2 Mat: the
 * original-degree padding rows produced by cv::solvePoly are not exposed.
 * out_roots and out_maximum_correction must be non-null and are initialized
 * to safe values before work.
 */
opencv_core_status
opencv_core_mat_solve_poly(const opencv_core_mat_handle *coefficients,
                           int32_t maximum_iterations,
                           opencv_core_mat_handle **out_roots,
                           double *out_maximum_correction);

/*
 * Performs ordinary algebraic matrix multiplication of two borrowed Mats
 * using cv::gemm with alpha=1, no addend, and no transpose flags:
 * result = left * right. Both operands must be non-empty, at most
 * two-dimensional, and share an identical complete type of CV_32FC1,
 * CV_64FC1, CV_32FC2, or CV_64FC2. Two-channel inputs use OpenCV
 * complex multiplication. left.cols must equal right.rows. The result
 * has shape left.rows x right.cols, the same type, and independently
 * owned storage. Continuity is not required.
 */
opencv_core_status
opencv_core_mat_matrix_multiply(const opencv_core_mat_handle *left,
                                const opencv_core_mat_handle *right,
                                opencv_core_mat_handle **out_mat);

/*
 * Performs weighted algebraic matrix multiplication with an addend using
 * cv::gemm: result = product_scale * left * right + addend_scale * addend.
 * No transpose flags are applied. left, right, and addend are borrowed.
 * All three must be non-empty, at most two-dimensional, and share an
 * identical complete type of CV_32FC1, CV_64FC1, CV_32FC2, or CV_64FC2.
 * Two-channel inputs use OpenCV complex arithmetic. left.cols must equal
 * right.rows, and addend must have the product shape left.rows x
 * right.cols even when addend_scale is 0.0. The result has that shape,
 * the same type, and independently owned storage. Continuity is not
 * required. product_scale maps to cv::gemm alpha and addend_scale maps
 * to cv::gemm beta; Float32 paths follow OpenCV's conversion of those
 * weights to float.
 */
opencv_core_status
opencv_core_mat_matrix_multiply_add(const opencv_core_mat_handle *left,
                                    const opencv_core_mat_handle *right,
                                    const opencv_core_mat_handle *addend,
                                    double product_scale,
                                    double addend_scale,
                                    opencv_core_mat_handle **out_mat);

/*
 * Computes the uncentered transposed product of a borrowed single-channel
 * Mat using cv::mulTransposed with an empty delta:
 *   order 0: scale * source^T * source, result is source.cols x source.cols
 *   order 1: scale * source * source^T, result is source.rows x source.rows
 * Source must be non-empty, at most two-dimensional, single-channel, and
 * one of CV_8U, CV_16U, CV_16S, CV_32F, or CV_64F. output_depth of -1
 * selects OpenCV 4.10 automatic depth, which is CV_64F for a CV_64F
 * source and CV_32F otherwise. Explicit output_depth must be the
 * binding's Float32 or Float64 identifier. CV_64F source with explicit
 * Float32 is rejected because OpenCV 4.10 has no such kernel. Continuity
 * is not required. The result owns independent storage.
 */
opencv_core_status
opencv_core_mat_transposed_product(const opencv_core_mat_handle *source,
                                   uint8_t order, double scale,
                                   int32_t output_depth,
                                   opencv_core_mat_handle **out_mat);

/*
 * Computes the centered transposed product of a borrowed single-channel
 * Mat using cv::mulTransposed with a required non-empty delta:
 *   order 0: scale * (source - delta)^T * (source - delta)
 *   order 1: scale * (source - delta) * (source - delta)^T
 * Delta is broadcast by OpenCV when it is 1 x source.cols, source.rows x 1,
 * or 1 x 1. Source depths remain CV_8U, CV_16U, CV_16S, CV_32F, or
 * CV_64F. Delta may be CV_8U, CV_8S, CV_16U, CV_16S, CV_32S, CV_32F, or
 * CV_64F; CV_16F is rejected. Automatic output is CV_64F when source or
 * delta is CV_64F, otherwise CV_32F. Explicit Float32 rejects a CV_64F
 * source or delta. Inputs are borrowed and unchanged. The result owns
 * independent storage.
 */
opencv_core_status
opencv_core_mat_transposed_product_with_delta(
    const opencv_core_mat_handle *source, const opencv_core_mat_handle *delta,
    uint8_t order, double scale, int32_t output_depth,
    opencv_core_mat_handle **out_mat);

/*
 * Calculates the normal feature covariance matrix and mean of a borrowed
 * sample Mat using cv::calcCovarMatrix. orientation is 0 (samples are
 * rows) or 1 (samples are columns). scaling is 0 (unscaled) or 1
 * (divide by sample count N). The shim always asks OpenCV to compute
 * the mean and always requests the normal feature covariance; scrambled
 * covariance and a caller-supplied mean are not part of this ABI.
 * ctype is taken from the source depth so Float32 stays Float32 and
 * Float64 stays Float64. Both output pointer arguments must be
 * non-null and distinct. On success both returned handles are
 * independently owned. On any failure both outputs remain null.
 */
opencv_core_status
opencv_core_mat_covariance(const opencv_core_mat_handle *source,
                           int32_t orientation, int32_t scaling,
                           opencv_core_mat_handle **out_covariance,
                           opencv_core_mat_handle **out_mean);

/*
 * Decomposes a borrowed real symmetric Mat using cv::eigen. Both
 * output pointer arguments must be non-null and distinct. On success
 * both returned handles are independently owned. Eigenvalues is N x 1
 * in descending order and eigenvectors is N x N with one vector per
 * row, matching OpenCV 4.10. The source is borrowed and unchanged.
 * If cv::eigen returns false, both outputs remain null and the call
 * fails. On any other failure both outputs remain null.
 */
opencv_core_status
opencv_core_mat_eigen_decomposition(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors);

/*
 * Decomposes a borrowed real square Mat using cv::eigenNonSymmetric.
 * OpenCV 4.10 assumes all eigenvalues are real and returns eigenvalues in
 * descending order, with each corresponding eigenvector in a row. Both output
 * pointers must be non-null and distinct; both are initialized to null before
 * work. On success both handles are independently owned. On any failure both
 * remain null. The source is borrowed and unchanged. Dimensions above
 * INT_MAX / 1000 are rejected for OpenCV 4.10 signed iteration-limit safety.
 */
opencv_core_status
opencv_core_mat_non_symmetric_eigen_decomposition(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors);

/*
 * Computes the PCA basis of a borrowed sample Mat using cv::PCA.
 * orientation is 0 (samples are rows) or 1 (samples are columns).
 * max_components is 0 to retain every available component, or a
 * positive count passed through to OpenCV (which may clamp it).
 * Negative max_components is rejected as invalid raw ABI input.
 * All three output pointer arguments must be non-null and pairwise
 * distinct. On success the three returned handles are independently
 * owned. On any failure all three outputs remain null.
 */
opencv_core_status
opencv_core_mat_principal_component_analysis(
    const opencv_core_mat_handle *source, int32_t orientation,
    int32_t max_components, opencv_core_mat_handle **out_mean,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors);

/*
 * Computes an OpenCV 4.10 LDA discriminant basis for row-aligned samples.
 * samples has N rows of D features and labels has one Int32 C1 label per
 * sample. components is zero for min(C - 1, D), or a positive exact retained
 * count. Both output pointers must be non-null and distinct. On success,
 * eigenvalues is a Float64 K x 1 column and eigenvectors is Float64 D x K,
 * with one discriminant direction per column. Inputs are borrowed and
 * unchanged; both outputs own independent storage. On any failure both output
 * handles remain null.
 */
opencv_core_status
opencv_core_mat_linear_discriminant_analysis(
    const opencv_core_mat_handle *samples,
    const opencv_core_mat_handle *labels, int32_t components,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors);

/*
 * Computes the PCA basis of a borrowed sample Mat using the OpenCV
 * 4.10 cv::PCA retained-variance overload. orientation is 0
 * (samples are rows) or 1 (samples are columns). retained_variance
 * is forwarded as a double so C++ overload resolution selects
 * PCA::operator()(..., double retainedVariance) rather than the
 * integer maxComponents overload. Public range and minimum-two
 * component policy belong in Ada; a raw caller may be rejected by
 * OpenCV. All three output pointer arguments must be non-null and
 * pairwise distinct. On success the three returned handles are
 * independently owned. On any failure all three outputs remain null.
 */
opencv_core_status
opencv_core_mat_principal_component_analysis_retained_variance(
    const opencv_core_mat_handle *source, int32_t orientation,
    double retained_variance, opencv_core_mat_handle **out_mean,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors);

/*
 * Projects borrowed samples onto a borrowed PCA basis (mean and
 * eigenvectors). orientation is 0 (samples are rows) or 1 (samples
 * are columns). Column orientation is adapted through OpenCV's
 * row-oriented PCA::project path so a one-feature 1x1 mean is not
 * treated as an ambiguous native branch. The independently owned
 * result is published only after success. On failure *out_mat
 * remains null. Inputs are borrowed and unchanged.
 */
opencv_core_status
opencv_core_mat_pca_project(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *mean,
    const opencv_core_mat_handle *eigenvectors, int32_t orientation,
    opencv_core_mat_handle **out_mat);

/*
 * Reconstructs borrowed principal-component coordinates through a
 * borrowed PCA basis (mean and eigenvectors). orientation is 0
 * (samples are rows) or 1 (samples are columns). Column orientation
 * is adapted through OpenCV's row-oriented PCA::backProject path so
 * a one-feature 1x1 mean is not treated as an ambiguous native
 * branch. The independently owned result is published only after
 * success. On failure *out_mat remains null. Inputs are borrowed
 * and unchanged.
 */
opencv_core_status
opencv_core_mat_pca_back_project(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *mean,
    const opencv_core_mat_handle *eigenvectors, int32_t orientation,
    opencv_core_mat_handle **out_mat);

/*
 * Computes the default compact SVD of a borrowed Mat using
 * cv::SVD::compute(..., flags = 0). All three output pointer
 * arguments must be non-null and pairwise distinct. On success the
 * three returned handles are independently owned. On any failure
 * all three outputs remain null. The source is borrowed and
 * unchanged.
 */
opencv_core_status
opencv_core_mat_singular_value_decomposition(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_singular_values,
    opencv_core_mat_handle **out_u,
    opencv_core_mat_handle **out_v_transpose);

/*
 * Solves A * X ~= right_hand_side by cv::SVD::backSubst using an
 * already computed compact SVD basis. This does not recompute the
 * SVD and does not reconstruct A. The four input handles are
 * borrowed. The independently owned result is published only after
 * success. On failure *out_mat remains null. Inputs are unchanged.
 */
opencv_core_status
opencv_core_mat_svd_back_substitute(
    const opencv_core_mat_handle *singular_values,
    const opencv_core_mat_handle *u,
    const opencv_core_mat_handle *v_transpose,
    const opencv_core_mat_handle *right_hand_side,
    opencv_core_mat_handle **out_mat);

/*
 * Computes the Moore-Penrose pseudoinverse of a borrowed Mat using
 * compact cv::SVD::compute(..., flags = 0) followed by empty-RHS
 * cv::SVD::backSubst. This does not call cv::invert. The source is
 * borrowed. The independently owned result is published only after
 * success. On failure *out_mat remains null. The source is unchanged.
 */
opencv_core_status
opencv_core_mat_pseudo_inverse(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_mat);

/*
 * Computes the reciprocal 2-norm condition number of a borrowed Mat
 * from OpenCV 4.10 singular-values-only SVD (SVD::NO_UV). On success
 * *out_value is sigma_min / sigma_max from the compact W column, or
 * 0.0 when sigma_max is exactly 0. On entry *out_value is set to 0.0
 * when out_value is non-null. On failure *out_value remains 0.0. The
 * source is borrowed and unchanged. U and V_Transpose are not computed.
 */
opencv_core_status
opencv_core_mat_reciprocal_condition_number(
    const opencv_core_mat_handle *source,
    double *out_value);

/*
 * Computes a unit-length homogeneous least-residual solution of a borrowed Mat
 * using cv::SVD::solveZ. out_mat must be non-null and is initialized to null.
 * The independently owned result is published only after success; it remains
 * null on failure. The source is borrowed and unchanged. Raw inputs whose
 * OpenCV 4.10 SVD workspace arithmetic exceeds size_t are rejected.
 */
opencv_core_status
opencv_core_mat_svd_solve_zero(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_mat);

/*
 * Applies cv::transform to each source element interpreted as its channel
 * vector. source and coefficients are borrowed. The independently owned
 * result has source.rows, source.cols, source.depth(), and
 * coefficients.rows channels.
 *
 * source must be non-empty, at most two-dimensional, have 1 to 4
 * channels, and depth CV_8U, CV_8S, CV_16U, CV_16S, CV_32S, CV_32F, or
 * CV_64F. CV_16F is rejected because OpenCV 4.10 has no TransformFunc
 * for it.
 *
 * coefficients must be non-empty, at most two-dimensional, single-channel
 * CV_32F or CV_64F, have 1 to 512 rows, and have either source.channels()
 * columns (linear) or source.channels()+1 columns (affine; last column is
 * additive bias). Continuity is not required. OpenCV selects internal
 * coefficient working precision from the source depth and may convert
 * coefficients; this wrapper does not pre-convert them.
 */

opencv_core_status
opencv_core_mat_transform(const opencv_core_mat_handle *source,
                          const opencv_core_mat_handle *coefficients,
                          opencv_core_mat_handle **out_mat);

/*
 * Applies cv::perspectiveTransform to each source element interpreted as a
 * 2D or 3D vector. This is not spatial image warping. source and
 * transform_matrix are borrowed. The independently owned result has
 * source.rows, source.cols, source.depth(), and source.channels().
 *
 * source must be non-empty, at most two-dimensional, have exactly 2 or 3
 * channels, and depth CV_32F or CV_64F.
 *
 * transform_matrix must be non-empty, at most two-dimensional,
 * single-channel CV_32F or CV_64F. A 2-channel source requires a 3x3
 * matrix. A 3-channel source requires a 4x4 matrix. Continuity is not
 * required. OpenCV converts a non-continuous or non-CV_64F matrix to an
 * internal Float64 coefficient buffer; this wrapper does not pre-convert
 * it. When abs(w) <= FLT_EPSILON, OpenCV 4.10 writes a zero vector for
 * both Float32 and Float64 sources.
 */
opencv_core_status
opencv_core_mat_perspective_transform(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *transform_matrix,
    opencv_core_mat_handle **out_mat);

/*
 * Performs a full-complex Discrete Fourier Transform of a borrowed Mat
 * using cv::dft. transform_kind must be one of the
 * OPENCV_CORE_DFT_* identifiers; the shim constructs the exact OpenCV
 * flags and never forwards a raw DftFlags mask.
 *
 * FORWARD_COMPLEX:
 *   C1 -> DFT_COMPLEX_OUTPUT (full C2 spectrum, not packed CCS)
 *   C2 -> flags 0
 * INVERSE_COMPLEX:
 *   DFT_INVERSE | DFT_SCALE
 * INVERSE_REAL:
 *   DFT_INVERSE | DFT_SCALE | DFT_REAL_OUTPUT
 *
 * nonzeroRows is always 0. DFT_ROWS is never set. Source is borrowed
 * and unmodified. The independently owned result is published only
 * after success. Dimensions whose OpenCV 4.10 signed DFT count or
 * byte-size products would overflow int are rejected before cv::dft.
 * On failure *out_mat remains null.
 */
opencv_core_status
opencv_core_mat_dft(const opencv_core_mat_handle *source,
                    int32_t transform_kind,
                    opencv_core_mat_handle **out_mat);

/*
 * Performs a Discrete Cosine Transform of a borrowed Mat using
 * cv::dct. transform_kind must be one of the OPENCV_CORE_DCT_*
 * identifiers; the shim constructs the exact OpenCV flags and never
 * forwards a raw DCT flag mask.
 *
 * FORWARD:
 *   cv::dct(source, result, 0)
 * INVERSE:
 *   cv::dct(source, result, cv::DCT_INVERSE)
 *
 * DCT_ROWS is never set. Source is borrowed and unmodified. The
 * independently owned result is published only after success.
 * Transformed dimensions whose OpenCV 4.10 signed DCT work-buffer
 * products would overflow int are rejected before cv::dct. A
 * Float32 source whose row step cannot be represented as the
 * signed int expected by OpenCV 4.10's IPP DCT path is also
 * rejected. On failure *out_mat remains null.
 */
opencv_core_status
opencv_core_mat_dct(const opencv_core_mat_handle *source,
                    int32_t transform_kind,
                    opencv_core_mat_handle **out_mat);

/*
 * Returns the smallest OpenCV-efficient DFT length N >= minimum_size
 * using cv::getOptimalDFTSize. OpenCV 4.10 efficient sizes are
 * 2^p * 3^q * 5^r. This is a size lookup only: it does not allocate a
 * Mat or apply the separate DFT signed-arithmetic safety limits.
 *
 * minimum_size must be positive. OpenCV's negative too-large sentinel
 * is translated to OPENCV_CORE_ERROR_INVALID_ARGUMENT rather than
 * published. *out_size is 0 on every failure and is published only
 * after a positive OpenCV result.
 */
opencv_core_status
opencv_core_get_optimal_dft_size(int32_t minimum_size, int32_t *out_size);

/*
 * Multiplies two borrowed full-complex spectra using cv::mulSpectrums
 * with flags 0. kind must be one of the OPENCV_CORE_SPECTRUM_PRODUCT_*
 * identifiers; the shim maps them to conjB and never forwards a raw
 * OpenCV flag mask or DFT_ROWS.
 *
 * ORDINARY:
 *   conjB = false  (Left(I) * Right(I))
 * CONJUGATE_RIGHT:
 *   conjB = true   (Left(I) * conjugate(Right(I)))
 *
 * Inputs are borrowed and unmodified. The independently owned result
 * is published only after success. On failure *out_mat remains null.
 */
opencv_core_status
opencv_core_mat_multiply_spectra(const opencv_core_mat_handle *left,
                                 const opencv_core_mat_handle *right,
                                 int32_t kind,
                                 opencv_core_mat_handle **out_mat);

/*
 * Computes unmasked per-channel mean values. Both operations support one to
 * four channels so each complete result fits opencv_core_scalar. Mean accepts
 * empty Mats and returns all zeroes; mean/stddev requires a non-empty Mat.
 */
opencv_core_status
opencv_core_mat_mean(const opencv_core_mat_handle *mat,
                     opencv_core_scalar *out_mean);

/*
 * Computes per-channel mean of source elements selected by mask. Mask must be
 * a same-sized single-channel UInt8 Mat; any nonzero value selects the element.
 * An all-zero mask returns a zero Scalar. Source supports one to four channels.
 * Empty source/mask follow OpenCV mean semantics (zero Scalar).
 */
opencv_core_status
opencv_core_mat_mean_masked(const opencv_core_mat_handle *mat,
                            const opencv_core_mat_handle *mask,
                            opencv_core_scalar *out_mean);

opencv_core_status
opencv_core_mat_mean_std_dev(const opencv_core_mat_handle *mat,
                             opencv_core_scalar *out_mean,
                             opencv_core_scalar *out_standard_deviation);

/*
 * Computes per-channel mean and population standard deviation of source
 * elements selected by mask. Mask must be a same-sized single-channel UInt8
 * Mat; any nonzero value selects the element. All-zero masks return zero mean
 * and standard-deviation Scalars. Empty source is rejected. Source supports
 * one to four channels.
 */
opencv_core_status
opencv_core_mat_mean_std_dev_masked(
    const opencv_core_mat_handle *mat, const opencv_core_mat_handle *mask,
    opencv_core_scalar *out_mean, opencv_core_scalar *out_standard_deviation);

/*
 * Computes the requested absolute norm over every scalar component of mat.
 * Empty Mats return zero according to OpenCV semantics.
 */
opencv_core_status
opencv_core_mat_norm(const opencv_core_mat_handle *mat, int32_t norm_kind,
                     double *out_norm);

/*
 * Computes the requested absolute norm over source elements selected by mask.
 * Mask must be a same-sized single-channel UInt8 Mat; any nonzero value
 * selects the complete source element, including every channel. Empty sources
 * and all-zero masks return zero according to OpenCV semantics.
 */
opencv_core_status
opencv_core_mat_norm_masked(const opencv_core_mat_handle *mat,
                            const opencv_core_mat_handle *mask,
                            int32_t norm_kind, double *out_norm);

/*
 * Computes cv::PSNR for two borrowed Mats. out_psnr must be non-null and is
 * initialized to zero; it remains zero on failure. Inputs and peak_value are
 * passed directly to OpenCV and the Mats remain borrowed and unmodified.
 */
opencv_core_status
opencv_core_mat_psnr(const opencv_core_mat_handle *left,
                     const opencv_core_mat_handle *right, double peak_value,
                     double *out_psnr);

/*
 * Finds extrema in a non-empty, two-dimensional, single-channel Mat.
 * Locations are reported as zero-based X (column) and Y (row) coordinates.
 */
opencv_core_status
opencv_core_mat_min_max_loc(const opencv_core_mat_handle *mat,
                            double *out_minimum, double *out_maximum,
                            int32_t *out_minimum_x, int32_t *out_minimum_y,
                            int32_t *out_maximum_x, int32_t *out_maximum_y);

/*
 * Finds extrema among elements selected by mask in a non-empty,
 * two-dimensional, single-channel Mat. Mask must be a same-sized,
 * single-channel UInt8 Mat; any nonzero value selects the element. An all-zero
 * mask returns zero extrema with (-1, -1) locations. Locations are reported
 * as zero-based X (column) and Y (row) coordinates.
 */
opencv_core_status
opencv_core_mat_min_max_loc_masked(
    const opencv_core_mat_handle *mat, const opencv_core_mat_handle *mask,
    double *out_minimum, double *out_maximum, int32_t *out_minimum_x,
    int32_t *out_minimum_y, int32_t *out_maximum_x, int32_t *out_maximum_y);

/*
 * Counts the number of nonzero scalar elements in a single-channel Mat.
 * Supports non-contiguous views. The result is returned as int64_t.
 * Defensive validation requires a valid 2D single-channel handle.
 */
opencv_core_status
opencv_core_mat_count_non_zero(const opencv_core_mat_handle *mat,
                               int64_t *out_count);

/*
 * Returns true if a single-channel Mat contains at least one nonzero element.
 * Supports non-contiguous views. The result is returned as uint8_t (0 or 1).
 * Defensive validation requires a valid 2D single-channel handle.
 */
opencv_core_status
opencv_core_mat_has_non_zero(const opencv_core_mat_handle *mat,
                              uint8_t *out_result);

/*
 * Writes row-major locations of nonzero elements from a two-dimensional,
 * single-channel Mat to caller-owned storage. Points are zero-based x
 * (column), y (row) coordinates relative to mat, including when mat is a
 * non-contiguous view. out_count is initialized to zero. capacity must be at
 * least the number of returned points; Float16 Mats are not supported.
 */
opencv_core_status
opencv_core_mat_find_non_zero(const opencv_core_mat_handle *mat,
                              opencv_core_point *out_points,
                              int64_t capacity, int64_t *out_count);

/*
 * Checks every scalar channel value of source in quiet mode. When
 * use_bounds is 0, OpenCV's default +/- DBL_MAX bounds are used. NaN
 * and +/- Infinity are invalid, and floating-point values are subject
 * to those default finite extrema; the positive maximum finite
 * endpoint is excluded by the half-open upper bound. When use_bounds
 * is 1, minimum and maximum are passed through to cv::checkRange.
 * out_valid is 1 when every value is accepted and 0 otherwise. On an
 * invalid Mat, out_x and out_y are the first-invalid column and row.
 * On a valid Mat they are the sentinel (-1, -1). use_bounds must be
 * 0 or 1. Float16 is not supported by OpenCV 4.10 checkRange.
 */
opencv_core_status
opencv_core_mat_check_range(const opencv_core_mat_handle *source,
                            uint8_t use_bounds, double minimum, double maximum,
                            uint8_t *out_valid, int32_t *out_x, int32_t *out_y);

/*
 * Replaces every NaN scalar in an existing Float32 Mat with value.
 * Mutates the Mat represented by the borrowed handle; the handle is
 * not consumed and no result Mat is allocated. OpenCV 4.10 accepts
 * only CV_32F depth and converts value to float before storing it.
 * Finite values and +/- Infinity are left unchanged. Multi-channel
 * and non-contiguous Mats are supported.
 */
opencv_core_status
opencv_core_mat_patch_nans(opencv_core_mat_handle *mat, double value);

/*
 * Completes a square floating-point Mat in place by copying one triangle
 * onto the other. The handle is borrowed and not consumed; no result Mat
 * is allocated. source_triangle is 0 (Upper_Triangle: copy upper -> lower)
 * or 1 (Lower_Triangle: copy lower -> upper). The diagonal is unchanged.
 * Supported depths are CV_32F and CV_64F. Any channel count is accepted
 * because each complete element is copied with elemSize(). Continuity is
 * not required. A typed 0x0 Float32 or Float64 Mat is a no-op.
 */
opencv_core_status
opencv_core_mat_complete_symmetry(opencv_core_mat_handle *mat,
                                  uint8_t source_triangle);

/*
 * Initializes an existing Mat in place as a scaled identity. The handle
 * is borrowed mutable storage and is not consumed; no result Mat is
 * allocated. value is borrowed. The matrix need not be square: every
 * off-diagonal element becomes zero and the main diagonal of length
 * min(rows, columns) receives value converted by OpenCV's Scalar
 * conversion. All eight public depths are accepted, including CV_16F.
 * Channel count must be 1 through 4. Continuity is not required.
 * A typed empty Mat is a no-op that preserves its metadata.
 */
opencv_core_status
opencv_core_mat_set_identity(opencv_core_mat_handle *mat,
                             const opencv_core_scalar *value);

/*
 * Stable FileStorage mode identifiers for the C ABI. These are translated
 * explicitly to cv::FileStorage::Mode by the shim and are not OpenCV flags.
 */
#define OPENCV_CORE_FILE_STORAGE_READ_ONLY ((int32_t)0)
#define OPENCV_CORE_FILE_STORAGE_WRITE_ONLY ((int32_t)1)

/*
 * Opens a disk-backed cv::FileStorage and returns a newly owned handle.
 * filename is a borrowed NUL-terminated path. mode must be one of the
 * OPENCV_CORE_FILE_STORAGE_* identifiers above. On success out_storage
 * receives one independently owned handle. On every failure out_storage
 * remains null. OpenCV selects XML/YAML/JSON from the filename extension.
 */
opencv_core_status
opencv_core_file_storage_open(const char *filename, int32_t mode,
                              opencv_core_file_storage_handle **out_storage);

/* Null-safe and exception-contained. */
void opencv_core_file_storage_destroy(
    opencv_core_file_storage_handle *storage);

/*
 * Writes a borrowed Mat under name using FileStorage::write. name is a
 * borrowed NUL-terminated node name. The Mat handle is not consumed and
 * the source Mat is not modified.
 */
opencv_core_status
opencv_core_file_storage_write_mat(
    opencv_core_file_storage_handle *storage, const char *name,
    const opencv_core_mat_handle *value);

/*
 * Looks up name and reads it as a Mat. A missing node is a failure, not
 * an empty Mat. On success out_mat receives one independently owned Mat
 * handle whose storage does not depend on FileStorage lifetime. On every
 * failure out_mat remains null.
 */
opencv_core_status
opencv_core_file_storage_read_mat(
    const opencv_core_file_storage_handle *storage, const char *name,
    opencv_core_mat_handle **out_mat);

/*
 * Writes a signed 32-bit integer under name using FileStorage::write.
 * name is a borrowed NUL-terminated node name. OpenCV 4.10 formats
 * integers through fs::itoa()/abs(int), so INT32_MIN is rejected.
 */
opencv_core_status
opencv_core_file_storage_write_int(
    opencv_core_file_storage_handle *storage, const char *name,
    int32_t value);

/*
 * Looks up name and reads it as a signed 32-bit integer. A missing node
 * is a failure. The node must be an OpenCV integer node; a real node is
 * rejected rather than rounded. On every failure *out_value is 0 when
 * out_value is non-null.
 */
opencv_core_status
opencv_core_file_storage_read_int(
    const opencv_core_file_storage_handle *storage, const char *name,
    int32_t *out_value);

/*
 * Writes a double under name using FileStorage::write. name is a
 * borrowed NUL-terminated node name.
 */
opencv_core_status
opencv_core_file_storage_write_double(
    opencv_core_file_storage_handle *storage, const char *name,
    double value);

/*
 * Looks up name and reads it as a double. A missing node is a failure.
 * A real node returns its exact OpenCV value. An integer node is widened
 * exactly to double. Strings and other node types are rejected. On every
 * failure *out_value is 0.0 when out_value is non-null.
 */
opencv_core_status
opencv_core_file_storage_read_double(
    const opencv_core_file_storage_handle *storage, const char *name,
    double *out_value);

/*
 * Writes a borrowed NUL-terminated string under name using
 * FileStorage::write. OpenCV 4.10 persistence emitters measure string
 * values with strlen, so embedded NUL cannot be persisted.
 */
opencv_core_status
opencv_core_file_storage_write_string(
    opencv_core_file_storage_handle *storage, const char *name,
    const char *value);

/*
 * Looks up name and reads it as a string using a caller-owned buffer.
 * A missing node or a non-string node is a failure. FileNode remains
 * internal to the shim.
 *
 * Query mode: buffer == NULL and capacity == 0. On success *out_length
 * is the exact byte count and no bytes are copied.
 *
 * Copy mode: buffer != NULL and capacity >= the value length. On
 * success the exact bytes are copied and *out_length is that length.
 * The buffer is not NUL-terminated by this function.
 *
 * On every failure *out_length is 0 when out_length is non-null, and
 * no caller-visible bytes are written.
 */
opencv_core_status
opencv_core_file_storage_read_string(
    const opencv_core_file_storage_handle *storage, const char *name,
    char *buffer, uint64_t capacity, uint64_t *out_length);

/*
 * Stable FileStorage format identifiers for the C ABI. These are
 * translated explicitly to cv::FileStorage::FORMAT_* by the shim and
 * are not OpenCV flags.
 */
#define OPENCV_CORE_FILE_STORAGE_FORMAT_XML ((int32_t)0)
#define OPENCV_CORE_FILE_STORAGE_FORMAT_YAML ((int32_t)1)
#define OPENCV_CORE_FILE_STORAGE_FORMAT_JSON ((int32_t)2)

/*
 * Stable FileStorage structure-kind identifiers for the C ABI. These
 * are translated explicitly to cv::FileNode::MAP / cv::FileNode::SEQ
 * by the shim and are not OpenCV FileNode flags.
 */
#define OPENCV_CORE_FILE_STORAGE_STRUCTURE_MAP ((int32_t)0)
#define OPENCV_CORE_FILE_STORAGE_STRUCTURE_SEQUENCE ((int32_t)1)

/*
 * Opens a memory-backed cv::FileStorage for writing and returns a newly
 * owned handle. format must be one of the
 * OPENCV_CORE_FILE_STORAGE_FORMAT_* identifiers above. On success
 * out_storage receives one independently owned handle. On every failure
 * out_storage remains null. No file is created.
 */
opencv_core_status
opencv_core_file_storage_open_memory_write(
    int32_t format, opencv_core_file_storage_handle **out_storage);

/*
 * Opens a memory-backed cv::FileStorage for reading and returns a newly
 * owned handle. text is a borrowed NUL-terminated document. OpenCV
 * 4.10 auto-detects XML, YAML, or JSON from the contents. The handle
 * owns a copy of text for the FileStorage lifetime. On success
 * out_storage receives one independently owned handle. On every failure
 * out_storage remains null.
 */
opencv_core_status
opencv_core_file_storage_open_memory_read(
    const char *text, opencv_core_file_storage_handle **out_storage);

/*
 * Finalizes a memory-backed write FileStorage and copies the serialized
 * document into a caller-owned buffer. releaseAndGetString is invoked
 * at most once; later calls read the cached result.
 *
 * Query mode: buffer == NULL and capacity == 0. On success *out_length
 * is the exact byte count and no bytes are copied.
 *
 * Copy mode: buffer != NULL and capacity >= the text length. On
 * success the exact bytes are copied and *out_length is that length.
 * The buffer is not NUL-terminated by this function.
 *
 * Disk-backed storage and memory readers are rejected. On every
 * failure *out_length is 0 when out_length is non-null, and no
 * caller-visible bytes are written.
 */
opencv_core_status
opencv_core_file_storage_finish_memory_write(
    opencv_core_file_storage_handle *storage, char *buffer,
    uint64_t capacity, uint64_t *out_length);

/*
 * Starts a nested mapping or sequence. kind must be one of the
 * OPENCV_CORE_FILE_STORAGE_STRUCTURE_* identifiers above. name is a
 * borrowed NUL-terminated node name. A nonempty name creates a named
 * child of the current mapping or root. An empty string creates an
 * unnamed sequence element and is valid only while writing a sequence.
 * FileNode::FLOW and typeName are not exposed.
 */
opencv_core_status
opencv_core_file_storage_begin_structure(
    opencv_core_file_storage_handle *storage, const char *name, int32_t kind);

/*
 * Ends the current nested mapping or sequence opened by
 * begin_structure. The implicit root mapping cannot be closed.
 * OpenCV endWriteStruct is invoked before the ABI write stack is
 * popped. An empty write stack is a failure.
 */
opencv_core_status
opencv_core_file_storage_end_structure(
    opencv_core_file_storage_handle *storage);

/*
 * Enters a named child mapping or sequence. kind must be one of the
 * OPENCV_CORE_FILE_STORAGE_STRUCTURE_* identifiers. The child must
 * exist and match kind. Named entry is valid at root or inside a
 * mapping. FileNode remains internal to the handle.
 */
opencv_core_status
opencv_core_file_storage_enter_named_structure(
    opencv_core_file_storage_handle *storage, const char *name, int32_t kind);

/*
 * Enters an indexed child mapping or sequence of the current sequence.
 * kind must be one of the OPENCV_CORE_FILE_STORAGE_STRUCTURE_*
 * identifiers. index is zero-based. The child must exist and match
 * kind. Indexed entry is valid only inside a sequence.
 */
opencv_core_status
opencv_core_file_storage_enter_indexed_structure(
    opencv_core_file_storage_handle *storage, uint64_t index, int32_t kind);

/*
 * Leaves the current read mapping or sequence and returns to the
 * parent context. The implicit root cannot be left.
 */
opencv_core_status
opencv_core_file_storage_leave_structure(
    opencv_core_file_storage_handle *storage);

/*
 * Returns FileNode::size of the current sequence. Valid only while
 * the current read context is a sequence. On every failure
 * *out_length is 0 when out_length is non-null.
 */
opencv_core_status
opencv_core_file_storage_sequence_length(
    const opencv_core_file_storage_handle *storage, uint64_t *out_length);

/*
 * Reads the indexed current-sequence element as a Mat. A missing or
 * out-of-range index is a failure. On success out_mat receives one
 * independently owned Mat handle. On every failure out_mat remains
 * null.
 */
opencv_core_status
opencv_core_file_storage_read_mat_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    opencv_core_mat_handle **out_mat);

/*
 * Reads the indexed current-sequence element as a signed 32-bit
 * integer. The node must be an OpenCV integer node. On every failure
 * *out_value is 0 when out_value is non-null.
 */
opencv_core_status
opencv_core_file_storage_read_int_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    int32_t *out_value);

/*
 * Reads the indexed current-sequence element as a double. A real node
 * returns its exact OpenCV value. An integer node is widened exactly
 * to double. On every failure *out_value is 0.0 when out_value is
 * non-null.
 */
opencv_core_status
opencv_core_file_storage_read_double_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    double *out_value);

/*
 * Reads the indexed current-sequence element as a string using a
 * caller-owned buffer. Query and copy modes match
 * opencv_core_file_storage_read_string.
 */
opencv_core_status
opencv_core_file_storage_read_string_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    char *buffer, uint64_t capacity, uint64_t *out_length);

#ifdef __cplusplus
}
#endif

#endif
