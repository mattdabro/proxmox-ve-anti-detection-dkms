#include <windows.h>
#include <intrin.h>
#include <stdint.h>
#include <stdio.h>

static __forceinline uint64_t begin_tsc(void)
{
    int cpu[4];
    __cpuid(cpu, 0);
    return __rdtsc();
}

static __forceinline uint64_t end_tsc(void)
{
    unsigned aux;
    uint64_t value = __rdtscp(&aux);
    _mm_lfence();
    return value;
}

int main(void)
{
    const int iterations = 1000000;
    uint64_t minimum = UINT64_MAX;
    uint64_t total = 0;

    for (int i = 0; i < iterations; ++i) {
        uint64_t a = begin_tsc();
        uint64_t b = end_tsc();
        uint64_t d = b - a;

        if (d < minimum) {
            minimum = d;
        }

        total += d;
    }

    printf(
        "samples=%d\nmin=%llu\navg=%.2f\n",
        iterations,
        (unsigned long long)minimum,
        (double)total / iterations
    );

    return 0;
}
