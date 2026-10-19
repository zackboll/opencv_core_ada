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
    for (int depth : {CV_8U, CV_8S, CV_16U, CV_16S, CV_32S}) {
        opencv_core_mat_handle parent(cv::Mat(4,263,CV_MAKETYPE(depth,4),
                                              cv::Scalar::all(8)));
        opencv_core_mat_handle roi(parent.value(cv::Rect(2,1,257,2)));
        opencv_core_mat_handle dst(cv::Mat(2,257,roi.value.type(),cv::Scalar::all(91)));
        auto* retained = dst.value.data;
        const opencv_core_scalar zero{2,4,8,0};
        require(opencv_core_mat_scalar_arithmetic(&roi,&zero,3,&output)!=0
                && output==nullptr,"integer scalar zero resets output");
        require(opencv_core_mat_scalar_arithmetic_into(&roi,&zero,3,&dst)!=0
                && retained==dst.value.data
                && cv::norm(dst.value,cv::NORM_INF)==91,"scalar zero preflight");
        roi.value(cv::Rect(256,1,1,1)).setTo(cv::Scalar(8,8,8,0));
        require(opencv_core_mat_scalar_arithmetic(&roi,&scalar,5,&output)!=0
                && output==nullptr,"last ROI pixel/channel zero");
        require(opencv_core_mat_scalar_arithmetic_into(&roi,&scalar,5,&dst)!=0
                && retained==dst.value.data
                && cv::norm(dst.value,cv::NORM_INF)==91,"Mat zero preflight");
        roi.value.setTo(cv::Scalar::all(8));
        require(opencv_core_mat_scalar_arithmetic(&roi,&scalar,5,&output)==0,
                "nonzero integer denominators accepted");
        opencv_core_mat_destroy(output);
        output=nullptr;
    }
    const opencv_core_scalar unsafe{NAN,0,0,0};
    require(opencv_core_mat_scalar_arithmetic(&source,&unsafe,0,&output)!=0
            && output==nullptr,"unsafe scalar conversion");
    require(opencv_core_mat_compare_scalar(nullptr,1,0,&output)!=0
            && output==nullptr,"null comparison source");
    require(opencv_core_mat_compare_scalar(&source,1,0,nullptr)!=0,
            "null comparison output");
    require(opencv_core_mat_compare_scalar_into(&source,1,0,nullptr)!=0,
            "null comparison destination");
    require(opencv_core_mat_compare_scalar_into(&source,1,0,&destination)!=0,
            "temporary comparison destination");
    require(opencv_core_mat_scalar_arithmetic_into(nullptr,&scalar,0,&destination)!=0,
            "null into source");
    require(opencv_core_mat_scalar_arithmetic_into(&source,nullptr,0,&destination)!=0,
            "null into scalar");
    // Safe invalid semantic input reaches native and is translated, not thrown.
    opencv_core_mat_handle five(cv::Mat(1,10,CV_8UC(5)));
    require(opencv_core_mat_scalar_arithmetic(&five,&scalar,0,&output)!=0
            && output==nullptr,"OpenCV exception contained");
    std::cout<<"PASS scalar shim ABI safety "<<CV_VERSION<<'\n';
}