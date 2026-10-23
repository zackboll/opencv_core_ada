// Independent cv::norm control: no Ada binding or production shim included.
#include <opencv2/core.hpp>
#include <cmath>
#include <iostream>

static const char* classify(double value) {
    if (std::isnan(value)) return "NAN";
    if (std::isinf(value)) return value > 0 ? "POSITIVE_INFINITY" : "NEGATIVE_INFINITY";
    return "FINITE";
}

int main() {
    std::cout << "OpenCV=" << CV_VERSION << '\n' << cv::getBuildInformation();
    const bool optimized = cv::useOptimized();
    const bool ipp = cv::ipp::useIPP();
    for (int mode = 0; mode < 3; ++mode) {
        cv::setUseOptimized(mode != 2);
        cv::ipp::setUseIPP(mode == 0 && ipp);
        for (int depth : {CV_8U, CV_8S, CV_16U, CV_16S, CV_32F, CV_64F}) {
            for (int channels = 1; channels <= 4; ++channels) {
                cv::Mat a(1, 5, CV_MAKETYPE(depth, channels), cv::Scalar::all(3));
                cv::Mat b(1, 5, a.type(), cv::Scalar::all(1));
                for (int partial = 0; partial <= 1; ++partial) {
                    cv::Mat mask(1, 5, CV_8UC1, cv::Scalar(0));
                    if (partial) mask.at<uchar>(0, 2) = 127;
                    for (int reverse = 0; reverse <= 1; ++reverse) {
                        for (int kind : {cv::NORM_L1, cv::NORM_L2, cv::NORM_INF}) {
                            std::cout << "MASK mode=" << mode
                                      << " optimized=" << cv::useOptimized()
                                      << " ipp=" << cv::ipp::useIPP()
                                      << " depth=" << depth << " channels=" << channels
                                      << " partial=" << partial << " reverse=" << reverse
                                      << " kind=" << kind << ' ';
                            try {
                                const double value = cv::norm(reverse ? b : a, reverse ? a : b,
                                    kind | cv::NORM_RELATIVE, mask);
                                std::cout << classify(value) << " value=" << value << std::endl;
                            } catch (const std::exception& error) {
                                std::cerr << "EXCEPTION " << error.what() << std::endl;
                                return 1;
                            }
                        }
                    }
                }
            }
        }
    }
    cv::setUseOptimized(optimized);
    cv::ipp::setUseIPP(ipp);
    std::cout << "NORMAL_RETURN native mask control" << std::endl;
}