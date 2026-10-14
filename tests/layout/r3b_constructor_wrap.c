/* The header refers to this tag before its definition. Forward-declare it
 * for strict C compilation without changing the published header. */
struct opencv_core_scalar;
#include "opencv_core_shim.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* GNU ld --wrap applies to the Ada caller's undefined C symbols. The real
 * shim remains unchanged. Counters record entries, not successful returns. */
static uint32_t calls[4];
static opencv_core_mat_handle *views[64];
static uint32_t live_views;
static uint32_t destroyed_views;
static unsigned char snapshot[4096];
static size_t snapshot_size;

void r3c_snapshot(const void *data, size_t size)
{
    if (!data || size > sizeof snapshot) abort();
    memcpy(snapshot, data, size);
    snapshot_size = size;
}

uint32_t r3c_bytes_unchanged(const void *data, size_t size)
{
    return size == snapshot_size && memcmp(snapshot, data, size) == 0;
}

uint32_t r3c_live_views(void) { return live_views; }
uint32_t r3c_destroyed_views(void) { return destroyed_views; }

static void remember(opencv_core_mat_handle *view)
{
    if (!view) abort();
    for (size_t i = 0; i < 64; ++i) {
        if (!views[i]) {
            views[i] = view;
            ++live_views;
            return;
        }
    }
    abort();
}

extern void __real_opencv_core_mat_destroy(opencv_core_mat_handle *view);
extern void r3h_forget_lease(opencv_core_mat_handle *view);
void __wrap_opencv_core_mat_destroy(opencv_core_mat_handle *view)
{
    r3h_forget_lease(view);
    if (view) {
        for (size_t i = 0; i < 64; ++i) {
            if (views[i] == view) {
                views[i] = NULL;
                --live_views;
                ++destroyed_views;
                break;
            }
        }
    }
    __real_opencv_core_mat_destroy(view);
}
uint32_t r3b_constructor_count(uint32_t boundary)
{
    return boundary < 4 ? calls[boundary] : UINT32_MAX;
}

#define WRAP(name, slot, parameters, arguments) \
    extern opencv_core_status __real_##name parameters; \
    opencv_core_status __wrap_##name parameters { \
        ++calls[slot]; \
        opencv_core_status status = __real_##name arguments; \
        if (status == OPENCV_CORE_OK) remember(*out); \
        return status; \
    }

WRAP(opencv_core_mat_create_external_2d, 0,
     (int32_t r, int32_t c, int32_t d, int32_t ch, void *p, uint64_t n,
      opencv_core_mat_handle **out), (r, c, d, ch, p, n, out))
WRAP(opencv_core_mat_create_external_nd, 1,
     (int32_t dims, const int32_t *sizes, int32_t d, int32_t ch, void *p,
      uint64_t n, opencv_core_mat_handle **out),
     (dims, sizes, d, ch, p, n, out))
WRAP(opencv_core_mat_create_external_2d_strided, 2,
     (int32_t r, int32_t c, int32_t d, int32_t ch, void *p, uint64_t n,
      uint64_t step, opencv_core_mat_handle **out),
     (r, c, d, ch, p, n, step, out))
WRAP(opencv_core_mat_create_external_nd_strided, 3,
     (int32_t dims, const int32_t *sizes, const uint64_t *steps, int32_t d,
      int32_t ch, void *p, uint64_t n, opencv_core_mat_handle **out),
     (dims, sizes, steps, d, ch, p, n, out))