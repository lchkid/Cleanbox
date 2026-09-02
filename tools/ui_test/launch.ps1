param([string]$Exe = "", [int]$VMPort = 8186)
if ($Exe -eq "") { $Exe = "build/windows/x64/runner/Debug/Cleanbox.exe" }
$env:FLUTTER_ENGINE_SWITCHES = "2"
$env:FLUTTER_ENGINE_SWITCH_1 = "vm-service-port=$VMPort"
$env:FLUTTER_ENGINE_SWITCH_2 = "disable-service-auth-codes=true"
Start-Process -FilePath $Exe -WorkingDirectory (Split-Path -Parent $Exe)
Write-Output "launched $Exe (vm $VMPort)"