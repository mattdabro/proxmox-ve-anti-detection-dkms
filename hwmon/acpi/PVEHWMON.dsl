DefinitionBlock ("PVEHWMON.aml", "SSDT", 2, "PVELAB", "LABHWMON", 0x00000002)
{
    External (\_SB.PCI0, DeviceObj)

    /*
     * pve-lab-hwmon is pinned by the VM factory to Q35 root-bus device 0x1E,
     * function 0. This SSDT therefore creates a firmware description for that
     * PCI function and maps BAR0 through PciBarTarget.
     */

    Scope (\_SB.PCI0)
    {
        Device (HWM0)
        {
            Name (_ADR, 0x001E0000)
            Name (_UID, Zero)

            Method (_STR, 0, NotSerialized)
            {
                Return (Unicode ("PVE Lab Hardware Monitor"))
            }

            OperationRegion (HREG, PciBarTarget, Zero, 0x1000)

            Field (HREG, DWordAcc, NoLock, Preserve)
            {
                TEMP, 32,
                BRDT, 32,
                FANR, 32,
                FANC, 32,
                FCTL, 32,
                VCOR, 32,
                V12R, 32,
                V5R0, 32,
                V33R, 32
            }
        }
    }

    Scope (\_SB)
    {
        Device (FAN0)
        {
            Name (_HID, "PNP0C0B")
            Name (_UID, Zero)

            Method (_STR, 0, NotSerialized)
            {
                Return (Unicode ("PVE Lab CPU Fan"))
            }

            Method (_FIF, 0, NotSerialized)
            {
                Return (Package ()
                {
                    Zero,
                    One,
                    5,
                    Zero
                })
            }

            Method (_FPS, 0, NotSerialized)
            {
                Return (Package ()
                {
                    Zero,

                    Package () { 20, 0, 650, 0xFFFFFFFF, 0xFFFFFFFF },
                    Package () { 40, 1, 1000, 0xFFFFFFFF, 0xFFFFFFFF },
                    Package () { 60, 2, 1500, 0xFFFFFFFF, 0xFFFFFFFF },
                    Package () { 80, 3, 2200, 0xFFFFFFFF, 0xFFFFFFFF },
                    Package () { 100, 4, 3000, 0xFFFFFFFF, 0xFFFFFFFF }
                })
            }

            Method (_FSL, 1, Serialized)
            {
                Store (Arg0, \_SB.PCI0.HWM0.FCTL)
            }

            Method (_FST, 0, NotSerialized)
            {
                Return (Package ()
                {
                    Zero,
                    \_SB.PCI0.HWM0.FCTL,
                    \_SB.PCI0.HWM0.FANR
                })
            }
        }
    }

    Scope (\_TZ)
    {
        ThermalZone (TZ00)
        {
            Method (_STR, 0, NotSerialized)
            {
                Return (Unicode ("PVE Lab CPU Thermal Zone"))
            }

            Method (_TMP, 0, Serialized)
            {
                Return (\_SB.PCI0.HWM0.TEMP)
            }

            Method (_CRT, 0, NotSerialized)
            {
                Return (3732)
            }

            Method (_AC0, 0, NotSerialized)
            {
                Return (3332)
            }

            Name (_AL0, Package ()
            {
                \_SB.FAN0
            })

            Name (_TZP, 10)

            Method (_TSN, 0, NotSerialized)
            {
                Return (\_SB.PCI0.HWM0)
            }

            Name (_TZD, Package ()
            {
                \_SB.PCI0.HWM0
            })
        }
    }
}
