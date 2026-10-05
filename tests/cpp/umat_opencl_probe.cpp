#include <opencv2/core/ocl.hpp>
#include <cstdint>
#include <limits>
#include <iostream>
#include "../../cpp/opencv_core_module_bridge.hpp"
#include "../../cpp/opencv_core_shim.h"

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

// Weighted test oracle only. Clones preserve the requested same-layout alias;
// compatibility intermediates use the same Dense family as the operation.
template<class Dense> static void native_weighted(
    Dense &a, Dense &b, Dense &dst, bool scaled,
    double alpha, double beta, double gamma) {
    if (a.depth()==CV_16F && (scaled || CV_VERSION_MAJOR<5)) {
        Dense x,y,z; a.convertTo(x,CV_32F); b.convertTo(y,CV_32F);
        if(scaled) cv::scaleAdd(x,static_cast<float>(alpha),y,z);
        else cv::addWeighted(x,alpha,y,beta,gamma,z);
        z.convertTo(dst,CV_16F);
    } else if(scaled) cv::scaleAdd(a,alpha,b,dst);
    else cv::addWeighted(a,alpha,b,beta,gamma,dst);
}
extern "C" UMAT_PROBE_EXPORT std::int32_t weighted_native_expected(
    const opencv_core_mat_handle *left, const opencv_core_mat_handle *right,
    opencv_core_mat_handle *output, std::uint8_t scaled,
    std::uint8_t alias_mode, std::uint8_t umat,
    double alpha, double beta, double gamma) noexcept {
    try {
        const cv::Mat *l=nullptr,*r=nullptr; cv::Mat *out=nullptr;
        if(opencv_core_module_input_mat(left,&l)!=OPENCV_CORE_OK ||
           opencv_core_module_input_mat(right,&r)!=OPENCV_CORE_OK ||
           opencv_core_module_output_mat(output,&out)!=OPENCV_CORE_OK) return 0;
        if(umat) {
            cv::UMat a,b,d; l->copyTo(a); r->copyTo(b);
            if(alias_mode==3) b=a;
            cv::UMat &dst=alias_mode==0?d:alias_mode==2?b:a;
            native_weighted(a,b,dst,scaled!=0,alpha,beta,gamma);
            dst.copyTo(*out);
        } else {
            cv::Mat a=l->clone(),b=r->clone(),d;
            if(alias_mode==3) b=a;
            cv::Mat &dst=alias_mode==0?d:alias_mode==2?b:a;
            native_weighted(a,b,dst,scaled!=0,alpha,beta,gamma);
            dst.copyTo(*out);
        }
        return 1;
    } catch (...) { return 0; }
}

// Test diagnostics only: identify the native build for precision observations.
extern "C" UMAT_PROBE_EXPORT void weighted_report_build_information() noexcept {
    try {
        static bool reported=false;
        if(!reported) {
            std::cout << "Weighted Int32 native backend build information:\n"
                      << cv::getBuildInformation() << std::flush;
            reported=true;
        }
    } catch (...) {}
}

// Special coefficients bypass Ada's -gnatVa validity checks, not production
// validation. Both public function and into ABI must preserve native classes.
extern "C" UMAT_PROBE_EXPORT std::int32_t weighted_special_coefficients()
    noexcept {
    try {
        struct owned_mat {
            opencv_core_mat_handle *value=nullptr;
            ~owned_mat() { opencv_core_mat_destroy(value); }
        };
        const double inf=std::numeric_limits<double>::infinity();
        const double nan=std::numeric_limits<double>::quiet_NaN();
        for(double coefficient:{inf,-inf,nan}) for(bool scaled:{false,true}) {
            owned_mat a,b,d,fresh;
            if(opencv_core_mat_create_2d(1,257,5,1,&a.value)!=OPENCV_CORE_OK ||
               opencv_core_mat_create_2d(1,257,5,1,&b.value)!=OPENCV_CORE_OK ||
               opencv_core_mat_create_2d(1,257,5,1,&d.value)!=OPENCV_CORE_OK) return 0;
            opencv_core_scalar value{1,0,0,0};
            const bool setup=opencv_core_mat_set_to(a.value,&value)==OPENCV_CORE_OK &&
                opencv_core_mat_set_to(b.value,&value)==OPENCV_CORE_OK;
            auto s1=scaled?opencv_core_mat_scale_add(a.value,coefficient,b.value,&fresh.value):
                opencv_core_mat_add_weighted(a.value,coefficient,b.value,1,0,&fresh.value);
            auto s2=scaled?opencv_core_mat_scale_add_into(a.value,coefficient,b.value,d.value):
                opencv_core_mat_add_weighted_into(a.value,coefficient,b.value,1,0,d.value);
            bool success=setup && s1==s2 && s1==OPENCV_CORE_OK;
            for(int c=0;success && c<257;++c) {
                std::int32_t x=0,y=0;
                success=opencv_core_mat_classify_float32(fresh.value,0,c,&x)==OPENCV_CORE_OK &&
                    opencv_core_mat_classify_float32(d.value,0,c,&y)==OPENCV_CORE_OK && x==y;
            }
            if(!success) return 0;
        }
        return 1;
    } catch (...) { return 0; }
}