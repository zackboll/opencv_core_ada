#include "opencv_core_module_bridge.hpp"

#include <opencv2/core.hpp>

#include <cstddef>
#include <cstdint>

#if defined(_WIN32)
#define INTEGER_BORROW_PROBE_EXPORT __declspec(dllexport)
#else
#define INTEGER_BORROW_PROBE_EXPORT
#endif

namespace {

// Test-only, single-target observation of one OpenCV-owned Mat allocation.
//
// OpenCV 4.10 StdMatAllocator::allocate constructs UMatData with the allocating
// allocator, so UMatData::currAllocator and prevAllocator name that object.
// Mat::deallocate then selects currAllocator (falling back to the Mat header
// allocator or the current default) and calls unmap, which calls deallocate
// when both reference counts are zero. Delegating allocate() and returning the
// upstream UMatData unchanged therefore never observes release: the saved
// allocator remains the release dispatcher.
//
// This observer allocates through the saved upstream allocator, then retargets
// only the first successful OpenCV-owned block. Later allocations, including
// replacement Mats created inside a callback, keep the upstream allocator and
// cannot increment the target's deallocation count. Evidence lives in this
// translation unit, not in the UMatData, and is not cleared when the block is
// destroyed. The observer does not retain a cv::Mat or bump a reference count.
//
// The upstream allocator pointer is kept until Finish, including after the
// default allocator is restored, so a still-live target can deallocate through
// this object and then through the original allocator.

constexpr std::uint8_t Status_Ok = 0;
constexpr std::uint8_t Status_Nested = 1;
constexpr std::uint8_t Status_Inactive = 2;
constexpr std::uint8_t Status_Still_Live = 3;

bool session_active = false;
bool default_is_observer = false;
cv::MatAllocator *upstream = nullptr;

bool target_captured = false;
const cv::UMatData *target = nullptr;
std::size_t target_size = 0;
int target_deallocations = 0;

class Allocation_Observer final : public cv::MatAllocator {
  public:
   cv::UMatData *allocate(
       int dims, const int *sizes, int type, void *data, std::size_t *step,
       cv::AccessFlag flags, cv::UMatUsageFlags usageFlags) const override {
      if (upstream == nullptr) {
         return nullptr;
      }

      cv::UMatData *block = upstream->allocate(
          dims, sizes, type, data, step, flags, usageFlags);
      if (block == nullptr || data != nullptr || target_captured) {
         return block;
      }

      // Only an OpenCV-owned block created while no target is captured is the
      // original allocation. External-data headers and every later allocation
      // are intentionally ignored.
      block->prevAllocator = this;
      block->currAllocator = this;
      target = block;
      target_size = block->size;
      target_captured = true;
      return block;
   }

   bool allocate(
       cv::UMatData *data, cv::AccessFlag accessflags,
       cv::UMatUsageFlags usageFlags) const override {
      if (upstream == nullptr) {
         return false;
      }
      return upstream->allocate(data, accessflags, usageFlags);
   }

   void deallocate(cv::UMatData *data) const override {
      if (data != nullptr && target_captured && data == target) {
         target_deallocations += 1;
         target = nullptr;
      }
      if (upstream != nullptr) {
         upstream->deallocate(data);
      }
   }
};

Allocation_Observer observer;

void Restore_Default_Allocator() {
   if (default_is_observer && upstream != nullptr) {
      cv::Mat::setDefaultAllocator(upstream);
   }
   default_is_observer = false;
}

}  // namespace

extern "C" {

INTEGER_BORROW_PROBE_EXPORT std::uint8_t
integer_borrow_lifetime_probe_begin(void) {
   if (session_active) {
      return Status_Nested;
   }

   upstream = cv::Mat::getDefaultAllocator();
   if (upstream == nullptr || upstream == &observer) {
      upstream = nullptr;
      return Status_Inactive;
   }

   target_captured = false;
   target = nullptr;
   target_size = 0;
   target_deallocations = 0;
   session_active = true;

   try {
      cv::Mat::setDefaultAllocator(&observer);
   } catch (...) {
      session_active = false;
      upstream = nullptr;
      return Status_Inactive;
   }
   default_is_observer = true;
   return Status_Ok;
}

INTEGER_BORROW_PROBE_EXPORT std::uint8_t
integer_borrow_lifetime_probe_restore_default(void) {
   if (!session_active) {
      return Status_Inactive;
   }
   try {
      Restore_Default_Allocator();
   } catch (...) {
      return Status_Inactive;
   }
   return Status_Ok;
}

INTEGER_BORROW_PROBE_EXPORT std::uint8_t
integer_borrow_lifetime_probe_finish(void) {
   if (!session_active) {
      return Status_Inactive;
   }

   std::uint8_t status = Status_Ok;
   try {
      Restore_Default_Allocator();
   } catch (...) {
      status = Status_Inactive;
   }

   // Drop delegation state only after the observed block has been released.
   // A target that is still live would otherwise lose its upstream allocator.
   if (target != nullptr) {
      status = Status_Still_Live;
   }

   session_active = false;
   default_is_observer = false;
   upstream = nullptr;
   target_captured = false;
   target = nullptr;
   target_size = 0;
   target_deallocations = 0;
   return status;
}

INTEGER_BORROW_PROBE_EXPORT std::uint8_t
integer_borrow_lifetime_probe_target_captured(void) {
   return target_captured ? static_cast<std::uint8_t>(1)
                          : static_cast<std::uint8_t>(0);
}

INTEGER_BORROW_PROBE_EXPORT std::uint8_t
integer_borrow_lifetime_probe_target_live(void) {
   return target != nullptr ? static_cast<std::uint8_t>(1)
                            : static_cast<std::uint8_t>(0);
}

INTEGER_BORROW_PROBE_EXPORT std::int32_t
integer_borrow_lifetime_probe_deallocation_count(void) {
   return static_cast<std::int32_t>(target_deallocations);
}

INTEGER_BORROW_PROBE_EXPORT std::uint64_t
integer_borrow_lifetime_probe_target_size(void) {
   return static_cast<std::uint64_t>(target_size);
}

}  // extern "C"
