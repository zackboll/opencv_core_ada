#include <opencv2/core/ocl.hpp>
#include <cstdint>
#include "../../cpp/opencv_core_module_bridge.hpp"

#if defined(_WIN32)
#define UMAT_PROBE_EXPORT __declspec(dllexport)
#else
#define UMAT_PROBE_EXPORT
#endif

extern "C" UMAT_PROBE_EXPORT std::uint8_t umat_probe_have_opencl() noexcept {
    try { return cv::ocl::haveOpenCL() ? 1 : 0; }
    catch (...) { return 0; }
}

extern "C" UMAT_PROBE_EXPORT std::uint8_t umat_probe_use_opencl() noexcept {
    try { return cv::ocl::useOpenCL() ? 1 : 0; }
    catch (...) { return 0; }
}

extern "C" UMAT_PROBE_EXPORT std::uint8_t umat_probe_set_opencl(
    std::uint8_t enabled) noexcept {
    try {
        cv::ocl::setUseOpenCL(enabled != 0);
        return 1;
    } catch (...) { return 0; }
}


// Test oracle only: run OpenCV directly on separate cloned headers/storage,
// preserving the requested native exact alias. Never call the binding export.
template<class Dense> static void native_extrema(
    Dense &a, Dense &b, bool maximum, bool right_alias) {
    Dense &dst = right_alias ? b : a;
#if CV_VERSION_MAJOR < 5
    if (a.depth() == CV_16F) {
        Dense x, y, result;
        a.convertTo(x, CV_32F); b.convertTo(y, CV_32F);
        if (maximum) cv::max(x,y,result); else cv::min(x,y,result);
        result.convertTo(dst,CV_16F);
        return;
    }
#endif
    if (maximum) cv::max(a,b,dst); else cv::min(a,b,dst);
}

extern "C" UMAT_PROBE_EXPORT std::int32_t min_max_native_alias_expected(
    const opencv_core_mat_handle *left, const opencv_core_mat_handle *right,
    opencv_core_mat_handle *output, std::uint8_t maximum,
    std::uint8_t right_alias, std::uint8_t umat) noexcept {
    try {
        const cv::Mat *l=nullptr, *r=nullptr;
        cv::Mat *out=nullptr;
        if (opencv_core_module_input_mat(left,&l) != OPENCV_CORE_OK ||
            opencv_core_module_input_mat(right,&r) != OPENCV_CORE_OK ||
            opencv_core_module_output_mat(output,&out) != OPENCV_CORE_OK)
            return 0;
        if (umat) {
            cv::UMat a,b; l->copyTo(a); r->copyTo(b);
            native_extrema(a,b,maximum!=0,right_alias!=0);
            (right_alias?b:a).copyTo(*out);
        } else {
            cv::Mat a=l->clone(), b=r->clone();
            native_extrema(a,b,maximum!=0,right_alias!=0);
            (right_alias?b:a).copyTo(*out);
        }
        return 1;
    } catch (...) { return 0; }
}