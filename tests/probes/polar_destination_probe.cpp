// Compile standalone: g++ -std=c++17 -Wall -Wextra -Wpedantic -Werror
// tests/probes/polar_destination_probe.cpp $(pkg-config --cflags --libs opencv4)
#include "../../cpp/opencv_core_shim.cpp"
#include <opencv2/core/ocl.hpp>
#include <iostream>
#include <limits>

static void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
static cv::Mat observe(const cv::Mat &m) { return m; }
static cv::Mat observe(const cv::UMat &m) { return m.getMat(cv::ACCESS_READ); }
template <typename Dense>
static void equal(const Dense &a, const Dense &b) {
    require(a.dims == b.dims && a.type() == b.type(), "metadata parity");
    if (a.empty() || b.empty()) {
        require(a.empty() == b.empty(), "empty parity");
        return;
    }
    require(cv::norm(observe(a), observe(b), cv::NORM_INF) < 1e-5,
            "native/helper parity");
}
template <typename Dense>
static void run_dense() {
    for (int depth : {CV_32F, CV_64F}) for (int channels : {1, 3})
    for (bool degrees : {false, true}) for (int operation = 0; operation < 3; ++operation)
    for (int mismatch = 0; mismatch < 4; ++mismatch)
    for (int layout = 0; layout < 4; ++layout)
    for (int bad = 0; bad < 3; ++bad)
    for (bool native : {false, true}) {
        int type = CV_MAKETYPE(depth, channels);
        Dense a(2, 257, type), b(2, 257, type);
        a.setTo(cv::Scalar::all(3)); b.setTo(cv::Scalar::all(4));
        const int old_type = bad == 1 ? CV_MAKETYPE(CV_8U, channels)
                           : bad == 2 ? CV_MAKETYPE(depth, 2) : type;
        Dense p(5, 600, type), q(5, 600, type);
        p.setTo(cv::Scalar::all(91)); q.setTo(cv::Scalar::all(92));
        Dense dp(5, 600, old_type), dq(5, 600, old_type);
        dp.setTo(cv::Scalar::all(91)); dq.setTo(cv::Scalar::all(92));
        Dense x = layout == 0 ? Dense(2, 257, type)
                             : p(cv::Rect(2, 1, 257, 2));
        Dense y = layout == 0 ? Dense(2, 257, type)
                  : layout == 2 ? p(cv::Rect(300, 1, 257, 2))
                                : q(cv::Rect(2, 1, 257, 2));
        x.setTo(cv::Scalar::all(91)); y.setTo(cv::Scalar::all(92));
        if (mismatch & 1) x = layout == 0 ? Dense(2, bad ? 257 : 17, old_type)
                             : dp(cv::Rect(2, 1, bad ? 257 : 17, 2));
        if (mismatch & 2) y = layout == 0 ? Dense(2, bad ? 257 : 17, old_type)
                             : dq(cv::Rect(2, 1, bad ? 257 : 17, 2));
        x.setTo(cv::Scalar::all(91)); y.setTo(cv::Scalar::all(92));
        Dense ax = x, ay = y, ex, ey;
        const size_t sx = x.step[0], sy = y.step[0];
        cv::Size wx, wy; cv::Point ox, oy;
        x.locateROI(wx, ox); y.locateROI(wy, oy);
        if (operation == 0) {
            if (native) cv::cartToPolar(a, b, x, y, degrees);
            else dense_cart_to_polar(a, b, x, y, degrees);
            cv::cartToPolar(a, b, ex, ey, degrees);
        } else {
            Dense magnitude = operation == 2 ? Dense() : a;
            if (!native) dense_polar_to_cart(magnitude, b, x, y, degrees);
            else {
#if CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR < 10
                if (operation == 2 && depth == CV_64F) {
                    Dense angle32, x32, y32;
                    b.convertTo(angle32, CV_32F);
                    cv::polarToCart(cv::noArray(), angle32, x32, y32, degrees);
                    x32.convertTo(x, CV_64F); y32.convertTo(y, CV_64F);
                } else
#endif
                    cv::polarToCart(magnitude, b, x, y, degrees);
            }
#if CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR < 10
            if (operation == 2 && depth == CV_64F) {
                // Do not enter the known partially-uninitialized legacy path.
                Dense angle32, x32, y32;
                b.convertTo(angle32, CV_32F);
                cv::polarToCart(cv::noArray(), angle32, x32, y32, degrees);
                x32.convertTo(ex, CV_64F); y32.convertTo(ey, CV_64F);
            } else
#endif
                cv::polarToCart(magnitude, b, ex, ey, degrees);
        }
        equal(x, ex); equal(y, ey);
        if (!(mismatch & 1)) {
            cv::Size w; cv::Point o; x.locateROI(w, o);
            require(w == wx && o == ox && x.step[0] == sx, "first geometry");
        }
        if (!(mismatch & 2)) {
            cv::Size w; cv::Point o; y.locateROI(w, o);
            require(w == wy && o == oy && y.step[0] == sy, "second geometry");
        }
        if (layout != 0) {
            cv::Mat ep(5, 600, type, cv::Scalar::all(91));
            cv::Mat eq(5, 600, type, cv::Scalar::all(92));
            if (layout == 2)
                ep(cv::Rect(300, 1, 257, 2)).setTo(cv::Scalar::all(92));
            if (!(mismatch & 1)) observe(ex).copyTo(ep(cv::Rect(2, 1, 257, 2)));
            if (!(mismatch & 2)) observe(ey).copyTo(
                layout == 2 ? ep(cv::Rect(300, 1, 257, 2))
                            : eq(cv::Rect(2, 1, 257, 2)));
            equal(observe(p), ep); equal(observe(q), eq);
        }
        if (!(mismatch & 1)) equal(ax, x);
        else require(cv::norm(observe(ax), cv::NORM_INF) == 91, "first detach");
        if (!(mismatch & 2)) equal(ay, y);
        else require(cv::norm(observe(ay), cv::NORM_INF) == 92, "second detach");
        ax.setTo(cv::Scalar::all(7)); equal(y, ey);
        if (!(mismatch & 1)) require(cv::norm(observe(x), cv::NORM_INF) == 7, "first reuse");
        ay.setTo(cv::Scalar::all(8));
        if (!(mismatch & 2)) require(cv::norm(observe(y), cv::NORM_INF) == 8, "second reuse");
        if (!(mismatch & 1)) {
            require(cv::norm(observe(x), cv::NORM_INF) == 7, "no cross write");
            x.setTo(cv::Scalar::all(9)); equal(x, ax);
        } else {
            x.setTo(cv::Scalar::all(9));
            require(cv::norm(observe(ax), cv::NORM_INF) == 7, "first old alias");
        }
        if (!(mismatch & 2)) { y.setTo(cv::Scalar::all(10)); equal(y, ay); }
        else {
            y.setTo(cv::Scalar::all(10));
            require(cv::norm(observe(ay), cv::NORM_INF) == 8, "second old alias");
        }
        if (layout != 0) {
            cv::Mat ep(5, 600, type, cv::Scalar::all(91));
            cv::Mat eq(5, 600, type, cv::Scalar::all(92));
            if (layout == 2)
                ep(cv::Rect(300, 1, 257, 2)).setTo(cv::Scalar::all(92));
            if (!(mismatch & 1)) ep(cv::Rect(2, 1, 257, 2)).setTo(cv::Scalar::all(9));
            if (!(mismatch & 2))
                (layout == 2 ? ep(cv::Rect(300, 1, 257, 2))
                             : eq(cv::Rect(2, 1, 257, 2))).setTo(cv::Scalar::all(10));
            equal(observe(p), ep); equal(observe(q), eq);
        }
        require((depth == CV_64F ? observe(p).template at<double>(0, 0)
                                : observe(p).template at<float>(0, 0)) == 91,
                "first parent corner");
    }
    for (int depth : {CV_32F, CV_64F}) {
        Dense a(0, 0, CV_MAKETYPE(depth, 3)), b(0, 0, CV_MAKETYPE(depth, 3));
        Dense x(2, 3, CV_8U), y(2, 3, CV_8U), ex, ey;
        dense_cart_to_polar(a, b, x, y, false);
        dense_cart_to_polar(a, b, ex, ey, false);
        equal(x, ex); equal(y, ey);
        dense_polar_to_cart(Dense(), b, x, y, false);
        dense_polar_to_cart(Dense(), b, ex, ey, false);
        equal(x, ex); equal(y, ey);
        std::cout << "empty depth=" << depth << " dims=" << x.dims
                  << " type=" << x.type() << '\n';
    }
}
template <typename Handle, typename Call>
static void raw(Call call) {
    Handle a, b, x, y;
    a.value.create(2, 257, CV_64FC3); b.value.create(2, 257, CV_64FC3);
    x.value.create(2, 257, CV_64FC3); y.value.create(2, 257, CV_64FC3);
    a.value.setTo(cv::Scalar::all(3)); b.value.setTo(cv::Scalar::all(4));
    x.value.setTo(cv::Scalar::all(91)); y.value.setTo(cv::Scalar::all(92));
    auto reject = [&](const Handle *p, const Handle *q, uint8_t flag,
                      Handle *r, Handle *s) {
        require(call(p, q, flag, r, s) == OPENCV_CORE_ERROR_INVALID_ARGUMENT,
                "raw preflight rejection");
        require(cv::norm(observe(a.value), cv::NORM_INF) == 3, "first source preserved");
        require(cv::norm(observe(b.value), cv::NORM_INF) == 4, "second source preserved");
        require(cv::norm(observe(x.value), cv::NORM_INF) == 91, "first output preserved");
        require(cv::norm(observe(y.value), cv::NORM_INF) == 92, "second output preserved");
    };
    reject(nullptr, &b, 0, &x, &y); reject(&a, nullptr, 0, &x, &y);
    reject(&a, &b, 0, nullptr, &y); reject(&a, &b, 0, &x, nullptr);
    reject(&a, &b, 0, &x, &x);
    reject(&a, &b, 0, &a, &y); reject(&a, &b, 0, &b, &y);
    reject(&a, &b, 0, &x, &a); reject(&a, &b, 0, &x, &b);
    reject(&a, &b, 2, &x, &y); reject(&a, &b, 255, &x, &y);
    if constexpr (std::is_same_v<Handle, opencv_core_mat_handle>) {
        x.temporary_external_view = true; reject(&a, &b, 0, &x, &y);
        x.temporary_external_view = false;
        y.temporary_external_view = true; reject(&a, &b, 0, &x, &y);
        y.temporary_external_view = false;
    }
    require(call(&a, &a, 0, &x, &y) == OPENCV_CORE_OK, "input-input alias");
}
static void special() {
    const double inf = std::numeric_limits<double>::infinity();
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double xs[] = {0.0, -0.0, inf, -inf, nan, inf, 0.0};
    const double ys[] = {0.0, -0.0, 1.0, -1.0, 2.0, inf, nan};
    for (int depth : {CV_32F, CV_64F}) for (bool degrees : {false, true}) {
        cv::Mat a(1, 7, CV_64F), b(1, 7, CV_64F);
        for (int i = 0; i < 7; ++i) {
            a.at<double>(0, i) = xs[i]; b.at<double>(0, i) = ys[i];
        }
        a.convertTo(a, depth); b.convertTo(b, depth);
        for (bool polar : {false, true}) {
            cv::Mat x, y, ex, ey;
            if (polar) {
                dense_polar_to_cart(a, b, x, y, degrees);
                cv::polarToCart(a, b, ex, ey, degrees);
            } else {
                dense_cart_to_polar(a, b, x, y, degrees);
                cv::cartToPolar(a, b, ex, ey, degrees);
            }
            x.convertTo(x, CV_64F); y.convertTo(y, CV_64F);
            ex.convertTo(ex, CV_64F); ey.convertTo(ey, CV_64F);
            for (int i = 0; i < 7; ++i) {
                const double vx = x.at<double>(0, i), vy = y.at<double>(0, i);
                const double px = ex.at<double>(0, i), py = ey.at<double>(0, i);
                require(std::fpclassify(vx) == std::fpclassify(px) &&
                        std::fpclassify(vy) == std::fpclassify(py), "special classification parity");
                if (std::isfinite(vx)) require(vx == px, "finite special first parity");
                if (std::isfinite(vy)) require(vy == py, "finite special second parity");
                std::cout << "special depth=" << depth << " polar=" << polar
                          << " degrees=" << degrees << " i=" << i
                          << " first=" << vx << " second=" << vy << '\n';
            }
        }
    }
}
static void selected_geometry() {
    const int32_t sizes[] = {3, 5, 7}, starts[] = {1, 1, 2}, stops[] = {2, 3, 5};
    const uint8_t drop[] = {1, 0, 0};
    opencv_core_mat_handle parent;
    parent.value = cv::Mat(3, sizes, CV_64F, cv::Scalar::all(93));
    const cv::Mat before = parent.value.clone();
    for (auto call : {opencv_core_mat_cart_to_polar_into,
                      opencv_core_mat_polar_to_cart_into})
    for (bool first : {false, true}) for (int layout = 0; layout < 4; ++layout) {
        opencv_core_mat_handle *view = nullptr;
        require(opencv_core_mat_select_nd_view(&parent, 3, drop, starts, stops,
                                               &view) == OPENCV_CORE_OK,
                "raw selected view construction");
        std::unique_ptr<opencv_core_mat_handle> owner(view);
        const auto *data = view->value.data;
        const auto *allocation = parent.value.data;
        const size_t step = view->value.step[0];
        opencv_core_mat_handle a, b, other;
        a.value = cv::Mat(layout == 1 ? 1 : 2, 3,
                         layout == 2 ? CV_32F : layout == 3 ? CV_64FC3 : CV_64F,
                         cv::Scalar::all(3));
        b.value = a.value.clone();
        other.value = cv::Mat(2, 3, CV_64F, cv::Scalar::all(92));
        const cv::Mat va = a.value.clone(), vb = b.value.clone();
        const cv::Mat vo = other.value.clone(), vv = view->value.clone();
        require(call(&a, &b, 0, first ? view : &other,
                     first ? &other : view) == OPENCV_CORE_ERROR_INVALID_ARGUMENT,
                "selected output rejection");
        require(view->value.data == data && view->value.step[0] == step &&
                parent.value.data == allocation && view->temporary_external_view,
                "selected allocation/geometry/capability preserved");
        equal(view->value, vv); equal(parent.value, before);
        equal(a.value, va); equal(b.value, vb); equal(other.value, vo);
    }
}
int main() {
    try {
        std::cout << "OpenCV " << CV_VERSION << '\n';
        raw<opencv_core_mat_handle>(opencv_core_mat_cart_to_polar_into);
        raw<opencv_core_mat_handle>(opencv_core_mat_polar_to_cart_into);
        raw<opencv_core_umat_handle>(opencv_core_umat_cart_to_polar_into);
        raw<opencv_core_umat_handle>(opencv_core_umat_polar_to_cart_into);
        special();
        selected_geometry();
        for (bool requested : {false, true}) {
            cv::ocl::setUseOpenCL(requested);
            std::cout << "OpenCL requested=" << requested
                      << " enabled=" << cv::ocl::useOpenCL() << '\n';
            run_dense<cv::Mat>(); run_dense<cv::UMat>();
        }
        std::cout << "PASS production helper/raw ABI qualification\n";
    } catch (const std::exception &e) {
        std::cerr << e.what() << '\n'; return 1;
    }
}