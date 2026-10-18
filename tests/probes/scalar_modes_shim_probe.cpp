// Compile standalone with sanitizers; tests actual ABI, no Ada imports repeated.
#include "../../cpp/opencv_core_shim.cpp"
#include <iostream>

static void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
int main() {
    opencv_core_scalar scalar{2,3,4,5};
    opencv_core_mat_handle source(cv::Mat(2,257,CV_64FC1,cv::Scalar(8)));
    opencv_core_mat_handle destination;
    opencv_core_mat_handle* output=&source;
    for (int op=0; op<6; ++op) {
        require(opencv_core_mat_scalar_arithmetic(nullptr,&scalar,op,&output)!=0
                && output==nullptr,"null source resets output");
        require(opencv_core_mat_scalar_arithmetic(&source,nullptr,op,&output)!=0,
                "null scalar");
        require(opencv_core_mat_scalar_arithmetic(&source,&scalar,op,nullptr)!=0,
                "null output");
        require(opencv_core_mat_scalar_arithmetic_into(&source,&scalar,op,nullptr)!=0,
                "null destination");
        require(opencv_core_mat_scalar_arithmetic(&source,&scalar,op,&output)==0,
                "published owned result");
        opencv_core_mat_destroy(output);
        require(opencv_core_mat_scalar_arithmetic_into(&source,&scalar,op,&destination)==0,
                "valid default destination");
    }
    require(opencv_core_mat_scalar_arithmetic(&source,&scalar,99,&output)!=0
            && output==nullptr,"operation selector");
    require(opencv_core_mat_compare_scalar(&source,1.5,99,&output)!=0
            && output==nullptr,"comparison selector");
    destination.temporary_external_view=true;
    require(opencv_core_mat_scalar_arithmetic_into(&source,&scalar,0,&destination)!=0,
            "temporary destination capability");
    opencv_core_mat_handle half(cv::Mat(1,1,CV_16FC1));
    require(opencv_core_mat_scalar_arithmetic(&half,&scalar,0,&output)!=0
            && output==nullptr,"unsafe half dispatch contained");
    require(opencv_core_mat_compare_scalar(&half,1.0,0,&output)!=0
            && output==nullptr,"half comparison contained");
    // Safe invalid semantic input reaches native and is translated, not thrown.
    opencv_core_mat_handle five(cv::Mat(1,10,CV_8UC(5)));
    require(opencv_core_mat_scalar_arithmetic(&five,&scalar,0,&output)!=0
            && output==nullptr,"OpenCV exception contained");
    std::cout<<"PASS scalar shim ABI safety "<<CV_VERSION<<'\n';
}