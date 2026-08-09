#include "opencv_core_shim.h"

#include <opencv2/core.hpp>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <exception>
#include <limits>
#include <new>

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

bool mats_have_same_shape_and_type(const cv::Mat &left,
                                   const cv::Mat &right) noexcept {
    return left.dims == right.dims && left.rows == right.rows &&
           left.cols == right.cols && left.type() == right.type();
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

} // extern "C"
