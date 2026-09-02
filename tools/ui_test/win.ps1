param([int]$ProcId = 0)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinRect {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
if ($ProcId -gt 0) {
  $p = Get-Process -Id $ProcId
} else {
  $p = Get-Process | Where-Object { $_.ProcessName -like 'Cleanbox' -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}
if (-not $p) { Write-Output "(no window)"; exit 1 }
[WinRect]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
$r = New-Object WinRect+RECT
[WinRect]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
Write-Output "pid=$($p.Id) title='$($p.MainWindowTitle)' rect=$($r.L),$($r.T)..$($r.R),$($r.B) size=$($r.R-$r.L)x$($r.B-$r.T)"