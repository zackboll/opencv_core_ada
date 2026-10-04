// Compile this translation unit alone: exercise the actual private helper.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <limits>
#include <cmath>

static int fresh_alias_differences = 0;
static void require(bool value, const char *message) {
    if (!value) throw std::runtime_error(message);
}
static cv::Mat host(const cv::Mat &m) { return m; }
static cv::Mat host(const cv::UMat &m) {
    cv::Mat result; m.copyTo(result); return result;
}
template<class Dense> static void native_alias(
    Dense &a, Dense &b, min_max_operation op, bool right) {
    Dense &dst=right?b:a;
#if CV_VERSION_MAJOR < 5
    if(a.depth()==CV_16F) {
        Dense x,y,z; a.convertTo(x,CV_32F); b.convertTo(y,CV_32F);
        if(op==min_max_operation::minimum) cv::min(x,y,z); else cv::max(x,y,z);
        z.convertTo(dst,CV_16F); return;
    }
#endif
    if(op==min_max_operation::minimum) cv::min(a,b,dst); else cv::max(a,b,dst);
}
template<class Dense> static Dense dense(const cv::Mat &m) {
    Dense result; m.copyTo(result); return result;
}
static void equal(const cv::Mat &a, const cv::Mat &b) {
    require(a.size == b.size && a.type() == b.type(), "layout parity");
    cv::Mat x, y; a.convertTo(x, CV_64F); b.convertTo(y, CV_64F);
    for (int r = 0; r < x.rows; ++r)
        for (int c = 0; c < x.cols*x.channels(); ++c) {
            double p=x.ptr<double>(r)[c], q=y.ptr<double>(r)[c];
            require((std::isnan(p) && std::isnan(q)) ||
                    (p == q && (p != 0 || std::signbit(p)==std::signbit(q))),
                    "value/classification/zero-sign parity");
        }
}
template<class Dense> static void run(min_max_operation op) {
    for (int depth : {CV_8U,CV_16S,CV_32S,CV_32F,CV_64F,CV_16F}) {
        cv::Mat x(2,257,CV_64FC3), y(2,257,CV_64FC3);
        for (int r=0;r<2;++r) for(int c=0;c<257*3;++c) {
            x.ptr<double>(r)[c]=c%13+1;
            y.ptr<double>(r)[c]=depth==CV_8U ? c%7+3 : -(c%7+3);
        }
        x.convertTo(x,depth); y.convertTo(y,depth);
        Dense a=dense<Dense>(x), b=dense<Dense>(y), expected;
        dense_min_max(a,b,expected,op);
        Dense dst=dense<Dense>(x), alias=dst;
        dense_min_max(a,b,dst,op); equal(host(dst),host(expected));
        equal(host(alias),host(expected));
        Dense parent=dense<Dense>(cv::Mat(4,260,x.type(),cv::Scalar::all(91)));
        dst=parent(cv::Rect(1,1,257,2)); alias=dst;
        dense_min_max(a,b,dst,op); equal(host(alias),host(expected));
        cv::Mat guard, result; host(parent).convertTo(guard, CV_64F);
        host(expected).convertTo(result,CV_64F);
        for(int r=0;r<4;++r) for(int c=0;c<260;++c) for(int ch=0;ch<3;++ch)
            require(guard.ptr<double>(r)[3*c+ch] ==
                    (r>=1 && r<=2 && c>=1 && c<=257 ?
                     result.ptr<double>(r-1)[3*(c-1)+ch] : 91),
                    "every Region result and outside guard");
        for(int mode=0;mode<4;++mode) {
            a=dense<Dense>(x); b=dense<Dense>(y);
            if(mode==0) dense_min_max(a,b,a,op);
            else if(mode==1) dense_min_max(a,b,b,op);
            else { dst=mode==2?a:b; dense_min_max(a,b,dst,op); }
            equal(host(mode==0?a:mode==1?b:dst),host(expected));
        }
        for(int old : {CV_8UC1,CV_16SC2,CV_64FC4}) {
            dst=dense<Dense>(cv::Mat(3,260,old,cv::Scalar::all(91)));
            alias=dst; dense_min_max(a,b,dst,op);
            equal(host(dst),host(expected));
            require(host(alias).type()==old,"mismatch old alias survives");
        }
    }
    const double nan=std::numeric_limits<double>::quiet_NaN();
    const double inf=std::numeric_limits<double>::infinity();
    const double pairs[][2]={{nan,3},{3,nan},{inf,3},{3,inf},{-inf,3},
        {3,-inf},{nan,nan},{inf,inf},{-inf,-inf},{0.,-0.},{-0.,0.}};
    for(int depth : {CV_32F,CV_64F,CV_16F}) for(const auto &pair:pairs) {
        cv::Mat x(1,257,CV_64F,cv::Scalar(pair[0]));
        cv::Mat y(1,257,CV_64F,cv::Scalar(pair[1]));
        x.convertTo(x,depth); y.convertTo(y,depth);
        Dense a=dense<Dense>(x), b=dense<Dense>(y), expected;
        dense_min_max(a,b,expected,op);
        cv::Mat h; host(expected).convertTo(h,CV_64F);
        std::cout << (op==min_max_operation::minimum?"min":"max")
                  << " depth=" << depth << " pair=" << pair[0] << ',' << pair[1]
                  << " first=" << h.at<double>(0,0)
                  << " sign=" << std::signbit(h.at<double>(0,0))
                  << " tail=" << h.at<double>(0,256)
                  << " sign=" << std::signbit(h.at<double>(0,256)) << '\n';
        for(int mode=0;mode<4;++mode) {
            a=dense<Dense>(x); b=dense<Dense>(y);
            Dense dst=mode%2==0?a:b;
            if(mode==0) dense_min_max(a,b,a,op);
            else if(mode==1) dense_min_max(a,b,b,op);
            else dense_min_max(a,b,dst,op);
            Dense oracle_a=dense<Dense>(x), oracle_b=dense<Dense>(y);
            native_alias(oracle_a,oracle_b,op,mode%2!=0);
            equal(host(mode==0?a:mode==1?b:dst),
                  host(mode%2==0?oracle_a:oracle_b));
            cv::Mat actual;
            host(mode==0?a:mode==1?b:dst).convertTo(actual,CV_64F);
            std::cout << "alias mode=" << mode << " first="
                      << actual.at<double>(0,0) << " tail="
                      << actual.at<double>(0,256) << " sign="
                      << std::signbit(actual.at<double>(0,256)) << '\n';
            try {
                equal(host(mode==0?a:mode==1?b:dst),host(expected));
            } catch (const std::runtime_error &e) {
                ++fresh_alias_differences;
                std::cout << "NATIVE FRESH/ALIAS DIFFERENCE: " << e.what() << '\n';
            }
        }
    }
    for(int layout=0;layout<3;++layout) {
        int type=layout==2?CV_32FC4:CV_32F, width=layout==1?4:1;
        Dense a=dense<Dense>(cv::Mat(1,width,type,cv::Scalar::all(3)));
        Dense b=dense<Dense>(cv::Mat(1,width,type,cv::Scalar::all(7)));
        Dense dst=dense<Dense>(cv::Mat(2,3,CV_16SC2,cv::Scalar::all(91)));
        dense_min_max(a,b,dst,op);
        require(dst.type()==type && dst.cols==width,"matching scalar-like arrays");
    }
    for(int mode=0;mode<4;++mode) for(int depth:{CV_8U,CV_32F,CV_16F}) {
        if(mode>=2 && depth!=CV_8U) continue;
        Dense a,b,dst=dense<Dense>(cv::Mat(2,3,CV_16SC2,cv::Scalar::all(91)));
        if(mode==1||mode==3) a.create(0,0,depth);
        if(mode==1||mode==2) b.create(0,0,depth);
        dense_min_max(a,b,dst,op);
        require(dst.empty(),"accepted empty");
        std::cout << "empty mode="<<mode<<" srcdepth="<<depth
                  <<" dims="<<dst.dims<<" type="<<dst.type()<<'\n';
    }
}
int main() {
    try {
        cv::ocl::setUseOpenCL(false);
        std::cout << CV_VERSION << '\n';
        for(bool optimized:{false,true}) {
            cv::setUseOptimized(optimized);
            std::cout << "optimized="<<optimized<<" Mat\n";
            for(auto op:{min_max_operation::minimum,min_max_operation::maximum})
                run<cv::Mat>(op);
            std::cout << "UMat CPU\n";
            for(auto op:{min_max_operation::minimum,min_max_operation::maximum})
                run<cv::UMat>(op);
        }
        for(auto op:{min_max_operation::minimum,min_max_operation::maximum})
            for(int old:{CV_8U,CV_16SC2,CV_64FC4}) {
                cv::Mat a(2,257,CV_32F,cv::Scalar(3));
                cv::Mat scalar(1,1,CV_64F,cv::Scalar(7));
                cv::Mat dst(3,260,old,cv::Scalar::all(91));
                dense_min_max(a,scalar,dst,op);
                require(dst.type()==CV_32F,"raw scalar output uses array type");
                dense_min_max(scalar,a,dst,op);
                require(dst.type()==CV_32F,"raw scalar-first output width");
            }
        std::cout << "native fresh/alias differences=" << fresh_alias_differences << '\n';
        // Fresh-output parity differences are diagnostic native observations,
        // not failures under the revised contract. Native alias parity is strict.
        std::cout << "PASS actual-helper reuse/aliases/specials/empty/scalar\n";
    } catch(const std::exception &e) { std::cerr << e.what()<<'\n'; return 1; }
}