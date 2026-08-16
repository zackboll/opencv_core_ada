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

typedef struct opencv_core_mat_handle opencv_core_mat_handle;

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

#ifdef __cplusplus
}
#endif

#endif