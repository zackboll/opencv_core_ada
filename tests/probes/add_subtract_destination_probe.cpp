// Test-only probe of the actual private compatibility helper, not a second
// implementation. Compile this translation unit alone (it includes the shim).
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

template <typename Dense>
static void run(const char *name) {
    for (int depth : {CV_32F, CV_16F}) {
        cv::Mat ah(1, 257, CV_32F), bh(1, 257, CV_32F);
        for (int i = 0; i < 257; ++i) {
            ah.at<float>(0, i) = (i % 31 - 15) * 0.5f;
            bh.at<float>(0, i) = (i % 17 - 8) * 0.25f;
        }
        ah.convertTo(ah, depth);
        bh.convertTo(bh, depth);
        for (bool subtract : {false, true}) {
            for (int mode = 0; mode < 7; ++mode) {
                Dense a, b, dst, expected;
                setup(ah, a);
                setup(bh, b);
                if (mode >= 5) b = a;
                dense_add_or_subtract(a, b, expected, subtract);
                if (mode == 1 || mode == 3 || mode >= 5) dst = a;
                else if (mode == 2 || mode == 4) dst = b;
                else dst.create(1, 257, depth);
                Dense alias = dst;
                Dense &output = mode == 1 || mode == 5 ? a :
                                mode == 2 ? b : dst;
                dense_add_or_subtract(a, b, output, subtract);
                cv::Mat actual32, expected32;
                observe(alias).convertTo(actual32, CV_32F);
                observe(expected).convertTo(expected32, CV_32F);
                require(cv::norm(actual32, expected32, cv::NORM_INF) == 0,
                        "alias/vector/tail parity");
                alias.setTo(13);
                observe(output).convertTo(actual32, CV_32F);
                require(actual32.at<float>(0, 256) == 13, "reuse after alias");
            }
            Dense a, b, parent(5, 7, depth), dst;
            setup(ah.colRange(0, 3).clone(), a);
            setup(bh.colRange(0, 3).clone(), b);
            parent.setTo(91);
            dst = parent(cv::Rect(2, 1, 3, 1));
            Dense alias = dst;
            auto *allocation = dst.u;
            dense_add_or_subtract(a, b, dst, subtract);
            require(dst.u == allocation && alias.u == dst.u, "Region reuse");
            alias.setTo(23);
            cv::Mat p32;
            observe(parent).convertTo(p32, CV_32F);
            require(p32.at<float>(1, 2) == 23 &&
                    p32.at<float>(0, 0) == 91, "Region parent/guards");
            Dense wrong = parent(cv::Rect(2, 1, 2, 1));
            Dense old = wrong;
            dense_add_or_subtract(a, b, wrong, subtract);
            require(wrong.u != old.u && old.u == parent.u, "detach mismatch");
        }
    }
    for (int depth : {CV_8U, CV_32F, CV_16F}) {
        for (int mode = 0; mode < 4; ++mode) {
            // Mixed empties are publicly compatible only at UInt8 C1.
            if (mode >= 2 && depth != CV_8U) continue;
            Dense a, b;
            if (mode == 1 || mode == 3) a.create(0, 0, depth);
            if (mode == 1 || mode == 2) b.create(0, 0, depth);
            for (bool subtract : {false, true}) {
                Dense result, dst(2, 3, CV_16SC2);
                dst.setTo(cv::Scalar(91, 92));
                Dense alias = dst;
                dense_add_or_subtract(a, b, result, subtract);
                dense_add_or_subtract(a, b, dst, subtract);
                require(dst.empty() && !alias.empty(), "empty releases only dst");
                std::cout << name << " empty depth=" << depth << " mode="
                          << mode << " sub=" << subtract
                          << " function=" << result.dims << '/' << result.type()
                          << " destination=" << dst.dims << '/' << dst.type()
                          << '\n';
            }
        }
    }
    for (int depth : {CV_8U, CV_8S}) {
        Dense a(2, 257, depth), b(2, 257, depth);
        Dense parent(5, 260, CV_32F);
        parent.setTo(91);
        Dense dst = parent(cv::Rect(1, 1, 257, 2));
        Dense old = dst;
        a.setTo(13);
        b.setTo(5);
        dense_add_or_subtract(a, b, dst, true);
        cv::Mat actual32;
        observe(dst).convertTo(actual32, CV_32F);
        require(cv::countNonZero(actual32 != 8) == 0, "old-depth dispatch");
        require(dst.u != old.u && old.u == parent.u, "old-depth detachment");
        require(cv::countNonZero(observe(parent) != 91) == 0,
                "old-depth parent preservation");
    }
    std::cout << name << " aliases/half/Region/detach PASS\n";
}

int main() {
    try {
        cv::ocl::setUseOpenCL(false);
        std::cout << CV_VERSION << " OpenCL=" << cv::ocl::useOpenCL() << '\n';
        run<cv::Mat>("Mat");
        run<cv::UMat>("UMat");
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}