#Requires -Version 5.1
$ErrorActionPreference = "Stop"

if (-not ("PveNativeClock" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class PveNativeClock {
    [DllImport("kernel32.dll")]
    public static extern bool QueryPerformanceCounter(out long value);

    [DllImport("kernel32.dll")]
    public static extern bool QueryPerformanceFrequency(out long value);

    [DllImport("ntdll.dll")]
    public static extern int NtQueryTimerResolution(
        out UInt32 minimum,
        out UInt32 maximum,
        out UInt32 current
    );
}
"@
}

[Int64]$freq = 0
[Int64]$start = 0
[Int64]$end = 0

[void][PveNativeClock]::QueryPerformanceFrequency([ref]$freq)
[void][PveNativeClock]::QueryPerformanceCounter([ref]$start)

Start-Sleep -Seconds 10

[void][PveNativeClock]::QueryPerformanceCounter([ref]$end)

[UInt32]$min = 0
[UInt32]$max = 0
[UInt32]$current = 0

$status = [PveNativeClock]::NtQueryTimerResolution(
    [ref]$min,
    [ref]$max,
    [ref]$current
)

[pscustomobject]@{
    QpcFrequencyHz = $freq
    QpcNominalTickNanoseconds = [Math]::Round(1e9 / $freq, 3)
    QpcElapsedSeconds = [Math]::Round(($end - $start) / [double]$freq, 9)
    TimerResolutionStatus = $status
    Minimum100ns = $min
    Maximum100ns = $max
    Current100ns = $current
    WindowsTimeStatus = (& w32tm.exe /query /status 2>&1 | Out-String)
}
