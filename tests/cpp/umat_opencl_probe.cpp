#include <opencv2/core/ocl.hpp>
#include <cstdint>

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