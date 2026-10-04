// Standalone translation unit: exercise the actual private production helpers.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <cmath>
#include <iostream>
#include <limits>
#include <iomanip>

enum class operation { weighted, scaled };
static int differences = 0;
static void require(bool test, const char *message) {
    if (!test) throw std::runtime_error(message);
}
static cv::Mat host(const cv::Mat &m) { return m; }
static cv::Mat host(const cv::UMat &m) {
    cv::Mat result; m.copyTo(result); return result;
}
template<class Dense> static double magnitude(const Dense &m) {
    cv::Mat wide; host(m).convertTo(wide,CV_64F);
    return cv::norm(wide,cv::NORM_INF);
}
template<class Dense> static Dense dense(const cv::Mat &m) {
    Dense result; m.copyTo(result); return result;
}
template<class Dense> static void apply(const Dense &a, const Dense &b,
    Dense &dst, operation op, double alpha=2.5, double beta=-3.0,
    double gamma=5.0) {
    if (op==operation::weighted)
        dense_add_weighted(a,alpha,b,beta,gamma,dst);
    else dense_scale_add(a,alpha,b,dst);
}
// Independent direct-native oracle; never calls a new export or dense helper.
template<class Dense> static void native(const Dense &a, const Dense &b,
    Dense &dst, operation op, double alpha, double beta, double gamma) {
    if (a.depth()==CV_16F &&
        (op==operation::scaled || CV_VERSION_MAJOR<5)) {
        Dense x,y,z; a.convertTo(x,CV_32F); b.convertTo(y,CV_32F);
        if (op==operation::weighted) cv::addWeighted(x,alpha,y,beta,gamma,z);
        else cv::scaleAdd(x,static_cast<float>(alpha),y,z);
        z.convertTo(dst,CV_16F);
    } else if (op==operation::weighted)
        cv::addWeighted(a,alpha,b,beta,gamma,dst);
    else cv::scaleAdd(a,alpha,b,dst);
}
static bool equal(const cv::Mat &a, const cv::Mat &b) {
    require(a.size==b.size && a.type()==b.type(),"layout parity");
    if (a.depth()==CV_32S) {
        cv::Mat x=a.clone(),y=b.clone();
        for (size_t i=0;i<a.total()*a.channels();++i)
            if (x.ptr<int>()[i]!=y.ptr<int>()[i]) return false;
        return true;
    }
    cv::Mat x,y; a.convertTo(x,CV_64F); b.convertTo(y,CV_64F);
    x=x.reshape(1,1); y=y.reshape(1,1);
    for (int i=0;i<x.cols;++i) {
        double p=x.at<double>(0,i), q=y.at<double>(0,i);
        if (!((std::isnan(p)&&std::isnan(q)) ||
              (p==q && (p!=0 || std::signbit(p)==std::signbit(q)))))
            return false;
    }
    return true;
}
template<class Dense> static void run(operation op) {
    for (int depth:{CV_8U,CV_16S,CV_32S,CV_32F,CV_64F,CV_16F}) {
        cv::Mat x(2,257,CV_64FC3),y(2,257,CV_64FC3);
        for(int r=0;r<2;++r) for(int c=0;c<771;++c) {
            x.ptr<double>(r)[c]=c%13+1;
            y.ptr<double>(r)[c]=c%7+3;
        }
        x.convertTo(x,depth); y.convertTo(y,depth);
        Dense a=dense<Dense>(x),b=dense<Dense>(y),expected;
        apply(a,b,expected,op);
        Dense dst=dense<Dense>(x),alias=dst;
        apply(a,b,dst,op);
        require(equal(host(dst),host(expected)),"whole reuse parity");
        require(equal(host(alias),host(expected)),"whole alias attached");
        alias.setTo(cv::Scalar::all(23));
        require(magnitude(dst)==23,"alias write");
        dst.setTo(cv::Scalar::all(25));
        require(magnitude(alias)==25,"destination write");
        Dense parent=dense<Dense>(cv::Mat(4,260,x.type(),cv::Scalar::all(91)));
        dst=parent(cv::Rect(1,1,257,2)); alias=dst;
        cv::Size whole; cv::Point offset; dst.locateROI(whole,offset);
        apply(a,b,dst,op);
        require(equal(host(alias),host(expected)),"Region reuse/narrowing");
        cv::Size after; cv::Point point; dst.locateROI(after,point);
        require(after==whole && point==offset,"Region geometry");
        cv::Mat p,e; host(parent).convertTo(p,CV_64F);
        host(expected).convertTo(e,CV_64F);
        for(int r=0;r<4;++r) for(int c=0;c<260;++c) for(int ch=0;ch<3;++ch)
            require(p.ptr<double>(r)[3*c+ch]==
                (r>=1&&r<=2&&c>=1&&c<=257 ?
                 e.ptr<double>(r-1)[3*(c-1)+ch]:91),"every Region guard");
        for(int mode=0;mode<7;++mode) {
            a=dense<Dense>(x); b=dense<Dense>(mode>=4?x:y);
            Dense fresh; apply(a,b,fresh,op);
            dst=mode==2||mode==6?a:b;
            if(mode==0||mode==5) apply(a,b,a,op);
            else if(mode==1) apply(a,b,b,op);
            else if(mode==4) { dst=Dense(); apply(a,a,dst,op); }
            else apply(a,mode==6?a:b,dst,op);
            require(equal(host(mode==0||mode==5?a:mode==1?b:dst),host(fresh)),
                    "finite integer/exact-binary alias and A/A ordering");
        }
        a=dense<Dense>(x); b=dense<Dense>(y);
        for(int old:{CV_8UC1,CV_16SC2,CV_64FC4}) {
            dst=dense<Dense>(cv::Mat(3,260,old,cv::Scalar::all(91)));
            alias=dst; apply(a,b,dst,op);
            require(equal(host(dst),host(expected)),"old layout harmless");
            require(magnitude(alias)==91,"old alias survives");
        }
        // Coefficient precision witness, including UInt8/Int16 rounding.
        const double coefficient=depth==CV_8U||depth==CV_16S?1.49999999:1.00000001;
        a=dense<Dense>(cv::Mat(1,257,depth,cv::Scalar(1)));
        b=dense<Dense>(cv::Mat(1,257,depth,cv::Scalar(
            depth==CV_8U||depth==CV_16S?0:-1)));
        apply(a,b,dst,op,coefficient,1,0);
        cv::Mat rounded; host(dst).convertTo(rounded,CV_64F);
        std::cout<<"coefficient op="<<int(op)<<" depth="<<depth
                 <<" first="<<rounded.at<double>(0,0)
                 <<" tail="<<rounded.at<double>(0,256)<<'\n';
        if(depth==CV_8U||depth==CV_16S)
            require(rounded.at<double>(0,256)==2,"float coefficient integer rounding");
        if(depth==CV_32S)
            require(host(dst).template at<int>(0,256)==0,"exact Int32 double coefficient");
        if(depth==CV_32S) {
            cv::Mat exact(1,257,CV_32S),zero(1,257,CV_32S,cv::Scalar(0));
            for(int c=0;c<257;++c) exact.at<int>(0,c)=c%2?-100000001:100000001;
            a=dense<Dense>(exact); b=dense<Dense>(zero);
            apply(a,b,dst,op,2,0,0);
            cv::Mat storage=host(dst);
            Dense oracle;
            native(a,b,oracle,op,2,0,0);
            require(equal(storage,host(oracle)),"large Int32 native storage parity");
            int rounded_count=0;
            for(int c=0;c<257;++c)
                if(storage.at<int>(0,c)!=exact.at<int>(0,c)*2) ++rounded_count;
            std::cout<<"exact Int32 first="<<storage.at<int>(0,0)
                     <<" tail="<<storage.at<int>(0,256)
                     <<" native rounded count="<<rounded_count<<'\n';
        }
        if(depth==CV_64F)
            require(std::abs(rounded.at<double>(0,256)-0.00000001)<1e-12,
                    "double coefficient retained");
        if(depth==CV_8U||depth==CV_16S) {
            cv::Mat fixture(1,257,CV_64F),other(1,257,CV_64F);
            for(int c=0;c<257;++c) {
                fixture.at<double>(0,c)=depth==CV_8U?200:(c%2? -20000:20000);
                other.at<double>(0,c)=depth==CV_8U?(c%2?200:0):0;
            }
            fixture.convertTo(fixture,depth); other.convertTo(other,depth);
            a=dense<Dense>(fixture); b=dense<Dense>(other);
            apply(a,b,dst,op,depth==CV_8U&&op==operation::scaled?-2:2,-3,5);
            cv::Mat h; host(dst).convertTo(h,CV_64F);
            for(int c=0;c<257;++c) require(h.at<double>(0,c)==
                (depth==CV_8U?(op==operation::scaled?0:(c%2?0:255)):
                 (c%2?-32768:32767)),"each integer saturation endpoint");
        }
    }
    for(int depth:{CV_32F,CV_64F,CV_16F}) for(bool special:{false,true}) {
        cv::Mat x(1,257,CV_64F),y(1,257,CV_64F);
        const double inf=std::numeric_limits<double>::infinity();
        const double nan=std::numeric_limits<double>::quiet_NaN();
        const double values[]={1.0000001192092896,-1.0000002384185791,
                               inf,-inf,nan,0.0,-0.0};
        for(int c=0;c<257;++c) {
            x.at<double>(0,c)=special?values[c%7]:1.0000001192092896*(c%17+1);
            y.at<double>(0,c)=special?values[(c+3)%7]:-1.0000002384185791*(c%11+1);
        }
        x.convertTo(x,depth); y.convertTo(y,depth);
        for(double alpha:{1.00000006,inf,nan,-0.0}) {
            if(!special && !std::isfinite(alpha)) continue;
            Dense a=dense<Dense>(x),b=dense<Dense>(y),fresh;
            apply(a,b,fresh,op,alpha,-0.333333333333,0.00000007);
            for(int mode=0;mode<4;++mode) {
                a=dense<Dense>(x); b=dense<Dense>(y);
                Dense dst=mode%2==0?a:b;
                if(mode==0) apply(a,b,a,op,alpha,-0.333333333333,0.00000007);
                else if(mode==1) apply(a,b,b,op,alpha,-0.333333333333,0.00000007);
                else apply(a,b,dst,op,alpha,-0.333333333333,0.00000007);
                Dense oa=dense<Dense>(x),ob=dense<Dense>(y);
                native(oa,ob,mode%2==0?oa:ob,op,alpha,-0.333333333333,0.00000007);
                cv::Mat actual=host(mode==0?a:mode==1?b:dst);
                require(equal(actual,host(mode%2==0?oa:ob)),"direct native alias oracle");
                if(!equal(actual,host(fresh))) {
                    ++differences;
                    std::cout<<"FRESH/ALIAS DIFFERENCE op="<<int(op)
                             <<" depth="<<depth<<" mode="<<mode
                             <<" special="<<special<<" alpha="<<alpha<<'\n';
                }
            }
        }
    }
    if(op==operation::weighted) for(int depth:{CV_8U,CV_32F,CV_16F}) {
        int shape[]={2,3,5};
        Dense a=dense<Dense>(cv::Mat(3,shape,depth,cv::Scalar(7)));
        Dense b=dense<Dense>(cv::Mat(3,shape,depth,cv::Scalar(3))),dst=a.clone();
        Dense alias=dst,expected; apply(a,b,expected,op); apply(a,b,dst,op);
        require(dst.dims==3 && equal(host(alias),host(expected)),"N-D reuse");
        dst=dense<Dense>(cv::Mat(2,3,CV_64FC3,cv::Scalar::all(91)));
        apply(a,b,dst,op);
        require(dst.dims==3 && equal(host(dst),host(expected)),"N-D reallocation");
    }
    for(int mode=0;mode<4;++mode) for(int depth:{CV_8U,CV_32F,CV_16F}) {
        Dense a,b,dst=dense<Dense>(cv::Mat(2,3,CV_16SC2,cv::Scalar::all(91)));
        if(mode==1||mode==3) a.create(0,0,depth);
        if(mode==1||mode==2) b.create(0,0,depth);
        Dense alias=dst;
        try {
            apply(a,b,dst,op);
            std::cout<<"empty op="<<int(op)<<" mode="<<mode<<" depth="<<depth
                     <<" dims="<<dst.dims<<" type="<<dst.type()<<'\n';
        } catch(const cv::Exception &e) {
            std::cout<<"empty native error op="<<int(op)<<" mode="<<mode
                     <<" depth="<<depth<<" code="<<e.code<<'\n';
        }
        require(magnitude(alias)==91,"empty old alias survives");
    }
}
int main() {
    try {
        cv::ocl::setUseOpenCL(false);
        std::cout<<std::setprecision(17);
        std::cout<<CV_VERSION<<'\n';
        for(bool optimized:{false,true}) {
            cv::setUseOptimized(optimized);
            // setUseOptimized also toggles OpenCL eligibility: keep this probe
            // explicitly CPU while varying only optimized CPU dispatch.
            cv::ocl::setUseOpenCL(false);
            for(auto op:{operation::weighted,operation::scaled}) {
                std::cout<<"optimized="<<optimized<<" op="<<int(op)<<" Mat\n";
                run<cv::Mat>(op);
                std::cout<<"UMat CPU\n"; run<cv::UMat>(op);
            }
        }
        std::cout<<"PASS actual helpers; fresh/alias differences="<<differences<<'\n';
    } catch(const std::exception &e) { std::cerr<<e.what()<<'\n'; return 1; }
}