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

} // extern "C"