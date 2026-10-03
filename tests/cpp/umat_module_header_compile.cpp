#include "opencv_core_module_bridge.hpp"
#include <type_traits>

static_assert(std::is_same_v<decltype(&opencv_core_module_input_umat),
    opencv_core_status (*)(const opencv_core_umat_handle *, const cv::UMat **)>);
static_assert(std::is_same_v<decltype(&opencv_core_module_output_umat),
    opencv_core_status (*)(opencv_core_umat_handle *, cv::UMat **)>);