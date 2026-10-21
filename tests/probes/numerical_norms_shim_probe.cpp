// Actual production shim, not a stand-in ABI implementation.
#include "../../cpp/opencv_core_shim.cpp"
#include <iostream>

static void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
static void same(double actual, double expected) {
    require((std::isnan(actual) && std::isnan(expected)) || actual == expected ||
        (std::isfinite(actual) && std::isfinite(expected) &&
         std::abs(actual - expected) <= 1e-12 * std::max(1., std::abs(expected))),
        "native parity");
}

int main() {
    std::cout << "Numerical norms actual-shim OpenCV " << CV_VERSION << '\n';
    opencv_core_mat_handle a(cv::Mat(3, 263, CV_64FC1, cv::Scalar(3)));
    opencv_core_mat_handle b(cv::Mat(3, 263, CV_64FC1, cv::Scalar(1)));
    double result = 91;
    auto bad = [&](opencv_core_status status) {
        require(status != OPENCV_CORE_OK, "invalid ABI rejected");
        require(result == 0, "failure initializes output");
        require(std::strlen(opencv_core_last_error_message()) > 0, "diagnostic");
        result = 91;
    };
    bad(opencv_core_mat_numeric_norm(nullptr, nullptr, 4, &result));
    bad(opencv_core_mat_numeric_norm(&a, nullptr, 99, &result));
    require(opencv_core_mat_numeric_norm(&a, nullptr, 4, nullptr) != 0,
            "null unary output");
    for (int kind : {-1, 0, 5, INT32_MAX})
        bad(opencv_core_mat_difference_norm(&a, &b, nullptr, kind, 0, &result));
    bad(opencv_core_mat_difference_norm(&a, &b, nullptr, 2, 2, &result));
    bad(opencv_core_mat_difference_norm(&a, &b, nullptr, 4, 1, &result));
    bad(opencv_core_mat_difference_norm(nullptr, &b, nullptr, 2, 0, &result));
    bad(opencv_core_mat_difference_norm(&a, nullptr, nullptr, 2, 0, &result));
    require(opencv_core_mat_difference_norm(&a, &b, nullptr, 2, 0, nullptr) != 0,
            "null pair output");
    for (int cell : {-1, 0, 3, INT32_MAX}) {
        bad(opencv_core_mat_binary_norm(&a, cell, &result));
        bad(opencv_core_mat_binary_difference_norm(&a, &b, cell, &result));
    }
    bad(opencv_core_mat_binary_norm(nullptr, 1, &result));
    bad(opencv_core_mat_binary_difference_norm(nullptr, &b, 1, &result));
    bad(opencv_core_mat_binary_difference_norm(&a, nullptr, 1, &result));
    require(opencv_core_mat_binary_norm(&a, 1, nullptr) != 0, "binary null output");
    require(opencv_core_mat_binary_difference_norm(&a, &b, 1, nullptr) != 0,
            "binary pair null output");
    bad(opencv_core_mat_binary_norm(&a, 1, &result)); // Native type exception.
    opencv_core_mat_handle other(cv::Mat(3, 264, CV_64FC1));
    bad(opencv_core_mat_difference_norm(&a, &other, nullptr, 2, 0, &result));
    for (int depth : {CV_32S, CV_16F}) {
        opencv_core_mat_handle excluded(cv::Mat(1, 1, depth));
        if (depth == CV_16F)
            bad(opencv_core_mat_numeric_norm(&excluded, nullptr, 4, &result));
        bad(opencv_core_mat_difference_norm(&excluded, &excluded, nullptr,
                                           2, 0, &result));
    }
    opencv_core_mat_handle wrong_mask(cv::Mat(1, 1, CV_8UC1));
    bad(opencv_core_mat_numeric_norm(&a, &wrong_mask, 4, &result));
    // Bounded synthetic header: no huge allocation or native data access.
    opencv_core_mat_handle synthetic(cv::Mat(1, 1, CV_8UC1));
    synthetic.value.cols = INT32_MAX / 8;
    synthetic.value.size[1] = synthetic.value.cols;
    norm_storage_preflight(synthetic.value, INT32_MAX / 8);
    synthetic.value.cols = INT32_MAX / 8 + 1;
    synthetic.value.size[1] = synthetic.value.cols;
    bad(opencv_core_mat_binary_norm(&synthetic, 1, &result));
    bad(opencv_core_mat_binary_difference_norm(&synthetic, &synthetic, 1, &result));
    synthetic.value.cols = INT32_MAX / 4 + 1;
    synthetic.value.size[1] = synthetic.value.cols;
    bad(opencv_core_mat_binary_norm(&synthetic, 2, &result));
    bad(opencv_core_mat_binary_difference_norm(&synthetic, &synthetic, 2, &result));
    bad(opencv_core_mat_numeric_norm(&synthetic, nullptr, 4, &result));
    bad(opencv_core_mat_difference_norm(&synthetic, &synthetic, nullptr,
                                       2, 0, &result));
    synthetic.value.cols = 1;
    synthetic.value.size[1] = 1;
    synthetic.value.step[0] = static_cast<size_t>(INT32_MAX) + 1;
    bad(opencv_core_mat_numeric_norm(&synthetic, nullptr, 4, &result));
    synthetic.value.step[0] = 1;
    opencv_core_mat_handle product(cv::Mat(1, 1, CV_64FC4));
    product.value.cols = INT32_MAX / 8 / 4 + 1;
    product.value.size[1] = product.value.cols;
    bad(opencv_core_mat_numeric_norm(&product, nullptr, 4, &result));
    product.value.cols = 1;
    product.value.size[1] = 1;

    for (int depth : {CV_8U, CV_8S, CV_16U, CV_16S, CV_32F, CV_64F}) {
        for (int channels : {1, 3, 4}) {
            const int shape[] = {2, 3, 9};
            cv::Mat lp(3, shape, CV_MAKETYPE(depth, channels), cv::Scalar::all(3));
            cv::Mat rp(3, shape, lp.type(), cv::Scalar::all(1));
            cv::Mat mp(3, shape, CV_8UC1, cv::Scalar(127));
            const cv::Range ranges[] = {cv::Range::all(), cv::Range::all(),
                                         cv::Range(1, 8)};
            opencv_core_mat_handle left(lp(ranges)), right(rp(ranges)), mask(mp(ranges));
            for (const auto* m : {static_cast<opencv_core_mat_handle*>(nullptr), &mask}) {
                require(opencv_core_mat_numeric_norm(&left, m, 4, &result) == 0,
                        "native unary");
                same(result, cv::norm(left.value, cv::NORM_L2SQR,
                                      m ? m->value : cv::Mat()));
                for (int kind = 1; kind <= 4; ++kind) {
                    for (int rel = 0; rel <= (kind == 4 ? 0 : 1); ++rel) {
                        require(opencv_core_mat_difference_norm(&left, &right, m,
                            kind, rel, &result) == 0, "native pair");
                        same(result, cv::norm(left.value, right.value,
                            numeric_norm_selector(kind) | (rel ? cv::NORM_RELATIVE : 0),
                            m ? m->value : cv::Mat()));
                    }
                }
            }
        }
    }
    for (int cell : {1, 2}) {
        cv::Mat ap(4, 263, CV_8UC1, cv::Scalar(255));
        cv::Mat bp(4, 263, CV_8UC1, cv::Scalar(3));
        opencv_core_mat_handle left(ap(cv::Rect(1, 1, 257, 2)));
        opencv_core_mat_handle right(bp(cv::Rect(1, 1, 257, 2)));
        const int native = cell == 1 ? cv::NORM_HAMMING : cv::NORM_HAMMING2;
        require(opencv_core_mat_binary_norm(&left, cell, &result) == 0, "binary unary");
        same(result, cv::norm(left.value, native));
        require(opencv_core_mat_binary_difference_norm(&left, &right, cell,
                                                      &result) == 0, "binary pair");
        same(result, cv::norm(left.value, right.value, native));
    }
    // Finite inputs do not imply a finite relative empty-selection result:
    // IPP may produce NaN. Preserve and compare with the direct native call.
    for (int depth : {CV_8U, CV_8S, CV_16U, CV_16S, CV_32F, CV_64F}) {
        for (int channels = 1; channels <= 4; ++channels) {
            opencv_core_mat_handle left(cv::Mat(1, 5, CV_MAKETYPE(depth, channels),
                                                cv::Scalar::all(3)));
            opencv_core_mat_handle right(cv::Mat(1, 5, left.value.type(),
                                                 cv::Scalar::all(1)));
            opencv_core_mat_handle mask(cv::Mat(1, 5, CV_8UC1, cv::Scalar(0)));
            for (int kind = 1; kind <= 3; ++kind) {
                require(opencv_core_mat_difference_norm(&left, &right, &mask,
                    kind, 1, &result) == 0, "zero-mask relative native call");
                same(result, cv::norm(left.value, right.value,
                    numeric_norm_selector(kind) | cv::NORM_RELATIVE, mask.value));
            }
        }
    }
    for (double value : {0., 1e-300, static_cast<double>(INFINITY),
                         static_cast<double>(NAN)}) {
        a.value.setTo(value);
        b.value.setTo(0.);
        for (int kind = 1; kind <= 4; ++kind) {
            for (int rel = 0; rel <= (kind == 4 ? 0 : 1); ++rel) {
                require(opencv_core_mat_difference_norm(&a, &b, nullptr, kind,
                    rel, &result) == 0, "nonfinite/relative parity");
                same(result, cv::norm(a.value, b.value,
                    numeric_norm_selector(kind) | (rel ? cv::NORM_RELATIVE : 0)));
            }
        }
    }
    opencv_core_mat_handle empty;
    require(opencv_core_mat_numeric_norm(&empty, nullptr, 4, &result) == 0 &&
            result == 0, "default empty unary");
    require(opencv_core_mat_difference_norm(&empty, &empty, nullptr, 2, 1,
            &result) == 0 && result == 0, "default empty relative");
    require(opencv_core_mat_binary_difference_norm(&empty, &empty, 1,
            &result) == 0 && result == 0, "default empty binary");
    require(opencv_core_mat_numeric_norm(&a, nullptr, 4, &result) == 0 &&
            std::strlen(opencv_core_last_error_message()) == 0, "error state cleared");
    require(opencv_core_mat_binary_norm(&empty, 1, &result) == 0 && result == 0,
            "default empty binary unary");
    result = 91;
    opencv_core_mat_handle typed_empty(cv::Mat(0, 3, CV_64FC1));
    bad(opencv_core_mat_difference_norm(&empty, &typed_empty, nullptr,
                                       2, 0, &result));
    bad(opencv_core_mat_binary_norm(&typed_empty, 1, &result));
    std::cout << "PASS native parity, negative ABI, bounded count/stride controls\n";
}