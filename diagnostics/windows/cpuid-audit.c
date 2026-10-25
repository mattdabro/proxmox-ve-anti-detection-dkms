#include <windows.h>
#include <intrin.h>
#include <stdio.h>

static void dump_leaf(unsigned leaf, unsigned subleaf)
{
    int r[4];

    __cpuidex(r, (int)leaf, (int)subleaf);

    printf(
        "%08X %08X EAX=%08X EBX=%08X ECX=%08X EDX=%08X\n",
        leaf,
        subleaf,
        (unsigned)r[0],
        (unsigned)r[1],
        (unsigned)r[2],
        (unsigned)r[3]
    );
}

int main(void)
{
    int r[4];

    __cpuid(r, 0);
    unsigned max_basic = (unsigned)r[0];

    for (unsigned leaf = 0; leaf <= max_basic; ++leaf) {
        dump_leaf(leaf, 0);
    }

    __cpuid(r, 0x80000000);
    unsigned max_ext = (unsigned)r[0];

    for (unsigned leaf = 0x80000000; leaf <= max_ext; ++leaf) {
        dump_leaf(leaf, 0);
    }

    for (unsigned leaf = 0x40000000; leaf <= 0x40000110; ++leaf) {
        dump_leaf(leaf, 0);
    }

    return 0;
}
