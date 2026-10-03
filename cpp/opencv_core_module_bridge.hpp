#ifndef OPENCV_CORE_MODULE_BRIDGE_HPP
#define OPENCV_CORE_MODULE_BRIDGE_HPP

/*
 * Private implementation bridge for cooperating OpenCV Ada module shims.
 * Application code must use OpenCV.Core.Mat / UMat / Sparse, not this header.
 *
 * Core owns both opencv_core_mat_handle and its cv::Mat header. The resolver
 * results are borrowed: a module shim must neither delete nor retain the
 * returned cv::Mat pointer beyond the corresponding Ada callback/call scope.
 * All cooperating module shims must use the same compatible OpenCV ABI and
 * installation as the Core shim.
 *
 * UMat follows the same ownership model: Core owns the opaque wrapper and
 * original cv::UMat header. Borrowed pointers must not be retained or deleted.
 * No host cv::Mat representation is created and no UMat::getMat() mapping is
 * performed. Modules may pass the UMat directly to InputArray / OutputArray
 * operations. A mutable output header may be rebound by OpenCV; Core sees
 * that rebinding after the callback because the actual wrapper header was
 * borrowed. Regions are ordinary reference-counted headers, not external
 * buffer views. UMat offers the Transparent API opportunity, not guaranteed
 * GPU execution; OpenCL remains optional. No ownership transfer occurs.
 *
 * SparseMat follows the same ownership model. Core owns both
 * opencv_core_sparse_mat_handle and its cv::SparseMat header. Resolver
 * results are borrowed for the Ada callback/call scope only. A module shim
 * must neither delete nor retain the returned cv::SparseMat pointer, and
 * must not copy node storage through this bridge. There is no temporary
 * external-buffer SparseMat view, so output resolution does not have the
 * Mat external-view rejection.
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

typedef struct opencv_core_umat_handle opencv_core_umat_handle;

opencv_core_status
opencv_core_umat_resolve_input(const opencv_core_umat_handle *source,
                              void **out_native_umat);

opencv_core_status
opencv_core_umat_resolve_output(opencv_core_umat_handle *destination,
                               void **out_native_umat);

typedef struct opencv_core_sparse_mat_handle opencv_core_sparse_mat_handle;

opencv_core_status
opencv_core_sparse_resolve_input(const opencv_core_sparse_mat_handle *source,
                                  void **out_native_sparse_mat);

opencv_core_status
opencv_core_sparse_resolve_output(opencv_core_sparse_mat_handle *destination,
                                   void **out_native_sparse_mat);

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

inline opencv_core_status opencv_core_module_input_umat(
    const opencv_core_umat_handle *handle, const cv::UMat **out_umat) {
    void *native_umat = nullptr;
    if (out_umat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_umat = nullptr;
    const opencv_core_status status =
        opencv_core_umat_resolve_input(handle, &native_umat);
    if (status == OPENCV_CORE_OK) {
        *out_umat = static_cast<const cv::UMat *>(native_umat);
    }
    return status;
}

inline opencv_core_status opencv_core_module_output_umat(
    opencv_core_umat_handle *handle, cv::UMat **out_umat) {
    void *native_umat = nullptr;
    if (out_umat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_umat = nullptr;
    const opencv_core_status status =
        opencv_core_umat_resolve_output(handle, &native_umat);
    if (status == OPENCV_CORE_OK) {
        *out_umat = static_cast<cv::UMat *>(native_umat);
    }
    return status;
}

inline opencv_core_status opencv_core_module_input_sparse_mat(
    const opencv_core_sparse_mat_handle *handle, const cv::SparseMat **out_mat) {
    void *native_mat = nullptr;
    if (out_mat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_mat = nullptr;
    const opencv_core_status status =
        opencv_core_sparse_resolve_input(handle, &native_mat);
    if (status == OPENCV_CORE_OK) {
        *out_mat = static_cast<const cv::SparseMat *>(native_mat);
    }
    return status;
}

inline opencv_core_status opencv_core_module_output_sparse_mat(
    opencv_core_sparse_mat_handle *handle, cv::SparseMat **out_mat) {
    void *native_mat = nullptr;
    if (out_mat == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_mat = nullptr;
    const opencv_core_status status =
        opencv_core_sparse_resolve_output(handle, &native_mat);
    if (status == OPENCV_CORE_OK) {
        *out_mat = static_cast<cv::SparseMat *>(native_mat);
    }
    return status;
}
#endif

#endif