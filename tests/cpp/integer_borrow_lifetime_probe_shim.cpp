#include "opencv_core_module_bridge.hpp"

#include <opencv2/core.hpp>

#include <cstddef>
#include <cstdint>
#include <cstring>

#if defined(_WIN32)
#define INTEGER_BORROW_PROBE_EXPORT __declspec(dllexport)
#else
#define INTEGER_BORROW_PROBE_EXPORT
#endif

namespace {

bool armed = false;
cv::MatAllocator *saved_allocator = nullptr;

// OpenCV's default allocator does not reliably poison freed storage. While a
// lease fixture is armed, released blocks are filled with 0xA5 before the
// real deallocator runs. A borrow that no longer owns its allocation then
// observes that sentinel instead of the original values.
class Poisoning_Allocator : public cv::MatAllocator {
 public:
   cv::UMatData *allocate(
       int dims, const int *sizes, int type, void *data, std::size_t *step,
       cv::AccessFlag flags, cv::UMatUsageFlags usageFlags) const override {
      return saved_allocator->allocate(
          dims, sizes, type, data, step, flags, usageFlags);
   }

   bool allocate(cv::UMatData *data, cv::AccessFlag accessflags,
                 cv::UMatUsageFlags usageFlags) const override {
      return saved_allocator->allocate(data, accessflags, usageFlags);
   }

   void deallocate(cv::UMatData *data) const override {
      if (data != nullptr && data->origdata != nullptr && data->size > 0) {
         std::memset(data->origdata, 0xA5, data->size);
      }
      saved_allocator->deallocate(data);
   }
};

Poisoning_Allocator probe_allocator;

}  // namespace

extern "C" {

INTEGER_BORROW_PROBE_EXPORT void
integer_borrow_lifetime_probe_arm(void) {
   if (!armed) {
      saved_allocator = cv::Mat::getDefaultAllocator();
      cv::Mat::setDefaultAllocator(&probe_allocator);
      armed = true;
   }
}

INTEGER_BORROW_PROBE_EXPORT void
integer_borrow_lifetime_probe_disarm(void) {
   if (armed && saved_allocator != nullptr) {
      cv::Mat::setDefaultAllocator(saved_allocator);
   }
   armed = false;
   saved_allocator = nullptr;
}

}  // extern "C"
