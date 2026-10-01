#include "opencv_core_module_bridge.hpp"

#include <opencv2/core.hpp>

#include <exception>

#if defined(_WIN32)
#define OPENCV_CORE_MODULE_PROBE_EXPORT __declspec(dllexport)
#else
#define OPENCV_CORE_MODULE_PROBE_EXPORT
#endif

namespace {

opencv_core_status translate_exception() noexcept {
    try {
        throw;
    } catch (...) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
}

} // namespace

extern "C" {

OPENCV_CORE_MODULE_PROBE_EXPORT int32_t opencv_core_module_probe_version_major(
    void) {
    return CV_VERSION_MAJOR;
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status opencv_core_module_probe_input(
    const opencv_core_mat_handle *handle, int32_t *out_rows,
    int32_t *out_columns, int32_t *out_depth, int32_t *out_value) {
    if (out_rows == nullptr || out_columns == nullptr || out_depth == nullptr ||
        out_value == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_rows = 0;
    *out_columns = 0;
    *out_depth = 0;
    *out_value = 0;

    try {
        const cv::Mat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_input_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || mat->rows < 1 || mat->cols < 1 ||
            mat->depth() != CV_8U || mat->channels() != 1) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        *out_rows = mat->rows;
        *out_columns = mat->cols;
        *out_depth = mat->depth();
        *out_value = static_cast<int>(mat->at<uint8_t>(0, 0));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status opencv_core_module_probe_mutate(
    opencv_core_mat_handle *handle, uint8_t value) {
    try {
        cv::Mat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_output_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || mat->rows < 1 || mat->cols < 1 ||
            mat->depth() != CV_8U || mat->channels() != 1) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        mat->at<uint8_t>(0, 0) = value;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status opencv_core_module_probe_create(
    opencv_core_mat_handle *handle, int32_t rows, int32_t columns,
    uint8_t value) {
    try {
        cv::Mat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_output_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || rows < 0 || columns < 0) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        mat->create(rows, columns, CV_8UC1);
        mat->setTo(cv::Scalar(value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_invalid_inputs(void) {
    const cv::Mat *input = nullptr;
    cv::Mat *output = nullptr;
    if (opencv_core_module_input_mat(nullptr, &input) == OPENCV_CORE_OK ||
        opencv_core_module_output_mat(nullptr, &output) == OPENCV_CORE_OK) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    return OPENCV_CORE_OK;
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_sparse_input(
    const opencv_core_sparse_mat_handle *handle, int32_t *out_dims,
    int32_t *out_extent_0, int32_t *out_extent_1, int32_t *out_nodes,
    int32_t *out_value) {
    if (out_dims == nullptr || out_extent_0 == nullptr ||
        out_extent_1 == nullptr || out_nodes == nullptr ||
        out_value == nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    *out_dims = 0;
    *out_extent_0 = 0;
    *out_extent_1 = 0;
    *out_nodes = 0;
    *out_value = 0;

    try {
        const cv::SparseMat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_input_sparse_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || mat->dims() != 2 || mat->depth() != CV_32F ||
            mat->channels() != 1) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        const int indices[2] = {0, 1};
        const float *stored = mat->find<float>(indices);
        *out_dims = mat->dims();
        *out_extent_0 = mat->size(0);
        *out_extent_1 = mat->size(1);
        *out_nodes = static_cast<int32_t>(mat->nzcount());
        *out_value = stored == nullptr ? 0 : static_cast<int32_t>(*stored);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_sparse_mutate(opencv_core_sparse_mat_handle *handle,
                                        float value) {
    try {
        cv::SparseMat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_output_sparse_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || mat->dims() != 2 || mat->depth() != CV_32F ||
            mat->channels() != 1) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        const int indices[2] = {0, 1};
        mat->ref<float>(indices) = value;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_sparse_create(opencv_core_sparse_mat_handle *handle,
                                        int32_t extent_0, int32_t extent_1,
                                        float value) {
    try {
        cv::SparseMat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_output_sparse_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        if (mat == nullptr || extent_0 < 1 || extent_1 < 1) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        const int sizes[2] = {extent_0, extent_1};
        mat->create(2, sizes, CV_32FC1);
        const int indices[2] = {0, 1};
        mat->ref<float>(indices) = value;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_sparse_invalid_inputs(void) {
    const cv::SparseMat *input = nullptr;
    cv::SparseMat *output = nullptr;
    if (opencv_core_module_input_sparse_mat(nullptr, &input) ==
            OPENCV_CORE_OK ||
        opencv_core_module_output_sparse_mat(nullptr, &output) ==
            OPENCV_CORE_OK ||
        opencv_core_module_input_sparse_mat(nullptr, nullptr) ==
            OPENCV_CORE_OK ||
        opencv_core_module_output_sparse_mat(nullptr, nullptr) ==
            OPENCV_CORE_OK) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    return OPENCV_CORE_OK;
}

} // extern "C"