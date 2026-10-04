// Compile alone: this exercises the production private helper, not a copy.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <stdexcept>

static void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
static cv::Mat observe(const cv::Mat &a) { return a; }
static cv::Mat observe(const cv::UMat &a) { return a.getMat(cv::ACCESS_READ); }
static void setup(const cv::Mat &a, cv::Mat &b) { a.copyTo(b); }
static void setup(const cv::Mat &a, cv::UMat &b) { a.copyTo(b); }

// Link with --wrap for cv::multiply (see source findings). Observe the actual
// layout at the helper's native call, regardless of whether a HAL implements
// either extended-width kernel. No unsafe raw multiply is executed here.
static int byte_calls = 0;
static bool audit_old_layout = false;
void real_multiply(cv::InputArray, cv::InputArray, cv::OutputArray, double, int)
    asm("__real__ZN2cv8multiplyERKNS_11_InputArrayES2_RKNS_12_OutputArrayEdi");
void audited_multiply(cv::InputArray, cv::InputArray, cv::OutputArray, double, int)
    asm("__wrap__ZN2cv8multiplyERKNS_11_InputArrayES2_RKNS_12_OutputArrayEdi");
void audited_multiply(cv::InputArray a, cv::InputArray b, cv::OutputArray dst,
                      double scale, int dtype) {
    require(scale == 1.0 && dtype == -1, "unchanged scale/dtype");
    if (audit_old_layout) {
#if CV_VERSION_MAJOR >= 5 || (CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR >= 10)
        require((a.depth() == CV_8U && dst.depth() == CV_16U) ||
                (a.depth() == CV_8S && dst.depth() == CV_16S),
                "audit expected uncorrected old-width layout");
        std::cout << "observed native selector input=" << a.depth()
                  << " old output=" << dst.depth()
                  << " (unsafe call intercepted, not executed)\n";
#else
        std::cout << "no extended selector in this exact version\n";
#endif
        return;
    }
#if CV_VERSION_MAJOR >= 5 || (CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR >= 10)
    if (!a.empty() && a.type() == b.type()) {
        require(!((a.depth() == CV_8U && dst.depth() == CV_16U) ||
                  (a.depth() == CV_8S && dst.depth() == CV_16S)),
                "native old-depth selector still selects 16-bit writes");
        if (a.depth() == CV_8U || a.depth() == CV_8S) {
            require(dst.type() == a.type() && dst.size() == a.size(),
                    "correct byte layout before native selector");
            ++byte_calls;
        }
    }
#endif
    real_multiply(a, b, dst, scale, dtype);
}

