#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <iostream>

template<class Image> void empty_cases(const char* name) {
    for (int typed = 0; typed != 2; ++typed) {
        for (int scaled = 0; scaled != 2; ++scaled) {
            Image source;
            if (typed) source.create(0, 0, CV_32FC3);
            Image destination(2, 3, CV_16SC2);
            source.convertTo(destination, CV_8U, scaled ? 2.0 : 1.0, 0.0);
            std::cout << name << " typed=" << typed << " scaled=" << scaled
                      << " empty=" << destination.empty()
                      << " dims=" << destination.dims
                      << " rows=" << destination.rows
                      << " cols=" << destination.cols
                      << " depth=" << destination.depth()
                      << " channels=" << destination.channels() << '\n';
        }
    }
}

int main() {
    std::cout << CV_VERSION << '\n';
    cv::ocl::setUseOpenCL(false);
    empty_cases<cv::Mat>("Mat");
    empty_cases<cv::UMat>("UMat");
}