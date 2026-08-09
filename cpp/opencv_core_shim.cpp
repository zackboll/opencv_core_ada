#include "opencv_core_shim.h"

#include <opencv2/core.hpp>

#include <cstdio>
#include <exception>
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

} // extern "C"