template <typename Dense>
static void run(const char *name) {
    for (int depth : {CV_8U, CV_8S}) {
        Dense a(2, 257, depth), b(2, 257, depth);
        const int old_depth = depth == CV_8U ? CV_16U : CV_16S;
        Dense parent(5, 260, old_depth);
        parent.setTo(91);
        Dense dst = parent(cv::Rect(1, 1, 257, 2));
        Dense alias = dst;
        a.setTo(depth == CV_8U ? 20 : -11);
        b.setTo(20);
        std::cout << name << " old-depth " << depth << " -> " << old_depth
#if CV_VERSION_MAJOR >= 5 || (CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR >= 10)
                  << " source selector="
                  << (depth == CV_8U ? "mul8u16uWrapper" : "mul8s16sWrapper")
#else
                  << " no getMulExtFunc"
#endif
                  << std::endl;
        dense_multiply(a, b, dst);
        if (audit_old_layout) continue;
        cv::Mat values;
        observe(dst).convertTo(values, CV_32F);
        require(cv::countNonZero(values != (depth == CV_8U ? 255 : -128)) == 0,
                "every byte product including tail saturates");
        require(dst.type() == depth && dst.rows == 2 && dst.cols == 257,
                "byte output shape/type");
        require(dst.u != alias.u && alias.u == parent.u, "Region detachment");
        require(cv::countNonZero(observe(parent) != 91) == 0,
                "every old parent/alias pixel survives");
        dst.setTo(17);
        require(cv::countNonZero(observe(parent) != 91) == 0,
                "independent new output");
        alias.setTo(23);
        require(cv::countNonZero(observe(dst) != 17) == 0,
                "old alias remains independent");
    }
    if (audit_old_layout) return;
    for (int depth : {CV_32F, CV_64F, CV_16F}) {
        cv::Mat ah(1, 257, CV_32F), bh(1, 257, CV_32F);
        for (int i = 0; i < 257; ++i) {
            ah.at<float>(0, i) = (i % 31 - 15) * 0.5f;
            bh.at<float>(0, i) = (i % 17 - 8) * 0.25f;
        }
        ah.convertTo(ah, depth);
        bh.convertTo(bh, depth);
        for (int mode = 0; mode < 7; ++mode) {
            Dense a, b, dst, expected;
            setup(ah, a);
            setup(bh, b);
            if (mode >= 5) b = a;
            dense_multiply(a, b, expected);
            if (mode == 1 || mode == 3 || mode >= 5) dst = a;
            else if (mode == 2 || mode == 4) dst = b;
            else dst.create(1, 257, depth);
            Dense alias = dst;
            Dense &output = mode == 1 || mode == 5 ? a : mode == 2 ? b : dst;
            dense_multiply(a, b, output);
            cv::Mat actual32, expected32;
            observe(alias).convertTo(actual32, CV_32F);
            observe(expected).convertTo(expected32, CV_32F);
            require(cv::norm(actual32, expected32, cv::NORM_INF) == 0,
                    "alias/vector/tail parity");
            alias.setTo(13);
            observe(output).convertTo(actual32, CV_32F);
            require(cv::countNonZero(actual32 != 13) == 0, "whole reuse");
        }
        Dense a, b, parent(5, 260, depth);
        setup(ah, a);
        setup(bh, b);
        parent.setTo(91);
        Dense dst = parent(cv::Rect(1, 1, 257, 1)), alias = dst;
        auto *allocation = dst.u;
        dense_multiply(a, b, dst);
        require(dst.u == allocation && alias.u == dst.u, "Region reuse");
        cv::Mat p32;
        observe(parent).convertTo(p32, CV_32F);
        for (int r = 0; r < 5; ++r)
            for (int c = 0; c < 260; ++c)
                require(p32.at<float>(r, c) ==
                    (r == 1 && c >= 1 && c <= 257 ?
                     ((c - 1) % 31 - 15) * 0.5f *
                     ((c - 1) % 17 - 8) * 0.25f : 91), "Region/guards");
        alias.setTo(23);
        observe(parent).convertTo(p32, CV_32F);
        require(p32.at<float>(1, 257) == 23, "Region alias parent write");
    }
    for (int depth : {CV_8U, CV_32F, CV_16F}) {
        for (int mode = 0; mode < 4; ++mode) {
            if (mode >= 2 && depth != CV_8U) continue;
            Dense a, b;
            if (mode == 1 || mode == 3) a.create(0, 0, depth);
            if (mode == 1 || mode == 2) b.create(0, 0, depth);
            Dense result, dst(2, 3, CV_16SC2);
            dst.setTo(cv::Scalar(91, 92));
            Dense alias = dst;
            dense_multiply(a, b, result);
            dense_multiply(a, b, dst);
            require(dst.empty() && !alias.empty(), "empty releases only dst");
            std::cout << name << " empty depth=" << depth << " mode=" << mode
                      << " function=" << result.dims << '/' << result.type()
                      << " destination=" << dst.dims << '/' << dst.type() << '\n';
        }
    }
    std::cout << name << " old-depth/aliases/half/Region PASS\n";
}
int main(int argc, char **argv) {
    try {
        if (argc == 2 && std::string(argv[1]) == "--audit-old-layout")
            audit_old_layout = true;
        else
            require(argc == 1, "usage: probe [--audit-old-layout]");
        cv::ocl::setUseOpenCL(false);
        std::cout << CV_VERSION << " OpenCL=" << cv::ocl::useOpenCL() << '\n';
        run<cv::Mat>("Mat");
        run<cv::UMat>("UMat");
        std::cout << "audited pre-native byte calls=" << byte_calls << '\n';
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}