/* Test-executable-only linker controls; production symbols remain unchanged. */
struct opencv_core_scalar;
#include "opencv_core_shim.h"
#include <string.h>

static int mode;
void runtime_identity_fault_mode(int value) { mode = value; }

extern opencv_core_status __real_opencv_core_native_version_string(
    char *, uint64_t, uint64_t *, uint64_t *);
extern opencv_core_status __real_opencv_core_native_build_information(
    char *, uint64_t, uint64_t *, uint64_t *);

static opencv_core_status control(char *buffer, uint64_t capacity,
    uint64_t *required, uint64_t *written) {
    *required = 3;
    *written = 0;
    if (!buffer) {
        if (mode == 1) *required = UINT64_MAX;
        if (mode == 2) *written = 1;
        if (mode == 3) return OPENCV_CORE_ERROR_STD;
        return OPENCV_CORE_OK;
    }
    if (capacity != 4) return OPENCV_CORE_ERROR_INVALID_ARGUMENT;
    memcpy(buffer, "abc", 4);
    *written = 3;
    if (mode == 4) *required = 2;
    if (mode == 5) *written = 2;
    if (mode == 6) buffer[3] = '!';
    if (mode == 7) return OPENCV_CORE_ERROR_STD;
    return OPENCV_CORE_OK;
}

opencv_core_status __wrap_opencv_core_native_version_string(
    char *buffer, uint64_t capacity, uint64_t *required, uint64_t *written) {
    if (!mode) return __real_opencv_core_native_version_string(
        buffer, capacity, required, written);
    return control(buffer, capacity, required, written);
}
opencv_core_status __wrap_opencv_core_native_build_information(
    char *buffer, uint64_t capacity, uint64_t *required, uint64_t *written) {
    if (!mode) return __real_opencv_core_native_build_information(
        buffer, capacity, required, written);
    return control(buffer, capacity, required, written);
}