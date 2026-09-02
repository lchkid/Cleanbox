param([string]$Json = 'tools/ui_test/tmp/tree.json', [string]$Method = 'ext.flutter.inspector.getRootWidgetSummaryTree', [string]$Arg = '')
$ErrorActionPreference = "Stop"
$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$reqId = 0
function Send-Rpc([string]$method, $params) {
  $script:reqId += 1
  $obj = @{ jsonrpc = "2.0"; id = $script:reqId; method = $method }
  if ($null -ne $params) { $obj.params = $params }
  $body = $obj | ConvertTo-Json -Depth 20 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
  $seg = [System.ArraySegment[byte]]::new($bytes)
  [void]$ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $sb = New-Object System.Text.StringBuilder
  do {
    $buf = New-Object byte[] 4194304
    $rseg = [System.ArraySegment[byte]]::new($buf)
    $res = $ws.ReceiveAsync($rseg, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buf, 0, $res.Count))
    if ($res.EndOfMessage) { break }
  } while ($true)
  return $sb.ToString()
}
[void]$ws.ConnectAsync([Uri]"ws://127.0.0.1:8186/ws", [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
$vmRaw = Send-Rpc "getVM" $null
$vm = $vmRaw | ConvertFrom-Json
$isolateId = $vm.result.isolates[0].id
$params = @{ isolateId = $isolateId }
if ($Ext -ne '') { $params.arg = $Ext }
$r = Send-Rpc $Method $params
$o = $r | ConvertFrom-Json
if ($o.error) { Write-Output "EXT_ERROR: $($o.error.message)" }
else { [System.IO.File]::WriteAllText($Json, $r, (New-Object System.Text.UTF8Encoding $false)) }
$ws.Dispose()
