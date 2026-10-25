/*
 * pve-lab-hwmon.c
 *
 * Explicitly lab-identified virtual hardware monitor.
 * This device is for compatibility and deterministic telemetry testing.
 */
#include "qemu/osdep.h"
#include "hw/pci/pci.h"
#include "hw/pci/pci_device.h"
#include "hw/qdev-properties.h"
#include "qemu/module.h"
#include "qemu/timer.h"
#include "migration/vmstate.h"

#define TYPE_PVE_LAB_HWMON "pve-lab-hwmon"
OBJECT_DECLARE_SIMPLE_TYPE(PVELabHwmonState, PVE_LAB_HWMON)

#define BAR_SIZE 0x1000

enum {
    REG_CPU_TEMP   = 0x00,
    REG_BOARD_TEMP = 0x04,
    REG_CPU_FAN    = 0x08,
    REG_CASE_FAN   = 0x0c,
    REG_CPU_FCTL   = 0x10,
    REG_VCORE_MV   = 0x14,
    REG_12V_MV     = 0x18,
    REG_5V_MV      = 0x1c,
    REG_33V_MV     = 0x20,
};

struct PVELabHwmonState {
    PCIDevice parent_obj;
    MemoryRegion mmio;
    QEMUTimer *timer;

    uint32_t init_cpu_temp_dk;
    uint32_t init_board_temp_dk;
    uint32_t init_cpu_fan_rpm;
    uint32_t init_case_fan_rpm;
    uint32_t init_cpu_fan_control;
    uint32_t init_vcore_mv;
    uint32_t init_v12_mv;
    uint32_t init_v5_mv;
    uint32_t init_v33_mv;

    uint32_t cpu_temp_dk;
    uint32_t board_temp_dk;
    uint32_t cpu_fan_rpm;
    uint32_t case_fan_rpm;
    uint32_t cpu_fan_control;
    uint32_t vcore_mv;
    uint32_t v12_mv;
    uint32_t v5_mv;
    uint32_t v33_mv;
};

static uint64_t pve_hwmon_read(void *opaque, hwaddr addr, unsigned size)
{
    PVELabHwmonState *s = opaque;

    switch (addr) {
    case REG_CPU_TEMP:
        return s->cpu_temp_dk;
    case REG_BOARD_TEMP:
        return s->board_temp_dk;
    case REG_CPU_FAN:
        return s->cpu_fan_rpm;
    case REG_CASE_FAN:
        return s->case_fan_rpm;
    case REG_CPU_FCTL:
        return s->cpu_fan_control;
    case REG_VCORE_MV:
        return s->vcore_mv;
    case REG_12V_MV:
        return s->v12_mv;
    case REG_5V_MV:
        return s->v5_mv;
    case REG_33V_MV:
        return s->v33_mv;
    default:
        return 0;
    }
}

static void pve_hwmon_write(void *opaque, hwaddr addr, uint64_t value,
                            unsigned size)
{
    PVELabHwmonState *s = opaque;

    if (addr == REG_CPU_FCTL) {
        s->cpu_fan_control = MIN(value, 100);
    }
}

static const MemoryRegionOps pve_hwmon_ops = {
    .read = pve_hwmon_read,
    .write = pve_hwmon_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
    .valid = {
        .min_access_size = 4,
        .max_access_size = 4,
    },
    .impl = {
        .min_access_size = 4,
        .max_access_size = 4,
    },
};

static void pve_hwmon_tick(void *opaque)
{
    PVELabHwmonState *s = opaque;
    uint32_t temp_c;
    uint32_t target_rpm = 700;
    uint32_t requested;

    if (s->cpu_temp_dk < 2732) {
        s->cpu_temp_dk = 2732;
    }

    temp_c = (s->cpu_temp_dk - 2732) / 10;

    if (temp_c < 45) {
        s->cpu_temp_dk += 1;
    } else if (temp_c > 45) {
        s->cpu_temp_dk -= 1;
    }

    if (temp_c > 35) {
        target_rpm += (temp_c - 35) * 45;
    }

    requested = 600 + s->cpu_fan_control * 24;
    if (requested > target_rpm) {
        target_rpm = requested;
    }

    target_rpm = MIN(target_rpm, 3200);

    s->cpu_fan_rpm =
        (s->cpu_fan_rpm * 3 + target_rpm) / 4;

    s->case_fan_rpm =
        650 + (temp_c > 30 ? (temp_c - 30) * 20 : 0);

    timer_mod(
        s->timer,
        qemu_clock_get_ms(QEMU_CLOCK_VIRTUAL) + 1000
    );
}

static void pve_hwmon_reset(DeviceState *dev)
{
    PVELabHwmonState *s = PVE_LAB_HWMON(dev);

    s->cpu_temp_dk = s->init_cpu_temp_dk;
    s->board_temp_dk = s->init_board_temp_dk;
    s->cpu_fan_rpm = s->init_cpu_fan_rpm;
    s->case_fan_rpm = s->init_case_fan_rpm;
    s->cpu_fan_control = MIN(s->init_cpu_fan_control, 100);
    s->vcore_mv = s->init_vcore_mv;
    s->v12_mv = s->init_v12_mv;
    s->v5_mv = s->init_v5_mv;
    s->v33_mv = s->init_v33_mv;
}

