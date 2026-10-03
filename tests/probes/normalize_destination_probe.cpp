#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <iostream>

// Isolated upstream behavior probe, not a replacement for public AUnit tests.
static cv::Mat observe(const cv::Mat &m) { return m; }
static cv::Mat observe(const cv::UMat &m) {
    cv::Mat result;
    m.copyTo(result);
    return result;
}

template <typename Dense>
static void run(const char *name) {
    const int kinds[] = {cv::NORM_L1, cv::NORM_L2,
                         cv::NORM_INF, cv::NORM_MINMAX};
    for (int kind : kinds) {
        for (int mode = 0; mode < 4; ++mode) {
            Dense source;
            if (mode == 1) source.create(0, 3, CV_32FC3);
            if (mode == 2) source.create(0, 3, CV_16FC1);
            if (mode == 3) {
                cv::Mat host(1, 2, CV_32F), half;
                host.at<float>(0, 0) = 3;
                host.at<float>(0, 1) = 4;
                host.convertTo(half, CV_16F);
                half.copyTo(source);
            }
            Dense destination(2, 3, CV_16SC2);
            destination.setTo(cv::Scalar::all(91));
            std::cout << name << " kind=" << kind << " mode=" << mode;
            try {
                cv::normalize(source, destination, 10, 2, kind, -1);
                std::cout << " ok dims=" << destination.dims
                          << " rows=" << destination.rows
                          << " cols=" << destination.cols
                          << " type=" << destination.type();
                if (!destination.empty()) {
                    cv::Mat values;
                    observe(destination).convertTo(values, CV_32F);
                    std::cout << " values=" << values;
                }
            } catch (const cv::Exception &e) {
                std::cout << " error=" << e.code
                          << " dst-type=" << destination.type();
            }
            std::cout << '\n';
        }
        cv::Mat host(1, 257, CV_32F);
        for (int i = 0; i < 257; ++i) host.at<float>(0, i) = float(i - 100);
        Dense source, expected;
        host.copyTo(source);
        cv::normalize(source, expected, 10, 2, kind);
        Dense alias = source;
        cv::normalize(source, alias, 10, 2, kind);
        std::cout << name << " alias-kind=" << kind << " error="
                  << cv::norm(observe(source), observe(expected), cv::NORM_INF)
                  << '\n';
        host.copyTo(source);
        cv::normalize(source, source, 10, 2, kind);
        std::cout << name << " self-kind=" << kind << " error="
                  << cv::norm(observe(source), observe(expected), cv::NORM_INF)
                  << '\n';
    }
}

int main() {
    cv::ocl::setUseOpenCL(false); // Do not enter known native empty OCL hazard.
    std::cout << "OpenCV " << CV_VERSION << " OpenCL=" << cv::ocl::useOpenCL()
              << '\n';
    run<cv::Mat>("Mat");
    run<cv::UMat>("UMat");
}