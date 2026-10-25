#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue

if (-not $cl) {
    throw "cl.exe not found. Run this from a Visual Studio Developer PowerShell/Command Prompt."
}

Push-Location $PSScriptRoot

try {
    & cl.exe /nologo /O2 /W4 cpuid-audit.c
    if ($LASTEXITCODE -ne 0) { throw "cpuid-audit.c compilation failed" }

    & cl.exe /nologo /O2 /W4 tsc-bench.c
    if ($LASTEXITCODE -ne 0) { throw "tsc-bench.c compilation failed" }
}
finally {
    Pop-Location
}