static void pve_hwmon_realize(PCIDevice *pdev, Error **errp)
{
    PVELabHwmonState *s = PVE_LAB_HWMON(pdev);

    pve_hwmon_reset(DEVICE(pdev));

    memory_region_init_io(
        &s->mmio,
        OBJECT(s),
        &pve_hwmon_ops,
        s,
        "pve-lab-hwmon-mmio",
        BAR_SIZE
    );

    pci_register_bar(
        pdev,
        0,
        PCI_BASE_ADDRESS_SPACE_MEMORY,
        &s->mmio
    );

    s->timer = timer_new_ms(
        QEMU_CLOCK_VIRTUAL,
        pve_hwmon_tick,
        s
    );

    timer_mod(
        s->timer,
        qemu_clock_get_ms(QEMU_CLOCK_VIRTUAL) + 1000
    );
}

static void pve_hwmon_exit(PCIDevice *pdev)
{
    PVELabHwmonState *s = PVE_LAB_HWMON(pdev);

    timer_free(s->timer);
    s->timer = NULL;
}

static const VMStateDescription vmstate_pve_hwmon = {
    .name = TYPE_PVE_LAB_HWMON,
    .version_id = 1,
    .minimum_version_id = 1,
    .fields = (const VMStateField[]) {
        VMSTATE_UINT32(cpu_temp_dk, PVELabHwmonState),
        VMSTATE_UINT32(board_temp_dk, PVELabHwmonState),
        VMSTATE_UINT32(cpu_fan_rpm, PVELabHwmonState),
        VMSTATE_UINT32(case_fan_rpm, PVELabHwmonState),
        VMSTATE_UINT32(cpu_fan_control, PVELabHwmonState),
        VMSTATE_UINT32(vcore_mv, PVELabHwmonState),
        VMSTATE_UINT32(v12_mv, PVELabHwmonState),
        VMSTATE_UINT32(v5_mv, PVELabHwmonState),
        VMSTATE_UINT32(v33_mv, PVELabHwmonState),
        VMSTATE_END_OF_LIST()
    }
};

static const Property pve_hwmon_properties[] = {
    DEFINE_PROP_UINT32("cpu-temp-dk", PVELabHwmonState, init_cpu_temp_dk, 3132),
    DEFINE_PROP_UINT32("board-temp-dk", PVELabHwmonState, init_board_temp_dk, 3042),
    DEFINE_PROP_UINT32("cpu-fan-rpm", PVELabHwmonState, init_cpu_fan_rpm, 900),
    DEFINE_PROP_UINT32("case-fan-rpm", PVELabHwmonState, init_case_fan_rpm, 700),
    DEFINE_PROP_UINT32("fan-control", PVELabHwmonState, init_cpu_fan_control, 30),
    DEFINE_PROP_UINT32("vcore-mv", PVELabHwmonState, init_vcore_mv, 1100),
    DEFINE_PROP_UINT32("v12-mv", PVELabHwmonState, init_v12_mv, 12040),
    DEFINE_PROP_UINT32("v5-mv", PVELabHwmonState, init_v5_mv, 5020),
    DEFINE_PROP_UINT32("v33-mv", PVELabHwmonState, init_v33_mv, 3310),
};

static void pve_hwmon_class_init(ObjectClass *klass, const void *data)
{
    DeviceClass *dc = DEVICE_CLASS(klass);
    PCIDeviceClass *pc = PCI_DEVICE_CLASS(klass);

    pc->realize = pve_hwmon_realize;
    pc->exit = pve_hwmon_exit;

    /*
     * QEMU test vendor plus project-local device ID.
     * This explicitly does not impersonate commercial silicon.
     */
    pc->vendor_id = 0x1234;
    pc->device_id = 0x11e9;
    pc->revision = 0x01;
    pc->class_id = PCI_CLASS_SYSTEM_OTHER;

    dc->desc = "PVE Lab Hardware Monitor";
    dc->vmsd = &vmstate_pve_hwmon;
    device_class_set_props(dc, pve_hwmon_properties);
    device_class_set_legacy_reset(dc, pve_hwmon_reset);
}

static const TypeInfo pve_hwmon_info = {
    .name = TYPE_PVE_LAB_HWMON,
    .parent = TYPE_PCI_DEVICE,
    .instance_size = sizeof(PVELabHwmonState),
    .class_init = pve_hwmon_class_init,
    .interfaces = (const InterfaceInfo[]) {
        { INTERFACE_CONVENTIONAL_PCI_DEVICE },
        { }
    },
};

static void pve_hwmon_register_types(void)
{
    type_register_static(&pve_hwmon_info);
}

type_init(pve_hwmon_register_types)
