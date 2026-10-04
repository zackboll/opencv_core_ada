// Compile this translation unit alone: exercise the private production helper.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

static void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
static cv::Mat host(const cv::Mat& value) { return value; }
static cv::Mat host(const cv::UMat& value) {
    cv::Mat result;
    value.copyTo(result);
    return result;
}
template<class Dense> static Dense image(const cv::Mat& value) {
    Dense result;
    value.copyTo(result);
    return result;
}
template<class Dense> static void run(const char* kind) {
    for (int depth : {CV_8U, CV_16S, CV_32S, CV_32F, CV_64F, CV_16F}) {
        cv::Mat a64(1,257,CV_64F), b64(1,257,CV_64F), a, b;
        for (int i=0; i<257; ++i) {
            a64.at<double>(0,i)=i%13+1;
            b64.at<double>(0,i)=depth==CV_8U ? i%7+3 : -(i%7+3);
        }
        a64.convertTo(a,depth); b64.convertTo(b,depth);
        for (int mode=0; mode<8; ++mode) {
            Dense left=image<Dense>(a), right=image<Dense>(b);
            Dense dst=image<Dense>(a), alias=dst;
            if (mode>=5) right=left;
            if (mode==1 || mode==6) dense_abs_diff(left,right,left);
            else if (mode==2) dense_abs_diff(left,right,right);
            else {
                if (mode==3 || mode==7) dst=left;
                if (mode==4) dst=right;
                dense_abs_diff(left,right,dst);
            }
            cv::Mat out;
            host(mode==1 || mode==6 ? left : mode==2 ? right : dst)
                .convertTo(out,CV_64F);
            for(int i=0;i<257;++i)
                require(out.at<double>(0,i)==(mode>=5 ? 0 :
                    std::abs(a64.at<double>(0,i)-b64.at<double>(0,i))),
                    "exact/shallow alias SIMD/tail numeric result");
            if (mode==0) {
                host(alias).convertTo(out,CV_64F);
                require(out.at<double>(0,256)==
                    std::abs(a64.at<double>(0,256)-b64.at<double>(0,256)),
                    "whole reuse");
                alias.setTo(cv::Scalar(17)); host(dst).convertTo(out,CV_64F);
                require(out.at<double>(0,256)==17,"whole alias write");
                dst.setTo(cv::Scalar(19)); host(alias).convertTo(out,CV_64F);
                require(out.at<double>(0,256)==19,"whole destination write");
            }
        }
        Dense left=image<Dense>(a), right=image<Dense>(b);
        Dense parent=image<Dense>(cv::Mat(3,259,depth,cv::Scalar(91)));
        Dense dst=parent(cv::Rect(1,1,257,1)), alias=dst;
        cv::Size whole; cv::Point offset; dst.locateROI(whole,offset);
        dense_abs_diff(left,right,dst);
        cv::Size after; cv::Point position; dst.locateROI(after,position);
        require(whole==after && offset==position,"Region attachment/geometry");
        cv::Mat out; host(parent).convertTo(out,CV_64F);
        for(int r=0;r<3;++r) for(int c=0;c<259;++c)
            require(out.at<double>(r,c)==(r==1 && c>=1 && c<=257 ?
                std::abs(a64.at<double>(0,c-1)-b64.at<double>(0,c-1)) : 91),
                "every Region and guard pixel");
        alias.setTo(cv::Scalar(17)); host(dst).convertTo(out,CV_64F);
        require(out.at<double>(0,256)==17,"half final narrowing reused Region");
        // Scalar-looking matching arrays: old destination depth cannot select
        // a different-width array kernel. No preallocation correction used.
        for(int layout=0;layout<3;++layout) for(int mode=0;mode<4;++mode) {
            int type=CV_MAKETYPE(depth,layout==2 ? 4 : 1);
            Dense x=image<Dense>(cv::Mat(1,layout==1 ? 4 : 1,type,cv::Scalar::all(10)));
            Dense y=image<Dense>(cv::Mat(1,layout==1 ? 4 : 1,type,cv::Scalar::all(50)));
            Dense d=image<Dense>(cv::Mat(1,layout==1 ? 4 : 1,
                mode==1 ? CV_MAKETYPE(CV_16S,layout==2 ? 4 : 1) : type,
                cv::Scalar::all(91)));
            if(mode==2) dense_abs_diff(x,y,x);
            else if(mode==3) dense_abs_diff(x,y,y);
            else dense_abs_diff(x,y,d);
            Dense result=mode==2 ? x : mode==3 ? y : d;
            require(result.type()==type && result.size()==x.size(),"small layout type");
            host(result).reshape(1).convertTo(out,CV_64F);
            for(int i=0;i<out.cols;++i)
                require(out.at<double>(0,i)==40,"scalar-like arrays safe");
        }
    }
    for(int depth : {CV_32F,CV_64F,CV_16F}) {
        double inf=std::numeric_limits<double>::infinity();
        double nan=std::numeric_limits<double>::quiet_NaN();
        const double x[]={3,3,inf,-inf,nan,3,0.0,-0.0};
        const double y[]={inf,-inf,inf,-inf,3,nan,-0.0,0.0};
        cv::Mat a(1,257,CV_64F),b(1,257,CV_64F),ad,bd,out;
        for(int i=0;i<257;++i) {a.at<double>(0,i)=x[i%8]; b.at<double>(0,i)=y[i%8];}
        a.convertTo(ad,depth); b.convertTo(bd,depth);
        Dense left=image<Dense>(ad),right=image<Dense>(bd),dst=image<Dense>(ad);
        dense_abs_diff(left,right,dst); host(dst).convertTo(out,CV_64F);
        for(int i=0;i<257;++i) {
            double v=out.at<double>(0,i);
            require(i%8<2 ? std::isinf(v) && v>0 : i%8<6 ? std::isnan(v) :
                    v==0 && !std::signbit(v),"floating special classification/positive zero");
        }
        dense_abs_diff(left,left,left); host(left).convertTo(out,CV_64F);
        require(std::isnan(out.at<double>(0,2)),"infinite A/A is NaN");
    }
    for(int depth : {CV_8U,CV_32F,CV_16F}) for(int mode=0;mode<4;++mode) {
        if(mode>1 && depth!=CV_8U) continue;
        Dense a,b,dst=image<Dense>(cv::Mat(2,3,CV_16SC2,cv::Scalar(91,92)));
        Dense alias=dst;
        if(mode==1 || mode==3) a.create(0,0,depth);
        if(mode==1 || mode==2) b.create(0,0,depth);
        dense_abs_diff(a,b,dst);
        std::cout<<kind<<" empty depth="<<depth<<" mode="<<mode
                 <<" dims="<<dst.dims<<" rows="<<dst.rows<<" cols="<<dst.cols
                 <<" depth="<<dst.depth()<<" channels="<<dst.channels()<<'\n';
        cv::Mat old=host(alias);
        require(old.at<cv::Vec2s>(1,2)==cv::Vec2s(91,92),"empty alias survives");
    }
    std::cout<<kind<<" reuse/Region/aliases/257/half/nonfinite/scalar-like passed\n";
}
int main() {
    try {
        std::cout<<"OpenCV "<<CV_VERSION<<"; actual dense_abs_diff, no correction\n";
        bool previous=cv::ocl::useOpenCL(); cv::ocl::setUseOpenCL(false);
        run<cv::Mat>("Mat"); run<cv::UMat>("UMat");
        cv::Mat a(1,257,CV_16S,cv::Scalar(-32768)),b(1,257,CV_16S,cv::Scalar(0)),d;
        dense_abs_diff(a,b,d);
        for(int i=0;i<257;++i) require(d.at<short>(0,i)==32767,"Int16 saturation");
        a=cv::Mat(1,257,CV_32S,cv::Scalar(-10000));
        b=cv::Mat(1,257,CV_32S,cv::Scalar(20000)); dense_abs_diff(a,b,d);
        for(int i=0;i<257;++i) require(d.at<int>(0,i)==30000,"safe Int32");
        // Observe overflow, do not assert a portable C++ signed-overflow result.
        a.setTo(cv::Scalar(std::numeric_limits<int>::min()));
        b.setTo(cv::Scalar(0)); dense_abs_diff(a,b,d);
        std::cout<<"native Int32 overflow observations first="<<d.at<int>(0,0)
                 <<" tail="<<d.at<int>(0,256)<<" (not a binding guarantee)\n";
        // Raw native-compatible array/scalar shapes can enter scalar handling.
        for(int depth : {CV_8U,CV_32S,CV_32F}) for(int old : {depth,CV_16S,CV_64F}) {
            opencv_core_mat_handle left(cv::Mat(2,257,depth,cv::Scalar(10)));
            opencv_core_mat_handle right(cv::Mat(1,1,CV_64F,cv::Scalar(50)));
            opencv_core_mat_handle dst(cv::Mat(2,257,old,cv::Scalar(91)));
            require(opencv_core_mat_abs_diff_into(&left,&right,&dst)==OPENCV_CORE_OK,
                    "raw native scalar-compatible input");
            cv::Mat out; dst.value.convertTo(out,CV_64F);
            require(dst.value.type()==depth,"scalar helper same storage width");
            for(int r=0;r<2;++r) for(int c=0;c<257;++c)
                require(out.at<double>(r,c)==40,"raw scalar-compatible output");
            require(opencv_core_mat_abs_diff_into(&right,&left,&dst)==OPENCV_CORE_OK,
                    "raw scalar-first compatible input");
            dst.value.convertTo(out,CV_64F);
            for(int r=0;r<2;++r) for(int c=0;c<257;++c)
                require(out.at<double>(r,c)==40,"raw scalar-first output");
        }
        int shape[]={2,3,257};
        opencv_core_mat_handle ndleft(cv::Mat(3,shape,CV_32F,cv::Scalar(-10)));
        opencv_core_mat_handle ndright(cv::Mat(3,shape,CV_32F,cv::Scalar(20)));
        opencv_core_mat_handle nddst(cv::Mat(2,2,CV_16S,cv::Scalar(91)));
        require(opencv_core_mat_abs_diff_into(&ndleft,&ndright,&nddst)==OPENCV_CORE_OK,
                "raw general N-D array path remains native");
        require(nddst.value.dims==3 && nddst.value.type()==CV_32F,"raw N-D layout");
        for(size_t i=0;i<nddst.value.total();++i)
            require(nddst.value.ptr<float>()[i]==30,"raw N-D pixels");
        static_assert(sizeof(uint32_t)==sizeof(int32_t),"32s32u storage width");
        cv::ocl::setUseOpenCL(previous);
        std::cout<<"Int16 saturation/safe Int32/raw scalar layouts passed\n";
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
}