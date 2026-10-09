// Standalone research probe: exercise the actual production helpers.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

static void require(bool ok, const char *why) {
    if (!ok) throw std::runtime_error(why);
}
static cv::Mat observe(const cv::Mat &a) { return a; }
static cv::Mat observe(const cv::UMat &a) { return a.getMat(cv::ACCESS_READ); }
template<class Dense>
static void apply(const Dense &x, const Dense &y, Dense &d, int op, bool native) {
    if (op == 0) {
        if (native) cv::magnitude(x, y, d); else dense_magnitude(x, y, d);
    } else {
        if (native) cv::phase(x, y, d, op == 1);
        else dense_phase(x, y, d, op == 1);
    }
}
static double value(const cv::Mat &a, size_t i) {
    return a.depth() == CV_32F ? a.ptr<float>()[i] : a.ptr<double>()[i];
}
static void equal(const cv::Mat &a, const cv::Mat &b) {
    require(a.type() == b.type() && a.size == b.size, "metadata parity");
    for (int r = 0; r < a.rows; ++r) {
        const cv::Mat ar = a.row(r), br = b.row(r);
        for (size_t i = 0; i < ar.total() * a.channels(); ++i) {
            const double x = value(ar, i), y = value(br, i);
            require((std::isnan(x) && std::isnan(y)) || x == y ||
                    std::abs(x-y) <= 1e-6 * std::max(1., std::abs(y)),
                    "helper/direct-native parity");
        }
    }
}
static void finite(const cv::Mat &x, const cv::Mat &y, const cv::Mat &d, int op) {
    for (int r = 0; r < x.rows; ++r) {
        const cv::Mat xr=x.row(r), yr=y.row(r), dr=d.row(r);
        for (size_t i=0; i<xr.total()*x.channels(); ++i) {
            const double a=value(xr,i), b=value(yr,i), actual=value(dr,i);
            if (op == 0) {
                const double expected=std::sqrt(a*a+b*b);
                require(std::abs(actual-expected) <= 1e-5*std::max(expected,1e-30),
                        "original-source finite magnitude");
            } else {
                const double pi=std::acos(-1.), period=op == 1 ? 360. : 2*pi;
                double expected=std::atan2(b,a)*period/(2*pi);
                if (expected<0) expected+=period;
                const double delta=std::abs(actual-expected);
                require(std::min(delta,std::abs(period-delta)) < period*.3/360.,
                        "original-source finite phase");
            }
        }
    }
}
template<class Dense>
static Dense source(int type, bool second) {
    cv::Mat host(2, 257, type);
    for (size_t i = 0; i < host.total() * host.channels(); ++i) {
        const double v = (i % 2 ? -1 : 1) * (.25 + (i % 17) / 8.);
        const double w = second ? (i % 3 ? v / 2 : -v * 3) : v;
        if (host.depth() == CV_32F) host.ptr<float>()[i] = static_cast<float>(w);
        else host.ptr<double>()[i] = w;
    }
    Dense result;
    host.copyTo(result);
    return result;
}
template<class Dense>
static void cases(const char *name) {
    for (int depth : {CV_32F, CV_64F}) for (int cn : {1, 3})
      for (int op : {0, 1, 2}) {
        const int type = CV_MAKETYPE(depth, cn);
        for (int mode = 0; mode < 10; ++mode) {
            Dense x = source<Dense>(type, false), y = source<Dense>(type, true);
            Dense nx = source<Dense>(type, false), ny = source<Dense>(type, true);
            Dense parent(5, 261, type), np(5, 261, type);
            parent.setTo(cv::Scalar::all(91)); np.setTo(cv::Scalar::all(91));
            Dense d = mode == 1 ? parent(cv::Rect(2, 1, 257, 2)) : Dense(2,257,type);
            Dense nd = mode == 1 ? np(cv::Rect(2, 1, 257, 2)) : Dense(2,257,type);
            if (mode == 2) { d = Dense(3, 7, type); nd = Dense(3, 7, type); }
            if (mode == 3) { d = Dense(2,257,CV_MAKETYPE(CV_16S,cn)); nd = Dense(2,257,CV_MAKETYPE(CV_16S,cn)); }
            if (mode == 4) { d = Dense(2,257,CV_MAKETYPE(depth,cn == 1 ? 3 : 1)); nd = Dense(2,257,CV_MAKETYPE(depth,cn == 1 ? 3 : 1)); }
            if (mode == 7) { d = x; nd = nx; }
            if (mode == 8) { d = y; nd = ny; }
            if (mode == 9) { y = x; ny = nx; d = x; nd = nx; }
            const cv::Mat original_x=observe(x).clone(), original_y=observe(y).clone();
            Dense retained = d;
            if (mode == 5) { apply(nx,ny,nx,op,true); apply(x,y,x,op,false); equal(observe(x),observe(nx)); }
            else if (mode == 6) { apply(nx,ny,ny,op,true); apply(x,y,y,op,false); equal(observe(y),observe(ny)); }
            else {
                apply(nx,ny,nd,op,true); apply(x,y,d,op,false);
                equal(observe(d),observe(nd));
                if (mode == 0 || mode == 1 || mode >= 7)
                    require(d.u == retained.u, "compatible output retained");
                if (mode >= 2 && mode <= 4)
                    require(d.u != retained.u, "incompatible output detached");
            }
            if (mode == 1) equal(observe(parent),observe(np));
            finite(original_x,original_y,
                   observe(mode == 5 ? x : mode == 6 ? y : d),op);
        }
      }
    std::cout << name << " whole/Region/mismatch/exact/shallow/X=Y PASS\n";
}
template<class Dense>
static void empties(const char *name, bool native) {
    for (int depth : {CV_32F,CV_64F}) for (int op : {0,1,2}) {
        Dense x(0,0,depth), y(0,0,depth), fresh, d(2,3,CV_16SC3);
        Dense old = d;
        apply(x,y,fresh,op,native); apply(x,y,d,op,native);
        require(d.empty() && !old.empty(), "empty release and alias survival");
        std::cout << name << " typed empty native=" << native << " op=" << op
                  << " depth=" << depth << " fresh=" << fresh.dims << '/'
                  << fresh.type() << " reused=" << d.dims << '/' << d.type() << '\n';
    }
}
template<class Dense>
static void special(const char *name) {
    for (int depth : {CV_32F,CV_64F}) for (int op : {0,1,2}) {
        const double inf = std::numeric_limits<double>::infinity();
        const double nan = std::numeric_limits<double>::quiet_NaN();
        const double xs[] = {0.,-0.,inf,-inf,nan,1.,inf};
        const double ys[] = {-0.,0.,1.,-1.,2.,nan,inf};
        cv::Mat hx(1,7,depth), hy(1,7,depth);
        for (size_t i = 0; i < 7; ++i) {
            if (depth == CV_32F) {
                hx.ptr<float>()[i] = static_cast<float>(xs[i]);
                hy.ptr<float>()[i] = static_cast<float>(ys[i]);
            } else { hx.ptr<double>()[i] = xs[i]; hy.ptr<double>()[i] = ys[i]; }
        }
        Dense x,y,fresh,reused(1,7,depth),native;
        hx.copyTo(x); hy.copyTo(y);
        apply(x,y,fresh,op,false); apply(x,y,reused,op,false);
        apply(x,y,native,op,true);
        equal(observe(fresh),observe(reused));
        equal(observe(fresh),observe(native));
        std::cout << name << " special depth=" << depth << " op=" << op << ':';
        const cv::Mat output = observe(reused);
        for (size_t i = 0; i < 7; ++i)
            std::cout << ' ' << std::fpclassify(value(output,i));
        std::cout << " PASS\n";
    }
}
int main(int argc, char **argv) {
    try {
        const bool requested = argc > 1 && std::string(argv[1]) == "--opencl";
        cv::ocl::setUseOpenCL(requested);
        std::cout << CV_VERSION << " OpenCL requested=" << requested
                  << " enabled=" << cv::ocl::useOpenCL()
                  << " GPU execution not demonstrated\n";
        if (argc > 1 && std::string(argv[1]) == "--raw-empty") {
            empties<cv::UMat>("UMat",true);
            return 0;
        }
        cases<cv::Mat>("Mat"); cases<cv::UMat>("UMat");
        empties<cv::Mat>("Mat",false); empties<cv::Mat>("Mat",true);
        empties<cv::UMat>("UMat",false);
        special<cv::Mat>("Mat"); special<cv::UMat>("UMat");
        std::cout << "PASS\n";
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n'; return 1;
    }
}