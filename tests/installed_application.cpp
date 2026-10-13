#include <opencv2/core.hpp>

// Application-owned C++ code: no binding handles or native pointer exchange.
extern "C" int application_opencv_check() noexcept {
    try {
        cv::Mat image(2, 3, CV_8UC1, cv::Scalar(1));
        return static_cast<int>(cv::sum(image)[0]);
    } catch (...) {
        return -1;
    }
}