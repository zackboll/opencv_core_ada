// Native behavior research; intentionally independent of the Ada binding.
#include <opencv2/core.hpp>
#include <iostream>
#include <limits>
#include <algorithm>

static void report(const char *name, const cv::Mat &src,
                   const cv::Mat &mask = cv::Mat()) {
    int low[32], high[32];
    std::fill_n(low, 32, -1);
    std::fill_n(high, 32, -1);
    double minimum = 99, maximum = 99;
    try {
        cv::minMaxIdx(src, &minimum, &maximum, low, high, mask);
        std::cout << name << " min=" << minimum << " max=" << maximum
                  << " minidx=";
        for (int i = 0; i < src.dims; ++i) std::cout << low[i] << ',';
        std::cout << " maxidx=";
        for (int i = 0; i < src.dims; ++i) std::cout << high[i] << ',';
        std::cout << '\n';
    } catch (const cv::Exception &e) {
        std::cout << name << " exception=" << e.code << '\n';
    }
}

template<class T> static void floats(int depth) {
    const int shape[] = {2, 1, 1, 1, 2};
    cv::Mat src(5, shape, depth), mask(5, shape, CV_8U, cv::Scalar(0));
    T *data = src.ptr<T>();
    const T nan = std::numeric_limits<T>::quiet_NaN();
    const T inf = std::numeric_limits<T>::infinity();
    data[0] = 4; data[1] = -2; data[2] = 9; data[3] = 3;
    report("finite", src);
    data[0] = nan;
    report("nan_then_finite", src);
    data[0] = 4; data[3] = nan;
    report("finite_then_nan", src);
    std::fill_n(data, 4, nan);
    report("nan_only", src);
    mask.ptr<unsigned char>()[2] = 255;
    report("masked_nan_only", src, mask);
    std::fill_n(data, 4, inf);
    report("positive_inf_only", src);
    report("masked_positive_inf_only", src, mask);
    std::fill_n(data, 4, -inf);
    report("negative_inf_only", src);
    report("masked_negative_inf_only", src, mask);
    mask.setTo(cv::Scalar(0));
    report("zero_mask", src, mask);
    std::fill_n(data, 4, T(7));
    report("ties", src);
}

int main() {
    std::cout << "OpenCV " << CV_VERSION << '\n';
    std::cout << cv::getBuildInformation() << '\n';
    for (bool optimized : {false, true}) {
        cv::setUseOptimized(optimized);
        std::cout << "optimized=" << optimized << " Float32\n";
        floats<float>(CV_32F);
        std::cout << "Float64\n";
        floats<double>(CV_64F);
        report("default_empty", cv::Mat());
        report("typed_empty", cv::Mat(0, 0, CV_32F));
        const int shape[] = {2, 3, 2, 4, 2};
        report("float16", cv::Mat(5, shape, CV_16F, cv::Scalar(2)));
    }
}