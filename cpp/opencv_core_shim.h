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
 * Creates a distinct Mat header for the indicated non-empty 2D region. The
 * header shares source storage through OpenCV reference counting.
 */
opencv_core_status
opencv_core_mat_region(const opencv_core_mat_handle *source, int32_t x,
                       int32_t y, int32_t width, int32_t height,
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

opencv_core_status
opencv_core_mat_set_float32(opencv_core_mat_handle *mat, int32_t row,
                            int32_t column, float value);

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
opencv_core_mat_set_float32_vec3(opencv_core_mat_handle *mat, int32_t row,
                                 int32_t column,
                                 const opencv_core_float32_vec3 *value);

opencv_core_status
opencv_core_mat_set_to(opencv_core_mat_handle *mat,
                       const opencv_core_scalar *value);

opencv_core_status
opencv_core_mat_sum(const opencv_core_mat_handle *mat,
                    opencv_core_scalar *out_sum);

#ifdef __cplusplus
}
#endif

#endif