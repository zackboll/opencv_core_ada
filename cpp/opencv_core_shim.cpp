#include "opencv_core_shim.h"

#include <opencv2/core.hpp>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <exception>
#include <limits>
#include <memory>
#include <new>
#include <vector>

struct opencv_core_mat_handle {
    cv::Mat value;

    opencv_core_mat_handle() = default;

    explicit opencv_core_mat_handle(const cv::Mat &source)
        : value(source) {}
};

namespace {

constexpr std::size_t error_message_capacity = 1024;
thread_local char last_error_message[error_message_capacity] = "";

void clear_error() noexcept {
    last_error_message[0] = '\0';
}

void set_error(const char *message) noexcept {
    const char *safe_message =
        message == nullptr ? "No diagnostic message is available" : message;

    std::snprintf(last_error_message, error_message_capacity, "%s",
                  safe_message);
}

opencv_core_status translate_current_exception() noexcept {
    try {
        throw;
    } catch (const cv::Exception &error) {
        set_error(error.what());
        return OPENCV_CORE_ERROR_OPENCV;
    } catch (const std::exception &error) {
        set_error(error.what());
        return OPENCV_CORE_ERROR_STD;
    } catch (...) {
        set_error("Unknown C++ exception");
        return OPENCV_CORE_ERROR_UNKNOWN;
    }
}

opencv_core_status invalid_argument(const char *message) noexcept {
    set_error(message);
    return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
}

bool to_opencv_norm(int32_t norm_kind, int &opencv_norm) noexcept {
    switch (norm_kind) {
    case OPENCV_CORE_NORM_L1:
        opencv_norm = cv::NORM_L1;
        return true;
    case OPENCV_CORE_NORM_L2:
        opencv_norm = cv::NORM_L2;
        return true;
    case OPENCV_CORE_NORM_INF:
        opencv_norm = cv::NORM_INF;
        return true;
    default:
        return false;
    }
}

bool to_opencv_normalize_kind(int32_t normalize_kind,
                              int &opencv_normalize_kind) noexcept {
    switch (normalize_kind) {
    case OPENCV_CORE_NORMALIZE_L1:
        opencv_normalize_kind = cv::NORM_L1;
        return true;
    case OPENCV_CORE_NORMALIZE_L2:
        opencv_normalize_kind = cv::NORM_L2;
        return true;
    case OPENCV_CORE_NORMALIZE_INF:
        opencv_normalize_kind = cv::NORM_INF;
        return true;
    case OPENCV_CORE_NORMALIZE_MIN_MAX:
        opencv_normalize_kind = cv::NORM_MINMAX;
        return true;
    default:
        return false;
    }
}

bool to_opencv_border_kind(int32_t border_kind, int &opencv_border_kind) noexcept {
    switch (border_kind) {
    case OPENCV_CORE_BORDER_CONSTANT:
        opencv_border_kind = cv::BORDER_CONSTANT;
        return true;
    case OPENCV_CORE_BORDER_REPLICATE:
        opencv_border_kind = cv::BORDER_REPLICATE;
        return true;
    case OPENCV_CORE_BORDER_REFLECT:
        opencv_border_kind = cv::BORDER_REFLECT;
        return true;
    case OPENCV_CORE_BORDER_REFLECT_101:
        opencv_border_kind = cv::BORDER_REFLECT_101;
        return true;
    case OPENCV_CORE_BORDER_WRAP:
        opencv_border_kind = cv::BORDER_WRAP;
        return true;
    default:
        return false;
    }
}

bool to_opencv_compare_kind(int32_t comparison_kind,
                            int &opencv_compare_kind) noexcept {
    switch (comparison_kind) {
    case OPENCV_CORE_COMPARE_EQUAL:
        opencv_compare_kind = cv::CMP_EQ;
        return true;
    case OPENCV_CORE_COMPARE_NOT_EQUAL:
        opencv_compare_kind = cv::CMP_NE;
        return true;
    case OPENCV_CORE_COMPARE_LESS_THAN:
        opencv_compare_kind = cv::CMP_LT;
        return true;
    case OPENCV_CORE_COMPARE_LESS_OR_EQUAL:
        opencv_compare_kind = cv::CMP_LE;
        return true;
    case OPENCV_CORE_COMPARE_GREATER_THAN:
        opencv_compare_kind = cv::CMP_GT;
        return true;
    case OPENCV_CORE_COMPARE_GREATER_OR_EQUAL:
        opencv_compare_kind = cv::CMP_GE;
        return true;
    default:
        return false;
    }
}

bool mats_have_same_shape_and_type(const cv::Mat &left,
                                   const cv::Mat &right) noexcept {
    return left.dims == right.dims && left.rows == right.rows &&
           left.cols == right.cols && left.type() == right.type();
}

bool is_valid_mask_for(const cv::Mat &source, const cv::Mat &mask) noexcept {
    return mask.depth() == CV_8U && mask.channels() == 1 &&
           mask.rows == source.rows && mask.cols == source.cols;
}

bool to_opencv_depth(int32_t depth, int &opencv_depth) noexcept {
    switch (depth) {
    case OPENCV_CORE_DEPTH_UINT8:
        opencv_depth = CV_8U;
        return true;
    case OPENCV_CORE_DEPTH_INT8:
        opencv_depth = CV_8S;
        return true;
    case OPENCV_CORE_DEPTH_UINT16:
        opencv_depth = CV_16U;
        return true;
    case OPENCV_CORE_DEPTH_INT16:
        opencv_depth = CV_16S;
        return true;
    case OPENCV_CORE_DEPTH_INT32:
        opencv_depth = CV_32S;
        return true;
    case OPENCV_CORE_DEPTH_FLOAT32:
        opencv_depth = CV_32F;
        return true;
    case OPENCV_CORE_DEPTH_FLOAT64:
        opencv_depth = CV_64F;
        return true;
    case OPENCV_CORE_DEPTH_FLOAT16:
        opencv_depth = CV_16F;
        return true;
    default:
        return false;
    }
}

cv::Scalar to_opencv_scalar(const opencv_core_scalar &value) {
    return cv::Scalar(value.component_0, value.component_1, value.component_2,
                      value.component_3);
}

opencv_core_scalar from_opencv_scalar(const cv::Scalar &value) noexcept {
    return {value[0], value[1], value[2], value[3]};
}

cv::Vec<uint8_t, 3>
to_opencv_vec3(const opencv_core_uint8_vec3 &value) noexcept {
    return cv::Vec<uint8_t, 3>(value.component_0, value.component_1,
                               value.component_2);
}

opencv_core_uint8_vec3
from_opencv_vec3(const cv::Vec<uint8_t, 3> &value) noexcept {
    return {value[0], value[1], value[2]};
}

cv::Vec<float, 3>
to_opencv_vec3(const opencv_core_float32_vec3 &value) noexcept {
    return cv::Vec<float, 3>(value.component_0, value.component_1,
                             value.component_2);
}

opencv_core_float32_vec3
from_opencv_vec3(const cv::Vec<float, 3> &value) noexcept {
    return {value[0], value[1], value[2]};
}

bool size_to_abi(std::size_t value, uint64_t &result) noexcept {
    if constexpr (std::numeric_limits<std::size_t>::max() >
                  std::numeric_limits<uint64_t>::max()) {
        if (value > static_cast<std::size_t>(
                        std::numeric_limits<uint64_t>::max())) {
            return false;
        }
    }

    result = static_cast<uint64_t>(value);
    return true;
}

template <typename T>
opencv_core_status prepare_row(const opencv_core_mat_handle *mat, int32_t row,
                               uint64_t element_count, int expected_depth,
                               const char *depth_name, const T *&row_data,
                               std::size_t &byte_count) {
    row_data = nullptr;
    byte_count = 0;
 
    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }
 
    if (row < 0) {
        return invalid_argument("row must not be negative");
    }
 
    if (mat->value.dims != 2) {
        return invalid_argument("Mat must be two-dimensional");
    }
 
    if (mat->value.depth() != expected_depth) {
        return invalid_argument(depth_name);
    }
 
    if (mat->value.channels() != 1) {
        return invalid_argument("Mat must have exactly one channel");
    }
 
    if (row >= mat->value.rows) {
        return invalid_argument("row is outside Mat bounds");
    }
 
    if (element_count != static_cast<uint64_t>(mat->value.cols)) {
        return invalid_argument("element_count must equal Mat columns");
    }
 
    if (element_count >
        static_cast<uint64_t>(std::numeric_limits<std::size_t>::max() /
                              sizeof(T))) {
        return invalid_argument("row byte count exceeds the native size range");
    }
 
    byte_count = static_cast<std::size_t>(element_count) * sizeof(T);
    row_data = mat->value.template ptr<T>(static_cast<int>(row));
    return OPENCV_CORE_OK;
}

template <typename T>
opencv_core_status
prepare_vec3_row(const opencv_core_mat_handle *mat, int32_t row,
                 uint64_t element_count, int expected_depth,
                 const char *depth_name,
                 const cv::Vec<T, 3> *&row_data) {
    row_data = nullptr;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0) {
        return invalid_argument("row must not be negative");
    }

    if (mat->value.dims != 2) {
        return invalid_argument("Mat must be two-dimensional");
    }

    if (mat->value.depth() != expected_depth) {
        return invalid_argument(depth_name);
    }

    if (mat->value.channels() != 3) {
        return invalid_argument("Mat must have exactly three channels");
    }

    if (row >= mat->value.rows) {
        return invalid_argument("row is outside Mat bounds");
    }

    if (element_count != static_cast<uint64_t>(mat->value.cols)) {
        return invalid_argument("element_count must equal Mat columns");
    }

    if (element_count >
        static_cast<uint64_t>(std::numeric_limits<std::size_t>::max() / 3)) {
        return invalid_argument(
            "Vec3 scalar count exceeds the native size range");
    }

    row_data =
        mat->value.template ptr<cv::Vec<T, 3>>(static_cast<int>(row));
    return OPENCV_CORE_OK;
}
 
