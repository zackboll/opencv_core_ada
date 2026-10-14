/* GNU ld forwarding control: exercise the real shim, not a mock result. */
struct opencv_core_scalar;
#include "opencv_core_shim.h"
#include <stdlib.h>

static int32_t expected;
static uint32_t calls;

void k_means_expect_attempts(int32_t value) { expected = value; }
uint32_t k_means_attempt_calls(void) { return calls; }

extern opencv_core_status __real_opencv_core_mat_kmeans(
    const opencv_core_mat_handle *, int32_t, int32_t, double, int32_t,
    int32_t, opencv_core_mat_handle **, opencv_core_mat_handle **, double *);

opencv_core_status __wrap_opencv_core_mat_kmeans(
    const opencv_core_mat_handle *samples, int32_t clusters, int32_t iterations,
    double epsilon, int32_t attempts, int32_t initialization,
    opencv_core_mat_handle **labels, opencv_core_mat_handle **centers,
    double *compactness)
{
    if (attempts != expected) abort();
    ++calls;
    return __real_opencv_core_mat_kmeans(samples, clusters, iterations,
        epsilon, attempts, initialization, labels, centers, compactness);
}

extern opencv_core_status __real_opencv_core_mat_kmeans_with_initial_labels(
    const opencv_core_mat_handle *, const opencv_core_mat_handle *, int32_t,
    int32_t, double, int32_t, int32_t, opencv_core_mat_handle **,
    opencv_core_mat_handle **, double *);

opencv_core_status __wrap_opencv_core_mat_kmeans_with_initial_labels(
    const opencv_core_mat_handle *samples, const opencv_core_mat_handle *initial,
    int32_t clusters, int32_t iterations, double epsilon, int32_t attempts,
    int32_t initialization, opencv_core_mat_handle **labels,
    opencv_core_mat_handle **centers, double *compactness)
{
    if (attempts != expected) abort();
    ++calls;
    return __real_opencv_core_mat_kmeans_with_initial_labels(samples, initial,
        clusters, iterations, epsilon, attempts, initialization, labels,
        centers, compactness);
}