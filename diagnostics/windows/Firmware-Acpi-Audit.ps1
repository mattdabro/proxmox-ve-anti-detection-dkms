# Windows PowerShell 5.1+; read-only ACPI and UEFI inventory.
[CmdletBinding()]
param([string]$OutputPath)
$ErrorActionPreference = 'Stop'
function SafeCim([string]$Name) {
    try { @(Get-CimInstance -ClassName $Name -ErrorAction Stop) }
    catch { @() }
}
$bios = @(SafeCim 'Win32_BIOS' | Select-Object Manufacturer, SMBIOSBIOSVersion, Version)
$thermal = @(SafeCim 'Win32_TemperatureProbe' | Select-Object Name, Status, CurrentReading)
$fan = @(SafeCim 'Win32_Fan' | Select-Object Name, Status, DesiredSpeed)
$acpi = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.InstanceId -match '^ACPI\\' } |
    Select-Object FriendlyName, InstanceId, Status)
$fw = $null
try { $fw = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name PEFirmwareType -ErrorAction Stop).PEFirmwareType }
catch { }
$report = [ordered]@{
    Utc = [DateTime]::UtcNow.ToString('o')
    FirmwareType = $fw
    SmbiosBios = $bios
    AcpiDevices = $acpi
    WmiTemperatureProbes = $thermal
    WmiFans = $fan
    Notes = @(
        'FirmwareType 2 indicates UEFI when the registry value is present.',
        'SMBIOS firmware fields are not the EFI System Table FirmwareVendor pointer.',
        'An empty Win32_Fan or Win32_TemperatureProbe result does not prove sensor hardware is absent.',
        'This script does not create or spoof ACPI devices.'
    )
}
$json = $report | ConvertTo-Json -Depth 6
if ($OutputPath) { [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputPath), $json) }
else { $json }
