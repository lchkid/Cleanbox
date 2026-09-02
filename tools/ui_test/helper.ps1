param([switch]$Stop)
$svc = Get-Service | Where-Object { $_.Name -like '*Cleanbox*' -or $_.DisplayName -like '*Cleanbox*' }
if ($svc) {
  $svc | Format-Table -AutoSize Name,Status,DisplayName
  if ($Stop) {
    foreach ($s in $svc) {
      try { Stop-Service -Name $s.Name -Force -ErrorAction Stop; Write-Output "stopped $($s.Name)" }
      catch { Write-Output "stop failed $($s.Name): $($_.Exception.Message)" }
    }
  }
} else { Write-Output "(no Cleanbox service found)" }