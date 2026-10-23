// Independent process-lifetime controls; every successful run returns normally.
#include <cstdio>
#include <cstdlib>
#include <climits>
#include <cstring>
#if defined(CONTROL_NATIVE)
#include <opencv2/core.hpp>
#endif
#if defined(CONTROL_SHIM)
#include CONTROL_SHIM
#endif

int main(int argc, char** argv) {
    std::puts("CONTROL main entered");
    std::fflush(stdout);
    if (argc > 1 && std::strcmp(argv[1], "asan-positive") == 0) {
        int* value = new int[1];
        delete[] value;
        volatile int* dangling = value;
        return *dangling;
    }
    if (argc > 1 && std::strcmp(argv[1], "ubsan-positive") == 0) {
        volatile int value = INT_MAX;
        volatile int result = value + 1;
        return result;
    }
#if defined(CONTROL_NATIVE)
    {
        cv::Mat a(2, 17, CV_64FC1, cv::Scalar(3));
        cv::Mat b(2, 17, CV_64FC1, cv::Scalar(1));
        if (cv::norm(a, b, cv::NORM_L1) != 68) return 2;
        std::puts("CONTROL direct norm complete");
    }
#endif
#if defined(CONTROL_SHIM)
    {
        opencv_core_mat_handle source(cv::Mat(2, 17, CV_64FC1, cv::Scalar(3)));
        double result = 0;
        if (opencv_core_mat_norm(&source, 1, &result) != 0 || result != 102)
            return 3;
        std::puts("CONTROL unchanged Norm complete");
    }
#endif
    std::puts("CONTROL local destructors complete; normal return");
    std::fflush(stdout);
    return 0;
}