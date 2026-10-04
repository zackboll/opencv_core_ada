// Isolate Scalar construction, native selection and widening; compile alone.
#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <algorithm>
#include <iostream>
#include <limits>
#include <stdexcept>

static cv::Mat host(const cv::Mat &m) { return m; }
static cv::Mat host(const cv::UMat &m) {
    cv::Mat result;
    m.copyTo(result);
    return result;
}
template<class Dense> static Dense transfer(const cv::Mat &m) {
    Dense result;
    m.copyTo(result);
    return result;
}
static void check(const cv::Mat &m, const cv::Vec3i &expected) {
    for (int r = 0; r < m.rows; ++r)
        for (int c = 0; c < m.cols; ++c)
            for (int ch = 0; ch < 3; ++ch)
                if (m.at<cv::Vec3i>(r, c)[ch] != expected[ch])
                    throw std::runtime_error("exact Int32 C3 selection failed");
}
template<class Dense> static void selection(
    const cv::Mat &left, const cv::Mat &right, bool maximum) {
    Dense a = transfer<Dense>(left), b = transfer<Dense>(right), fresh;
    Dense reused = transfer<Dense>(left);
    check(host(a), left.at<cv::Vec3i>(0, 0));
    check(host(b), right.at<cv::Vec3i>(0, 0));
    if (maximum) {
        cv::max(a, b, fresh);
        cv::max(a, b, reused);
    } else {
        cv::min(a, b, fresh);
        cv::min(a, b, reused);
    }
    cv::Vec3i expected;
    for (int ch = 0; ch < 3; ++ch) {
        const int x = left.at<cv::Vec3i>(0, 0)[ch];
        const int y = right.at<cv::Vec3i>(0, 0)[ch];
        expected[ch] = maximum ? std::max(x, y) : std::min(x, y);
    }
    check(host(fresh), expected);
    check(host(reused), expected);
    if (maximum && cv::useOptimized()) {
        const cv::Mat observed = host(reused);
        cv::Mat widened;
        observed.convertTo(widened, CV_64F);
        std::cout << std::fixed << "Maximum raw channel 1="
                  << observed.at<cv::Vec3i>(0, 0)[1]
                  << " widened actual=" << widened.at<cv::Vec3d>(0, 0)[1]
                  << " expected=" << expected[1] << '\n';
    }
}
int main() {
    try {
        cv::ocl::setUseOpenCL(false);
        std::cout << "OpenCV " << CV_VERSION << '\n';
        for (int depth : {CV_8U, CV_16S, CV_32S, CV_32F, CV_64F, CV_16F}) {
            const cv::Scalar l = depth == CV_8U ? cv::Scalar(1, 8, 3) :
                depth == CV_16S ? cv::Scalar(-32768, 32767, -7) :
                depth == CV_32S ? cv::Scalar(-2147483648., 2147483647., -7) :
                depth == CV_16F ? cv::Scalar(-65504, 65504, -1) :
                cv::Scalar(-3.5, 4, -1);
            const cv::Scalar r = depth == CV_8U ? cv::Scalar(4, 5, 6) :
                depth == CV_16S || depth == CV_32S ? cv::Scalar(9, -9, 12) :
                cv::Scalar(-2, -5, 2);
            cv::Mat a(2, 257, CV_MAKETYPE(depth, 3));
            cv::Mat b(2, 257, a.type());
            a.setTo(l);
            b.setTo(r);
            if (depth == CV_32S) {
                check(a, cv::Vec3i(std::numeric_limits<int>::min(),
                                  std::numeric_limits<int>::max(), -7));
                check(b, cv::Vec3i(9, -9, 12));
                std::cout << "Scalar raw stored left="
                          << a.at<cv::Vec3i>(0, 0) << " right="
                          << b.at<cv::Vec3i>(0, 0) << '\n';
            }
            cv::Mat x, y;
            a.convertTo(x, CV_64F);
            b.convertTo(y, CV_64F);
            bool reported = false;
            for (int row = 0; row < 2 && !reported; ++row)
                for (int c = 0; c < 257 && !reported; ++c)
                    for (int ch = 0; ch < 3; ++ch) {
                        const double actual_l = x.at<cv::Vec3d>(row, c)[ch];
                        const double actual_r = y.at<cv::Vec3d>(row, c)[ch];
                        if (actual_l != l[ch] || actual_r != r[ch]) {
                            std::cout << "Widened observation mismatch depth=" << depth
                                      << " channel=" << ch << " row=" << row
                                      << " column=" << c << std::fixed
                                      << " left actual=" << actual_l
                                      << " expected=" << l[ch]
                                      << " right actual=" << actual_r
                                      << " expected=" << r[ch] << '\n';
                            // First mismatch identifies this fixture's failure.
                            reported = true;
                            break;
                        }
                    }
        }
        const cv::Vec3i l(std::numeric_limits<int>::min(),
                         std::numeric_limits<int>::max(), -7);
        const cv::Vec3i r(9, -9, 12);
        cv::Mat a(2, 257, CV_32SC3), b(2, 257, CV_32SC3);
        for (int row = 0; row < 2; ++row)
            for (int c = 0; c < 257; ++c) {
                a.at<cv::Vec3i>(row, c) = l;
                b.at<cv::Vec3i>(row, c) = r;
            }
        check(a, l);
        check(b, r);
        std::cout << "exact stored left=" << l << " right=" << r << '\n';
        cv::Mat widened;
        a.convertTo(widened, CV_64F);
        std::cout << std::fixed << "exact source widened to Float64="
                  << widened.at<cv::Vec3d>(0, 0) << '\n';
        for (bool optimized : {false, true}) {
            cv::setUseOptimized(optimized);
            for (bool maximum : {false, true}) {
                selection<cv::Mat>(a, b, maximum);
                selection<cv::UMat>(a, b, maximum);
            }
        }
        std::cout << "PASS exact Int32 C3 independent/fresh/reused Mat/UMat\n";
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}