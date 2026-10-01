#include "opencv_core_module_bridge.hpp"

#include <opencv2/core.hpp>

#include <exception>
#include <cstdint>

#if defined(_WIN32)
#define OPENCV_CORE_MODULE_PROBE_EXPORT __declspec(dllexport)
#else
#define OPENCV_CORE_MODULE_PROBE_EXPORT
#endif

constexpr int32_t maximum_probe_dimensions = 32;

namespace {

opencv_core_status translate_exception() noexcept {
    try {
        throw;
    } catch (...) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
}

opencv_core_status read_sparse_node(const cv::SparseMat *mat, int32_t index_count,
                                     const int32_t *indices, int32_t extent_count,
                                     int32_t *out_extents, int32_t *out_depth,
                                     int32_t *out_channels, int32_t *out_nodes,
                                     int32_t *out_value) {
    if (mat == nullptr || indices == nullptr || out_extents == nullptr ||
        out_depth == nullptr || out_channels == nullptr || out_nodes == nullptr ||
        out_value == nullptr || index_count < 1 ||
        index_count > maximum_probe_dimensions || extent_count < index_count ||
        extent_count > maximum_probe_dimensions || mat->dims() != index_count ||
        mat->depth() != CV_32F || mat->channels() != 1) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    for (int32_t axis = 0; axis < index_count; ++axis) {
        if (indices[axis] < 0 || indices[axis] >= mat->size(axis)) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
    }

    int native_indices[maximum_probe_dimensions];
    for (int32_t axis = 0; axis < index_count; ++axis) {
        native_indices[axis] = static_cast<int>(indices[axis]);
    }
    const float *stored = mat->find<float>(native_indices);
    for (int32_t axis = 0; axis < index_count; ++axis) {
        out_extents[axis] = mat->size(axis);
    }
    for (int32_t axis = index_count; axis < extent_count; ++axis) {
        out_extents[axis] = 0;
    }
    *out_depth = mat->depth();
    *out_channels = mat->channels();
    *out_nodes = static_cast<int32_t>(mat->nzcount());
    *out_value = stored == nullptr ? 0 : static_cast<int32_t>(*stored);
    return OPENCV_CORE_OK;
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
    const opencv_core_sparse_mat_handle *handle, int32_t index_count,
    const int32_t *indices, int32_t extent_capacity, int32_t *out_extents,
    int32_t *out_depth, int32_t *out_channels, int32_t *out_nodes,
    int32_t *out_value) {
    if (out_extents == nullptr || out_depth == nullptr ||
        out_channels == nullptr || out_nodes == nullptr ||
        out_value == nullptr || extent_capacity < 0 ||
        extent_capacity > maximum_probe_dimensions) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    for (int32_t axis = 0; axis < extent_capacity; ++axis) {
        out_extents[axis] = 0;
    }
    *out_depth = 0;
    *out_channels = 0;
    *out_nodes = 0;
    *out_value = 0;

    try {
        const cv::SparseMat *mat = nullptr;
        const opencv_core_status status =
            opencv_core_module_input_sparse_mat(handle, &mat);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
        return read_sparse_node(mat, index_count, indices, extent_capacity,
                                 out_extents, out_depth, out_channels, out_nodes,
                                 out_value);
    } catch (...) {
        return translate_exception();
    }
}

OPENCV_CORE_MODULE_PROBE_EXPORT opencv_core_status
opencv_core_module_probe_sparse_inputs(
    const opencv_core_sparse_mat_handle *left,
    const opencv_core_sparse_mat_handle *right, int32_t index_count,
    const int32_t *left_indices, const int32_t *right_indices,
    int32_t extent_capacity, int32_t *out_left_extents,
    int32_t *out_right_extents, int32_t *out_left_nodes, int32_t *out_right_nodes,
    int32_t *out_left_depth, int32_t *out_right_depth, int32_t *out_left_channels,
    int32_t *out_right_channels, int32_t *out_left_value, int32_t *out_right_value) {
    if (out_left_extents == nullptr || out_right_extents == nullptr ||
        out_left_nodes == nullptr || out_right_nodes == nullptr ||
        out_left_depth == nullptr || out_right_depth == nullptr ||
        out_left_channels == nullptr || out_right_channels == nullptr ||
        out_left_value == nullptr || out_right_value == nullptr ||
        left == right || extent_capacity < 0 ||
        extent_capacity > maximum_probe_dimensions) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    for (int32_t axis = 0; axis < extent_capacity; ++axis) {
        out_left_extents[axis] = 0;
        out_right_extents[axis] = 0;
    }
    *out_left_nodes = 0;
    *out_right_nodes = 0;
    *out_left_depth = 0;
    *out_right_depth = 0;
    *out_left_channels = 0;
    *out_right_channels = 0;
    *out_left_value = 0;
    *out_right_value = 0;

    try {
        const cv::SparseMat *left_mat = nullptr;
        const cv::SparseMat *right_mat = nullptr;
        const opencv_core_status left_status =
            opencv_core_module_input_sparse_mat(left, &left_mat);
        if (left_status != OPENCV_CORE_OK) {
            return left_status;
        }
        const opencv_core_status right_status =
            opencv_core_module_input_sparse_mat(right, &right_mat);
        if (right_status != OPENCV_CORE_OK) {
            return right_status;
        }
        if (left_mat == nullptr || right_mat == nullptr || left_mat == right_mat) {
            return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
        }
        int32_t left_depth = 0;
        int32_t right_depth = 0;
        int32_t left_channels = 0;
        int32_t right_channels = 0;
        const opencv_core_status observed_left = read_sparse_node(
            left_mat, index_count, left_indices, extent_capacity, out_left_extents,
            &left_depth, &left_channels, out_left_nodes, out_left_value);
        if (observed_left != OPENCV_CORE_OK) {
            return observed_left;
        }
        const opencv_core_status observed_right = read_sparse_node(
            right_mat, index_count, right_indices, extent_capacity,
            out_right_extents, &right_depth, &right_channels, out_right_nodes,
            out_right_value);
        if (observed_right != OPENCV_CORE_OK) {
            return observed_right;
        }
        *out_left_depth = left_depth;
        *out_right_depth = right_depth;
        *out_left_channels = left_channels;
        *out_right_channels = right_channels;
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
    const cv::SparseMat *typed_input = nullptr;
    cv::SparseMat *typed_output = nullptr;
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

    opencv_core_sparse_mat_handle *const allocated =
        reinterpret_cast<opencv_core_sparse_mat_handle *>(
            static_cast<uintptr_t>(1));
    if (opencv_core_module_input_sparse_mat(allocated, nullptr) ==
            OPENCV_CORE_OK ||
        opencv_core_module_output_sparse_mat(allocated, nullptr) ==
            OPENCV_CORE_OK) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    if (opencv_core_module_input_sparse_mat(nullptr, &typed_input) !=
            OPENCV_CORE_ERROR_INVALID_ARGUMENT ||
        opencv_core_module_output_sparse_mat(nullptr, &typed_output) !=
            OPENCV_CORE_ERROR_INVALID_ARGUMENT ||
        typed_input != nullptr || typed_output != nullptr) {
        return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    }
    return OPENCV_CORE_OK;
}

} // extern "C"