#include "opencv_core_shim.h"

#include <opencv2/core.hpp>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <exception>
#include <limits>
#include <memory>
#include <new>
#include <vector>
#include <string>

struct opencv_core_mat_handle {
    cv::Mat value;

    opencv_core_mat_handle() = default;

    explicit opencv_core_mat_handle(const cv::Mat &source)
        : value(source) {}
};

enum class opencv_core_file_storage_structure_kind { map, sequence };

struct opencv_core_file_storage_handle {
    cv::FileStorage value;
    // ABI/lifetime safety: OpenCV 4.10 memory-read sets
    // strbuf = (char *)filename_or_buf and measures it with strlen()
    // while parsing. Keep an owned copy so a temporary Ada C-string
    // cannot dangle during open() or any later access.
    std::string memory_source;
    std::string released_memory_text;
    bool memory_backed = false;
    bool write_mode = false;
    bool released_memory_text_ready = false;
    std::vector<opencv_core_file_storage_structure_kind> write_structure_stack;
    // Declared after value so FileNode copies are destroyed before the
    // FileStorage implementation they reference.
    std::vector<cv::FileNode> read_context_stack;
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

bool int32_sum_exceeds_max(int32_t left, int32_t right) noexcept {
    return left >= 0 && right >= 0 &&
           left > std::numeric_limits<int32_t>::max() - right;
}

bool int32_product_exceeds_max(int32_t left, int32_t right) noexcept {
    return left > 0 && right > 0 &&
           left > std::numeric_limits<int32_t>::max() / right;
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

    // ABI safety: this helper forms a typed row pointer and copies
    // element_count * sizeof(T) bytes. Depth, channel, dimension, and
    // bounds errors would cause out-of-bounds access here.
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

    // ABI safety: this helper forms a typed Vec3 row pointer and copies
    // element_count * 3 scalars. Depth, channel, dimension, and bounds
    // errors would cause out-of-bounds access here.
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

// ABI safety: Mat::at<T> relies on CV_DbgAssert for type/dimension/
// bounds validation and then performs typed pointer access. Release
// OpenCV builds cannot be relied upon to reject a raw ABI caller safely.
opencv_core_status validate_typed_at(const cv::Mat &mat, int32_t row,
                                     int32_t column, int expected_depth,
                                     int expected_channels,
                                     const char *depth_message,
                                     const char *channel_message) {
    if (row < 0 || column < 0) {
        return invalid_argument("row and column must not be negative");
    }

    if (mat.dims != 2) {
        return invalid_argument("Mat must be two-dimensional");
    }

    if (mat.depth() != expected_depth) {
        return invalid_argument(depth_message);
    }

    if (mat.channels() != expected_channels) {
        return invalid_argument(channel_message);
    }

    if (row >= mat.rows || column >= mat.cols) {
        return invalid_argument("row or column is outside Mat bounds");
    }

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

bool to_opencv_file_storage_mode(int32_t mode, int &opencv_mode) noexcept {
    switch (mode) {
    case OPENCV_CORE_FILE_STORAGE_READ_ONLY:
        opencv_mode = cv::FileStorage::READ;
        return true;
    case OPENCV_CORE_FILE_STORAGE_WRITE_ONLY:
        opencv_mode = cv::FileStorage::WRITE;
        return true;
    default:
        return false;
    }
}

bool to_opencv_file_storage_format(int32_t format,
                                   int &opencv_format) noexcept {
    switch (format) {
    case OPENCV_CORE_FILE_STORAGE_FORMAT_XML:
        opencv_format = cv::FileStorage::FORMAT_XML;
        return true;
    case OPENCV_CORE_FILE_STORAGE_FORMAT_YAML:
        opencv_format = cv::FileStorage::FORMAT_YAML;
        return true;
    case OPENCV_CORE_FILE_STORAGE_FORMAT_JSON:
        opencv_format = cv::FileStorage::FORMAT_JSON;
        return true;
    default:
        return false;
    }
}

bool to_file_storage_structure_kind(
    int32_t kind, opencv_core_file_storage_structure_kind &decoded) noexcept {
    switch (kind) {
    case OPENCV_CORE_FILE_STORAGE_STRUCTURE_MAP:
        decoded = opencv_core_file_storage_structure_kind::map;
        return true;
    case OPENCV_CORE_FILE_STORAGE_STRUCTURE_SEQUENCE:
        decoded = opencv_core_file_storage_structure_kind::sequence;
        return true;
    default:
        return false;
    }
}

int to_opencv_file_node_flags(
    opencv_core_file_storage_structure_kind kind) noexcept {
    switch (kind) {
    case opencv_core_file_storage_structure_kind::map:
        return cv::FileNode::MAP;
    case opencv_core_file_storage_structure_kind::sequence:
        return cv::FileNode::SEQ;
    }

    return cv::FileNode::NONE;
}

bool write_context_is_sequence(
    const opencv_core_file_storage_handle &storage) noexcept {
    return !storage.write_structure_stack.empty() &&
           storage.write_structure_stack.back() ==
               opencv_core_file_storage_structure_kind::sequence;
}

opencv_core_status require_write_name_for_context(
    const opencv_core_file_storage_handle &storage, const char *name) {
    const bool unnamed = name[0] == '\0';
    if (write_context_is_sequence(storage)) {
        if (!unnamed) {
            return invalid_argument(
                "named write is not valid inside a sequence");
        }
    } else if (unnamed) {
        return invalid_argument(
            "unnamed write is not valid outside a sequence");
    }

    return OPENCV_CORE_OK;
}

cv::FileNode current_read_context(
    const opencv_core_file_storage_handle &storage) {
    if (storage.read_context_stack.empty()) {
        return cv::FileNode();
    }

    return storage.read_context_stack.back();
}

opencv_core_status lookup_named_node(
    const opencv_core_file_storage_handle &storage, const char *name,
    cv::FileNode &node) {
    node = cv::FileNode();

    if (storage.read_context_stack.empty()) {
        node = storage.value[name];
    } else {
        const cv::FileNode &context = storage.read_context_stack.back();
        if (!context.isMap()) {
            return invalid_argument(
                "named lookup requires a mapping read context");
        }

        node = context[name];
    }

    if (node.empty()) {
        return invalid_argument("named file node is missing");
    }

    return OPENCV_CORE_OK;
}

opencv_core_status lookup_indexed_node(
    const opencv_core_file_storage_handle &storage, uint64_t index,
    cv::FileNode &node) {
    node = cv::FileNode();

    if (storage.read_context_stack.empty()) {
        return invalid_argument(
            "indexed lookup is not valid at the file storage root");
    }

    const cv::FileNode &context = storage.read_context_stack.back();
    if (!context.isSeq()) {
        return invalid_argument(
            "indexed lookup requires a sequence read context");
    }

    const size_t length = context.size();
    if (index >= static_cast<uint64_t>(length)) {
        return invalid_argument("sequence index is out of range");
    }

    // ABI safety: FileNode::operator[](int) takes a signed int. Reject
    // values that cannot convert without implementation-defined narrowing
    // before the shim performs that conversion.
    if (index > static_cast<uint64_t>(std::numeric_limits<int>::max())) {
        return invalid_argument("sequence index exceeds OpenCV int range");
    }

    node = context[static_cast<int>(index)];
    if (node.empty()) {
        return invalid_argument("indexed file node is missing");
    }

    return OPENCV_CORE_OK;
}

opencv_core_status copy_file_node_string(const cv::FileNode &node,
                                         char *buffer, uint64_t capacity,
                                         uint64_t *out_length) {
    if (!node.isString()) {
        return invalid_argument("file node is not a string");
    }

    const std::string value = node.string();
    uint64_t length = 0;
    if (!size_to_abi(value.size(), length)) {
        return invalid_argument("stored string exceeds the ABI size range");
    }

    if (buffer == nullptr) {
        *out_length = length;
        return OPENCV_CORE_OK;
    }

    if (capacity < length) {
        return invalid_argument(
            "string buffer capacity is smaller than the stored value");
    }

    if (!value.empty()) {
        std::memcpy(buffer, value.data(), value.size());
    }

    *out_length = length;
    return OPENCV_CORE_OK;
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

    // ABI safety: CV_MAKETYPE encodes (channels-1) into a bit field. Values
    // outside 1 .. CV_CN_MAX produce a wrapped or truncated type before
    // OpenCV sees the request.
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
        // ABI safety: OpenCV forms destination dimensions using signed int
        // additions before allocation. Reject combinations exceeding INT_MAX.
        if (top >= 0 && bottom >= 0 &&
            (int32_sum_exceeds_max(top, bottom) ||
             int32_sum_exceeds_max(source->value.rows, top + bottom))) {
            return invalid_argument(
                "bordered row count would exceed the signed 32-bit range");
        }
        if (left >= 0 && right >= 0 &&
            (int32_sum_exceeds_max(left, right) ||
             int32_sum_exceeds_max(source->value.cols, left + right))) {
            return invalid_argument(
                "bordered column count would exceed the signed 32-bit range");
        }
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

    try {
        // ABI safety: OpenCV computes repeated dimensions using signed int
        // multiplication before destination creation. Reject values whose
        // products would exceed INT_MAX and otherwise risk signed overflow.
        if (int32_product_exceeds_max(source->value.rows, row_repetitions) ||
            int32_product_exceeds_max(source->value.cols,
                                      column_repetitions)) {
            return invalid_argument(
                "repeated dimensions would exceed the signed 32-bit range");
        }
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
        int32_t total_columns = 0;
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            const int32_t columns = sources[index]->value.cols;
            // ABI safety: OpenCV accumulates concatenated columns in signed int.
            // Reject a total that would exceed INT_MAX before OpenCV performs
            // the addition.
            if (columns >= 0 && int32_sum_exceeds_max(total_columns, columns)) {
                return invalid_argument(
                    "concatenated column count would exceed the signed 32-bit range");
            }
            if (columns >= 0) {
                total_columns += columns;
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
        int32_t total_rows = 0;
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            const int32_t rows = sources[index]->value.rows;
            // ABI safety: OpenCV accumulates concatenated rows in signed int.
            // Reject a total that would exceed INT_MAX before OpenCV performs
            // the addition.
            if (rows >= 0 && int32_sum_exceeds_max(total_rows, rows)) {
                return invalid_argument(
                    "concatenated row count would exceed the signed 32-bit range");
            }
            if (rows >= 0) {
                total_rows += rows;
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
        cv::Mat result;
        cv::inRange(source->value, to_opencv_scalar(*lower),
                    to_opencv_scalar(*upper), result);
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

    try {
        cv::Mat result;
        cv::compare(left->value, right->value, result, opencv_compare_kind);
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

    try {
        // ABI safety: OpenCV's Rect Mat constructor adjusts the data pointer
        // using roi.x/roi.y before its complete ROI bounds assertion. Validate
        // the origin here so a raw ABI caller cannot form an invalid pointer.
        if (source->value.dims != 2) {
            return invalid_argument("source Mat must be two-dimensional");
        }

        if (x < 0 || y < 0 || x >= source->value.cols ||
            y >= source->value.rows) {
            return invalid_argument("region origin is outside source Mat bounds");
        }

        // ABI safety: OpenCV evaluates roi.x + roi.width and
        // roi.y + roi.height as signed int during ROI validation.
        // Reject combinations that would overflow before its assertion.
        if (width >= 0 && int32_sum_exceeds_max(x, width)) {
            return invalid_argument(
                "region x + width would exceed the signed 32-bit range");
        }
        if (height >= 0 && int32_sum_exceeds_max(y, height)) {
            return invalid_argument(
                "region y + height would exceed the signed 32-bit range");
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

    try {
        // ABI safety: OpenCV Mat::row constructs Range(y, y + 1). y == INT_MAX
        // overflows signed int before OpenCV's Range assertion.
        if (row == std::numeric_limits<int32_t>::max()) {
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

    try {
        // ABI safety: OpenCV Mat::col constructs Range(x, x + 1). x == INT_MAX
        // overflows signed int before OpenCV's Range assertion.
        if (column == std::numeric_limits<int32_t>::max()) {
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

    try {
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

    try {
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

    // ABI safety: reshape writes (channels-1) into the Mat channel bit field.
    // Values outside 1 .. CV_CN_MAX would wrap that encoding before OpenCV
    // reports an unsupported reshape.
    if (channels < 1 || channels > OPENCV_CORE_MAX_CHANNELS) {
        return invalid_argument("channels must be in the range 1 .. 512");
    }

    try {
        const cv::Mat &source_mat = source->value;
        const int32_t source_channels = source_mat.channels();

        // ABI safety: OpenCV 4.10 computes cols * channels as signed int
        // before validating the reshape. Reject values that would overflow.
        if (int32_product_exceeds_max(source_mat.cols, source_channels)) {
            return invalid_argument(
                "reshape column-channel product would exceed the signed 32-bit range");
        }

        const int32_t total_width = source_mat.cols * source_channels;
        const bool derive_rows =
            rows == 0 && (channels > total_width || total_width % channels != 0);
        const bool change_rows = rows != 0 && rows != source_mat.rows;

        // ABI safety: OpenCV 4.10 then computes rows * total_width as signed
        // int on the derive-rows and change-rows paths before diagnosing the
        // request. Reject values that would overflow those intermediates.
        if ((derive_rows || change_rows) &&
            int32_product_exceeds_max(source_mat.rows, total_width)) {
            return invalid_argument(
                "reshape row-channel product would exceed the signed 32-bit range");
        }

        *out_mat = new opencv_core_mat_handle(
            source_mat.reshape(static_cast<int>(channels),
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
        // ABI safety: OpenCV computes rows + cols - 1 using signed int after
        // validating that the source is a row or column vector. Protect the
        // intermediate addition from overflow for raw ABI callers.
        if (int32_sum_exceeds_max(diagonal->value.rows, diagonal->value.cols)) {
            return invalid_argument(
                "diagonal length would exceed the signed 32-bit range");
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
        // ABI safety: OpenCV 4.10 Mat::diag(offset) constructs a view from
        // rows/cols without a safe empty/out-of-range rejection before
        // forming that header.
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_8U, 1,
                              "Mat depth must be UInt8",
                              "Mat must have exactly one channel");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_8U, 1,
                              "Mat depth must be UInt8",
                              "Mat must have exactly one channel");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_32F, 1,
                              "Mat depth must be Float32",
                              "Mat must have exactly one channel");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_32F, 1,
                              "Mat depth must be Float32",
                              "Mat must have exactly one channel");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_32F, 1,
                              "Mat depth must be Float32",
                              "Mat must have exactly one channel");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_8U, 3,
                              "Mat depth must be UInt8",
                              "Mat must have exactly three channels");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_8U, 3,
                              "Mat depth must be UInt8",
                              "Mat must have exactly three channels");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_32F, 3,
                              "Mat depth must be Float32",
                              "Mat must have exactly three channels");
        if (status != OPENCV_CORE_OK) {
            return status;
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

    try {
        const opencv_core_status status =
            validate_typed_at(mat->value, row, column, CV_32F, 3,
                              "Mat depth must be Float32",
                              "Mat must have exactly three channels");
        if (status != OPENCV_CORE_OK) {
            return status;
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
opencv_core_mat_dot_product(const opencv_core_mat_handle *left,
                            const opencv_core_mat_handle *right,
                            double *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0.0;
    }

    if (left == nullptr || right == nullptr || out_value == nullptr) {
        return invalid_argument("dot product requires non-null handles and output");
    }

    try {
        *out_value = left->value.dot(right->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_mahalanobis_distance(
    const opencv_core_mat_handle *left,
    const opencv_core_mat_handle *right,
    const opencv_core_mat_handle *inverse_covariance,
    double *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0.0;
    }

    if (left == nullptr || right == nullptr ||
        inverse_covariance == nullptr || out_value == nullptr) {
        return invalid_argument(
            "Mahalanobis distance requires non-null handles and output");
    }

    try {
        *out_value = cv::Mahalanobis(left->value, right->value,
                                     inverse_covariance->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_cross_product(const opencv_core_mat_handle *left,
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

        // ABI safety: OpenCV 4.10 Mat::cross writes only three CV_32F or
        // CV_64F scalars. Other depths that pass its shape assertion leave
        // the allocated result uninitialized.
        if (A.depth() != CV_32F && A.depth() != CV_64F) {
            return invalid_argument(
                "cross product requires Float32 or Float64 vectors");
        }

        // ABI safety: OpenCV 4.10 Mat::cross accepts rows == 3 && cols == 1
        // without constraining channels, then writes only three scalars into
        // a same-type result. Extra channels in a 3x1 multi-channel Mat
        // would remain uninitialized.
        if (A.rows == 3 && A.cols == 1 && A.channels() != 1) {
            return invalid_argument(
                "cross product of a 3x1 Mat requires a single channel");
        }

        cv::Mat product = A.cross(B);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(product));
        *out_mat = result_handle.release();
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
        cv::Mat solution;
        const bool solved = cv::solve(coefficients->value,
                                      right_hand_side->value, solution,
                                      cv::DECOMP_LU);

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
        cv::Mat result;
        cv::gemm(left->value, right->value, 1.0, cv::noArray(), 0.0, result, 0);

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
        cv::Mat result;
        cv::gemm(left->value, right->value, product_scale, addend->value,
                 addend_scale, result, 0);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_transposed_product(const opencv_core_mat_handle *source,
                                   uint8_t order, double scale,
                                   int32_t output_depth,
                                   opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        bool a_t_a;
        switch (order) {
        case OPENCV_CORE_TRANSPOSED_PRODUCT_TRANSPOSE_TIMES_SELF:
            a_t_a = true;
            break;
        case OPENCV_CORE_TRANSPOSED_PRODUCT_SELF_TIMES_TRANSPOSE:
            a_t_a = false;
            break;
        default:
            return invalid_argument(
                "transposed product order is not a supported identifier");
        }

        int requested_dtype = -1;
        if (output_depth != OPENCV_CORE_DEFAULT_OUTPUT_DEPTH &&
            !to_opencv_depth(output_depth, requested_dtype)) {
            return invalid_argument(
                "output depth is not a supported depth identifier");
        }

        cv::Mat result;
        cv::mulTransposed(source->value, result, a_t_a, cv::noArray(), scale,
                          requested_dtype);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_transposed_product_with_delta(
    const opencv_core_mat_handle *source, const opencv_core_mat_handle *delta,
    uint8_t order, double scale, int32_t output_depth,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr || delta == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        bool a_t_a;
        switch (order) {
        case OPENCV_CORE_TRANSPOSED_PRODUCT_TRANSPOSE_TIMES_SELF:
            a_t_a = true;
            break;
        case OPENCV_CORE_TRANSPOSED_PRODUCT_SELF_TIMES_TRANSPOSE:
            a_t_a = false;
            break;
        default:
            return invalid_argument(
                "transposed product order is not a supported identifier");
        }

        int requested_dtype = -1;
        if (output_depth != OPENCV_CORE_DEFAULT_OUTPUT_DEPTH &&
            !to_opencv_depth(output_depth, requested_dtype)) {
            return invalid_argument(
                "output depth is not a supported depth identifier");
        }

        cv::Mat result;
        cv::mulTransposed(source->value, result, a_t_a, delta->value, scale,
                          requested_dtype);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_covariance(const opencv_core_mat_handle *source,
                           int32_t orientation, int32_t scaling,
                           opencv_core_mat_handle **out_covariance,
                           opencv_core_mat_handle **out_mean) {
    clear_error();

    if (out_covariance != nullptr) {
        *out_covariance = nullptr;
    }
    if (out_mean != nullptr) {
        *out_mean = nullptr;
    }

    if (out_covariance == nullptr || out_mean == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_covariance == out_mean) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int flags = cv::COVAR_NORMAL;
    switch (orientation) {
    case OPENCV_CORE_SAMPLE_ORIENTATION_ROWS:
        flags |= cv::COVAR_ROWS;
        break;
    case OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS:
        flags |= cv::COVAR_COLS;
        break;
    default:
        return invalid_argument(
            "sample orientation is not a supported identifier");
    }

    switch (scaling) {
    case OPENCV_CORE_COVARIANCE_SCALING_UNSCALED:
        break;
    case OPENCV_CORE_COVARIANCE_SCALING_BY_SAMPLE_COUNT:
        flags |= cv::COVAR_SCALE;
        break;
    default:
        return invalid_argument(
            "covariance scaling is not a supported identifier");
    }

    try {
        cv::Mat covariance;
        cv::Mat mean;
        const int ctype = source->value.depth();
        cv::calcCovarMatrix(source->value, covariance, mean, flags, ctype);

        std::unique_ptr<opencv_core_mat_handle> covariance_handle(
            new opencv_core_mat_handle(covariance));
        std::unique_ptr<opencv_core_mat_handle> mean_handle(
            new opencv_core_mat_handle(mean));

        *out_covariance = covariance_handle.release();
        *out_mean = mean_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_eigen_decomposition(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors) {
    clear_error();

    if (out_eigenvalues != nullptr) {
        *out_eigenvalues = nullptr;
    }
    if (out_eigenvectors != nullptr) {
        *out_eigenvectors = nullptr;
    }

    if (out_eigenvalues == nullptr || out_eigenvectors == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_eigenvalues == out_eigenvectors) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        // ABI safety: OpenCV 4.10's non-Eigen Jacobi backend computes
        // maxIters = n*n*30 using signed int. Reject dimensions that would
        // overflow before the backend can safely complete or fail.
        // 8460 is the largest n such that n*n*30 still fits in INT_MAX.
        if (source->value.rows > 8460) {
            return invalid_argument(
                "eigen source dimension would overflow OpenCV 4.10 Jacobi maxIters");
        }

        cv::Mat eigenvalues;
        cv::Mat eigenvectors;
        const bool ok = cv::eigen(source->value, eigenvalues, eigenvectors);
        if (!ok) {
            set_error("eigen decomposition did not succeed");
            return OPENCV_CORE_ERROR_OPENCV;
        }

        std::unique_ptr<opencv_core_mat_handle> eigenvalues_handle(
            new opencv_core_mat_handle(eigenvalues));
        std::unique_ptr<opencv_core_mat_handle> eigenvectors_handle(
            new opencv_core_mat_handle(eigenvectors));

        *out_eigenvalues = eigenvalues_handle.release();
        *out_eigenvectors = eigenvectors_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_principal_component_analysis(
    const opencv_core_mat_handle *source, int32_t orientation,
    int32_t max_components, opencv_core_mat_handle **out_mean,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors) {
    clear_error();

    if (out_mean != nullptr) {
        *out_mean = nullptr;
    }
    if (out_eigenvalues != nullptr) {
        *out_eigenvalues = nullptr;
    }
    if (out_eigenvectors != nullptr) {
        *out_eigenvectors = nullptr;
    }

    if (out_mean == nullptr || out_eigenvalues == nullptr ||
        out_eigenvectors == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_mean == out_eigenvalues || out_mean == out_eigenvectors ||
        out_eigenvalues == out_eigenvectors) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int flags = 0;
    int sample_count = 0;
    int feature_count = 0;
    switch (orientation) {
    case OPENCV_CORE_SAMPLE_ORIENTATION_ROWS:
        flags = cv::PCA::DATA_AS_ROW;
        sample_count = source->value.rows;
        feature_count = source->value.cols;
        break;
    case OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS:
        flags = cv::PCA::DATA_AS_COL;
        sample_count = source->value.cols;
        feature_count = source->value.rows;
        break;
    default:
        return invalid_argument(
            "sample orientation is not a supported identifier");
    }

    if (max_components < 0) {
        return invalid_argument("max_components must not be negative");
    }

    try {
        // ABI safety: OpenCV 4.10 PCA calls cv::eigen on a
        // min(sample_count, feature_count)-square covariance matrix. The
        // non-Eigen Jacobi backend computes maxIters = n*n*30 using signed
        // int, so reject dimensions above 8460 before that overflow occurs.
        const int available_components =
            std::min(sample_count, feature_count);
        if (available_components > 8460) {
            return invalid_argument(
                "PCA component-space dimension would overflow OpenCV 4.10 "
                "Jacobi maxIters");
        }

        cv::PCA pca;
        pca(source->value, cv::Mat(), flags, max_components);

        std::unique_ptr<opencv_core_mat_handle> mean_handle(
            new opencv_core_mat_handle(pca.mean));
        std::unique_ptr<opencv_core_mat_handle> eigenvalues_handle(
            new opencv_core_mat_handle(pca.eigenvalues));
        std::unique_ptr<opencv_core_mat_handle> eigenvectors_handle(
            new opencv_core_mat_handle(pca.eigenvectors));

        *out_mean = mean_handle.release();
        *out_eigenvalues = eigenvalues_handle.release();
        *out_eigenvectors = eigenvectors_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_principal_component_analysis_retained_variance(
    const opencv_core_mat_handle *source, int32_t orientation,
    double retained_variance, opencv_core_mat_handle **out_mean,
    opencv_core_mat_handle **out_eigenvalues,
    opencv_core_mat_handle **out_eigenvectors) {
    clear_error();

    if (out_mean != nullptr) {
        *out_mean = nullptr;
    }
    if (out_eigenvalues != nullptr) {
        *out_eigenvalues = nullptr;
    }
    if (out_eigenvectors != nullptr) {
        *out_eigenvectors = nullptr;
    }

    if (out_mean == nullptr || out_eigenvalues == nullptr ||
        out_eigenvectors == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_mean == out_eigenvalues || out_mean == out_eigenvectors ||
        out_eigenvalues == out_eigenvectors) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    int flags = 0;
    int sample_count = 0;
    int feature_count = 0;
    switch (orientation) {
    case OPENCV_CORE_SAMPLE_ORIENTATION_ROWS:
        flags = cv::PCA::DATA_AS_ROW;
        sample_count = source->value.rows;
        feature_count = source->value.cols;
        break;
    case OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS:
        flags = cv::PCA::DATA_AS_COL;
        sample_count = source->value.cols;
        feature_count = source->value.rows;
        break;
    default:
        return invalid_argument(
            "sample orientation is not a supported identifier");
    }

    try {
        // ABI safety: OpenCV 4.10 PCA calls cv::eigen on a
        // min(sample_count, feature_count)-square covariance matrix. The
        // non-Eigen Jacobi backend computes maxIters = n*n*30 using signed
        // int, so reject dimensions above 8460 before that overflow occurs.
        const int available_components =
            std::min(sample_count, feature_count);
        if (available_components > 8460) {
            return invalid_argument(
                "PCA component-space dimension would overflow OpenCV 4.10 "
                "Jacobi maxIters");
        }

        // retained_variance is already double so this selects
        // PCA::operator()(..., double retainedVariance), not the
        // integer maxComponents overload.
        cv::PCA pca;
        pca(source->value, cv::Mat(), flags, retained_variance);

        std::unique_ptr<opencv_core_mat_handle> mean_handle(
            new opencv_core_mat_handle(pca.mean));
        std::unique_ptr<opencv_core_mat_handle> eigenvalues_handle(
            new opencv_core_mat_handle(pca.eigenvalues));
        std::unique_ptr<opencv_core_mat_handle> eigenvectors_handle(
            new opencv_core_mat_handle(pca.eigenvectors));

        *out_mean = mean_handle.release();
        *out_eigenvalues = eigenvalues_handle.release();
        *out_eigenvectors = eigenvectors_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_pca_project(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *mean,
    const opencv_core_mat_handle *eigenvectors, int32_t orientation,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr || mean == nullptr || eigenvectors == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    switch (orientation) {
    case OPENCV_CORE_SAMPLE_ORIENTATION_ROWS:
    case OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS:
        break;
    default:
        return invalid_argument(
            "sample orientation is not a supported identifier");
    }

    try {
        cv::PCA pca;
        cv::Mat result;
        if (orientation == OPENCV_CORE_SAMPLE_ORIENTATION_ROWS) {
            pca.mean = mean->value;
            pca.eigenvectors = eigenvectors->value;
            result = pca.project(source->value);
        } else {
            // OpenCV 4.10 PCA::project chooses its multiplication
            // branch with mean.rows == 1. A one-feature column mean
            // is 1x1, so native inference is ambiguous. Transpose the
            // column layout into the row-oriented path instead.
            pca.mean = mean->value.t();
            pca.eigenvectors = eigenvectors->value;
            result = pca.project(source->value.t()).t();
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
opencv_core_mat_pca_back_project(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *mean,
    const opencv_core_mat_handle *eigenvectors, int32_t orientation,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr || mean == nullptr || eigenvectors == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    switch (orientation) {
    case OPENCV_CORE_SAMPLE_ORIENTATION_ROWS:
    case OPENCV_CORE_SAMPLE_ORIENTATION_COLUMNS:
        break;
    default:
        return invalid_argument(
            "sample orientation is not a supported identifier");
    }

    try {
        cv::PCA pca;
        cv::Mat result;
        if (orientation == OPENCV_CORE_SAMPLE_ORIENTATION_ROWS) {
            pca.mean = mean->value;
            pca.eigenvectors = eigenvectors->value;
            result = pca.backProject(source->value);
        } else {
            // OpenCV 4.10 PCA::backProject also branches on
            // mean.rows == 1, so a 1x1 column mean is ambiguous.
            // Transpose into the row-oriented path instead.
            pca.mean = mean->value.t();
            pca.eigenvectors = eigenvectors->value;
            result = pca.backProject(source->value.t()).t();
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
opencv_core_mat_singular_value_decomposition(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_singular_values,
    opencv_core_mat_handle **out_u,
    opencv_core_mat_handle **out_v_transpose) {
    clear_error();

    if (out_singular_values != nullptr) {
        *out_singular_values = nullptr;
    }
    if (out_u != nullptr) {
        *out_u = nullptr;
    }
    if (out_v_transpose != nullptr) {
        *out_v_transpose = nullptr;
    }

    if (out_singular_values == nullptr || out_u == nullptr ||
        out_v_transpose == nullptr) {
        return invalid_argument("output Mat handles must not be null");
    }

    if (out_singular_values == out_u ||
        out_singular_values == out_v_transpose ||
        out_u == out_v_transpose) {
        return invalid_argument("output Mat handle pointers must be distinct");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat singular_values;
        cv::Mat u;
        cv::Mat v_transpose;
        cv::SVD::compute(source->value, singular_values, u, v_transpose, 0);

        std::unique_ptr<opencv_core_mat_handle> singular_values_handle(
            new opencv_core_mat_handle(singular_values));
        std::unique_ptr<opencv_core_mat_handle> u_handle(
            new opencv_core_mat_handle(u));
        std::unique_ptr<opencv_core_mat_handle> v_transpose_handle(
            new opencv_core_mat_handle(v_transpose));

        *out_singular_values = singular_values_handle.release();
        *out_u = u_handle.release();
        *out_v_transpose = v_transpose_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_svd_back_substitute(
    const opencv_core_mat_handle *singular_values,
    const opencv_core_mat_handle *u,
    const opencv_core_mat_handle *v_transpose,
    const opencv_core_mat_handle *right_hand_side,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (singular_values == nullptr || u == nullptr ||
        v_transpose == nullptr || right_hand_side == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    const cv::Mat &w = singular_values->value;
    const cv::Mat &left = u->value;
    const cv::Mat &vt = v_transpose->value;
    const cv::Mat &rhs = right_hand_side->value;

    // ABI safety: OpenCV 4.10 SVBkSbImpl_ zeros the destination with
    // x[i * ldx + j] using signed int index arithmetic. The wrapper
    // destination is newly allocated and packed, so ldx equals the
    // RHS column count K. Valid Mat dimensions are each at most
    // INT_MAX, but N * K can still overflow int before OpenCV writes
    // the solution.
    if (vt.cols > 0 && rhs.cols > 0 &&
        int32_product_exceeds_max(vt.cols, rhs.cols)) {
        return invalid_argument(
            "SVD back substitution destination index N * K exceeds INT_MAX");
    }

    const size_t elem_size = left.elemSize();
    const size_t u_ld =
        elem_size == 0 ? 0 : left.step / elem_size;
    // ABI safety: OpenCV 4.10 SVBkSbImpl_ indexes left singular
    // vectors as u[j * udelta1]. For compact U (uT = false), udelta1
    // is (int)(u.step / sizeof(element)). A packed U row has stride
    // R, and a Region can have a still-larger parent stride, so
    // U.rows * that stride can overflow int.
    if (u_ld > static_cast<size_t>(std::numeric_limits<int32_t>::max()) ||
        (left.rows > 0 && u_ld > 0 &&
         int32_product_exceeds_max(left.rows, static_cast<int32_t>(u_ld)))) {
        return invalid_argument(
            "SVD back substitution U index exceeds INT_MAX");
    }

    const size_t w_elem_size = w.elemSize();
    const size_t w_inc =
        w.rows == 1
            ? 1
            : (w_elem_size == 0 ? 0 : w.step / w_elem_size);
    const int32_t nm = left.rows < vt.cols ? left.rows : vt.cols;
    // ABI safety: OpenCV 4.10 SVBkSbImpl_ reads singular values as
    // w[i * incw]. A compact packed column has incw = 1, but a
    // Region can inherit a parent row stride whose product with R
    // overflows int.
    if (w_inc > static_cast<size_t>(std::numeric_limits<int32_t>::max()) ||
        (nm > 0 && w_inc > 0 &&
         int32_product_exceeds_max(nm, static_cast<int32_t>(w_inc)))) {
        return invalid_argument(
            "SVD back substitution W index exceeds INT_MAX");
    }

    const size_t rhs_element_size = rhs.elemSize();
    const size_t rhs_ld =
        rhs_element_size == 0 ? 0 : rhs.step / rhs_element_size;
    // ABI safety: OpenCV 4.10 SVBkSb converts bstep / sizeof(T) from
    // size_t to int ldb. A non-contiguous Region can inherit a parent
    // row stride larger than INT_MAX even when logical Rows/Columns
    // are individually valid. For a single-column RHS, SVBkSbImpl_
    // then evaluates b[j * ldb] with signed int multiplication, so
    // M * rhs_ld must also fit int. Multi-column RHS uses MatrAXPY,
    // which advances the RHS pointer incrementally by ldb rather than
    // forming that product.
    if (rhs_ld > static_cast<size_t>(std::numeric_limits<int32_t>::max()) ||
        (rhs.cols == 1 && left.rows > 0 && rhs_ld > 0 &&
         int32_product_exceeds_max(left.rows,
                                   static_cast<int32_t>(rhs_ld)))) {
        return invalid_argument(
            "SVD back substitution RHS index exceeds INT_MAX");
    }

    const size_t vt_element_size = vt.elemSize();
    const size_t vt_ld =
        vt_element_size == 0 ? 0 : vt.step / vt_element_size;
    // ABI safety: OpenCV 4.10 SVBkSb converts vstep / sizeof(T) from
    // size_t to int ldv. This API calls SVBkSb with vT = true, so
    // vdelta0 = ldv and the outer loop advances the V pointer by that
    // converted stride. An inherited Region stride can exceed INT_MAX
    // even when the logical V_Transpose dimensions are individually
    // valid. The loop does not form a signed R * ldv product.
    if (vt_ld > static_cast<size_t>(std::numeric_limits<int32_t>::max())) {
        return invalid_argument(
            "SVD back substitution V_Transpose stride exceeds INT_MAX");
    }

    try {
        cv::Mat result;
        cv::SVD::backSubst(w, left, vt, rhs, result);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_pseudo_inverse(
    const opencv_core_mat_handle *source,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    const cv::Mat &src = source->value;
    // ABI safety: OpenCV 4.10 empty-RHS SVD::backSubst creates an
    // N x M packed destination and zeros it with x[i * ldx + j]
    // using signed int index arithmetic and ldx = M. That product
    // is N * M. Compact U is later indexed as u[j * udelta1] with
    // udelta1 = R = min(M, N), so M * R <= M * N. Rejecting
    // M * N > INT_MAX therefore also bounds the compact U span.
    if (src.rows > 0 && src.cols > 0 &&
        int32_product_exceeds_max(src.rows, src.cols)) {
        return invalid_argument(
            "pseudoinverse destination index N * M exceeds INT_MAX");
    }

    try {
        cv::Mat singular_values;
        cv::Mat u;
        cv::Mat v_transpose;
        cv::Mat result;
        cv::SVD::compute(src, singular_values, u, v_transpose, 0);
        cv::SVD::backSubst(singular_values, u, v_transpose, cv::Mat(), result);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_reciprocal_condition_number(
    const opencv_core_mat_handle *source,
    double *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0.0;
    }

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    if (source == nullptr) {
        return invalid_argument("source Mat handle must not be null");
    }

    try {
        cv::Mat singular_values;
        cv::SVD::compute(source->value, singular_values, cv::SVD::NO_UV);

        // ABI safety: this function indexes W[0] and W[R-1] after
        // SVD::compute. OpenCV 4.10 _SVDcompute accepts a typed empty
        // CV_32F/CV_64F Mat and copies an empty W, so those accesses
        // would be out of bounds if R == 0.
        if (singular_values.rows < 1) {
            return OPENCV_CORE_OK;
        }

        const int rank = singular_values.rows;
        double sigma_max = 0.0;
        double sigma_min = 0.0;
        if (singular_values.type() == CV_32F) {
            sigma_max = static_cast<double>(singular_values.at<float>(0, 0));
            sigma_min =
                static_cast<double>(singular_values.at<float>(rank - 1, 0));
        } else {
            sigma_max = singular_values.at<double>(0, 0);
            sigma_min = singular_values.at<double>(rank - 1, 0);
        }

        if (sigma_max == 0.0) {
            return OPENCV_CORE_OK;
        }

        *out_value = sigma_min / sigma_max;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_transform(const opencv_core_mat_handle *source,
                          const opencv_core_mat_handle *coefficients,
                          opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr || coefficients == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        cv::Mat result;
        cv::transform(source->value, result, coefficients->value);

        std::unique_ptr<opencv_core_mat_handle> result_handle(
            new opencv_core_mat_handle(result));
        *out_mat = result_handle.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_mat_perspective_transform(
    const opencv_core_mat_handle *source,
    const opencv_core_mat_handle *transform_matrix,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (source == nullptr || transform_matrix == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    try {
        cv::Mat result;
        cv::perspectiveTransform(source->value, result, transform_matrix->value);

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
        // ABI safety: OpenCV 4.10 minMaxLoc does not initialize the location
        // outputs for an empty Mat, so a raw C ABI caller would receive
        // uninitialized coordinates.
        if (mat->value.empty()) {
            return invalid_argument("Mat must not be empty");
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
        // ABI safety: OpenCV 4.10 minMaxLoc does not initialize the location
        // outputs for an empty Mat, so a raw C ABI caller would receive
        // uninitialized coordinates.
        if (mat->value.empty()) {
            return invalid_argument("Mat must not be empty");
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
        // ABI safety: this function writes count output handles. An empty
        // source must not produce leftover or mismatched owned handles.
        if (source->value.empty()) {
            if (count != 0) {
                return invalid_argument("empty source requires zero output count");
            }
            return OPENCV_CORE_OK;
        }

        // ABI safety: count is the caller-owned output-handle length used
        // for writes below; it must match the number of Mats split produces.
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

    if (count < 0) {
        return invalid_argument("input count must not be negative");
    }
    if (count > 0 && sources == nullptr) {
        return invalid_argument("sources must not be null for nonempty input");
    }

    try {
        std::vector<cv::Mat> inputs;
        inputs.reserve(static_cast<size_t>(count));
        int32_t total_channels = 0;
        for (int32_t index = 0; index < count; ++index) {
            if (sources[index] == nullptr) {
                return invalid_argument("source Mat handle must not be null");
            }
            const int32_t channels = sources[index]->value.channels();
            // ABI safety: OpenCV accumulates merged channel counts in signed
            // int before the CV_CN_MAX assertion. Reject a total that would
            // exceed INT_MAX before OpenCV performs the addition.
            if (channels >= 0 &&
                int32_sum_exceeds_max(total_channels, channels)) {
                return invalid_argument(
                    "merged channel count would exceed the signed 32-bit range");
            }
            if (channels >= 0) {
                total_channels += channels;
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
        cv::setIdentity(mat->value, to_opencv_scalar(*value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_open(const char *filename, int32_t mode,
                              opencv_core_file_storage_handle **out_storage) {
    clear_error();

    if (out_storage != nullptr) {
        *out_storage = nullptr;
    }

    if (out_storage == nullptr) {
        return invalid_argument("out_storage must not be null");
    }

    if (filename == nullptr) {
        return invalid_argument("filename must not be null");
    }

    int opencv_mode = 0;
    if (!to_opencv_file_storage_mode(mode, opencv_mode)) {
        return invalid_argument("file storage mode is not supported");
    }

    try {
        auto storage = std::make_unique<opencv_core_file_storage_handle>();
        storage->memory_backed = false;
        storage->write_mode =
            opencv_mode == cv::FileStorage::WRITE;
        const bool opened = storage->value.open(filename, opencv_mode);
        if (!opened || !storage->value.isOpened()) {
            return invalid_argument("could not open file storage");
        }

        *out_storage = storage.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

void opencv_core_file_storage_destroy(
    opencv_core_file_storage_handle *storage) {
    clear_error();

    try {
        delete storage;
    } catch (const cv::Exception &error) {
        set_error(error.what());
    } catch (const std::exception &error) {
        set_error(error.what());
    } catch (...) {
        set_error("Unknown C++ exception during FileStorage destruction");
    }
}

opencv_core_status
opencv_core_file_storage_write_mat(
    opencv_core_file_storage_handle *storage, const char *name,
    const opencv_core_mat_handle *value) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    if (value == nullptr) {
        return invalid_argument("Mat handle must not be null");
    }

    const opencv_core_status context_status =
        require_write_name_for_context(*storage, name);
    if (context_status != OPENCV_CORE_OK) {
        return context_status;
    }

    try {
        storage->value.write(name, value->value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_mat(
    const opencv_core_file_storage_handle *storage, const char *name,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_named_node(*storage, name, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        // FileNode::mat() calls read(*this, value, Mat()), which
        // Mat::create()s destination storage and copies parsed values
        // into it. The returned Mat does not alias FileStorage memory.
        const cv::Mat loaded = node.mat();
        auto result = std::make_unique<opencv_core_mat_handle>(loaded);
        *out_mat = result.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_write_int(
    opencv_core_file_storage_handle *storage, const char *name,
    int32_t value) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    // ABI safety: OpenCV 4.10 persistence formats integers through
    // fs::itoa(), which calls abs(int). abs(INT_MIN) is not
    // representable as int, so reject INT32_MIN before OpenCV sees it.
    if (value == std::numeric_limits<int32_t>::min()) {
        return invalid_argument(
            "integer value INT32_MIN cannot be written with OpenCV 4.10");
    }

    const opencv_core_status context_status =
        require_write_name_for_context(*storage, name);
    if (context_status != OPENCV_CORE_OK) {
        return context_status;
    }

    try {
        storage->value.write(name, static_cast<int>(value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_int(
    const opencv_core_file_storage_handle *storage, const char *name,
    int32_t *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0;
    }

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_named_node(*storage, name, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        if (!node.isInt()) {
            return invalid_argument("named file node is not an integer");
        }

        *out_value = static_cast<int32_t>(static_cast<int>(node));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_write_double(
    opencv_core_file_storage_handle *storage, const char *name,
    double value) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    const opencv_core_status context_status =
        require_write_name_for_context(*storage, name);
    if (context_status != OPENCV_CORE_OK) {
        return context_status;
    }

    try {
        storage->value.write(name, value);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_double(
    const opencv_core_file_storage_handle *storage, const char *name,
    double *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0.0;
    }

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_named_node(*storage, name, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        if (node.isReal()) {
            *out_value = node.real();
            return OPENCV_CORE_OK;
        }

        if (node.isInt()) {
            *out_value = static_cast<double>(static_cast<int>(node));
            return OPENCV_CORE_OK;
        }

        return invalid_argument("named file node is not a real or integer");
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_write_string(
    opencv_core_file_storage_handle *storage, const char *name,
    const char *value) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    if (value == nullptr) {
        return invalid_argument("string value must not be null");
    }

    const opencv_core_status context_status =
        require_write_name_for_context(*storage, name);
    if (context_status != OPENCV_CORE_OK) {
        return context_status;
    }

    try {
        storage->value.write(name, cv::String(value));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_string(
    const opencv_core_file_storage_handle *storage, const char *name,
    char *buffer, uint64_t capacity, uint64_t *out_length) {
    clear_error();

    if (out_length != nullptr) {
        *out_length = 0;
    }

    if (out_length == nullptr) {
        return invalid_argument("out_length must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    if (buffer == nullptr && capacity != 0) {
        return invalid_argument(
            "string buffer must not be null when capacity is nonzero");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_named_node(*storage, name, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        return copy_file_node_string(node, buffer, capacity, out_length);
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_open_memory_write(
    int32_t format, opencv_core_file_storage_handle **out_storage) {
    clear_error();

    if (out_storage != nullptr) {
        *out_storage = nullptr;
    }

    if (out_storage == nullptr) {
        return invalid_argument("out_storage must not be null");
    }

    int opencv_format = 0;
    if (!to_opencv_file_storage_format(format, opencv_format)) {
        return invalid_argument("file storage format is not supported");
    }

    try {
        auto storage = std::make_unique<opencv_core_file_storage_handle>();
        const int flags =
            cv::FileStorage::WRITE | cv::FileStorage::MEMORY | opencv_format;
        const bool opened = storage->value.open(cv::String(), flags);
        if (!opened || !storage->value.isOpened()) {
            return invalid_argument("could not open memory file storage");
        }

        storage->memory_backed = true;
        storage->write_mode = true;
        *out_storage = storage.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_open_memory_read(
    const char *text, opencv_core_file_storage_handle **out_storage) {
    clear_error();

    if (out_storage != nullptr) {
        *out_storage = nullptr;
    }

    if (out_storage == nullptr) {
        return invalid_argument("out_storage must not be null");
    }

    if (text == nullptr) {
        return invalid_argument("memory text must not be null");
    }

    try {
        auto storage = std::make_unique<opencv_core_file_storage_handle>();
        // ABI/lifetime safety: OpenCV 4.10 memory-read retains
        // filename_or_buf as strbuf during parse. Copy first so the
        // Ada temporary C-string cannot dangle.
        storage->memory_source = text;
        const int flags = cv::FileStorage::READ | cv::FileStorage::MEMORY;
        const bool opened =
            storage->value.open(storage->memory_source, flags);
        if (!opened || !storage->value.isOpened()) {
            return invalid_argument("could not open memory file storage");
        }

        storage->memory_backed = true;
        storage->write_mode = false;
        *out_storage = storage.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_finish_memory_write(
    opencv_core_file_storage_handle *storage, char *buffer,
    uint64_t capacity, uint64_t *out_length) {
    clear_error();

    if (out_length != nullptr) {
        *out_length = 0;
    }

    if (out_length == nullptr) {
        return invalid_argument("out_length must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (buffer == nullptr && capacity != 0) {
        return invalid_argument(
            "string buffer must not be null when capacity is nonzero");
    }

    if (!storage->memory_backed) {
        return invalid_argument(
            "finish memory write requires memory-backed file storage");
    }

    if (!storage->write_mode) {
        return invalid_argument(
            "finish memory write requires write-only file storage");
    }

    if (!storage->write_structure_stack.empty()) {
        return invalid_argument(
            "finish memory write requires all structures to be closed");
    }

    try {
        if (!storage->released_memory_text_ready) {
            if (!storage->value.isOpened()) {
                return invalid_argument(
                    "finish memory write requires open write storage");
            }

            // releaseAndGetString is one-shot: it closes FileStorage
            // while producing the serialized document. Cache the
            // result so later query/copy calls do not invoke it again.
            storage->released_memory_text =
                storage->value.releaseAndGetString();
            storage->released_memory_text_ready = true;
        }

        uint64_t length = 0;
        if (!size_to_abi(storage->released_memory_text.size(), length)) {
            return invalid_argument(
                "serialized memory text exceeds the ABI size range");
        }

        if (buffer == nullptr) {
            *out_length = length;
            return OPENCV_CORE_OK;
        }

        if (capacity < length) {
            return invalid_argument(
                "string buffer capacity is smaller than the serialized text");
        }

        if (!storage->released_memory_text.empty()) {
            std::memcpy(buffer, storage->released_memory_text.data(),
                        storage->released_memory_text.size());
        }

        *out_length = length;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_begin_structure(
    opencv_core_file_storage_handle *storage, const char *name, int32_t kind) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    opencv_core_file_storage_structure_kind decoded =
        opencv_core_file_storage_structure_kind::map;
    if (!to_file_storage_structure_kind(kind, decoded)) {
        return invalid_argument("file storage structure kind is not supported");
    }

    const opencv_core_status context_status =
        require_write_name_for_context(*storage, name);
    if (context_status != OPENCV_CORE_OK) {
        return context_status;
    }

    try {
        // Reserve first so a later push_back cannot allocate after
        // OpenCV has already entered the structure.
        storage->write_structure_stack.reserve(
            storage->write_structure_stack.size() + 1);
        storage->value.startWriteStruct(name,
                                        to_opencv_file_node_flags(decoded));
        storage->write_structure_stack.push_back(decoded);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_end_structure(
    opencv_core_file_storage_handle *storage) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (storage->write_structure_stack.empty()) {
        return invalid_argument(
            "end structure is not valid at the file storage root");
    }

    try {
        storage->value.endWriteStruct();
        storage->write_structure_stack.pop_back();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_enter_named_structure(
    opencv_core_file_storage_handle *storage, const char *name, int32_t kind) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (name == nullptr) {
        return invalid_argument("node name must not be null");
    }

    opencv_core_file_storage_structure_kind decoded =
        opencv_core_file_storage_structure_kind::map;
    if (!to_file_storage_structure_kind(kind, decoded)) {
        return invalid_argument("file storage structure kind is not supported");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_named_node(*storage, name, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        const bool matches =
            decoded == opencv_core_file_storage_structure_kind::map
                ? node.isMap()
                : node.isSeq();
        if (!matches) {
            return invalid_argument(
                "named file node does not match the requested structure kind");
        }

        storage->read_context_stack.reserve(
            storage->read_context_stack.size() + 1);
        storage->read_context_stack.push_back(node);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_enter_indexed_structure(
    opencv_core_file_storage_handle *storage, uint64_t index, int32_t kind) {

    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    opencv_core_file_storage_structure_kind decoded =
        opencv_core_file_storage_structure_kind::map;
    if (!to_file_storage_structure_kind(kind, decoded)) {
        return invalid_argument("file storage structure kind is not supported");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_indexed_node(*storage, index, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        const bool matches =
            decoded == opencv_core_file_storage_structure_kind::map
                ? node.isMap()
                : node.isSeq();
        if (!matches) {
            return invalid_argument(
                "indexed file node does not match the requested structure "
                "kind");
        }

        storage->read_context_stack.reserve(
            storage->read_context_stack.size() + 1);
        storage->read_context_stack.push_back(node);
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_leave_structure(
    opencv_core_file_storage_handle *storage) {
    clear_error();

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (storage->read_context_stack.empty()) {
        return invalid_argument(
            "leave structure is not valid at the file storage root");
    }

    try {
        storage->read_context_stack.pop_back();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_sequence_length(
    const opencv_core_file_storage_handle *storage, uint64_t *out_length) {
    clear_error();

    if (out_length != nullptr) {
        *out_length = 0;
    }

    if (out_length == nullptr) {
        return invalid_argument("out_length must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    try {
        const cv::FileNode context = current_read_context(*storage);
        if (context.empty() || !context.isSeq()) {
            return invalid_argument(
                "sequence length requires a sequence read context");
        }

        uint64_t length = 0;
        if (!size_to_abi(context.size(), length)) {
            return invalid_argument(
                "sequence length exceeds the ABI size range");
        }

        *out_length = length;
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}



opencv_core_status
opencv_core_file_storage_read_mat_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    opencv_core_mat_handle **out_mat) {
    clear_error();

    if (out_mat != nullptr) {
        *out_mat = nullptr;
    }

    if (out_mat == nullptr) {
        return invalid_argument("out_mat must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_indexed_node(*storage, index, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        const cv::Mat loaded = node.mat();
        auto result = std::make_unique<opencv_core_mat_handle>(loaded);
        *out_mat = result.release();
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_int_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    int32_t *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0;
    }

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_indexed_node(*storage, index, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        if (!node.isInt()) {
            return invalid_argument("indexed file node is not an integer");
        }

        *out_value = static_cast<int32_t>(static_cast<int>(node));
        return OPENCV_CORE_OK;
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_double_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    double *out_value) {
    clear_error();

    if (out_value != nullptr) {
        *out_value = 0.0;
    }

    if (out_value == nullptr) {
        return invalid_argument("out_value must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_indexed_node(*storage, index, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        if (node.isReal()) {
            *out_value = node.real();
            return OPENCV_CORE_OK;
        }

        if (node.isInt()) {
            *out_value = static_cast<double>(static_cast<int>(node));
            return OPENCV_CORE_OK;
        }

        return invalid_argument("indexed file node is not a real or integer");
    } catch (...) {
        return translate_current_exception();
    }
}

opencv_core_status
opencv_core_file_storage_read_string_at(
    const opencv_core_file_storage_handle *storage, uint64_t index,
    char *buffer, uint64_t capacity, uint64_t *out_length) {
    clear_error();

    if (out_length != nullptr) {
        *out_length = 0;
    }

    if (out_length == nullptr) {
        return invalid_argument("out_length must not be null");
    }

    if (storage == nullptr) {
        return invalid_argument("file storage handle must not be null");
    }

    if (buffer == nullptr && capacity != 0) {
        return invalid_argument(
            "string buffer must not be null when capacity is nonzero");
    }

    try {
        cv::FileNode node;
        const opencv_core_status lookup_status =
            lookup_indexed_node(*storage, index, node);
        if (lookup_status != OPENCV_CORE_OK) {
            return lookup_status;
        }

        return copy_file_node_string(node, buffer, capacity, out_length);
    } catch (...) {
        return translate_current_exception();
    }
}
} // extern "C"


