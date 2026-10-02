// Disposable process: native empty math paths may crash before throwing.
// Run one operation per invocation, outside the AUnit process.
#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <cstdlib>
#include <iostream>
#include <string>

template <typename Dense>
static void describe(const char *name, const Dense &value) {
    std::cout << name << " empty=" << value.empty()
              << " dims=" << value.dims << " type=" << value.type()
              << " shape=";
    for (int i = 0; i < value.dims; ++i) {
        std::cout << (i ? "x" : "") << value.size[i];
    }
    std::cout << std::endl;
}

template <typename Dense>
static int probe(const std::string &operation, const std::string &layout,
                 int type, double power) {
    Dense source, other, first, second;
    if (layout == "typed") {
        source.create(0, 0, type);
        other.create(0, 0, type);
    } else if (layout == "unit-default" || layout == "unit-typed") {
        source.create(1, 2, type);
        source.setTo(cv::Scalar::all(0));
        if (layout == "unit-typed") other.create(0, 0, type);
    } else if (layout == "nd") {
        const int sizes[] = {2, 2, 2};
        source.create(3, sizes, type);
        other.create(3, sizes, type);
        source.setTo(cv::Scalar::all(4));
        other.setTo(cv::Scalar::all(3));
    } else if (layout == "full") {
        source.create(2, 2, type);
        other.create(2, 2, type);
        source.setTo(cv::Scalar::all(4));
        other.setTo(cv::Scalar::all(3));
    } else if (layout != "default") {
        std::cerr << "unknown layout\n";
        return 2;
    }
    describe("source", source);
    describe("other", other);
    if (operation == "normalize-l1")
        cv::normalize(source, first, 1, 0, cv::NORM_L1);
    else if (operation == "normalize-l2")
        cv::normalize(source, first, 1, 0, cv::NORM_L2);
    else if (operation == "normalize-inf")
        cv::normalize(source, first, 1, 0, cv::NORM_INF);
    else if (operation == "normalize-minmax")
        cv::normalize(source, first, 0, 1, cv::NORM_MINMAX);
    else if (operation == "sqrt") cv::sqrt(source, first);
    else if (operation == "exp") cv::exp(source, first);
    else if (operation == "log") cv::log(source, first);
    else if (operation == "pow") cv::pow(source, power, first);
    else if (operation == "magnitude") cv::magnitude(source, other, first);
    else if (operation == "phase") cv::phase(source, other, first);
    else if (operation == "cart")
        cv::cartToPolar(source, other, first, second);
    else if (operation == "polar")
        cv::polarToCart(other, source, first, second);
    else {
        std::cerr << "unknown operation\n";
        return 2;
    }
    describe("first", first);
    describe("second", second);
    return 0;
}

int main(int argc, char **argv) {
    if (argc != 7) {
        std::cerr << "usage: probe mat|umat operation layout type power opencl\n";
        return 2;
    }
    try {
        cv::ocl::setUseOpenCL(std::stoi(argv[6]) != 0);
        std::cout << "OpenCV=" << CV_VERSION
                  << " haveOpenCL=" << cv::ocl::haveOpenCL()
                  << " useOpenCL=" << cv::ocl::useOpenCL() << std::endl;
        const std::string family(argv[1]);
        if (family == "mat")
            return probe<cv::Mat>(argv[2], argv[3], std::stoi(argv[4]),
                                  std::stod(argv[5]));
        if (family == "umat")
            return probe<cv::UMat>(argv[2], argv[3], std::stoi(argv[4]),
                                   std::stod(argv[5]));
        return 2;
    } catch (const cv::Exception &error) {
        std::cerr << "OpenCV exception: " << error.what() << std::endl;
        return 1;
    } catch (const std::exception &error) {
        std::cerr << "standard exception: " << error.what() << std::endl;
        return 1;
    }
}