bool from_opencv_depth(int opencv_depth, int32_t &depth) noexcept {
    switch (opencv_depth) {
    case CV_8U:
        depth = OPENCV_CORE_DEPTH_UINT8;
        return true;
    case CV_8S:
        depth = OPENCV_CORE_DEPTH_INT8;
        return true;
    case CV_16U:
        depth = OPENCV_CORE_DEPTH_UINT16;
        return true;
    case CV_16S:
        depth = OPENCV_CORE_DEPTH_INT16;
        return true;
    case CV_32S:
        depth = OPENCV_CORE_DEPTH_INT32;
        return true;
    case CV_32F:
        depth = OPENCV_CORE_DEPTH_FLOAT32;
        return true;
    case CV_64F:
        depth = OPENCV_CORE_DEPTH_FLOAT64;
        return true;
    case CV_16F:
        depth = OPENCV_CORE_DEPTH_FLOAT16;
        return true;
    default:
        return false;
    }
}

} // namespace

extern "C" {

const char *opencv_core_last_error_message(void) {
    return last_error_message;
}

opencv_core_status
opencv_core_mat_create(opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    try {
        *out_mat = new opencv_core_mat_handle();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_create_2d(int32_t rows, int32_t columns, int32_t depth,
                          int32_t channels,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (rows < 0) {
        return invalid_argument("rows must not be negative");
    }

    if (columns < 0) {
        return invalid_argument("columns must not be negative");
    }

    if (channels < 1 || channels > OPENCV_CORE_MAX_CHANNELS) {
        return invalid_argument("channels must be in the range 1 .. 512");
    }

    int opencv_depth = 0;
    if (!to_opencv_depth(depth, opencv_depth)) {
        return invalid_argument("depth is not a supported depth identifier");
    }

    try {
        const int type = CV_MAKETYPE(opencv_depth, channels);
        *out_mat = new opencv_core_mat_handle(
            cv::Mat(static_cast<int>(rows), static_cast<int>(columns), type));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_copy(const opencv_core_mat_handle *source,
                     opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        *out_mat = new opencv_core_mat_handle(source->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_clone(const opencv_core_mat_handle *source,
                      opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        *out_mat = new opencv_core_mat_handle(source->value.clone());
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_transpose(const opencv_core_mat_handle *source,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat transposed;
        cv::transpose(source->value, transposed);
        *out_mat = new opencv_core_mat_handle(transposed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_flip(const opencv_core_mat_handle *source, int32_t flip_kind,
                     opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (flip_kind != OPENCV_CORE_FLIP_VERTICAL &&
        flip_kind != OPENCV_CORE_FLIP_HORIZONTAL &&
        flip_kind != OPENCV_CORE_FLIP_BOTH_AXES) {
        return invalid_argument("flip kind is not supported");
    }

    try {
        cv::Mat flipped;
        cv::flip(source->value, flipped, flip_kind);
        *out_mat = new opencv_core_mat_handle(flipped);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_sort(const opencv_core_mat_handle *source, uint8_t axis,
                     uint8_t descending, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (axis != 0 && axis != 1) {
        return invalid_argument("sort axis must be 0 or 1");
    }

    if (descending != 0 && descending != 1) {
        return invalid_argument("descending must be 0 or 1");
    }

    try {
        int flags = (axis == 0 ? cv::SORT_EVERY_ROW : cv::SORT_EVERY_COLUMN) |
                    (descending == 0 ? cv::SORT_ASCENDING : cv::SORT_DESCENDING);
        cv::Mat sorted;
        cv::sort(source->value, sorted, flags);
        *out_mat = new opencv_core_mat_handle(sorted);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_sort_indices(const opencv_core_mat_handle *source, uint8_t axis,
                             uint8_t descending,
                             opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (axis != 0 && axis != 1) {
        return invalid_argument("sort axis must be 0 or 1");
    }

    if (descending != 0 && descending != 1) {
        return invalid_argument("descending must be 0 or 1");
    }

    try {
        int flags = (axis == 0 ? cv::SORT_EVERY_ROW : cv::SORT_EVERY_COLUMN) |
                    (descending == 0 ? cv::SORT_ASCENDING : cv::SORT_DESCENDING);
        cv::Mat indices;
        cv::sortIdx(source->value, indices, flags);
        *out_mat = new opencv_core_mat_handle(indices);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_copy_make_border(const opencv_core_mat_handle *source,
                                 int32_t top, int32_t bottom, int32_t left,
                                 int32_t right, int32_t border_kind,
                                 const opencv_core_scalar *value,
                                 uint8_t isolated,
                                 opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr || value == nullptr) {
        return invalid_argument("source Mat handle and border value must not be null");
    }

    if (top < 0 || bottom < 0 || left < 0 || right < 0) {
        return invalid_argument("border sizes must not be negative");
    }

    if (isolated != 0 && isolated != 1) {
        return invalid_argument("isolated must be 0 or 1");
    }

    int opencv_border_kind = 0;
    if (!to_opencv_border_kind(border_kind, opencv_border_kind)) {
        return invalid_argument("border kind is not supported");
    }

    if (isolated != 0) {
        opencv_border_kind |= cv::BORDER_ISOLATED;
    }

    try {
        cv::Mat bordered;
        cv::copyMakeBorder(source->value, bordered, top, bottom, left, right,
                           opencv_border_kind, to_opencv_scalar(*value));
        *out_mat = new opencv_core_mat_handle(bordered);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_rotate(const opencv_core_mat_handle *source, int32_t rotation_kind,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int rotate_code;
    switch (rotation_kind) {
    case OPENCV_CORE_ROTATE_90_CLOCKWISE:
        rotate_code = cv::ROTATE_90_CLOCKWISE;
        break;
    case OPENCV_CORE_ROTATE_180:
        rotate_code = cv::ROTATE_180;
        break;
    case OPENCV_CORE_ROTATE_90_COUNTERCLOCKWISE:
        rotate_code = cv::ROTATE_90_COUNTERCLOCKWISE;
        break;
    default:
        return invalid_argument("rotation kind is not supported");
    }

    try {
        cv::Mat rotated;
        cv::rotate(source->value, rotated, rotate_code);
        *out_mat = new opencv_core_mat_handle(rotated);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_repeat(const opencv_core_mat_handle *source,
                       int32_t row_repetitions, int32_t column_repetitions,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (source->value.dims > 2) {
        return invalid_argument("Mat repeat supports two-dimensional Mats only");
    }

    if (row_repetitions <= 0 || column_repetitions <= 0) {
        return invalid_argument("repeat counts must be positive");
    }

    try {
        cv::Mat repeated;
        cv::repeat(source->value, row_repetitions, column_repetitions, repeated);
        *out_mat = new opencv_core_mat_handle(repeated);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_reduce(const opencv_core_mat_handle *source, int32_t axis,
                       int32_t reduction_kind, int32_t output_depth,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }
    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }
    if (source->value.dims > 2) {
        return invalid_argument("Mat reduce supports two-dimensional Mats only");
    }

    int opencv_axis;
    switch (axis) {
    case OPENCV_CORE_REDUCE_ACROSS_ROWS:
        opencv_axis = 0;
        break;
    case OPENCV_CORE_REDUCE_ACROSS_COLUMNS:
        opencv_axis = 1;
        break;
    default:
        return invalid_argument("reduction axis is not supported");
    }

    int opencv_kind;
    switch (reduction_kind) {
    case OPENCV_CORE_REDUCE_SUM:
        opencv_kind = cv::REDUCE_SUM;
        break;
    case OPENCV_CORE_REDUCE_AVERAGE:
        opencv_kind = cv::REDUCE_AVG;
        break;
    case OPENCV_CORE_REDUCE_MAXIMUM:
        opencv_kind = cv::REDUCE_MAX;
        break;
    case OPENCV_CORE_REDUCE_MINIMUM:
        opencv_kind = cv::REDUCE_MIN;
        break;
    case OPENCV_CORE_REDUCE_SUM_OF_SQUARES:
        opencv_kind = cv::REDUCE_SUM2;
        break;
    default:
        return invalid_argument("reduction kind is not supported");
    }

    int opencv_depth = -1;
    if (output_depth != OPENCV_CORE_DEFAULT_OUTPUT_DEPTH &&
        !to_opencv_depth(output_depth, opencv_depth)) {
        return invalid_argument("output depth is not a supported depth identifier");
    }

    try {
        cv::Mat reduced;
        cv::reduce(source->value, reduced, opencv_axis, opencv_kind,
                   opencv_depth);
        *out_mat = new opencv_core_mat_handle(reduced);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_hconcat(const opencv_core_mat_handle *const *sources,
                        int32_t count, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }
    *out_mat = nullptr;

    if (count < 0) {
        return invalid_argument("input count must not be negative");
    }
    if (count > 0 && sources == nullptr) {
        return invalid_argument("sources must not be null for nonempty input");
    }

    try {
        std::vector<cv::Mat> inputs;
        inputs.reserve(static_cast<size_t>(count));
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            inputs.push_back(sources[index]->value);
        }

        cv::Mat concatenated;
        cv::hconcat(inputs, concatenated);
        *out_mat = new opencv_core_mat_handle(concatenated);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_vconcat(const opencv_core_mat_handle *const *sources,
                        int32_t count, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }
    *out_mat = nullptr;

    if (count < 0) {
        return invalid_argument("input count must not be negative");
    }
    if (count > 0 && sources == nullptr) {
        return invalid_argument("sources must not be null for nonempty input");
    }

    try {
        std::vector<cv::Mat> inputs;
        inputs.reserve(static_cast<size_t>(count));
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            inputs.push_back(sources[index]->value);
        }

        cv::Mat concatenated;
        cv::vconcat(inputs, concatenated);
        *out_mat = new opencv_core_mat_handle(concatenated);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_copy_to(const opencv_core_mat_handle *source,
                        opencv_core_mat_handle *destination) {
    clear_error();

    if (source == nullptr || destination == nullptr) {
        return invalid_argument("source and destination Mat handles must not be null");
    }

    try {
        source->value.copyTo(destination->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_copy_to_masked(const opencv_core_mat_handle *source,
                               opencv_core_mat_handle *destination,
                               const opencv_core_mat_handle *mask) {
    clear_error();

    if (source == nullptr || destination == nullptr || mask == nullptr) {
        return invalid_argument(
            "source, destination, and mask Mat handles must not be null");
    }

    try {
        if (!is_valid_mask_for(source->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        source->value.copyTo(destination->value, mask->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_convert_to(const opencv_core_mat_handle *source, int32_t depth,
                           double scale, double offset,
                           opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int opencv_depth = 0;
    if (!to_opencv_depth(depth, opencv_depth)) {
        return invalid_argument("depth is not a supported depth identifier");
    }

    try {
        cv::Mat converted;
        source->value.convertTo(converted, opencv_depth, scale, offset);
        *out_mat = new opencv_core_mat_handle(converted);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_convert_scale_abs(const opencv_core_mat_handle *source,
                                  double scale, double offset,
                                  opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat converted;
        cv::convertScaleAbs(source->value, converted, scale, offset);
        *out_mat = new opencv_core_mat_handle(converted);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_apply_lut(const opencv_core_mat_handle *source,
                          const opencv_core_mat_handle *lut,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (lut == nullptr) {
        return invalid_argument("lookup-table Mat handle must not be null");
    }

    try {
        cv::Mat transformed;
        cv::LUT(source->value, lut->value, transformed);
        *out_mat = new opencv_core_mat_handle(transformed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_sqrt(const opencv_core_mat_handle *source,
                     opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat transformed;
        cv::sqrt(source->value, transformed);
        *out_mat = new opencv_core_mat_handle(transformed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_exp(const opencv_core_mat_handle *source,
                    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat transformed;
        cv::exp(source->value, transformed);
        *out_mat = new opencv_core_mat_handle(transformed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_log(const opencv_core_mat_handle *source,
                    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat transformed;
        cv::log(source->value, transformed);
        *out_mat = new opencv_core_mat_handle(transformed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_pow(const opencv_core_mat_handle *source, double power,
                    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat transformed;
        cv::pow(source->value, power, transformed);
        *out_mat = new opencv_core_mat_handle(transformed);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_magnitude(const opencv_core_mat_handle *x,
                          const opencv_core_mat_handle *y,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (x == nullptr || y == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    try {
        cv::Mat magnitude;
        cv::magnitude(x->value, y->value, magnitude);
        *out_mat = new opencv_core_mat_handle(magnitude);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_phase(const opencv_core_mat_handle *x,
                      const opencv_core_mat_handle *y,
                      uint8_t angle_in_degrees,
                      opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (x == nullptr || y == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (angle_in_degrees != 0 && angle_in_degrees != 1) {
        return invalid_argument("angle_in_degrees must be 0 or 1");
    }

    try {
        cv::Mat angle;
        cv::phase(x->value, y->value, angle, angle_in_degrees != 0);
        *out_mat = new opencv_core_mat_handle(angle);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_cart_to_polar(const opencv_core_mat_handle *x,
                              const opencv_core_mat_handle *y,
                              uint8_t angle_in_degrees,
                              opencv_core_mat_handle **out_magnitude,
                              opencv_core_mat_handle **out_angle) {
    clear_error();

    if (out_magnitude != nullptr) {
        *out_magnitude = nullptr;
    }
    if (out_angle != nullptr) {
        *out_angle = nullptr;
    }

    if (out_magnitude == nullptr || out_angle == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_magnitude == out_angle) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (x == nullptr || y == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (angle_in_degrees != 0 && angle_in_degrees != 1) {
        return invalid_argument("angle_in_degrees must be 0 or 1");
    }

    try {
        cv::Mat magnitude;
        cv::Mat angle;
        cv::cartToPolar(x->value, y->value, magnitude, angle,
                        angle_in_degrees != 0);

        std::unique_ptr<opencv_core_mat_handle> magnitude_handle(
            new opencv_core_mat_handle(magnitude));
        std::unique_ptr<opencv_core_mat_handle> angle_handle(
            new opencv_core_mat_handle(angle));

        *out_magnitude = magnitude_handle.release();
        *out_angle = angle_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_polar_to_cart(const opencv_core_mat_handle *magnitude,
                              const opencv_core_mat_handle *angle,
                              uint8_t angle_in_degrees,
                              opencv_core_mat_handle **out_x,
                              opencv_core_mat_handle **out_y) {
    clear_error();

    if (out_x != nullptr) {
        *out_x = nullptr;
    }
    if (out_y != nullptr) {
        *out_y = nullptr;
    }

    if (out_x == nullptr || out_y == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_x == out_y) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (magnitude == nullptr || angle == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (angle_in_degrees != 0 && angle_in_degrees != 1) {
        return invalid_argument("angle_in_degrees must be 0 or 1");
    }

    try {
        cv::Mat x;
        cv::Mat y;
        cv::polarToCart(magnitude->value, angle->value, x, y,
                        angle_in_degrees != 0);

        std::unique_ptr<opencv_core_mat_handle> x_handle(
            new opencv_core_mat_handle(x));
        std::unique_ptr<opencv_core_mat_handle> y_handle(
            new opencv_core_mat_handle(y));

        *out_x = x_handle.release();
        *out_y = y_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_normalize(const opencv_core_mat_handle *source,
                          int32_t normalize_kind, double alpha, double beta,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int opencv_normalize_kind = 0;
    if (!to_opencv_normalize_kind(normalize_kind, opencv_normalize_kind)) {
        return invalid_argument("normalization kind is not supported");
    }

    try {
        cv::Mat normalized;
        cv::normalize(source->value, normalized, alpha, beta,
                      opencv_normalize_kind, -1);
        *out_mat = new opencv_core_mat_handle(normalized);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_add(const opencv_core_mat_handle *left,
                    const opencv_core_mat_handle *right,
                    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat sum;
        cv::add(left->value, right->value, sum, cv::noArray(), -1);
        *out_mat = new opencv_core_mat_handle(sum);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_subtract(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat difference;
        cv::subtract(left->value, right->value, difference, cv::noArray(), -1);
        *out_mat = new opencv_core_mat_handle(difference);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_multiply(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat product;
        cv::multiply(left->value, right->value, product, 1.0, -1);
        *out_mat = new opencv_core_mat_handle(product);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_divide(const opencv_core_mat_handle *left,
                       const opencv_core_mat_handle *right,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat quotient;
        cv::divide(left->value, right->value, quotient, 1.0, -1);
        *out_mat = new opencv_core_mat_handle(quotient);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_abs_diff(const opencv_core_mat_handle *left,
                         const opencv_core_mat_handle *right,
                         opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat difference;
        cv::absdiff(left->value, right->value, difference);
        *out_mat = new opencv_core_mat_handle(difference);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_add_weighted(const opencv_core_mat_handle *left, double alpha,
                             const opencv_core_mat_handle *right, double beta,
                             double gamma, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat weighted_sum;
        cv::addWeighted(left->value, alpha, right->value, beta, gamma,
                        weighted_sum, -1);
        *out_mat = new opencv_core_mat_handle(weighted_sum);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_scale_add(const opencv_core_mat_handle *left, double scale,
                          const opencv_core_mat_handle *right,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat scaled_sum;
        cv::scaleAdd(left->value, scale, right->value, scaled_sum);
        *out_mat = new opencv_core_mat_handle(scaled_sum);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_minimum(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat result;
        cv::min(left->value, right->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_maximum(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat result;
        cv::max(left->value, right->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_and(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat result;
        cv::bitwise_and(left->value, right->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_or(const opencv_core_mat_handle *left,
                           const opencv_core_mat_handle *right,
                           opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat result;
        cv::bitwise_or(left->value, right->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_xor(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    try {
        cv::Mat result;
        cv::bitwise_xor(left->value, right->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_not(const opencv_core_mat_handle *source,
                            opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat result;
        cv::bitwise_not(source->value, result);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_and_masked(const opencv_core_mat_handle *left,
                                   const opencv_core_mat_handle *right,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr || mask == nullptr) {
        return invalid_argument("Mat operand and mask handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    if (!is_valid_mask_for(left->value, mask->value)) {
        return invalid_argument(
            "mask must be a same-sized single-channel UInt8 Mat");
    }

    try {
        cv::Mat result;
        cv::bitwise_and(left->value, right->value, result, mask->value);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_or_masked(const opencv_core_mat_handle *left,
                                  const opencv_core_mat_handle *right,
                                  const opencv_core_mat_handle *mask,
                                  opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr || mask == nullptr) {
        return invalid_argument("Mat operand and mask handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    if (!is_valid_mask_for(left->value, mask->value)) {
        return invalid_argument(
            "mask must be a same-sized single-channel UInt8 Mat");
    }

    try {
        cv::Mat result;
        cv::bitwise_or(left->value, right->value, result, mask->value);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_xor_masked(const opencv_core_mat_handle *left,
                                   const opencv_core_mat_handle *right,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr || mask == nullptr) {
        return invalid_argument("Mat operand and mask handles must not be null");
    }

    if (!mats_have_same_shape_and_type(left->value, right->value)) {
        return invalid_argument("Mat operands must have identical shape and type");
    }

    if (!is_valid_mask_for(left->value, mask->value)) {
        return invalid_argument(
            "mask must be a same-sized single-channel UInt8 Mat");
    }

    try {
        cv::Mat result;
        cv::bitwise_xor(left->value, right->value, result, mask->value);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_bitwise_not_masked(const opencv_core_mat_handle *source,
                                   const opencv_core_mat_handle *mask,
                                   opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr || mask == nullptr) {
        return invalid_argument("source Mat and mask handles must not be null");
    }

    if (!is_valid_mask_for(source->value, mask->value)) {
        return invalid_argument(
            "mask must be a same-sized single-channel UInt8 Mat");
    }

    try {
        cv::Mat result;
        cv::bitwise_not(source->value, result, mask->value);
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_in_range_scalar(const opencv_core_mat_handle *source,
                                const opencv_core_scalar *lower,
                                const opencv_core_scalar *upper,
                                opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr || lower == nullptr || upper == nullptr) {
        return invalid_argument("source Mat and scalar bounds must not be null");
    }

    try {
        if (source->value.channels() > 4) {
            return invalid_argument(
                "scalar-bounded in-range supports Mats with at most four channels");
        }

        cv::Mat result;
        cv::inRange(source->value, to_opencv_scalar(*lower),
                    to_opencv_scalar(*upper), result);
        if (result.type() != CV_8UC1 || result.size() != source->value.size()) {
            return invalid_argument("in-range produced an invalid mask result");
        }
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_compare(const opencv_core_mat_handle *left,
                        const opencv_core_mat_handle *right,
                        int32_t comparison_kind,
                        opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat operand handles must not be null");
    }

    int opencv_compare_kind = 0;
    if (!to_opencv_compare_kind(comparison_kind, opencv_compare_kind)) {
        return invalid_argument("comparison kind is not supported");
    }

    const cv::Mat &left_mat = left->value;
    const cv::Mat &right_mat = right->value;

    if (left_mat.dims > 2 || right_mat.dims > 2) {
        return invalid_argument("Mat compare supports two-dimensional Mats only");
    }

    if (left_mat.channels() != 1 || right_mat.channels() != 1) {
        return invalid_argument("Mat compare requires single-channel operands");
    }

    if (left_mat.rows != right_mat.rows || left_mat.cols != right_mat.cols) {
        return invalid_argument(
            "Mat compare requires operands with identical dimensions");
    }

    if (left_mat.depth() != right_mat.depth()) {
        return invalid_argument(
            "Mat compare requires operands with identical depths");
    }

    try {
        cv::Mat result;
        cv::compare(left_mat, right_mat, result, opencv_compare_kind);
        if (result.type() != CV_8UC1 || result.rows != left_mat.rows ||
            result.cols != left_mat.cols) {
            return invalid_argument("compare produced an invalid mask result");
        }
        *out_mat = new opencv_core_mat_handle(result);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_region(const opencv_core_mat_handle *source, int32_t x,
                       int32_t y, int32_t width, int32_t height,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (x < 0 || y < 0) {
        return invalid_argument("region origin must not be negative");
    }

    if (width <= 0 || height <= 0) {
        return invalid_argument("region width and height must be positive");
    }

    try {
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (x >= source->value.cols || y >= source->value.rows) {
            return invalid_argument("region origin is outside source Mat bounds");
        }

        if (width > source->value.cols - x ||
            height > source->value.rows - y) {
            return invalid_argument("region extends outside source Mat bounds");
        }

        *out_mat = new opencv_core_mat_handle(
            cv::Mat(source->value, cv::Rect(x, y, width, height)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_row_view(const opencv_core_mat_handle *source, int32_t row,
                         opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (row < 0) {
        return invalid_argument("row must not be negative");
    }

    try {
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (row >= source->value.rows) {
            return invalid_argument("row is outside source Mat bounds");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.row(static_cast<int>(row)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_column_view(const opencv_core_mat_handle *source,
                            int32_t column,
                            opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (column < 0) {
        return invalid_argument("column must not be negative");
    }

    try {
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (column >= source->value.cols) {
            return invalid_argument("column is outside source Mat bounds");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.col(static_cast<int>(column)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_row_range_view(const opencv_core_mat_handle *source,
                               int32_t start, int32_t stop,
                               opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (start < 0 || stop < 0) {
        return invalid_argument("range endpoints must not be negative");
    }

    if (start > stop) {
        return invalid_argument("range start must not exceed range stop");
    }

    try {
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (stop > source->value.rows) {
            return invalid_argument("range stop is outside source Mat bounds");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.rowRange(static_cast<int>(start),
                                   static_cast<int>(stop)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_column_range_view(const opencv_core_mat_handle *source,
                                  int32_t start, int32_t stop,
                                  opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (start < 0 || stop < 0) {
        return invalid_argument("range endpoints must not be negative");
    }

    if (start > stop) {
        return invalid_argument("range start must not exceed range stop");
    }

    try {
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (stop > source->value.cols) {
            return invalid_argument("range stop is outside source Mat bounds");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.colRange(static_cast<int>(start),
                                   static_cast<int>(stop)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_reshape(const opencv_core_mat_handle *source, int32_t channels,
                        int32_t rows, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (channels < 1 || channels > OPENCV_CORE_MAX_CHANNELS) {
        return invalid_argument("channels must be in the range 1 .. 512");
    }

    if (rows < 0) {
        return invalid_argument("rows must not be negative");
    }

    try {
        if (!source->value.empty() && source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.reshape(static_cast<int>(channels),
                                  static_cast<int>(rows)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_diagonal_matrix(const opencv_core_mat_handle *diagonal,
                                opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (diagonal == nullptr) {
        return invalid_argument("diagonal Mat handle must not be null");
    }

    try {
        if (diagonal->value.dims != 2 ||
            (diagonal->value.rows != 1 && diagonal->value.cols != 1)) {
            return invalid_argument("diagonal Mat must be a row or column vector");
        }

        *out_mat = new opencv_core_mat_handle(cv::Mat::diag(diagonal->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_diagonal_view(const opencv_core_mat_handle *source,
                              int32_t offset,
                              opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        if (source->value.dims > 2) {
            return invalid_argument("source Mat must be at most two-dimensional");
        }

        if (source->value.empty() || offset >= source->value.cols ||
            offset <= -source->value.rows) {
            return invalid_argument("diagonal offset selects no source elements");
        }

        *out_mat = new opencv_core_mat_handle(
            source->value.diag(static_cast<int>(offset)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

void opencv_core_mat_destroy(opencv_core_mat_handle *mat) {
    clear_error();

    try {
        delete mat;
    } catch (const cv::Exception &error) {
        set_error(error.what());
    } catch (const std::exception &error) {
        set_error(error.what());
    } catch (...) {
        set_error("Unknown C++ exception during Mat destruction");
    }
}

opencv_core_status
opencv_core_mat_is_empty(const opencv_core_mat_handle *mat,
                         uint8_t *out_is_empty) {
    clear_error();

    if (out_is_empty == nullptr) {
        return invalid_argument("out_is_empty must not be null");
    }

    *out_is_empty = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_is_empty = mat->value.empty() ? UINT8_C(1) : UINT8_C(0);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_rows(const opencv_core_mat_handle *mat, int32_t *out_rows) {
    clear_error();

    if (out_rows == nullptr) {
        return invalid_argument("out_rows must not be null");
    }

    *out_rows = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_rows = static_cast<int32_t>(mat->value.rows);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_columns(const opencv_core_mat_handle *mat,
                        int32_t *out_columns) {
    clear_error();

    if (out_columns == nullptr) {
        return invalid_argument("out_columns must not be null");
    }

    *out_columns = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_columns = static_cast<int32_t>(mat->value.cols);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_channels(const opencv_core_mat_handle *mat,
                         int32_t *out_channels) {
    clear_error();

    if (out_channels == nullptr) {
        return invalid_argument("out_channels must not be null");
    }

    *out_channels = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_channels = static_cast<int32_t>(mat->value.channels());
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_depth(const opencv_core_mat_handle *mat, int32_t *out_depth) {
    clear_error();

    if (out_depth == nullptr) {
        return invalid_argument("out_depth must not be null");
    }

    *out_depth = OPENCV_CORE_DEPTH_UINT8;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (!from_opencv_depth(mat->value.depth(), *out_depth)) {
            return invalid_argument("Mat has an unsupported OpenCV depth");
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_total(const opencv_core_mat_handle *mat, uint64_t *out_total) {
    clear_error();

    if (out_total == nullptr) {
        return invalid_argument("out_total must not be null");
    }

    *out_total = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (!size_to_abi(mat->value.total(), *out_total)) {
            return invalid_argument("Mat total exceeds the C ABI size range");
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_element_size(const opencv_core_mat_handle *mat,
                             uint64_t *out_element_size) {
    clear_error();

    if (out_element_size == nullptr) {
        return invalid_argument("out_element_size must not be null");
    }

    *out_element_size = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (!size_to_abi(mat->value.elemSize(), *out_element_size)) {
            return invalid_argument(
                "Mat element size exceeds the C ABI size range");
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_channel_size(const opencv_core_mat_handle *mat,
                             uint64_t *out_channel_size) {
    clear_error();

    if (out_channel_size == nullptr) {
        return invalid_argument("out_channel_size must not be null");
    }

    *out_channel_size = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (!size_to_abi(mat->value.elemSize1(), *out_channel_size)) {
            return invalid_argument(
                "Mat channel size exceeds the C ABI size range");
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_is_continuous(const opencv_core_mat_handle *mat,
                              uint8_t *out_is_continuous) {
    clear_error();

    if (out_is_continuous == nullptr) {
        return invalid_argument("out_is_continuous must not be null");
    }

    *out_is_continuous = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_is_continuous =
            mat->value.isContinuous() ? UINT8_C(1) : UINT8_C(0);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_is_submatrix(const opencv_core_mat_handle *mat,
                             uint8_t *out_is_submatrix) {
    clear_error();

    if (out_is_submatrix == nullptr) {
        return invalid_argument("out_is_submatrix must not be null");
    }

    *out_is_submatrix = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_is_submatrix =
            mat->value.isSubmatrix() ? UINT8_C(1) : UINT8_C(0);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_get_uint8(const opencv_core_mat_handle *mat, int32_t row,
                          int32_t column, uint8_t *out_value) {
    clear_error();

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    *out_value = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_8U) {
            return invalid_argument("Mat depth must be UInt8");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        *out_value =
            mat->value.at<uint8_t>(static_cast<int>(row),
                                   static_cast<int>(column));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_uint8(opencv_core_mat_handle *mat, int32_t row,
                          int32_t column, uint8_t value) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_8U) {
            return invalid_argument("Mat depth must be UInt8");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        mat->value.at<uint8_t>(static_cast<int>(row),
                               static_cast<int>(column)) = value;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_get_float32(const opencv_core_mat_handle *mat, int32_t row,
                            int32_t column, float *out_value) {
    clear_error();

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    *out_value = 0.0F;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_32F) {
            return invalid_argument("Mat depth must be Float32");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        *out_value = mat->value.at<float>(static_cast<int>(row),
                                          static_cast<int>(column));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_classify_float32(const opencv_core_mat_handle *mat,
                                 int32_t row, int32_t column,
                                 int32_t *out_classification) {
    clear_error();

    if (out_classification == nullptr) {
        return invalid_argument("out_classification must not be null");
    }

    *out_classification = OPENCV_CORE_FLOAT32_FINITE;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_32F) {
            return invalid_argument("Mat depth must be Float32");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        const float value = mat->value.at<float>(static_cast<int>(row),
                                                  static_cast<int>(column));
        if (std::isnan(value)) {
            *out_classification = OPENCV_CORE_FLOAT32_NOT_A_NUMBER;
        } else if (std::isinf(value)) {
            *out_classification = value > 0.0F
                                      ? OPENCV_CORE_FLOAT32_POSITIVE_INFINITY
                                      : OPENCV_CORE_FLOAT32_NEGATIVE_INFINITY;
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_float32(opencv_core_mat_handle *mat, int32_t row,
                            int32_t column, float value) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_32F) {
            return invalid_argument("Mat depth must be Float32");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        mat->value.at<float>(static_cast<int>(row),
                             static_cast<int>(column)) = value;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_read_uint8_row(const opencv_core_mat_handle *mat, int32_t row,
                               uint8_t *data, uint64_t element_count) {
    clear_error();
 
    if (data == nullptr && element_count != 0) {
        return invalid_argument("data must not be null when element_count is nonzero");
    }
 
    try {
        const uint8_t *row_data = nullptr;
        std::size_t byte_count = 0;
        const opencv_core_status status =
            prepare_row(mat, row, element_count, CV_8U,
                        "Mat depth must be UInt8", row_data, byte_count);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
 
        if (byte_count != 0) {
            std::memcpy(data, row_data, byte_count);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}
 
opencv_core_status
opencv_core_mat_write_uint8_row(opencv_core_mat_handle *mat, int32_t row,
                                const uint8_t *data, uint64_t element_count) {
    clear_error();
 
    if (data == nullptr && element_count != 0) {
        return invalid_argument("data must not be null when element_count is nonzero");
    }
 
    try {
        const uint8_t *row_data = nullptr;
        std::size_t byte_count = 0;
        const opencv_core_status status =
            prepare_row(mat, row, element_count, CV_8U,
                        "Mat depth must be UInt8", row_data, byte_count);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
 
        if (byte_count != 0) {
            std::memcpy(const_cast<uint8_t *>(row_data), data, byte_count);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}
 
opencv_core_status
opencv_core_mat_read_float32_row(const opencv_core_mat_handle *mat,
                                 int32_t row, float *data,
                                 uint64_t element_count) {
    clear_error();
 
    if (data == nullptr && element_count != 0) {
        return invalid_argument("data must not be null when element_count is nonzero");
    }
 
    try {
        const float *row_data = nullptr;
        std::size_t byte_count = 0;
        const opencv_core_status status =
            prepare_row(mat, row, element_count, CV_32F,
                        "Mat depth must be Float32", row_data, byte_count);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
 
        if (byte_count != 0) {
            std::memcpy(data, row_data, byte_count);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}
 
opencv_core_status
opencv_core_mat_write_float32_row(opencv_core_mat_handle *mat, int32_t row,
                                  const float *data, uint64_t element_count) {
    clear_error();
 
    if (data == nullptr && element_count != 0) {
        return invalid_argument("data must not be null when element_count is nonzero");
    }
 
    try {
        const float *row_data = nullptr;
        std::size_t byte_count = 0;
        const opencv_core_status status =
            prepare_row(mat, row, element_count, CV_32F,
                        "Mat depth must be Float32", row_data, byte_count);
        if (status != OPENCV_CORE_OK) {
            return status;
        }
 
        if (byte_count != 0) {
            std::memcpy(const_cast<float *>(row_data), data, byte_count);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}
 
opencv_core_status
opencv_core_mat_read_uint8_vec3_row(const opencv_core_mat_handle *mat,
                                    int32_t row, uint8_t *data,
                                    uint64_t element_count) {
    clear_error();

    if (data == nullptr && element_count != 0) {
        return invalid_argument(
            "data must not be null when element_count is nonzero");
    }

    try {
        const cv::Vec<uint8_t, 3> *row_data = nullptr;
        const opencv_core_status status =
            prepare_vec3_row(mat, row, element_count, CV_8U,
                             "Mat depth must be UInt8", row_data);
        if (status != OPENCV_CORE_OK) {
            return status;
        }

        for (std::size_t column = 0;
             column < static_cast<std::size_t>(element_count); ++column) {
            const std::size_t offset = column * 3;
            data[offset] = row_data[column][0];
            data[offset + 1] = row_data[column][1];
            data[offset + 2] = row_data[column][2];
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_write_uint8_vec3_row(opencv_core_mat_handle *mat, int32_t row,
                                     const uint8_t *data,
                                     uint64_t element_count) {
    clear_error();

    if (data == nullptr && element_count != 0) {
        return invalid_argument(
            "data must not be null when element_count is nonzero");
    }

    try {
        const cv::Vec<uint8_t, 3> *const_row_data = nullptr;
        const opencv_core_status status =
            prepare_vec3_row(mat, row, element_count, CV_8U,
                             "Mat depth must be UInt8", const_row_data);
        if (status != OPENCV_CORE_OK) {
            return status;
        }

        cv::Vec<uint8_t, 3> *const row_data =
            const_cast<cv::Vec<uint8_t, 3> *>(const_row_data);
        for (std::size_t column = 0;
             column < static_cast<std::size_t>(element_count); ++column) {
            const std::size_t offset = column * 3;
            row_data[column] =
                cv::Vec<uint8_t, 3>(data[offset], data[offset + 1],
                                    data[offset + 2]);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_read_float32_vec3_row(const opencv_core_mat_handle *mat,
                                      int32_t row, float *data,
                                      uint64_t element_count) {
    clear_error();

    if (data == nullptr && element_count != 0) {
        return invalid_argument(
            "data must not be null when element_count is nonzero");
    }

    try {
        const cv::Vec<float, 3> *row_data = nullptr;
        const opencv_core_status status =
            prepare_vec3_row(mat, row, element_count, CV_32F,
                             "Mat depth must be Float32", row_data);
        if (status != OPENCV_CORE_OK) {
            return status;
        }

        for (std::size_t column = 0;
             column < static_cast<std::size_t>(element_count); ++column) {
            const std::size_t offset = column * 3;
            data[offset] = row_data[column][0];
            data[offset + 1] = row_data[column][1];
            data[offset + 2] = row_data[column][2];
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_write_float32_vec3_row(opencv_core_mat_handle *mat,
                                       int32_t row, const float *data,
                                       uint64_t element_count) {
    clear_error();

    if (data == nullptr && element_count != 0) {
        return invalid_argument(
            "data must not be null when element_count is nonzero");
    }

    try {
        const cv::Vec<float, 3> *const_row_data = nullptr;
        const opencv_core_status status =
            prepare_vec3_row(mat, row, element_count, CV_32F,
                             "Mat depth must be Float32", const_row_data);
        if (status != OPENCV_CORE_OK) {
            return status;
        }

        cv::Vec<float, 3> *const row_data =
            const_cast<cv::Vec<float, 3> *>(const_row_data);
        for (std::size_t column = 0;
             column < static_cast<std::size_t>(element_count); ++column) {
            const std::size_t offset = column * 3;
            row_data[column] =
                cv::Vec<float, 3>(data[offset], data[offset + 1],
                                  data[offset + 2]);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_get_uint8_vec3(const opencv_core_mat_handle *mat, int32_t row,
                               int32_t column,
                               opencv_core_uint8_vec3 *out_value) {
    clear_error();

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    *out_value = {0, 0, 0};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_8U) {
            return invalid_argument("Mat depth must be UInt8");
        }

        if (mat->value.channels() != 3) {
            return invalid_argument("Mat must have exactly three channels");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        *out_value = from_opencv_vec3(
            mat->value.at<cv::Vec<uint8_t, 3>>(static_cast<int>(row),
                                                static_cast<int>(column)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_uint8_vec3(opencv_core_mat_handle *mat, int32_t row,
                               int32_t column,
                               const opencv_core_uint8_vec3 *value) {
    clear_error();

    if (value == nullptr) {
        return invalid_argument("value must not be null");
    }

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_8U) {
            return invalid_argument("Mat depth must be UInt8");
        }

        if (mat->value.channels() != 3) {
            return invalid_argument("Mat must have exactly three channels");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        mat->value.at<cv::Vec<uint8_t, 3>>(static_cast<int>(row),
                                             static_cast<int>(column)) =
            to_opencv_vec3(*value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_get_float32_vec3(const opencv_core_mat_handle *mat,
                                 int32_t row, int32_t column,
                                 opencv_core_float32_vec3 *out_value) {
    clear_error();

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    *out_value = {0.0F, 0.0F, 0.0F};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_32F) {
            return invalid_argument("Mat depth must be Float32");
        }

        if (mat->value.channels() != 3) {
            return invalid_argument("Mat must have exactly three channels");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        *out_value = from_opencv_vec3(
            mat->value.at<cv::Vec<float, 3>>(static_cast<int>(row),
                                              static_cast<int>(column)));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_float32_vec3(opencv_core_mat_handle *mat, int32_t row,
                                 int32_t column,
                                 const opencv_core_float32_vec3 *value) {
    clear_error();

    if (value == nullptr) {
        return invalid_argument("value must not be null");
    }

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.depth() != CV_32F) {
            return invalid_argument("Mat depth must be Float32");
        }

        if (mat->value.channels() != 3) {
            return invalid_argument("Mat must have exactly three channels");
        }

        if (row >= mat->value.rows || column >= mat->value.cols) {
            return invalid_argument("row or column is outside Mat bounds");
        }

        mat->value.at<cv::Vec<float, 3>>(static_cast<int>(row),
                                          static_cast<int>(column)) =
            to_opencv_vec3(*value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_to(opencv_core_mat_handle *mat,
                       const opencv_core_scalar *value) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (value == nullptr) {
        return invalid_argument("Scalar value must not be null");
    }

    try {
        mat->value.setTo(to_opencv_scalar(*value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_to_masked(opencv_core_mat_handle *mat,
                              const opencv_core_scalar *value,
                              const opencv_core_mat_handle *mask) {
    clear_error();

    if (mat == nullptr || mask == nullptr) {
        return invalid_argument("Mat and mask handles must not be null");
    }

    if (value == nullptr) {
        return invalid_argument("Scalar value must not be null");
    }

    try {
        if (!is_valid_mask_for(mat->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        mat->value.setTo(to_opencv_scalar(*value), mask->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_sum(const opencv_core_mat_handle *mat,
                    opencv_core_scalar *out_sum) {
    clear_error();

    if (out_sum == nullptr) {
        return invalid_argument("out_sum must not be null");
    }

    *out_sum = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_sum = from_opencv_scalar(cv::sum(mat->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_trace(const opencv_core_mat_handle *mat,
                      opencv_core_scalar *out_trace) {
    clear_error();

    if (out_trace == nullptr) {
        return invalid_argument("out_trace must not be null");
    }

    *out_trace = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.dims > 2) {
            return invalid_argument("Trace requires a Mat with at most two dimensions");
        }

        if (mat->value.channels() > 4) {
            return invalid_argument("Trace supports Mats with at most four channels");
        }

        if (mat->value.depth() == CV_16F) {
            return invalid_argument("Trace does not support Float16 Mats");
        }

        *out_trace = from_opencv_scalar(cv::trace(mat->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_determinant(const opencv_core_mat_handle *source,
                            double *out_determinant) {
    clear_error();

    if (out_determinant == nullptr) {
        return invalid_argument("out_determinant must not be null");
    }

    *out_determinant = 0.0;

    if (source == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        *out_determinant = cv::determinant(source->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_invert(const opencv_core_mat_handle *source,
                       uint8_t *out_invertible,
                       opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_invertible != nullptr) {
        *out_invertible = UINT8_C(0);
    }

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_invertible == nullptr || out_mat == nullptr) {
        return invalid_argument("invert output pointers must not be null");
    }

    if (source == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        cv::Mat inverse;
        const double result =
            cv::invert(source->value, inverse, cv::DECOMP_LU);

        if (result == 0.0) {
            return OPENCV_CORE_OK;
        }

        std::unique_ptr<opencv_core_mat_handle> inverse_handle(
            new opencv_core_mat_handle(inverse));
        *out_mat = inverse_handle.release();
        *out_invertible = UINT8_C(1);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_solve(const opencv_core_mat_handle *coefficients,
                      const opencv_core_mat_handle *right_hand_side,
                      uint8_t *out_solved,
                      opencv_core_mat_handle **out_solution) {
    clear_error();

    if (out_solved != nullptr) {
        *out_solved = UINT8_C(0);
    }

    if (out_solution != nullptr) {
        *out_solution = nullptr;
    }

    if (out_solved == nullptr || out_solution == nullptr) {
        return invalid_argument("solve output pointers must not be null");
    }

    if (coefficients == nullptr || right_hand_side == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        const cv::Mat &A = coefficients->value;
        const cv::Mat &B = right_hand_side->value;

        if (A.empty() || B.empty()) {
            return invalid_argument("solve requires non-empty coefficient and right-hand-side Mats");
        }

        if (A.rows != A.cols) {
            return invalid_argument("solve requires a square coefficient matrix");
        }

        if (A.type() != CV_32FC1 && A.type() != CV_64FC1) {
            return invalid_argument("solve requires a single-channel Float32 or Float64 coefficient matrix");
        }

        if (B.type() != A.type()) {
            return invalid_argument("solve requires a right-hand side with the same type as the coefficients");
        }

        if (B.rows != A.rows) {
            return invalid_argument("solve requires a right-hand side with the same number of rows as the coefficients");
        }

        cv::Mat solution;
        const bool solved =
            cv::solve(A, B, solution, cv::DECOMP_LU);

        if (!solved) {
            return OPENCV_CORE_OK;
        }

        std::unique_ptr<opencv_core_mat_handle> solution_handle(
            new opencv_core_mat_handle(solution));
        *out_solution = solution_handle.release();
        *out_solved = UINT8_C(1);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_matrix_multiply(const opencv_core_mat_handle *left,
                                const opencv_core_mat_handle *right,
                                opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (left == nullptr || right == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        const cv::Mat &A = left->value;
        const cv::Mat &B = right->value;

        if (A.empty() || B.empty()) {
            return invalid_argument(
                "matrix multiply requires non-empty Left and Right Mats");
        }

        if (A.dims > 2 || B.dims > 2) {
            return invalid_argument(
                "matrix multiply requires Mats with at most two dimensions");
        }

        if (A.type() != B.type()) {
            return invalid_argument(
                "matrix multiply requires operands with identical complete types");
        }

        if (A.type() != CV_32FC1 && A.type() != CV_64FC1 &&
            A.type() != CV_32FC2 && A.type() != CV_64FC2) {
            return invalid_argument(
                "matrix multiply requires Float32 or Float64 Mats with one or two channels");
        }

        if (A.cols != B.rows) {
            return invalid_argument(
                "matrix multiply requires Left.Columns to equal Right.Rows");
        }

        cv::Mat result;
        cv::gemm(A, B, 1.0, cv::noArray(), 0.0, result, 0);

        if (result.rows != A.rows || result.cols != B.cols ||
            result.type() != A.type()) {
            return invalid_argument(
                "matrix multiply produced a result with inconsistent shape or type");
        }

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_matrix_multiply_add(const opencv_core_mat_handle *left,
                                    const opencv_core_mat_handle *right,
                                    const opencv_core_mat_handle *addend,
                                    double product_scale,
                                    double addend_scale,
                                    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (left == nullptr || right == nullptr || addend == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        const cv::Mat &A = left->value;
        const cv::Mat &B = right->value;
        const cv::Mat &C = addend->value;

        if (A.empty() || B.empty() || C.empty()) {
            return invalid_argument(
                "matrix multiply-add requires non-empty Left, Right, and Addend Mats");
        }

        if (A.dims > 2 || B.dims > 2 || C.dims > 2) {
            return invalid_argument(
                "matrix multiply-add requires Mats with at most two dimensions");
        }

        if (A.type() != B.type()) {
            return invalid_argument(
                "matrix multiply-add requires Left and Right with identical complete types");
        }

        if (C.type() != A.type()) {
            return invalid_argument(
                "matrix multiply-add requires Addend to have the same complete type as Left and Right");
        }

        if (A.type() != CV_32FC1 && A.type() != CV_64FC1 &&
            A.type() != CV_32FC2 && A.type() != CV_64FC2) {
            return invalid_argument(
                "matrix multiply-add requires Float32 or Float64 Mats with one or two channels");
        }

        if (A.cols != B.rows) {
            return invalid_argument(
                "matrix multiply-add requires Left.Columns to equal Right.Rows");
        }

        if (C.rows != A.rows || C.cols != B.cols) {
            return invalid_argument(
                "matrix multiply-add requires Addend to have shape Left.Rows x Right.Columns");
        }

        cv::Mat result;
        cv::gemm(A, B, product_scale, C, addend_scale, result, 0);

        if (result.rows != A.rows || result.cols != B.cols ||
            result.type() != A.type()) {
            return invalid_argument(
                "matrix multiply-add produced a result with inconsistent shape or type");
        }

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mean(const opencv_core_mat_handle *mat,
                     opencv_core_scalar *out_mean) {
    clear_error();

    if (out_mean == nullptr) {
        return invalid_argument("out_mean must not be null");
    }

    *out_mean = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.channels() > 4) {
            return invalid_argument("Mean supports Mats with at most four channels");
        }

        *out_mean = from_opencv_scalar(cv::mean(mat->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mean_masked(const opencv_core_mat_handle *mat,
                            const opencv_core_mat_handle *mask,
                            opencv_core_scalar *out_mean) {
    clear_error();

    if (out_mean == nullptr) {
        return invalid_argument("out_mean must not be null");
    }

    *out_mean = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr || mask == nullptr) {
        return invalid_argument("Mat and mask handles must not be null");
    }

    try {
        if (mat->value.channels() > 4) {
            return invalid_argument("Mean supports Mats with at most four channels");
        }

        if (!is_valid_mask_for(mat->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        *out_mean = from_opencv_scalar(cv::mean(mat->value, mask->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mean_std_dev(const opencv_core_mat_handle *mat,
                             opencv_core_scalar *out_mean,
                             opencv_core_scalar *out_standard_deviation) {
    clear_error();

    if (out_mean == nullptr || out_standard_deviation == nullptr) {
        return invalid_argument("mean and standard deviation outputs must not be null");
    }

    *out_mean = {0.0, 0.0, 0.0, 0.0};
    *out_standard_deviation = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.empty()) {
            return invalid_argument("Mean/stddev requires a non-empty Mat");
        }

        if (mat->value.channels() > 4) {
            return invalid_argument(
                "Mean/stddev supports Mats with at most four channels");
        }

        cv::Scalar mean;
        cv::Scalar standard_deviation;
        cv::meanStdDev(mat->value, mean, standard_deviation);
        *out_mean = from_opencv_scalar(mean);
        *out_standard_deviation = from_opencv_scalar(standard_deviation);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mean_std_dev_masked(
    const opencv_core_mat_handle *mat, const opencv_core_mat_handle *mask,
    opencv_core_scalar *out_mean, opencv_core_scalar *out_standard_deviation) {
    clear_error();

    if (out_mean == nullptr || out_standard_deviation == nullptr) {
        return invalid_argument("mean and standard deviation outputs must not be null");
    }

    *out_mean = {0.0, 0.0, 0.0, 0.0};
    *out_standard_deviation = {0.0, 0.0, 0.0, 0.0};

    if (mat == nullptr || mask == nullptr) {
        return invalid_argument("Mat and mask handles must not be null");
    }

    try {
        if (mat->value.empty()) {
            return invalid_argument("Mean/stddev requires a non-empty Mat");
        }

        if (mat->value.channels() > 4) {
            return invalid_argument(
                "Mean/stddev supports Mats with at most four channels");
        }

        if (!is_valid_mask_for(mat->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        cv::Scalar mean;
        cv::Scalar standard_deviation;
        cv::meanStdDev(mat->value, mean, standard_deviation, mask->value);
        *out_mean = from_opencv_scalar(mean);
        *out_standard_deviation = from_opencv_scalar(standard_deviation);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_norm(const opencv_core_mat_handle *mat, int32_t norm_kind,
                     double *out_norm) {
    clear_error();

    if (out_norm == nullptr) {
        return invalid_argument("norm output pointer must not be null");
    }

    *out_norm = 0.0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    int opencv_norm = 0;
    if (!to_opencv_norm(norm_kind, opencv_norm)) {
        return invalid_argument("norm kind is not supported");
    }

    try {
        *out_norm = cv::norm(mat->value, opencv_norm);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_norm_masked(const opencv_core_mat_handle *mat,
                            const opencv_core_mat_handle *mask,
                            int32_t norm_kind, double *out_norm) {
    clear_error();

    if (out_norm == nullptr) {
        return invalid_argument("norm output pointer must not be null");
    }

    *out_norm = 0.0;

    if (mat == nullptr || mask == nullptr) {
        return invalid_argument("Mat and mask handles must not be null");
    }

    int opencv_norm = 0;
    if (!to_opencv_norm(norm_kind, opencv_norm)) {
        return invalid_argument("norm kind is not supported");
    }

    try {
        if (!is_valid_mask_for(mat->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        *out_norm = cv::norm(mat->value, opencv_norm, mask->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_min_max_loc(const opencv_core_mat_handle *mat,
                            double *out_minimum, double *out_maximum,
                            int32_t *out_minimum_x, int32_t *out_minimum_y,
                            int32_t *out_maximum_x, int32_t *out_maximum_y) {
    clear_error();

    if (out_minimum == nullptr || out_maximum == nullptr ||
        out_minimum_x == nullptr || out_minimum_y == nullptr ||
        out_maximum_x == nullptr || out_maximum_y == nullptr) {
        return invalid_argument("Min/max output pointers must not be null");
    }

    *out_minimum = 0.0;
    *out_maximum = 0.0;
    *out_minimum_x = 0;
    *out_minimum_y = 0;
    *out_maximum_x = 0;
    *out_maximum_y = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (mat->value.empty()) {
            return invalid_argument("Mat must not be empty");
        }

        if (mat->value.depth() == CV_16F) {
            return invalid_argument("Mat depth Float16 is not supported");
        }

        double minimum = 0.0;
        double maximum = 0.0;
        cv::Point minimum_location;
        cv::Point maximum_location;
        cv::minMaxLoc(mat->value, &minimum, &maximum, &minimum_location,
                      &maximum_location);

        *out_minimum = minimum;
        *out_maximum = maximum;
        *out_minimum_x = static_cast<int32_t>(minimum_location.x);
        *out_minimum_y = static_cast<int32_t>(minimum_location.y);
        *out_maximum_x = static_cast<int32_t>(maximum_location.x);
        *out_maximum_y = static_cast<int32_t>(maximum_location.y);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_min_max_loc_masked(
    const opencv_core_mat_handle *mat, const opencv_core_mat_handle *mask,
    double *out_minimum, double *out_maximum, int32_t *out_minimum_x,
    int32_t *out_minimum_y, int32_t *out_maximum_x, int32_t *out_maximum_y) {
    clear_error();

    if (out_minimum == nullptr || out_maximum == nullptr ||
        out_minimum_x == nullptr || out_minimum_y == nullptr ||
        out_maximum_x == nullptr || out_maximum_y == nullptr) {
        return invalid_argument("Min/max output pointers must not be null");
    }

    *out_minimum = 0.0;
    *out_maximum = 0.0;
    *out_minimum_x = 0;
    *out_minimum_y = 0;
    *out_maximum_x = 0;
    *out_maximum_y = 0;

    if (mat == nullptr || mask == nullptr) {
        return invalid_argument("Mat and mask handles must not be null");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (mat->value.empty()) {
            return invalid_argument("Mat must not be empty");
        }

        if (mat->value.depth() == CV_16F) {
            return invalid_argument("Mat depth Float16 is not supported");
        }

        if (!is_valid_mask_for(mat->value, mask->value)) {
            return invalid_argument(
                "mask must be a same-sized single-channel UInt8 Mat");
        }

        double minimum = 0.0;
        double maximum = 0.0;
        cv::Point minimum_location;
        cv::Point maximum_location;
        cv::minMaxLoc(mat->value, &minimum, &maximum, &minimum_location,
                      &maximum_location, mask->value);

        *out_minimum = minimum;
        *out_maximum = maximum;
        *out_minimum_x = static_cast<int32_t>(minimum_location.x);
        *out_minimum_y = static_cast<int32_t>(minimum_location.y);
        *out_maximum_x = static_cast<int32_t>(maximum_location.x);
        *out_maximum_y = static_cast<int32_t>(maximum_location.y);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_count_non_zero(const opencv_core_mat_handle *mat,
                               int64_t *out_count) {
    clear_error();

    if (out_count == nullptr) {
        return invalid_argument("out_count must not be null");
    }

    *out_count = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        *out_count = static_cast<int64_t>(cv::countNonZero(mat->value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_has_non_zero(const opencv_core_mat_handle *mat,
                               uint8_t *out_result) {
    clear_error();

    if (out_result == nullptr) {
        return invalid_argument("out_result must not be null");
    }

    *out_result = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        *out_result = cv::hasNonZero(mat->value) ? 1 : 0;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_find_non_zero(const opencv_core_mat_handle *mat,
                              opencv_core_point *out_points,
                              int64_t capacity, int64_t *out_count) {
    clear_error();

    if (out_count == nullptr) {
        return invalid_argument("out_count must not be null");
    }

    *out_count = 0;

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (capacity < 0) {
        return invalid_argument("capacity must not be negative");
    }

    try {
        if (mat->value.dims != 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() != 1) {
            return invalid_argument("Mat must have exactly one channel");
        }

        if (mat->value.depth() == CV_16F) {
            return invalid_argument("Mat depth Float16 is not supported");
        }

        std::vector<cv::Point> locations;
        cv::findNonZero(mat->value, locations);

        if (locations.size() > static_cast<size_t>(INT64_MAX)) {
            return invalid_argument("nonzero point count exceeds int64 range");
        }

        const int64_t count = static_cast<int64_t>(locations.size());
        if (count > capacity) {
            return invalid_argument("point buffer capacity is insufficient");
        }

        if (count > 0 && out_points == nullptr) {
            return invalid_argument("out_points must not be null for nonempty Mat");
        }

        for (int64_t index = 0; index < count; ++index) {
            out_points[index].x = static_cast<int32_t>(locations[index].x);
            out_points[index].y = static_cast<int32_t>(locations[index].y);
        }

        *out_count = count;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_split(const opencv_core_mat_handle *source,
                      opencv_core_mat_handle **out_mats, int32_t count) {
    clear_error();

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (count < 0) {
        return invalid_argument("output count must not be negative");
    }

    if (count > 0 && out_mats == nullptr) {
        return invalid_argument("out_mats must not be null for nonempty output");
    }

    for (int32_t index = 0; index < count; ++index) {
        out_mats[index] = nullptr;
    }

    std::vector<std::unique_ptr<opencv_core_mat_handle>> handles;
    try {
        if (source->value.empty()) {
            if (count != 0) {
                return invalid_argument("empty source requires zero output count");
            }
            return OPENCV_CORE_OK;
        }

        if (count != source->value.channels()) {
            return invalid_argument("output count must equal source channel count");
        }

        std::vector<cv::Mat> channels;
        cv::split(source->value, channels);
        if (channels.size() != static_cast<size_t>(count)) {
            return invalid_argument("split returned an unexpected channel count");
        }

        handles.reserve(channels.size());
        for (const cv::Mat &channel : channels) {
            handles.push_back(
                std::make_unique<opencv_core_mat_handle>(channel));
        }

        for (int32_t index = 0; index < count; ++index) {
            out_mats[index] = handles[static_cast<size_t>(index)].release();
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_extract_channel(const opencv_core_mat_handle *source,
                                int32_t channel,
                                opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }
    *out_mat = nullptr;

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }
    if (channel < 0 || channel >= source->value.channels()) {
        return invalid_argument("channel index is outside the source channel range");
    }

    try {
        cv::Mat extracted;
        cv::extractChannel(source->value, extracted, channel);
        *out_mat = new opencv_core_mat_handle(extracted);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_insert_channel(const opencv_core_mat_handle *source,
                               opencv_core_mat_handle *destination,
                               int32_t channel) {
    clear_error();

    if (source == nullptr || destination == nullptr) {
        return invalid_argument(
            "source and destination Mat handles must not be null");
    }

    try {
        if (source->value.channels() != 1) {
            return invalid_argument("source Mat must have exactly one channel");
        }
        if (source->value.rows != destination->value.rows) {
            return invalid_argument(
                "source and destination Mats must have identical row counts");
        }
        if (source->value.cols != destination->value.cols) {
            return invalid_argument(
                "source and destination Mats must have identical column counts");
        }
        if (source->value.depth() != destination->value.depth()) {
            return invalid_argument(
                "source and destination Mats must have identical depths");
        }
        if (channel < 0 || channel >= destination->value.channels()) {
            return invalid_argument(
                "channel index is outside the destination channel range");
        }

        cv::insertChannel(source->value, destination->value, channel);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mix_channels(const opencv_core_mat_handle *const *sources,
                             int32_t source_count,
                             opencv_core_mat_handle *const *destinations,
                             int32_t destination_count,
                             const int32_t *from_to, int32_t pair_count) {
    clear_error();

    if (pair_count < 0 || source_count < 0 || destination_count < 0) {
        return invalid_argument("channel counts must not be negative");
    }
    if (pair_count == 0) {
        return OPENCV_CORE_OK;
    }
    if (sources == nullptr || destinations == nullptr || from_to == nullptr) {
        return invalid_argument("channel arrays must not be null for nonempty routes");
    }
    if (source_count == 0 || destination_count == 0) {
        return invalid_argument("source and destination counts must be positive");
    }

    try {
        std::vector<cv::Mat> source_mats;
        std::vector<cv::Mat> destination_mats;
        source_mats.reserve(static_cast<size_t>(source_count));
        destination_mats.reserve(static_cast<size_t>(destination_count));
        for (int32_t index = 0; index < source_count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            source_mats.push_back(sources[index]->value);
        }
        for (int32_t index = 0; index < destination_count; ++index) {
            if (destinations[index] == nullptr) {
                return invalid_argument("destination Mat handle must not be null");
            }
            destination_mats.push_back(destinations[index]->value);
        }
        cv::mixChannels(source_mats.data(), source_mats.size(),
                        destination_mats.data(), destination_mats.size(),
                        from_to, static_cast<size_t>(pair_count));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_merge(const opencv_core_mat_handle *const *sources,
                      int32_t count, opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }
    *out_mat = nullptr;

    if (sources == nullptr) {
        return invalid_argument("sources must not be null");
    }
    if (count <= 0) {
        return invalid_argument("input count must be positive");
    }

    try {
        std::vector<cv::Mat> inputs;
        inputs.reserve(static_cast<size_t>(count));
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            inputs.push_back(sources[index]->value);
        }

        cv::Mat merged;
        cv::merge(inputs, merged);
        *out_mat = new opencv_core_mat_handle(merged);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_check_range(const opencv_core_mat_handle *source,
                            uint8_t use_bounds, double minimum, double maximum,
                            uint8_t *out_valid, int32_t *out_x, int32_t *out_y) {
    clear_error();

    if (out_valid != nullptr) {
        *out_valid = UINT8_C(0);
    }
    if (out_x != nullptr) {
        *out_x = -1;
    }
    if (out_y != nullptr) {
        *out_y = -1;
    }

    if (out_valid == nullptr || out_x == nullptr || out_y == nullptr) {
        return invalid_argument("Check_Range output pointers must not be null");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    if (use_bounds != 0 && use_bounds != 1) {
        return invalid_argument("use_bounds must be 0 or 1");
    }

    try {
        if (source->value.dims > 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (source->value.depth() == CV_16F) {
            return invalid_argument("Mat depth Float16 is not supported");
        }

        const double effective_minimum =
            use_bounds != 0 ? minimum : -std::numeric_limits<double>::max();
        const double effective_maximum =
            use_bounds != 0 ? maximum : std::numeric_limits<double>::max();

        cv::Point first_invalid(-1, -1);
        const bool valid =
            cv::checkRange(source->value, true, &first_invalid,
                           effective_minimum, effective_maximum);

        *out_valid = valid ? UINT8_C(1) : UINT8_C(0);
        if (valid) {
            *out_x = -1;
            *out_y = -1;
        } else {
            *out_x = static_cast<int32_t>(first_invalid.x);
            *out_y = static_cast<int32_t>(first_invalid.y);
        }
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_patch_nans(opencv_core_mat_handle *mat, double value) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        cv::patchNaNs(mat->value, value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_complete_symmetry(opencv_core_mat_handle *mat,
                                  uint8_t source_triangle) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (source_triangle != 0 && source_triangle != 1) {
        return invalid_argument("source_triangle must be 0 or 1");
    }

    try {
        if (mat->value.dims > 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.rows != mat->value.cols) {
            return invalid_argument("complete symmetry requires a square Mat");
        }

        const int depth = mat->value.depth();
        if (depth != CV_32F && depth != CV_64F) {
            return invalid_argument(
                "complete symmetry requires a Float32 or Float64 Mat");
        }

        const bool lower_to_upper = source_triangle != 0;
        cv::completeSymm(mat->value, lower_to_upper);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_set_identity(opencv_core_mat_handle *mat,
                             const opencv_core_scalar *value) {
    clear_error();

    if (mat == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    if (value == nullptr) {
        return invalid_argument("Scalar value must not be null");
    }

    try {
        if (mat->value.dims > 2) {
            return invalid_argument("Mat must be two-dimensional");
        }

        if (mat->value.channels() > 4) {
            return invalid_argument(
                "set identity supports at most four channels");
        }

        if (mat->value.empty()) {
            return OPENCV_CORE_OK;
        }

        cv::setIdentity(mat->value, to_opencv_scalar(*value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

} // extern "C"
