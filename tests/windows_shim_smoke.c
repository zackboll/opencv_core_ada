/*
 * Windows CI-only smoke test for the GNAT executable -> MSYS2 shim C ABI.
 * Not part of the public Ada API or the Linux/macOS test crates.
 */

#include "opencv_core_shim.h"

#include <stdio.h>

static void
print_shim_failure(const char *operation, opencv_core_status status)
{
    const char *message = opencv_core_last_error_message();

    fprintf(stderr, "windows_shim_smoke: %s failed with status %d\n",
            operation, (int)status);
    if (message != NULL && message[0] != '\0') {
        fprintf(stderr, "windows_shim_smoke: %s\n", message);
    }
}

int
main(void)
{
    opencv_core_mat_handle *mat = NULL;
    opencv_core_status status;

    status = opencv_core_set_rng_seed(1);
    if (status != OPENCV_CORE_OK) {
        print_shim_failure("opencv_core_set_rng_seed", status);
        return 1;
    }

    status = opencv_core_mat_create(&mat);
    if (status != OPENCV_CORE_OK) {
        print_shim_failure("opencv_core_mat_create", status);
        return 1;
    }

    if (mat == NULL) {
        fprintf(stderr,
                "windows_shim_smoke: opencv_core_mat_create returned a null handle\n");
        return 1;
    }

    opencv_core_mat_destroy(mat);

    printf("windows_shim_smoke: GNAT gcc executable loaded MSYS2 shim and created a Mat\n");
    return 0;
}
