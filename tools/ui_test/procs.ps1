param([switch]$Kill)
$procs = Get-Process | Where-Object { $_.ProcessName -like 'Cleanbox*' }
foreach ($p in $procs) {
  if ($Kill) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Output "killed $($p.ProcessName) $($p.Id)" }
    catch { Write-Output "failed $($p.ProcessName) $($p.Id): $($_.Exception.Message)" }
  } else {
    Write-Output "$($p.ProcessName) $($p.Id)"
  }
}
if (-not $procs) { Write-Output "(none)" }