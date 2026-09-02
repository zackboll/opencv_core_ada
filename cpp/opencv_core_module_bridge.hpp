#ifndef OPENCV_CORE_MODULE_BRIDGE_HPP
#define OPENCV_CORE_MODULE_BRIDGE_HPP

/*
 * Private implementation bridge for cooperating OpenCV Ada module shims.
 * Application code must use OpenCV.Core.Mat, not this header.
 *
 * Core owns both opencv_core_mat_handle and its cv::Mat header. The resolver
 * results are borrowed: a module shim must neither delete nor retain the
 * returned cv::Mat pointer beyond the corresponding Ada callback/call scope.
 * All cooperating module shims must use the same compatible OpenCV ABI and
 * installation as the Core shim.
 */
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t opencv_core_status;

#define OPENCV_CORE_OK ((opencv_core_status)0)
#define OPENCV_CORE_ERROR_INVALID_ARGUMENT ((opencv_core_status)4)

typedef struct opencv_core_mat_handle opencv_core_mat_handle;

opencv_core_status
opencv_core_mat_resolve_input(const opencv_core_mat_handle *source,
                              void **out_native_mat);

opencv_core_status
opencv_core_mat_resolve_output(opencv_core_mat_handle *destination,
                               void **out_native_mat);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <opencv2/core.hpp>

inline opencv_core_status opencv_core_module_input_mat(
    const opencv_core_mat_handle *handle, const cv::Mat **out_mat) {
    void *native_mat = nullptr;
    if (out_mat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_mat = nullptr;
    const opencv_core_status status =
        opencv_core_mat_resolve_input(handle, &native_mat);
    if (status == OPENCV_CORE_OK) {
        *out_mat = static_cast<const cv::Mat *>(native_mat);
    }
    return status;
}

inline opencv_core_status opencv_core_module_output_mat(
    opencv_core_mat_handle *handle, cv::Mat **out_mat) {
    void *native_mat = nullptr;
    if (out_mat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_mat = nullptr;
    const opencv_core_status status =
        opencv_core_mat_resolve_output(handle, &native_mat);
    if (status == OPENCV_CORE_OK) {
        *out_mat = static_cast<cv::Mat *>(native_mat);
    }
    return status;
}
#endif

#endif