// Isolated zero-work investigation; compile against either actual shim head.
// -DBITWISE_SHIM_SOURCE='"/absolute/path/to/reviewed/shim.cpp"' selects a head.
#ifndef BITWISE_SHIM_SOURCE
#define BITWISE_SHIM_SOURCE "../../cpp/opencv_core_shim.cpp"
#endif
#include BITWISE_SHIM_SOURCE
#include <iostream>

static void metadata(const char *label, const cv::Mat &m) {
    std::cout << label << " dims=" << m.dims << " type=" << m.type()
              << " depth=" << m.depth() << " channels=" << m.channels()
              << " empty=" << m.empty() << " total=" << m.total() << " shape=";
    for (int i = 0; i < m.dims; ++i) std::cout << m.size[i] << ',';
    std::cout << '\n';
}

template <typename Operation>
static void observe(const char *label, Operation operation) {
    cv::Mat d(2, 257, CV_16SC2, cv::Scalar::all(91)), alias = d;
    std::cout << label << '\n';
    metadata("Destination before", d);
    try {
        operation(d);
        std::cout << "result=success\n";
    } catch (const cv::Exception &e) {
        std::cout << "result=exception " << e.what() << '\n';
    }
    metadata("Destination after", d);
    metadata("Alias after", alias);
    if (alias.rows != 2 || alias.cols != 257 || alias.type() != CV_16SC2 ||
        cv::norm(alias, cv::NORM_INF) != 91)
        throw std::runtime_error("retained Alias changed");
}

int main() {
    try {
        const cv::Mat a(0, 0, CV_8UC1), b(0, 0, CV_8UC1);
        const opencv_core_mat_handle left(a), right(b);
        std::cout << "OpenCV " << CV_VERSION
                  << " isolated Mat And unmasked typed/typed UInt8 C1\n";
        metadata("Left", a);
        metadata("Right", b);
        // Each call is independent, not inferred from the all-case loop order.
        observe("direct cv::bitwise_and", [&](cv::Mat &d) {
            cv::bitwise_and(a, b, d);
        });
        observe("actual dense_bitwise_binary", [&](cv::Mat &d) {
            dense_bitwise_binary(a, b, d, bitwise_operation::bit_and);
        });
        observe("destination-taking Bitwise_And C boundary", [&](cv::Mat &d) {
            opencv_core_mat_handle destination(d);
            const auto status = opencv_core_mat_bitwise_and_into(
                &left, &right, &destination);
            std::cout << "status=" << status << " diagnostic="
                      << opencv_core_last_error_message() << '\n';
            d = destination.value;
        });
        opencv_core_mat_handle *out = nullptr;
        const auto status = opencv_core_mat_bitwise_and(&left, &right, &out);
        std::cout << "allocation-returning Bitwise_And C boundary status="
                  << status << " diagnostic="
                  << opencv_core_last_error_message() << '\n';
        if (out) metadata("Function result", out->value);
        else std::cout << "Function result=null\n";
        opencv_core_mat_destroy(out);
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}