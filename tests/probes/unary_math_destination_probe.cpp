// Compile alone: includes and exercises the actual private production helpers.
// Native research modes run separately because an upstream call may abort.
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <stdexcept>

// Optional --wrap of cv::pow observes the production call boundary. This is
// not a replacement implementation; the original OpenCV operation still runs.
#ifdef UNARY_MATH_AUDIT_POW_LAYOUT
[[maybe_unused]] static int protected_calls = 0;
static bool checking_helper = false;
void real_pow(cv::InputArray, double, cv::OutputArray)
    asm("__real__ZN2cv3powERKNS_11_InputArrayEdRKNS_12_OutputArrayE");
void audited_pow(cv::InputArray, double, cv::OutputArray)
    asm("__wrap__ZN2cv3powERKNS_11_InputArrayEdRKNS_12_OutputArrayE");
void audited_pow(cv::InputArray source, double power, cv::OutputArray dst) {
#if CV_VERSION_MAJOR >= 5 || (CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR >= 10)
    if (checking_helper && !source.empty() && power == 2 &&
        (source.depth() == CV_8U || source.depth() == CV_8S)) {
        if (dst.depth() != source.depth())
            throw std::runtime_error("uncorrected layout at native Pow boundary");
        ++protected_calls;
    }
#endif
    real_pow(source, power, dst);
}
#endif

static void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
static cv::Mat observe(const cv::Mat &a) { return a; }
static cv::Mat observe(const cv::UMat &a) { return a.getMat(cv::ACCESS_READ); }

template <typename Dense>
static void apply(const Dense &a, Dense &b, int op, double power, bool native) {
    switch (op) {
    case 0: if (native) cv::sqrt(a, b); else dense_sqrt(a, b); break;
    case 1: if (native) cv::exp(a, b); else dense_exp(a, b); break;
    case 2: if (native) cv::log(a, b); else dense_log(a, b); break;
    default: if (native) cv::pow(a, power, b); else dense_pow(a, power, b);
    }
}

template <typename Dense>
static void old_depth(const char *name, bool native) {
    for (int depth : {CV_8U, CV_8S}) {
      for (bool region : {false, true}) {
        Dense source(2, 257, depth), expected;
        source.setTo(depth == CV_8U ? 20 : -11);
        Dense parent(5, 260, depth == CV_8U ? CV_16U : CV_16S);
        parent.setTo(91);
        Dense destination = region ? parent(cv::Rect(1, 1, 257, 2))
                                   : Dense(2, 257, parent.type());
        destination.setTo(91);
        Dense alias = destination;
        prepare_pow_output(source, 2, expected);
        cv::pow(source, 2, expected);
#ifdef UNARY_MATH_AUDIT_POW_LAYOUT
        checking_helper = !native;
#endif
        apply(source, destination, 3, 2, native);
#ifdef UNARY_MATH_AUDIT_POW_LAYOUT
        checking_helper = false;
#endif
        require(destination.type() == source.type() &&
                destination.size == source.size, "Pow(2) output layout");
        require(cv::norm(observe(expected), observe(destination), cv::NORM_INF)
                == 0, "Pow(2) independent/reused parity");
        require(cv::countNonZero(observe(parent) != 91) == 0,
                "old parent unchanged");
        require(cv::countNonZero(observe(alias) != 91) == 0,
                "old alias survives detachment");
        destination.setTo(7);
        require(cv::countNonZero(observe(alias) != 91) == 0,
                "new storage independent");
        std::cout << name << " old-depth=" << depth << " native=" << native
                  << " PASS\n";
      }
    }
}

