struct opencv_core_scalar;
#include "opencv_core_shim.h"
#include <stdint.h>
#include <stdlib.h>

static uint32_t leases;
static uint32_t borrows;
static uint32_t misalign;
static opencv_core_mat_handle *retained[64];
static uint32_t live_leases;
static uint32_t destroyed_leases;
uint32_t r3h_live_leases(void) { return live_leases; }
uint32_t r3h_destroyed_leases(void) { return destroyed_leases; }
void r3h_forget_lease(opencv_core_mat_handle *handle)
{
    for (unsigned i = 0; i < 64; ++i) {
        if (handle && retained[i] == handle) {
            retained[i] = NULL;
            --live_leases;
            ++destroyed_leases;
            return;
        }
    }
}
void r3g_set_misalignment(uint32_t enabled) { misalign = enabled; }
uint32_t r3g_lease_count(void) { return leases; }
uint32_t r3g_borrow_count(void) { return borrows; }
extern opencv_core_status __real_opencv_core_mat_acquire_borrow_lease(
    const opencv_core_mat_handle *, opencv_core_mat_handle **);
opencv_core_status __wrap_opencv_core_mat_acquire_borrow_lease(
    const opencv_core_mat_handle *mat, opencv_core_mat_handle **out)
{
    ++leases;
    opencv_core_status status =
        __real_opencv_core_mat_acquire_borrow_lease(mat, out);
    if (status == OPENCV_CORE_OK) {
        if (!*out) abort();
        for (unsigned i = 0; i < 64; ++i) {
            if (!retained[i]) {
                retained[i] = *out;
                ++live_leases;
                return status;
            }
        }
        abort();
    }
    return status;
}
extern opencv_core_status __real_opencv_core_mat_borrow_row_data(
    opencv_core_mat_handle *, int32_t, void **, uint64_t *);
opencv_core_status __wrap_opencv_core_mat_borrow_row_data(
    opencv_core_mat_handle *mat, int32_t row, void **data, uint64_t *bytes)
{
    ++borrows;
    opencv_core_status status =
        __real_opencv_core_mat_borrow_row_data(mat, row, data, bytes);
    if (status == OPENCV_CORE_OK && *data && misalign)
        *data = (unsigned char *)*data + 1;
    return status;
}
extern opencv_core_status __real_opencv_core_mat_borrow_contiguous_data(
    opencv_core_mat_handle *, void **, uint64_t *);
opencv_core_status __wrap_opencv_core_mat_borrow_contiguous_data(
    opencv_core_mat_handle *mat, void **data, uint64_t *bytes)
{
    ++borrows;
    opencv_core_status status =
        __real_opencv_core_mat_borrow_contiguous_data(mat, data, bytes);
    if (status == OPENCV_CORE_OK && *data && misalign)
        *data = (unsigned char *)*data + 1;
    return status;
}