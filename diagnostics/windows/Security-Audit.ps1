#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"

$result = [ordered]@{}

$result.TPM = try {
    Get-Tpm | Select-Object *
} catch {
    @{ Error = $_.Exception.Message }
}

$result.SecureBoot = try {
    Confirm-SecureBootUEFI
} catch {
    $_.Exception.Message
}

$result.DeviceGuard = try {
    Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard |
        Select-Object *
} catch {
    @{ Error = $_.Exception.Message }
}

$result.BitLocker = try {
    Get-BitLockerVolume |
        Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionMethod
} catch {
    @{ Error = $_.Exception.Message }
}

$result.WindowsTime = (& w32tm.exe /query /status 2>&1 | Out-String)

$result | ConvertTo-Json -Depth 12
