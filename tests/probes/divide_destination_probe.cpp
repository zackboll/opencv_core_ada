// Isolated actual-helper probe: compile this TU only, linking OpenCV Core.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <cmath>
#include <iostream>
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
        cv::Mat a64(1, 257, CV_64F), b64(1, 257, CV_64F), a, b;
        for (int i = 0; i < 257; ++i) {
            b64.at<double>(0,i) = i % 7 + 1;
            a64.at<double>(0,i) = b64.at<double>(0,i) * (i % 13 + 1);
        }
        a64.convertTo(a, depth); b64.convertTo(b, depth);
        for (int mode = 0; mode < 5; ++mode) {
            Dense left = image<Dense>(a), right = image<Dense>(b);
            Dense dst = image<Dense>(a), alias = dst;
            if (mode == 1) dense_divide(left, right, left);
            else if (mode == 2) dense_divide(left, right, right);
            else {
                if (mode == 3) dst = left;
                if (mode == 4) dst = right;
                dense_divide(left, right, dst);
            }
            cv::Mat out;
            host(mode == 1 ? left : mode == 2 ? right : dst).convertTo(out, CV_64F);
            for (int i = 0; i < 257; ++i)
                require(out.at<double>(0,i) == i % 13 + 1, "order/tail quotient");
            if (mode == 0) {
                host(alias).convertTo(out, CV_64F);
                require(out.at<double>(0,256) == 10, "whole alias reused");
            }
        }
        Dense left = image<Dense>(a), right = image<Dense>(b);
        cv::Mat guards(3,259,depth,cv::Scalar(91));
        Dense parent = image<Dense>(guards);
        Dense dst = parent(cv::Rect(1,1,257,1)), alias = dst;
        dense_divide(left,right,dst);
        cv::Mat out; host(parent).convertTo(out,CV_64F);
        for (int r=0;r<3;++r) for(int c=0;c<259;++c)
            require(out.at<double>(r,c) ==
                    (r==1 && c>=1 && c<=257 ? (c-1)%13+1 : 91), "Region guards");
        alias.setTo(cv::Scalar(17)); host(dst).convertTo(out,CV_64F);
        require(out.at<double>(0,256)==17,"Region alias reused");
        // Ordinary mismatch: no preallocation compatibility correction.
        Dense mismatch = image<Dense>(cv::Mat(2,2,CV_64F,cv::Scalar(43)));
        dense_divide(left,right,mismatch);
        require(mismatch.type()==left.type() && mismatch.size()==left.size(),"native create");
        cv::Mat zeros(1,257,depth,cv::Scalar(0));
        Dense zero = image<Dense>(zeros);
        dense_divide(left,zero,dst);
        host(dst).convertTo(out,CV_64F);
        require(depth<=CV_32S ? out.at<double>(0,256)==0 :
                std::isinf(out.at<double>(0,256)),"finite/zero");
        dense_divide(zero,zero,dst); host(dst).convertTo(out,CV_64F);
        require(depth<=CV_32S ? out.at<double>(0,256)==0 :
                std::isnan(out.at<double>(0,256)),"zero/zero");
    }
    for (int depth : {CV_8U,CV_32F,CV_16F}) for (int mode=0;mode<4;++mode) {
        Dense a,b,dst=image<Dense>(cv::Mat(2,3,CV_16SC2,cv::Scalar(91,92)));
        Dense alias=dst;
        if(mode==1 || mode==3) a.create(0,0,depth);
        if(mode==1 || mode==2) b.create(0,0,depth);
        if(mode>1 && depth!=CV_8U) continue;
        try {
            dense_divide(a,b,dst);
            std::cout<<kind<<" empty depth="<<depth<<" mode="<<mode
                     <<" dims="<<dst.dims<<" rows="<<dst.rows<<" cols="<<dst.cols
                     <<" depth="<<dst.depth()<<" channels="<<dst.channels()<<'\n';
        } catch(const cv::Exception& e) { std::cout<<kind<<" empty native error "<<e.what()<<'\n'; }
        cv::Mat old = host(alias);
        require(old.at<cv::Vec2s>(1,2)==cv::Vec2s(91,92),"empty old alias lifetime");
    }
    std::cout<<kind<<" actual-helper reuse/Region/order/257/zero/half passed\n";
}
int main() {
    try {
        std::cout<<"OpenCV "<<CV_VERSION<<"; normal getDivTab path, no correction\n";
        cv::ocl::setUseOpenCL(false);
        run<cv::Mat>("Mat"); run<cv::UMat>("UMat");
        cv::Mat a(1,257,CV_16S),b(1,257,CV_16S),d;
        for(int i=0;i<257;++i) {
            a.at<short>(0,i)=i%3==0?7:i%3==1?5:-7;
            b.at<short>(0,i)=2;
        }
        dense_divide(a,b,d);
        for(int i=0;i<257;++i)
            require(d.at<short>(0,i)==(i%3==0?4:i%3==1?2:-4),"native rounding");
        std::cout<<"rounding 7/2=4, 5/2=2, -7/2=-4 (vector and tail)\n";
    } catch(const std::exception& e) { std::cerr<<e.what()<<'\n'; return 1; }
}