template <typename Dense>
static void aliases(const char *name) {
    for (int depth : {CV_32F, CV_64F})
        for (int cn : {1, 3})
            for (bool nd : {false, true})
                for (int op = 0; op < 4; ++op)
                    for (double power : {0., 1., 2., 3., -1., -2., .5, -.5, 1.3}) {
                        if (op != 3 && power != 0) continue;
                        int sizes[] = {2, 3, 5};
                        Dense a, oracle;
                        if (nd) {
                            a.create(3, sizes, CV_MAKETYPE(depth, cn));
                            oracle.create(3, sizes, CV_MAKETYPE(depth, cn));
                        } else {
                            a.create(2, 257, CV_MAKETYPE(depth, cn));
                            oracle.create(2, 257, CV_MAKETYPE(depth, cn));
                        }
                        cv::Mat host = observe(a);
                        cv::Mat host_oracle = observe(oracle);
                        for (size_t i = 0; i < host.total() * cn; ++i) {
                            const double v = .25 + (i % 17) / 8.;
                            if (depth == CV_32F) {
                                host.ptr<float>()[i] = static_cast<float>(v);
                                host_oracle.ptr<float>()[i] = static_cast<float>(v);
                            } else {
                                host.ptr<double>()[i] = v;
                                host_oracle.ptr<double>()[i] = v;
                            }
                        }
                        host.release();
                        host_oracle.release();
                        Dense retained = a;
                        apply(oracle, oracle, op, power, true);
                        apply(a, a, op, power, false);
                        require(cv::norm(observe(a), observe(oracle), cv::NORM_INF)
                                < 1e-6, "exact native alias parity");
                        require(a.u == retained.u, "exact alias attachment");
                        a.setTo(cv::Scalar::all(1.75));
                        oracle.setTo(cv::Scalar::all(1.75));
                        Dense shallow = a, oracle_shallow = oracle;
                        apply(oracle, oracle_shallow, op, power, true);
                        apply(a, shallow, op, power, false);
                        require(cv::norm(observe(shallow), observe(oracle_shallow),
                                         cv::NORM_INF) < 1e-6,
                                "shallow native alias parity");
                    }
    std::cout << name << " exact/shallow aliases and N-D PASS\n";
}

template <typename Dense>
static void empties(const char *name, bool native) {
    for (int depth : {CV_8U, CV_32F, CV_64F})
        for (bool typed : {false, true})
            for (int op = 0; op < 4; ++op)
                for (double power : {0., 1., 2., 3., .5}) {
                    if (op != 3 && (depth == CV_8U || !typed || power != 0))
                        continue;
                    if (op == 3 && depth == CV_8U && power == .5) continue;
                    Dense source, fresh, destination(2, 3, CV_16SC2);
                    if (typed) source.create(0, 0, depth);
                    Dense retained = destination;
                    try {
                        apply(source, fresh, op, power, native);
                        apply(source, destination, op, power, native);
                        std::cout << name << " empty op=" << op << " power="
                                  << power << " typed=" << typed << " depth="
                                  << depth << " fresh=" << fresh.dims << '/'
                                  << fresh.type() << " reused=" << destination.dims
                                  << '/' << destination.type() << std::endl;
                        require(destination.empty() && !retained.empty(),
                                "empty result and old alias survival");
                    } catch (const cv::Exception &e) {
                        std::cout << name << " empty native exception "
                                  << e.what() << std::endl;
                    }
                }
}

int main(int argc, char **argv) {
    try {
        require(argc == 4 || argc == 5,
                "usage: probe mat|umat old|alias|empty helper|native [opencl]");
        cv::ocl::setUseOpenCL(argc == 5 && std::string(argv[4]) == "1");
        const bool native = std::string(argv[3]) == "native";
        const std::string mode(argv[2]);
        std::cout << CV_VERSION << " OpenCL=" << cv::ocl::useOpenCL()
                  << std::endl;
        if (std::string(argv[1]) == "mat") {
            if (mode == "old") old_depth<cv::Mat>("Mat", native);
            else if (mode == "alias") aliases<cv::Mat>("Mat");
            else empties<cv::Mat>("Mat", native);
        } else {
            if (mode == "old") old_depth<cv::UMat>("UMat", native);
            else if (mode == "alias") aliases<cv::UMat>("UMat");
            else empties<cv::UMat>("UMat", native);
        }
#ifdef UNARY_MATH_AUDIT_POW_LAYOUT
#if CV_VERSION_MAJOR >= 5 || (CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR >= 10)
        if (mode == "old" && !native)
            require(protected_calls == 4, "all helper Pow call layouts");
#endif
#endif
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n';
        return 1;
    }
}