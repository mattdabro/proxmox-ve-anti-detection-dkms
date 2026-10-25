# Windows PowerShell 5.1+ — read-only Windows VM hardware inventory.
# Run in an elevated PowerShell session for complete firmware information.
$ErrorActionPreference = 'Stop'
function Read-CimSafe([string]$ClassName) {
    try {
        @(Get-CimInstance -ClassName $ClassName -ErrorAction Stop |
            Select-Object *)
    } catch {
        @()
    }
}
$computer = Read-CimSafe 'Win32_ComputerSystem'
$bios = Read-CimSafe 'Win32_BIOS'
$baseboard = Read-CimSafe 'Win32_BaseBoard'
$enclosure = Read-CimSafe 'Win32_SystemEnclosure'
$processor = Read-CimSafe 'Win32_Processor'
$fan = Read-CimSafe 'Win32_Fan'
$temp = Read-CimSafe 'Win32_TemperatureProbe'
$drivers = @(Get-CimInstance Win32_PnPSignedDriver |
    Where-Object { $_.DeviceName -match 'VirtIO|Red Hat|QEMU' -or $_.Manufacturer -match 'Red Hat|QEMU' } |
    Select-Object DeviceName, Manufacturer, DriverVersion, InfName)
$devices = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.InstanceId -match 'VEN_1AF4|VEN_1B36|VEN_1234' } |
    Select-Object FriendlyName, InstanceId, Status)
$firmware = $null
try {
    $firmware = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control' -ErrorAction Stop).PEFirmwareType
} catch { }
$report = [ordered]@{
    TimestampUtc = [DateTime]::UtcNow.ToString('o')
    Computer = @($computer | Select-Object Manufacturer, Model, HypervisorPresent)
    FirmwareType = $firmware
    BIOS = @($bios | Select-Object Manufacturer, SMBIOSBIOSVersion, Version, SerialNumber)
    Baseboard = @($baseboard | Select-Object Manufacturer, Product, Version)
    Enclosure = @($enclosure | Select-Object Manufacturer, ChassisTypes)
    Processor = @($processor | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors)
    FanObjects = $fan.Count
    TemperatureProbeObjects = $temp.Count
    MatchedDrivers = $drivers
    MatchedPciDevices = $devices
    Notes = @(
        'Empty WMI sensor classes do not prove physical sensors are absent.',
        'FirmwareType: 1 = BIOS, 2 = UEFI (when provided).',
        'HypervisorPresent is not a definitive VM classification.',
        'PCI vendor IDs are used for normal device driver matching.'
    )
}
$report | ConvertTo-Json -Depth 6
