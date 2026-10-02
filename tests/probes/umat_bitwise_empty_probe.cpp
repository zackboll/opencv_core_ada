// Disposable subprocess probe: each mode must be run in its own process.
#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <cstdlib>
#include <iostream>

int main(int argc, char **argv) {
    if (argc != 4) return 2;
    cv::ocl::setUseOpenCL(std::atoi(argv[3]) != 0);
    int mode = std::atoi(argv[1]);
    int form = std::atoi(argv[2]);
    cv::UMat a = (form & 1) ? cv::UMat(0, 0, CV_16FC3) : cv::UMat();
    cv::UMat b = (form & 2) ? cv::UMat(0, 0, CV_16FC3) : cv::UMat();
    cv::UMat mask = (form & 4) ? cv::UMat(0, 0, CV_8UC1) : cv::UMat();
    cv::UMat result;
    try {
        switch (mode) {
        case 0: cv::bitwise_and(a, b, result); break;
        case 1: cv::bitwise_not(a, result); break;
        case 2: cv::bitwise_and(a, b, result, mask); break;
        case 3: cv::bitwise_not(a, result, mask); break;
        case 4: cv::inRange(a, cv::Scalar(0), cv::Scalar(1), result); break;
        case 5: cv::compare(a, b, result, cv::CMP_EQ); break;
        default: return 2;
        }
        std::cout << "ok dims=" << result.dims << " type=" << result.type()
                  << " empty=" << result.empty() << '\n';
    } catch (const cv::Exception &e) {
        std::cout << "exception " << e.what() << '\n';
    }
}